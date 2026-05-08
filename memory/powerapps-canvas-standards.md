# Canvas App Standards

Apply these standards to every Canvas App generated from this toolkit.

---

## File Structure

Each Canvas App lives in its own folder:

```
<AppName>/
├── App.pa.yaml             # App-level OnStart, Formulas, Themes
├── <Screen1>.pa.yaml       # One file per screen
├── <Screen2>.pa.yaml
├── README.md               # What this app does
└── assets/                 # Images, icons (committed if small)
```

Never put multiple screens in one file.

---

## App.pa.yaml — Required Sections

```yaml
App:
  Properties:
    StartScreen: =LoginScreen
    OnStart: |-
      =Set(varCurrentUser, User());
      Set(varAppLoaded, true)
    Formulas: |-
      =AppVersion = "v1.0.0 · 2026-05-08";
      ColorPrimary = RGBA(99, 91, 255, 1);
      ColorBg = RGBA(238, 238, 252, 1);
      ColorCard = RGBA(255, 255, 255, 1);
      ColorTextDark = RGBA(28, 24, 72, 1);
      ColorTextGray = RGBA(148, 142, 190, 1);
      ColorError = RGBA(220, 50, 50, 1);
      ColorSuccess = RGBA(40, 185, 100, 1);
      // Sizing
      SpSmall = 8;
      SpMedium = 16;
      SpLarge = 24;
      // Helpers
      FmtDate(d: DateTime): Text = Text(d, "dd MMM yyyy")
```

### Required formulas in every app
- `AppVersion` — visible in the UI; bumped every deploy
- A complete color palette (no hardcoded RGBA in screens)
- Spacing constants

---

## Screen Layout Rules

1. **Phone form factor**: 390 × 844 (iPhone 14)
2. **Tablet form factor**: 1024 × 768
3. Always reserve 65px at the bottom for nav bar (if app has nav)
4. All controls position inside the visible area — never partial overflow

### Header pattern

```yaml
- rectHeader:
    Control: Rectangle
    Properties:
      X: =0
      Y: =0
      Width: =Parent.Width
      Height: =80
      Fill: =ColorPrimary

- lblTitle:
    Control: Label
    Properties:
      X: =0
      Y: =20
      Width: =Parent.Width
      Height: =40
      Text: ="Page Title"
      Color: =Color.White
      Size: =22
      FontWeight: =FontWeight.Bold
      Align: =Align.Center
```

### Version label pattern (every app)

```yaml
- lblVersion:
    Control: Label
    Properties:
      X: =0
      Y: =Parent.Height - 20
      Width: =Parent.Width
      Height: =16
      Text: =AppVersion
      Color: =ColorTextGray
      Size: =9
      Align: =Align.Center
```

---

## Data Patterns

### Reading from Dataverse

```powerapps
// Always sort and filter at source
Filter(
    SortByColumns('Assets', "createdon", SortOrder.Descending),
    'Status'.Active
)
```

### Writing to Dataverse

Always use `Patch` with `Defaults()` for new records, an existing record for updates. Always include all required fields in the Patch:

```powerapps
Patch(
    'Assets',
    Defaults('Assets'),
    {
        ws_assetname: txtName.Text,
        ws_serialnumber: txtSerial.Text,
        ws_status: 'Status (Assets)'.Active,
        ws_assignedto: User().FullName
    }
)
```

### Choice columns

Always reference choice values via the local option set syntax:

```powerapps
'Result Type (Dice Game Results)'.SMALL
```

### Required-field checking

If a Patch fails with "Field X is required", add the field to the Patch — do not change the table schema unless the field is genuinely optional.

---

## Error Handling

Wrap every data write in `IfError`:

```powerapps
IfError(
    Patch('Assets', Defaults('Assets'), {ws_assetname: txtName.Text});
    Notify("Saved successfully", NotificationType.Success),
    Notify("Save failed: " & FirstError.Message, NotificationType.Error)
)
```

---

## Performance

| Pattern | Why |
|---|---|
| Use delegation-friendly functions (`Filter`, `Sort`, `LookUp`) | Server-side execution |
| Avoid `First(Filter(...))` — use `LookUp` instead | Single round-trip |
| Cache static data in `OnStart` | Avoid repeated queries |
| Set Gallery `Items` via a named formula | Improves rebuilds |

---

## Accessibility

- Every interactive control has `AccessibleLabel`
- Color contrast ≥ 4.5:1 for body text
- Touch targets ≥ 44×44 px
- Screen-reader friendly tab order

---

## Theming

The toolkit ships with three themes in `templates/uiux/themes/`:
- `theme-corporate.pa.yaml` — Conservative blue/grey
- `theme-modern.pa.yaml` — Purple gradient (default)
- `theme-dark.pa.yaml` — Dark mode

Apply by copying the named formulas into your `App.pa.yaml`.

---

## Versioning

Bump `AppVersion` in `App.pa.yaml` for every deployment:

```
v1.0.0 · 2026-05-08    ← initial release
v1.0.1 · 2026-05-09    ← bugfix
v1.1.0 · 2026-05-15    ← new feature
v2.0.0 · 2026-06-01    ← breaking change
```

The label is visible in the app so users can confirm the deployed version.

---

## Compile / Sync Workflow

1. Edit `.pa.yaml` files locally
2. Have Power Apps Studio open with coauthoring ON
3. Run **Compile canvas app to Power Apps Studio** (terminal task in VS Code)
4. Refresh Studio and validate
5. Commit when stable

Never edit pa.yaml and Studio simultaneously without compiling first.
