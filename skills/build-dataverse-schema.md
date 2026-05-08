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

## Path A — Dataverse MCP (recommended)

### Step A1 — Confirm preview tools are available

Schema-write requires the preview endpoint. Run a quick read to confirm — if `list_tables` works but `create_table` doesn't, the user hasn't enabled preview. Tell them:
> "I need preview tools to create tables. Power Platform Admin Center → your env → Settings → Product → Features → Dataverse Model Context Protocol → enable 'Allow MCP clients to interact with Dataverse MCP server (Preview version)'. Then re-run with `claude mcp add dataverse -t stdio -- npx -y @microsoft/dataverse mcp <env-url> --preview`."

### Step A2 — Create the schema artifacts

For each entity in the design:

1. **Choice sets first** — Dataverse columns can reference them
2. **Tables** — without lookups
3. **Columns on each table** — including the choice column references
4. **Relationships** — 1:N lookups, N:N where needed
5. **Security roles** — Reader / Manager / Administrator per `dataverse-schema-standards.md`

Use the Dataverse MCP create tools for each. Validate after each step (call list/describe to confirm the artifact exists).

### Step A3 — Document what was created

Generate `examples/<app>/dataverse/schema.yaml` reflecting what you actually created. This is the source of truth for future re-creates / promotions to other environments.

Generate `examples/<app>/docs/schema.md` with:
- Mermaid ER diagram
- Table-by-table reference
- Security model

### Step A4 — Report

Tell the user:
- Which tables/columns/choices/relationships were created
- Any items that failed (with the error)
- Where the docs are

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
