# Themes

Three pre-built theme palettes for the Canvas starter. Each defines the same set of named formulas so swapping is one find-and-replace.

| Theme | Use when |
|---|---|
| `theme-modern.pa.yaml` | Internal apps, modern web look (default) |
| `theme-corporate.pa.yaml` | Finance, regulated, conservative branding |
| `theme-dark.pa.yaml` | Dark mode preference, low-light environments |

## How to apply

1. Open `App.pa.yaml` of your app
2. Replace the color palette block with the contents of the chosen theme file
3. Compile and verify in Studio

## Adding a new theme

1. Copy `theme-modern.pa.yaml` and rename
2. Tune the RGBA values
3. Confirm contrast ratios meet WCAG AA (≥ 4.5:1 for body text on background)
4. Update this README

## Conventions

Every theme **must** define:

- `ColorPrimary`, `ColorPrimaryMid`, `ColorPrimaryBg`
- `ColorBg`, `ColorCard`
- `ColorTextDark`, `ColorTextMid`, `ColorTextGray`
- `ColorBorder`
- `ColorError`, `ColorWarning`, `ColorSuccess`

Apps that reference these formulas work with any theme. Don't add theme-specific names.
