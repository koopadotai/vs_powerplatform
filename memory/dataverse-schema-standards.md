# Dataverse Schema Design Standards

---

## Table Design Principles

1. **One concept per table** — A table represents a single business entity (Asset, Customer, Order)
2. **Normalize where it makes sense** — Don't denormalize for performance until profiling proves the need
3. **Use lookups, not text references** — Foreign keys via lookup columns, not free text
4. **Audit columns are free** — Created On, Modified On, Owner are automatic; use them
5. **Required at schema, validated at app** — Make critical fields required at the table level

---

## Required Columns Per Table

Every custom table should have at minimum:

| Column | Schema Name | Type | Required | Notes |
|---|---|---|---|---|
| Primary | `<prefix>_name` | Text | Yes | The "label" you'd show in a dropdown |
| Status | `<prefix>_status` | Choice | Yes | Active / Inactive / Archived |
| Description | `<prefix>_description` | Multi-line text | No | Free-form notes |

Plus the system columns: CreatedOn, ModifiedOn, OwnerId, OwningBusinessUnit.

---

## Choice Columns vs Text

| Use Choice when... | Use Text when... |
|---|---|
| Values are bounded and known up-front | Values are user-generated |
| You'll filter/group by the value | Field is purely descriptive |
| Reusable across tables | Specific to one table only |

**Global option sets** for choices used in 2+ tables. **Local option sets** for table-specific.

---

## Lookups & Relationships

### 1:N (Parent → Children)

Example: Asset Category → Assets

- Lookup column on the child: `ws_assetcategoryid` on `ws_asset`
- Relationship name: `ws_assetcategory_ws_asset`
- Cascade behavior: typically **Restrict** (don't auto-delete children)

### N:N (Many-to-Many)

Use sparingly — Dataverse N:N relationships have limited extensibility. If you need attributes on the relationship itself, create an intersect table.

---

## Naming

| Asset | Convention | Example |
|---|---|---|
| Table schema | `<prefix>_<lowercase>` | `ws_asset` |
| Table display | Singular Title Case | `Asset` |
| Column schema | `<prefix>_<lowercase>` | `ws_serialnumber` |
| Column display | Title Case With Spaces | `Serial Number` |
| Lookup column | `<prefix>_<targettable>id` | `ws_categoryid` |
| Choice column | `<prefix>_<conceptname>` | `ws_status` |

See `memory/powerapps-naming.md` for the full reference.

---

## Security Roles

For each table, define at minimum:

| Role | Read | Create | Write | Delete | Append | Append To |
|---|---|---|---|---|---|---|
| App User | User | User | User | None | None | None |
| App Manager | BU | BU | BU | BU | BU | BU |
| App Admin | Org | Org | Org | Org | Org | Org |

Apply principle of least privilege.

---

## Auditing

Enable auditing on tables that:
- Hold financial or contractual data
- Are subject to compliance review (GDPR, SOX, HIPAA)
- Have multiple write paths (app + flows + API)

Disable auditing on:
- High-volume operational data with no compliance need (saves storage)

---

## Indexing & Performance

- Add an alternate key on any column used as a natural key (e.g. employee number, serial number)
- For tables expected to exceed 100k rows, review default indexes
- Use **virtual tables** for data that lives in an external system

---

## Solution Strategy

- One solution per business domain (e.g. `AssetManagement`, `LicenseTracker`)
- Add the table, all its columns, all its choice columns, all its relationships, all its security roles, and any related flows to the solution
- Never modify default Dataverse tables (Account, Contact) unless absolutely required — extend them, don't override

---

## Schema Generation Workflow

When the user asks "design a schema for X":

1. **Identify the entities** — list each as a table
2. **Identify relationships** — 1:N, N:N
3. **Identify lookups, choice sets, key fields**
4. **Generate the table-create script** in `templates/powerapps/dataverse/`
5. **Generate a sample seed-data script** for testing
6. **Document** the schema in `examples/<app>/docs/schema.md`

Use `pac data` and `pac solution` to operate on Dataverse from the CLI.
