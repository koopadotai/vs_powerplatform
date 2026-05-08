---
description: Design a Dataverse table schema from a domain description, generate the table-create script, and document it. USE WHEN the user asks to design a Dataverse schema, create tables, or model their data.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Build Dataverse Schema Skill

## Step 1 — Read standards

- `memory/dataverse-schema-standards.md`
- `memory/powerapps-naming.md`
- `memory/security-standards.md`

## Step 2 — Decompose the domain

From the user's description, identify:

1. **Entities** — each becomes a table
2. **Attributes** — each entity's fields, with types and required flags
3. **Relationships** — 1:N (lookups), N:N (intersect tables)
4. **Choice sets** — bounded value sets; decide global vs local
5. **Security** — who reads, writes, deletes each table

If the domain is ambiguous, ask one clarifying question.

## Step 3 — Generate the schema

For each table, generate a YAML manifest in `templates/powerapps/dataverse/<solution>/`:

```yaml
table:
  schemaName: ws_asset
  displayName: Asset
  pluralDisplayName: Assets
  primaryColumn: ws_assetname
  description: Tracks IT equipment assigned to employees
  ownership: User

columns:
  - schemaName: ws_assetname
    displayName: Asset Name
    type: Text
    maxLength: 100
    required: true

  - schemaName: ws_serialnumber
    displayName: Serial Number
    type: Text
    maxLength: 50
    required: true

  - schemaName: ws_status
    displayName: Status
    type: Choice
    optionSet: ws_assetstatus
    required: true

  - schemaName: ws_assignedto
    displayName: Assigned To
    type: Lookup
    target: systemuser

  - schemaName: ws_purchasedate
    displayName: Purchase Date
    type: DateTime
    behavior: DateOnly

choiceSets:
  - schemaName: ws_assetstatus
    displayName: Asset Status
    options:
      - { value: 1, label: Active }
      - { value: 2, label: Assigned }
      - { value: 3, label: Retired }

relationships:
  - type: 1:N
    name: ws_assetcategory_ws_asset
    parent: ws_assetcategory
    child: ws_asset
    cascade: Restrict
```

## Step 4 — Generate the create script

Generate `automation/CreateSchema-<solution>.ps1` that creates the tables via PAC CLI:

```powershell
pac data schema create --file ./templates/powerapps/dataverse/<solution>/schema.yaml
```

## Step 5 — Generate seed data

Generate a seed-data script for testing:

`templates/powerapps/dataverse/<solution>/seed.json`

## Step 6 — Document

`examples/<app>/docs/schema.md` — ER diagram (mermaid), table descriptions, security model.

## Step 7 — Validate

Run lint/standards check:
- All schema names use the publisher prefix
- All required columns are present (primary, status)
- All choice sets have at least 2 options
- All relationships have cascade behavior set

## Don't do

- Don't modify default tables (Account, Contact) unless explicitly asked
- Don't skip the publisher prefix
- Don't use generic column names (`name`, `description` without prefix)
- Don't omit security role assignments
