# Power Apps Naming Conventions

These conventions are enforced for all Canvas Apps, Model-Driven Apps, Dataverse, and Power Automate artifacts produced from this toolkit.

---

## Why this matters

Consistent naming makes apps:
- Searchable in the formula bar
- Reviewable by anyone on the team
- Maintainable across environments
- Compatible with our standards-validation tooling

Deviation requires architect approval.

---

## Canvas App Controls

Format: `<typePrefix><PascalCaseName>`

| Control | Prefix | Example |
|---|---|---|
| Screen | `scr` or descriptive name + `Screen` | `HomeScreen`, `scrHome` |
| Button | `btn` | `btnSubmit`, `btnNavBack` |
| Label | `lbl` | `lblTitle`, `lblErrorMsg` |
| TextInput | `txt` | `txtSearchQuery` |
| DataCard | `card` | `cardCustomerName` |
| Gallery | `gal` | `galAssets` |
| Form | `frm` | `frmEditAsset` |
| Image | `img` | `imgLogo`, `imgDie1` |
| Icon | `ico` | `icoSearch` |
| Rectangle | `rect` | `rectHeader` |
| Container | `con` | `conMainContent` |
| Dropdown / ComboBox | `cmb` | `cmbStatus` |
| DatePicker | `dte` | `dteDueDate` |
| Toggle | `tgl` | `tglNotifications` |
| Slider | `sld` | `sldVolume` |
| Checkbox | `chk` | `chkAgreeTerms` |
| RadioGroup | `rad` | `radPriority` |
| Timer | `tmr` | `tmrAutoRefresh` |
| HTML Text | `htm` | `htmRichContent` |

---

## Variables & Collections

| Type | Prefix | Example |
|---|---|---|
| Global variable (`Set`) | `var` | `varCurrentUser`, `varSelectedAsset` |
| Context variable (`UpdateContext`) | `loc` | `locShowDialog` |
| Collection (`Collect`) | `col` | `colAssets`, `colRollHistory` |

---

## Named Formulas (App.pa.yaml `Formulas:`)

Pure values and reusable expressions go in named formulas — never recompute in screens.

| Type | Prefix / Convention | Example |
|---|---|---|
| Color | `Color<Purpose>` | `ColorPrimary`, `ColorTextDark` |
| Spacing | `Sp<Size>` | `SpSmall`, `SpMedium` |
| Font size | `Fs<Purpose>` | `FsTitle`, `FsBody` |
| Text constant | `Txt<Purpose>` | `TxtAppTitle` |
| Function | PascalCase + typed params | `DiceText(n: Number): Text` |
| Version | `AppVersion` | `AppVersion = "v1.2.0 · 2026-05-08"` |

---

## Dataverse Tables & Columns

### Tables
- Schema name: `<prefix>_<entityname>` (lowercase, no spaces) — e.g. `ws_asset`, `ws_assetcategory`
- Display name: Singular, Title Case — e.g. "Asset", "Asset Category"
- Plural display name: standard pluralization

### Columns
- Schema name: `<prefix>_<columnname>` — e.g. `ws_serialnumber`, `ws_purchasedate`
- Display name: Title Case with spaces — "Serial Number", "Purchase Date"

### Relationships
- 1:N: `<prefix>_<parent>_<child>`
- N:N: `<prefix>_<table1>_<table2>`

---

## Power Automate Flows

Format: `<env>-<domain>-<action>-<trigger>`

Examples:
- `dev-asset-notify-onassign`
- `prod-license-renew-scheduled`
- `dev-approval-route-onsubmit`

---

## Solutions

| Aspect | Convention |
|---|---|
| Name | PascalCase, no spaces — `AssetManagement`, `LicenseTracker` |
| Publisher prefix | Org-wide consistent (e.g. `ws`) |
| Versioning | SemVer — `1.0.0`, `1.1.0`, `2.0.0` |

---

## Files in This Repo

| Asset | Convention |
|---|---|
| `.pa.yaml` files | One per screen — `<ScreenName>.pa.yaml` |
| App-level | `App.pa.yaml` |
| Memory files | `kebab-case.md` |
| Skills | `kebab-case.md` |
| PowerShell scripts | `Verb-Noun.ps1` (PascalCase, approved verbs) |
| .NET projects | PascalCase folder names |
