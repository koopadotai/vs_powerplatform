# UI/UX Templates

Reusable layouts and theme systems for Power Apps.

## Available now

| Template | Purpose |
|---|---|
| [`themes/theme-modern.pa.yaml`](themes/theme-modern.pa.yaml) | Default purple-gradient theme (used by canvas-starter and asset-management) |
| [`themes/theme-corporate.pa.yaml`](themes/theme-corporate.pa.yaml) | Conservative blue/grey for finance + regulated industries |
| [`themes/theme-dark.pa.yaml`](themes/theme-dark.pa.yaml) | Dark mode |

Each theme defines the same set of named formulas — swapping is one find-and-replace.

## Planned

| Template | Purpose |
|---|---|
| `layouts/phone/` | Mobile-first reusable layout components (header, content, nav patterns) |
| `layouts/tablet/` | Tablet split-view layouts |
| `layouts/dashboard/` | KPI dashboard layouts |
| `components/` | Reusable Canvas App components (buttons, cards, gallery rows) packaged for re-use |

## How to use a theme

1. Open your `App.pa.yaml`
2. Replace the color palette block in `Formulas:` with the contents of the chosen theme file
3. Compile and verify in Studio

See [`themes/README.md`](themes/README.md) for the contract every theme must implement.

## Standards

- All themes must define the same named formulas — apps that reference these work with any theme
- Contrast ≥ 4.5:1 for body text on background (WCAG AA)
- Touch targets ≥ 44 × 44 px
