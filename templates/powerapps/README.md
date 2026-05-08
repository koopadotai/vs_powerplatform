# Power Apps Templates

Reusable starter projects for Power Platform.

| Template | Purpose |
|---|---|
| `canvas-starter/` | Phone-form-factor Canvas App skeleton with theme + nav bar |
| `canvas-tablet-starter/` | Tablet form factor |
| `model-driven-starter/` | Model-Driven App skeleton |
| `dataverse/` | Dataverse table/schema YAML manifests |
| `power-automate/` | Common flow patterns (approval, notification, scheduled) |

To create a new project from a template:

```powershell
.\automation\New-Project.ps1 -Type canvas-app -Name <YourAppName>
```

Or via Claude Code: `/new-project canvas-app "<description>"`.

> Phase 1 ships with the directory. Templates themselves are added in Phase 2.
