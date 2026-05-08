# Asset Management — Data Model

## Entity Relationship Diagram

```mermaid
erDiagram
    AssetCategory ||--o{ Asset : "has many"
    Asset ||--o{ AssetAssignment : "has history"
    SystemUser ||--o{ Asset : "currently assigned"
    SystemUser ||--o{ AssetAssignment : "was assigned"

    AssetCategory {
        guid ws_assetcategoryid PK
        string ws_categoryname "Required, max 80"
        string ws_icon "Emoji or short text"
        string ws_description
    }

    Asset {
        guid ws_assetid PK
        string ws_assetname "Required, max 100"
        string ws_serialnumber "Required, max 50"
        guid ws_categoryid FK "→ AssetCategory"
        choice ws_status "Available|Assigned|In Repair|Retired|Lost"
        date ws_purchasedate
        money ws_purchasecost
        date ws_warrantyend
        guid ws_assignedto FK "→ SystemUser"
        datetime ws_assigneddate
        memo ws_notes "max 2000"
    }

    AssetAssignment {
        guid ws_assetassignmentid PK
        string ws_assignmentname "Required"
        guid ws_assetid FK "→ Asset"
        guid ws_assignedto FK "→ SystemUser"
        datetime ws_assignedfrom "Required"
        datetime ws_assignedto_dt
        memo ws_notes
    }
```

## Tables

### Asset Category (`ws_assetcategory`)
Reference data — Laptop, Phone, Monitor, Headset, etc. Owned by Organization (admins maintain).

### Asset (`ws_asset`)
The core entity. One row per physical/logical IT asset. Status drives most workflows.

### Asset Assignment (`ws_assetassignment`)
Append-only audit log. Every time an asset is assigned or unassigned, a row is created. Enables historical reporting ("what laptops did this user have over the past 3 years?").

## Status Lifecycle

```
Available ─────▶ Assigned ─────▶ Available
    │              │
    │              ▼
    │           In Repair ──▶ Assigned / Available
    │
    ├─▶ Retired
    └─▶ Lost
```

## Key Constraints

- `ws_serialnumber` is unique within active assets (alternate key)
- Deleting `ws_assetcategory` is **Restricted** if any asset references it
- Deleting `ws_asset` performs **RemoveLink** on assignments (preserves audit history)

## Security Roles

| Role | Read | Write | Delete | Scope |
|---|---|---|---|---|
| Asset Reader | All | None | None | Org |
| Asset Manager | All | All | None | Business Unit |
| Asset Administrator | All | All | All | Org |

## Reporting Views (Dataverse)

| View | Filter | Sort |
|---|---|---|
| Available Assets | `ws_status = Available` | `ws_assetname asc` |
| My Assigned Assets | `ws_assignedto = current user` | `ws_assigneddate desc` |
| Out of Warranty | `ws_warrantyend < today` | `ws_warrantyend asc` |
| Recently Assigned | `ws_assigneddate > today - 30` | `ws_assigneddate desc` |

## Schema Source

Authoritative schema definition: [`../dataverse/schema.yaml`](../dataverse/schema.yaml)

To create the tables in a Dataverse environment:

```powershell
.\automation\CreateSchema.ps1 `
    -Schema examples\asset-management\dataverse\schema.yaml `
    -Environment dev
```
