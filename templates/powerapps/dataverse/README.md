# Dataverse Schema Template

Schema-as-YAML manifests for Dataverse tables. The `New-Project.ps1` and `CreateSchema.ps1` scripts read these manifests and create the tables via PAC CLI.

## File format

```yaml
solution:
  name: <SolutionName>            # PascalCase, no spaces
  publisherPrefix: ws             # Your org's publisher prefix
  version: 1.0.0

tables:
  - schemaName: ws_asset
    displayName: Asset
    pluralDisplayName: Assets
    primaryColumn: ws_assetname
    description: Tracks IT equipment assigned to employees
    ownership: User
    auditingEnabled: true

    columns:
      - { schemaName: ws_assetname,    displayName: Asset Name,     type: Text,     maxLength: 100, required: true }
      - { schemaName: ws_serialnumber, displayName: Serial Number,  type: Text,     maxLength: 50,  required: true }
      - { schemaName: ws_status,       displayName: Status,         type: Choice,   optionSet: ws_assetstatus, required: true }
      - { schemaName: ws_purchasedate, displayName: Purchase Date,  type: DateTime, behavior: DateOnly }
      - { schemaName: ws_assignedto,   displayName: Assigned To,    type: Lookup,   target: systemuser }
      - { schemaName: ws_value,        displayName: Value,          type: Currency }
      - { schemaName: ws_notes,        displayName: Notes,          type: Memo,     maxLength: 2000 }

choiceSets:
  - schemaName: ws_assetstatus
    displayName: Asset Status
    isGlobal: false                  # If true, can be reused across tables
    options:
      - { value: 100000000, label: Available, color: '#28b964' }
      - { value: 100000001, label: Assigned,  color: '#635bff' }
      - { value: 100000002, label: Retired,   color: '#94 8e c0' }

relationships:
  - type: 1:N
    name: ws_assetcategory_ws_asset
    parent: ws_assetcategory
    child:  ws_asset
    cascade: Restrict
```

## Available samples

- `sample-schema/asset-management.yaml` — Asset / Asset Category / Assignment

## How to use

### Via Claude Code

```
/build-dataverse-schema "IT asset management with categories, assignments, and warranties"
```

### Via the script

```powershell
.\automation\CreateSchema.ps1 `
    -Schema templates\powerapps\dataverse\sample-schema\asset-management.yaml `
    -Environment dev
```

### Manually via PAC CLI

The schema YAML is a documentation format; PAC CLI doesn't read it directly. Use `pac data schema` commands or the maker portal, then export the resulting solution and check the export back into Git.

## Conventions

- All schema names use the publisher prefix
- Display names are Title Case with spaces
- Choice sets use sensible value ranges (Dataverse defaults to 100000000+)
- Cascade behavior is explicit on every relationship

See [`memory/dataverse-schema-standards.md`](../../../memory/dataverse-schema-standards.md) for the full ruleset.
