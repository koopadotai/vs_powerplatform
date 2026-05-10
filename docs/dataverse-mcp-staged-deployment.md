# Dataverse MCP — Staged Deployment Runbook

A step-by-step checklist for using **Dataverse MCP (preview)** to build a custom solution end-to-end. This is the **most stable** pattern observed for AI-driven Power Platform schema work in 2026.

> **Why this runbook exists:** Dataverse MCP (preview) is unstable when given a full enterprise schema in one prompt. Failure modes include MCP context overflow, metadata propagation race conditions, hallucinated type enums, and choice/lookup/relationship dependency timing issues. The staged approach below dramatically improves success rate.

For the alternate `pac solution import` path (which works in corporate tenants where MCP is blocked), see [examples/asset-management/README.md](../examples/asset-management/README.md).

---

## Prerequisites checklist

- [ ] PAC CLI installed and authenticated: `pac org who`
- [ ] Dataverse MCP registered: `claude mcp list` shows `dataverse: ✓ Connected`
- [ ] Preview tools enabled for the env: Power Platform Admin Center → Environment → Settings → Product → Features → "Allow MCP clients to interact with Dataverse MCP server (Preview version)" → ON
- [ ] Tenant admin has consented to the Dataverse MCP CLI app (`0c412cc3-0dd6-449b-987f-05b053db9457`) — without this, browser sign-in fails with "Need admin approval"
- [ ] User has **System Customizer** or **System Administrator** role in the target env

If any are missing, switch to `pac solution import` path — see [examples/asset-management/README.md](../examples/asset-management/README.md).

---

## The core rules (read this first)

### Rule 1 — Always prefix every MCP prompt with the target solution

```
Inside solution: <SolutionName>
Use publisher prefix: <prefix>
```

Without this, Dataverse MCP often creates the table in the **Default Solution** rather than your custom one, especially in preview mode.

### Rule 2 — One artifact type per prompt

| Prompt contains... | Stable? |
|---|---|
| Just the solution shell | ✅ Yes |
| One table (name + primary column) | ✅ Yes |
| 5–10 simple columns on one table | ✅ Yes |
| One choice set | ✅ Yes |
| One lookup relationship | ✅ Yes |
| Table + columns + lookup + choice in one prompt | ❌ Frequently fails |

### Rule 3 — Verify and wait between steps

```
After EACH step:
  1. Verify success (list_tables / describe_table)
  2. Wait ~5–10 seconds for metadata propagation
  3. Re-read the schema state
  4. Continue only if successful
```

### Rule 4 — Order matters

Tables → Simple columns → Choice sets → Relationships → Alternate keys.
Lookups depend on the related table existing **and** its metadata being propagated.

---

## The 6 stages

### Stage 1 — Create the solution shell

**Goal:** An empty solution + publisher exists in the env.

Prompt template:
```
Use Dataverse MCP. Create:

solution:
  uniqueName:        <Name>
  displayName:       <Display>
  publisherUnique:   <PublisherName>
  publisherDisplay:  <Publisher Display>
  prefix:            <prefix>
  optionValuePrefix: 10000
  description:       <one-line>

After creation, verify:
  1. Solution appears in pac solution list
  2. Publisher exists with the correct prefix
```

Verify: `pac solution list | Select-String <Name>`

---

### Stage 2 — Create base tables (one prompt per table)

**Goal:** All tables exist with their primary column. NO lookups, choices, or relationships yet.

Prompt template (repeat for each table):
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
  2. Verify table belongs to <SolutionName> solution (NOT Default Solution)
  3. List logical names and column types
```

For asset-management, recommended order:
1. Asset Category
2. Asset
3. Asset Assignment

(Add Employee / Vendor / Location / Maintenance as needed for larger schemas — always before relationships.)

---

### Stage 3 — Verify all tables exist

```
List all tables in the <SolutionName> solution and confirm:
  - <prefix>_<entity1>
  - <prefix>_<entity2>
  - <prefix>_<entity3>

Wait 5-10 seconds for metadata propagation before proceeding.
```

If any table is missing or in the wrong solution → **stop, fix, retry stage 2**.

---

### Stage 4 — Add simple columns (one prompt per table)

**Goal:** Each table has its text / date / number / memo / currency columns. Skip lookups + choices in this stage.

Prompt template (per table):
```
Inside solution: <SolutionName>
Add these columns to <prefix>_<entity>:

  - {schemaName: <prefix>_serialnumber, displayName: Serial Number, type: Text,     maxLength: 50,   required: true}
  - {schemaName: <prefix>_purchasedate, displayName: Purchase Date, type: DateTime, behavior: DateOnly}
  - {schemaName: <prefix>_purchasecost, displayName: Purchase Cost, type: Currency}
  - {schemaName: <prefix>_warrantyend,  displayName: Warranty End,  type: DateTime, behavior: DateOnly}
  - {schemaName: <prefix>_assigneddate, displayName: Assigned Date, type: DateTime}
  - {schemaName: <prefix>_notes,        displayName: Notes,         type: Memo,     maxLength: 2000}

After each column:
  1. Verify success
  2. Wait for metadata propagation
  3. Continue only if successful
```

**Limit: 5–10 columns max per prompt.** If a table has more, split into multiple prompts.

---

### Stage 5 — Add choice sets (one prompt per choice)

Prompt template:
```
Inside solution: <SolutionName>

Create choice set <prefix>_<choiceName>:
  isGlobal: false
  options:
    - {value: 100000000, label: <Label1>}
    - {value: 100000001, label: <Label2>}
    - {value: 100000002, label: <Label3>}

Then add to <prefix>_<entity> as a column:
  schemaName:   <prefix>_<columnName>
  displayName:  <Display>
  type:         Choice
  optionSet:    <prefix>_<choiceName>
  required:     true

After creation, verify with describe_table that the column appears.
```

---

### Stage 6 — Add lookup relationships LAST (one prompt per relationship)

Prompt template:
```
Inside solution: <SolutionName>

Create 1:N relationship:
  parent:        <prefix>_<parentEntity>
  child:         <prefix>_<childEntity>
  lookupColumn:  <prefix>_<lookupId>
  required:      true
  cascade:       <Restrict | RemoveLink | NoCascade>
  description:   <one-line>

After creation:
  1. Verify relationship exists
  2. Verify lookup column appears on the child table
  3. Wait for metadata propagation
```

For asset-management:
1. ws_assetcategory → ws_asset (required, Restrict)
2. ws_asset → ws_assetassignment (required, RemoveLink)
3. SystemUser → ws_asset (optional, NoCascade)
4. SystemUser → ws_assetassignment (required, NoCascade)

---

### Stage 7 — Alternate keys (if needed)

Prompt template:
```
Inside solution: <SolutionName>

Create alternate key:
  table:        <prefix>_<entity>
  name:         <prefix>_<entity>_<columnName>_key
  displayName:  <Display>
  columns:      [<prefix>_<columnName>]
  description:  Enforces uniqueness for upsert and duplicate detection
```

For asset-management: alternate key on `ws_asset.ws_serialnumber`.

---

### Stage 8 — Capture the portable artifact

```powershell
pac solution export --name <SolutionName> --path <SolutionName>.zip --managed false
```

Commit this `.zip` as `examples/<app>/dataverse/<SolutionName>.zip` so teammates can deploy without going through the staged MCP build.

---

## What to do if a stage fails

| Symptom | Fix |
|---|---|
| Table created in **Default Solution** instead of yours | Re-state `Inside solution: <Name>` and retry. If already created in Default, delete and recreate. |
| `Entity not found` when creating relationship | Wait 10 seconds for metadata propagation. Re-run `list_tables`. If the table still isn't there, repeat stage 2 for that table. |
| Choice column creation succeeds but option set has wrong values | Stage 5's prompt was bundled with stage 4. Separate them. |
| "Hallucinated type" error from MCP | The schema spec used a non-Dataverse type (e.g. `String` instead of `Text`). Re-state with valid Dataverse type names. |
| MCP returns vague parsing errors after multi-table prompt | You bundled too much in one prompt. Break apart and retry. |
| Browser auth fails with "Need admin approval" | Tenant admin consent missing. Switch to `pac solution import` path. |

---

## Don't do

- ❌ Don't ask the AI to "create the entire schema" in one prompt
- ❌ Don't omit `Inside solution: <Name>` — every MCP prompt needs it
- ❌ Don't create relationships before all related tables have been verified
- ❌ Don't bundle different artifact types (table + lookup + choice) in one prompt
- ❌ Don't skip the "wait for metadata propagation" step between stages
- ❌ Don't try to re-import a `pac-exported` .zip back to its origin env (this fails with `Must specify valid information for parsing in the string` — for column updates to a deployed solution, use maker portal directly)

---

## Cross-references

- Standards: [`memory/dataverse-schema-standards.md`](../memory/dataverse-schema-standards.md)
- Schema spec format: [`examples/asset-management/dataverse/schema.yaml`](../examples/asset-management/dataverse/schema.yaml)
- Build skill: [`skills/build-dataverse-schema.md`](../skills/build-dataverse-schema.md)
- Asset Management end-to-end: [`skills/asset-management.md`](../skills/asset-management.md)
- MCP framework overview: [`memory/powerplatform-mcp-framework.md`](../memory/powerplatform-mcp-framework.md)
