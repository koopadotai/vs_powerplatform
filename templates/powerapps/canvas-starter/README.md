# Canvas Starter — Phone Form Factor

A production-ready Power Apps Canvas App skeleton for **phone-form-factor** apps (390 × 844).

## What you get

- **App.pa.yaml** — App-level setup with full color/spacing/typography system as named formulas
- **HomeScreen** — Welcome card + primary action button + bottom nav
- **ListScreen** — Search input + empty state + add (FAB) button + nav
- **ProfileScreen** — User card + about section + nav
- **AppVersion** label visible on every screen for deployment traceability
- Three-tab bottom navigation (Home / List / Profile)
- Theming via named formulas — no hardcoded colors anywhere in screens

## Tokens to replace

When you scaffold from this template, these tokens get replaced:

| Token | Example |
|---|---|
| `__APP_TITLE__` | "Asset Management" |
| `__APP_TAGLINE__` | "Track every device in your fleet" |
| `__BUILD_DATE__` | "2026-05-08" |

The `New-Project.ps1` script does this automatically.

## How to use

### Via Claude Code (recommended)

```
/build-canvas-app "Vehicle inspection app for our drivers, phone form factor"
```

### Via the script

```powershell
.\automation\New-Project.ps1 `
    -Type canvas-app `
    -Name VehicleInspection `
    -Title "Vehicle Inspection" `
    -Tagline "Quick checks before you hit the road"
```

### Manually

1. Copy this folder into `examples/<your-app-name>/canvas/`
2. Find-and-replace the `__TOKEN__` placeholders
3. Open Power Apps Studio with coauthoring ON
4. Run **Compile canvas app to Power Apps Studio** in VS Code

## Standards followed

- All controls use the toolkit naming convention (`btn`, `lbl`, `rect`, `txt`)
- All colors and spacing are named formulas (no hardcoded RGBA in screens)
- Header pattern: `rectHeader` + title + version label
- Nav bar pinned to `Parent.Height - NavBarH`
- Active nav button uses `ColorPrimary` + `Semibold`; inactive uses `ColorTextGray`

See [`memory/powerapps-canvas-standards.md`](../../../memory/powerapps-canvas-standards.md) for the full ruleset.

## Customizing

| To change... | Edit... |
|---|---|
| Color scheme | `App.pa.yaml` formulas (`ColorPrimary`, `ColorBg`, etc.) |
| Spacing | `App.pa.yaml` formulas (`SpMedium`, etc.) |
| Typography sizes | `App.pa.yaml` formulas (`FsTitle`, etc.) |
| Number of nav tabs | All three screen files (currently 3) |
| Add a new screen | Copy `HomeScreen.pa.yaml` and add a nav button |

## Themes

Apply a different theme by replacing the color formulas in `App.pa.yaml` with one of:
- [`themes/theme-corporate.pa.yaml`](../../uiux/themes/theme-corporate.pa.yaml) — conservative blue/grey
- [`themes/theme-modern.pa.yaml`](../../uiux/themes/theme-modern.pa.yaml) — purple gradient (current default)
- [`themes/theme-dark.pa.yaml`](../../uiux/themes/theme-dark.pa.yaml) — dark mode
