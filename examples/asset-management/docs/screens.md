# Asset Management — Screen Reference

| Screen | Purpose | Key Controls |
|---|---|---|
| [HomeScreen](#homescreen) | Landing page with KPIs and primary actions | KPI cards, "View Assets", "Add New Asset" |
| [AssetListScreen](#assetlistscreen) | Browse/search all assets | Search input, gallery, FAB |
| [AssetDetailScreen](#assetdetailscreen) | View one asset in detail | Status pill, assignment card, edit/delete |
| [AssetEditScreen](#asseteditscreen) | Add or edit an asset | Form with name, serial, category, status |

---

## HomeScreen

```
┌─────────────────────────────────┐
│       Asset Management          │  ← Header (ColorPrimary)
│        v1.0.0 · 2026-05-08      │
├─────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐     │
│  │   142    │  │   89     │     │  ← KPI Cards
│  │  Total   │  │ Assigned │     │
│  └──────────┘  └──────────┘     │
│                                 │
│  QUICK ACTIONS                  │
│  ┌─────────────────────────┐    │
│  │ 📋  View All Assets     │    │  ← Navigates to AssetListScreen
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ ➕  Add New Asset       │    │  ← Navigates to AssetEditScreen (new)
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│   🏠 Home    📋 Assets          │  ← Bottom nav
└─────────────────────────────────┘
```

**Key formulas:**
- `Total Assets` = `CountRows('Assets')`
- `Assigned` = `CountIf('Assets', ws_status.'Asset Status' = "Assigned")`

---

## AssetListScreen

Searchable gallery sorted by name. Each row shows name, serial, and a colored status pill.

**Status pill colors** (via `StatusColor()` named formula):
- Available → green
- Assigned → primary purple
- In Repair → warning orange
- Retired → grey
- Lost → red

**Items formula:**
```powerapps
SortByColumns(
    Filter('Assets',
        txtSearch.Text = "" Or
        StartsWith(ws_assetname, txtSearch.Text) Or
        StartsWith(ws_serialnumber, txtSearch.Text)),
    "ws_assetname", SortOrder.Ascending)
```

Tapping a row → navigates to `AssetDetailScreen` with `varSelectedAsset` set.

The `+` FAB → opens `AssetEditScreen` with a blank `Defaults('Assets')` record.

---

## AssetDetailScreen

Read-only view of `varSelectedAsset`. Three sections:
1. Asset card — name + status pill + serial + category
2. Assignment card — assigned to + assigned date
3. Delete button (with `IfError` and confirmation)

Edit pencil (top-right) → opens `AssetEditScreen` with the current asset.

**Delete formula:**
```powerapps
IfError(
    Remove('Assets', varSelectedAsset);
    Notify("Asset deleted", NotificationType.Success);
    Navigate(AssetListScreen, ScreenTransition.CoverLeft),
    Notify("Delete failed: " & FirstError.Message, NotificationType.Error)
)
```

---

## AssetEditScreen

Same screen for both create and update — distinguished by whether `varEditingAsset.ws_assetname` is blank.

**Form controls:**
- `txtName` — Asset Name (required)
- `txtSerial` — Serial Number (required)
- `cmbCategory` — Lookup to Asset Categories (required)
- `cmbStatus` — Choice (required)

**Save button** — disabled until all required fields are filled.

**Save formula:**
```powerapps
IfError(
    Patch('Assets',
        If(IsBlank(varEditingAsset.ws_assetname), Defaults('Assets'), varEditingAsset),
        {
            ws_assetname: txtName.Text,
            ws_serialnumber: txtSerial.Text,
            ws_categoryid: cmbCategory.Selected,
            ws_status: cmbStatus.Selected
        }
    );
    Notify("Saved", NotificationType.Success);
    Navigate(AssetListScreen, ScreenTransition.CoverLeft),
    Notify("Save failed: " & FirstError.Message, NotificationType.Error)
)
```

---

## Navigation Map

```
HomeScreen
  ├──▶ AssetListScreen ─▶ AssetDetailScreen ─▶ AssetEditScreen (edit)
  │                  └──▶ AssetEditScreen (new)
  └──▶ AssetEditScreen (new)
```

All screens reachable from any other via the bottom nav (Home + Assets) or back buttons.

---

## Standards Compliance

- ✅ All controls follow naming conventions (`btn`, `lbl`, `rect`, `txt`, `cmb`, `gal`)
- ✅ All colors via named formulas (no hardcoded RGBA)
- ✅ `AppVersion` label visible on every screen
- ✅ All Patch operations wrapped in `IfError` with `Notify`
- ✅ Required fields enforced on form (Save button disabled until valid)
- ✅ Delegation-friendly Filter using `StartsWith`
