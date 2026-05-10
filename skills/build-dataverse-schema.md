---
description: Design a Dataverse table schema from a domain description, generate the table-create script, and document it. USE WHEN the user asks to design a Dataverse schema, create tables, or model their data.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build Dataverse Schema Skill

This skill has two execution paths depending on whether the **Dataverse MCP server** is available:

| If Dataverse MCP is configured... | If not... |
|---|---|
| Claude calls the MCP's create-table / create-column / create-choice / create-relationship tools directly. Tables exist in the env when done. | Claude generates the YAML schema manifest + a PAC CLI script the user can run later. |

The toolkit prefers the **MCP path** for incremental, AI-driven schema work. The YAML/PAC CLI path is the fallback when the user hasn't set up Dataverse MCP yet.

## Step 1 — Read standards (always)

- `memory/dataverse-schema-standards.md`
- `memory/powerapps-naming.md`
- `memory/security-standards.md`
- `memory/powerplatform-mcp-framework.md`

## Step 2 — Detect Dataverse MCP availability

Run:

```bash
claude mcp list
```

If `dataverse` appears in the list, take Path A. If not, ask the user once: "Want me to set up Dataverse MCP first so I can create the tables directly?" If yes, delegate to the `/configure-dataverse-mcp` skill, then return here.

If the user says no (or wants the manifest path explicitly), take Path B.

## Step 3 — Decompose the domain

From the user's description, identify:

1. **Entities** — each becomes a table
2. **Attributes** — each entity's fields, with types and required flags
3. **Relationships** — 1:N (lookups), N:N (intersect tables)
4. **Choice sets** — bounded value sets; decide global vs local
5. **Security** — who reads, writes, deletes each table

If the domain is ambiguous, ask one clarifying question.

---

## Path A — Dataverse MCP, **Staged Build** (recommended when MCP is available)

> **Critical:** Do NOT create the full schema in one prompt. Dataverse MCP (preview) is unstable for long orchestration chains. Use the 6 staged steps below. Reference: `memory/dataverse-schema-standards.md` → "Path A — Dataverse MCP, Staged Build".

### Step A1 — Confirm preview tools are available

Schema-write requires the preview endpoint. Quick check — if `list_tables` works but `create_table` doesn't, the user hasn't enabled preview. Tell them:
> "I need preview tools to create tables. Power Platform Admin Center → your env → Settings → Product → Features → Dataverse Model Context Protocol → enable 'Allow MCP clients to interact with Dataverse MCP server (Preview version)'. Then re-run with `claude mcp add dataverse -t stdio -- npx -y @microsoft/dataverse mcp <env-url> --preview`."

### Step A2 — **Stage 1: Create the solution shell**

In its own prompt, ask the MCP to create just the solution + publisher. No tables.

```
Inside solution: <SolutionName>
Use publisher prefix: <prefix>
Action: Create empty solution + publisher only.
```

Verify with `list_solutions` before moving on.

### Step A3 — **Stage 2: Create base tables (one per prompt)**

For each entity in the design, send ONE prompt per table containing only:
- Table schema name + display name + plural display name
- The primary column (text)
- Ownership + auditing flags

**Do NOT include lookups, choice columns, or relationships in this stage.** Even if your `schema.yaml` has them, defer them to later stages.

Template for each prompt:
```
Inside solution: <SolutionName>
Use publisher prefix: <prefix>
Create this Dataverse table:
  schemaName:        <prefix>_<entity>
  displayName:       <Display>
  pluralDisplayName: <Plural>
  primaryColumn:     <prefix>_<primaryName>
  description:       <one-line>
  ownership:         Organization
  auditingEnabled:   true

After creation:
  1. Verify table exists
  2. Verify table belongs to <SolutionName> solution
  3. List logical names and column types
```

For Asset Management, the recommended order:
1. Asset Category
2. Asset
3. Asset Assignment
(Add Employee/Vendor/Location/Maintenance as needed for larger schemas — always before relationships.)

### Step A4 — **Stage 3: Verify all tables exist**

Call `list_tables` filtered by prefix. Confirm all expected tables are present. Wait ~5–10 seconds for metadata propagation before continuing — Dataverse is NOT instant.

### Step A5 — **Stage 4: Add simple columns (one table at a time)**

For each table, send ONE prompt that adds only its **simple columns** (text, date, number, memo, currency). Skip lookups and choices in this stage.

```
Inside solution: <SolutionName>
Add these columns to <prefix>_<entity>:
  - {schema, display, type=Text, maxLength}
  - {schema, display, type=DateTime, behavior=DateOnly}
  - {schema, display, type=Currency}
  - {schema, display, type=Memo, maxLength}

After each column:
  1. Verify success
  2. Wait for metadata propagation
  3. Continue only if successful
```

Limit: **5–10 columns max per prompt.** If a table has more, split into multiple prompts.

### Step A6 — **Stage 5: Add choice sets (one per prompt)**

For each choice set, send ONE prompt:

```
Inside solution: <SolutionName>
Create choice set <prefix>_<choiceName>:
  isGlobal: false
  options:
    - {value: 100000000, label: <Label1>}
    - {value: 100000001, label: <Label2>}
    ...

Then add to <prefix>_<entity> as column <prefix>_<columnName>.
```

After each, verify with `describe_table` that the column appears.

### Step A7 — **Stage 6: Add relationships LAST (one per prompt)**

For each lookup, send ONE prompt:

```
Inside solution: <SolutionName>
Create 1:N relationship:
  parent:        <prefix>_<parentEntity>
  child:         <prefix>_<childEntity>
  lookupColumn:  <prefix>_<lookupId>
  cascade:       <Restrict|RemoveLink|NoCascade>
  description:   <one-line>

After creation:
  1. Verify relationship exists
  2. Verify lookup column appears on child table
```

This is the most stable order — child tables already exist, so the foreign key references resolve immediately.

### Step A8 — Document what was created

Generate `examples/<app>/dataverse/schema.yaml` reflecting what was created.
Generate `examples/<app>/docs/schema.md` with: Mermaid ER diagram, table reference, security model.

### Step A9 — Report

Tell the user:
- Which tables/columns/choices/relationships were created
- Any failures (with the error)
- Where the docs are
- That `pac solution export --name <SolutionName> --path <Name>.zip` will produce the portable artifact for redeployment

### Don't (Path A specifics)

- ❌ Don't create the schema in one giant prompt — preview MCP fails on long chains
- ❌ Don't omit `Inside solution: <SolutionName>` — without it, MCP may create tables in Default Solution
- ❌ Don't create relationships before all related tables exist + metadata has propagated
- ❌ Don't bundle different artifact types in one prompt (e.g., "create table + add 5 columns + create lookup")

---

## Path B — YAML manifest + PAC CLI (fallback)

### Step B1 — Generate the schema manifest

Write to `templates/powerapps/dataverse/<solution>/schema.yaml` (or `examples/<app>/dataverse/schema.yaml`):

```yaml
solution:
  name: AssetManagement
  publisherPrefix: ws
  version: 1.0.0

tables:
  - schemaName: ws_asset
    displayName: Asset
    pluralDisplayName: Assets
    primaryColumn: ws_assetname
    description: Tracks IT equipment assigned to employees
    ownership: User

    columns:
      - { schemaName: ws_assetname,    displayName: Asset Name,    type: Text,    maxLength: 100, required: true }
      - { schemaName: ws_serialnumber, displayName: Serial Number, type: Text,    maxLength: 50,  required: true }
      - { schemaName: ws_status,       displayName: Status,        type: Choice,  optionSet: ws_assetstatus, required: true }
      ...

choiceSets:
  - schemaName: ws_assetstatus
    displayName: Asset Status
    options:
      - { value: 100000000, label: Available }
      - { value: 100000001, label: Assigned }
      ...

relationships:
  - type: 1:N
    name: ws_assetcategory_ws_asset
    parent: ws_assetcategory
    child: ws_asset
    cascade: Restrict
```

### Step B2 — Generate the create script

`automation/CreateSchema-<solution>.ps1` that reads the YAML and creates the tables via PAC CLI commands. (Note: PAC CLI doesn't have a single "create table from YAML" command; the script can wrap `pac data` operations or guide the user through Power Platform Admin Center / maker portal.)

### Step B3 — Generate seed data

`templates/powerapps/dataverse/<solution>/seed.json` — sample rows for testing.

### Step B4 — Document

`examples/<app>/docs/schema.md` — ER diagram (mermaid), table reference, security model.

### Step B5 — Tell the user how to apply it

> "I've written the schema manifest. To create the tables, you have three options:
> 1. **Set up Dataverse MCP** (recommended) — run `/configure-dataverse-mcp`, then re-run me. I'll create the tables directly.
> 2. **PAC CLI / maker portal** — run `automation/CreateSchema-<solution>.ps1` for guided creation.
> 3. **Solution import** — if you have an existing solution package, import via Power Platform Admin Center."

---

## Step 4 (always) — Validate

Whichever path was taken, lint the result against `dataverse-schema-standards.md`:

- All schema names use the publisher prefix
- All required columns are present (primary, status)
- All choice sets have at least 2 options
- All relationships have explicit cascade behavior
- Auditing decision documented per table

## Don't do

- Don't modify default tables (Account, Contact) unless explicitly asked
- Don't skip the publisher prefix
- Don't use generic column names (`name`, `description` without prefix)
- Don't skip security role assignments
- Don't take Path A without confirming preview tools are available — the create tools won't exist on the GA endpoint
- Don't take Path B silently when MCP is available — it's the slower path; offer Path A first
