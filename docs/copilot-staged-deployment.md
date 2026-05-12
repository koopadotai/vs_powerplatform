# Maker Portal Copilot — Staged Deployment Runbook

The **primary path** for deploying a Dataverse + Canvas solution in corporate tenants. The AI agent prepares terse structured prompts; the user pastes them into Power Apps maker portal's "Start with Copilot" feature; Copilot creates the artifacts; user validates; AI gives next prompt.

> **Why this beats PAC CLI / MCP for corporate tenants:**
> - No tenant admin consent needed (unlike Dataverse MCP)
> - No re-import parsing issues (unlike PAC `pac solution import` of exported zips)
> - Runs in the user's existing browser session — same auth as `make.powerapps.com`
> - User stays in control and can correct Copilot's output in real time

For the alternate paths, see:
- [`dataverse-mcp-staged-deployment.md`](dataverse-mcp-staged-deployment.md) — when Dataverse MCP IS available
- [`pac-cli-staged-deployment.md`](pac-cli-staged-deployment.md) — PAC CLI solution import flow (legacy; has known issues with re-import)

---

## Prerequisites checklist

- [ ] User can access https://make.powerapps.com (same browser that works for daily Power Apps use)
- [ ] User has **System Customizer** or **System Administrator** role in the target env
- [ ] PAC CLI authenticated for the final export: `pac org who` works
- [ ] Schema spec exists: `examples/<app>/dataverse/schema.yaml`
- [ ] Copilot prompt blocks exist: `examples/<app>/dataverse/copilot-prompts.md`

---

## Stage 0 — Collect personalization inputs (one-time)

AI asks the user (skip whichever are already known):

| Input | Validation | Example |
|---|---|---|
| Publisher unique name | alphanumeric, no spaces | `ContosoCorp` |
| Publisher display name | any string | `Contoso Corporation` |
| Prefix | 2–8 lowercase letters | `ctso` |
| Solution display name | any string | `Asset Management` |
| Solution unique name | alphanumeric, no spaces | `AssetManagement` |

If the user's prefix is anything other than `ws`, the AI **modifies the Copilot prompt text** before showing it to the user:
- `ws_` → `<prefix>_`
- `ws ` (top line "with prefix ws_") → `<prefix>_`

---

## The core rules

### Rule 1 — User pastes the prompt; Copilot does the work
The AI's job is to **prepare the prompt text** with the user's prefix substituted in. The AI does NOT make API calls during Stage 2 — the user is the one driving maker portal.

### Rule 2 — User must be INSIDE their solution
Every Copilot prompt for tables must be invoked from: Solutions → MySolution → **+ New** → **Table** → **Start with Copilot**. If the user clicks Tables from the top-level nav instead, the table is orphaned outside any solution.

### Rule 3 — Approval gate after every paste
After every Copilot result, the AI tells the user what to verify in maker portal, then **STOPS** and waits for explicit "approved". Don't proceed to the next prompt until validated.

### Rule 4 — Dependencies matter
Asset Category must exist before Asset (Asset has a lookup to it). Asset must exist before Asset Assignment. If using Flow B (per-table prompts), order is fixed.

---

## The 6 stages

### Stage 1 — Solution shell (manual in maker portal)

Copilot doesn't create solutions. User creates manually:

AI tells the user (substituting Stage-0 values):

> "Open https://make.powerapps.com → Solutions → **+ New solution**. Fill in:
>   - Display name: `<SolutionDisplayName>`
>   - Name: `<SolutionUniqueName>`
>   - Publisher: + New publisher → Display `<PublisherDisplayName>`, Name `<PublisherUniqueName>`, Prefix `<prefix>`
>   - Save publisher, then Create solution.
>
> You should land inside your new solution. Reply 'approved' when done."

**Verify (optional, via PAC):**
```powershell
pac solution list | Select-String <SolutionUniqueName>
```

**Gate → wait for "approved".**

---

### Stage 2 — Schema creation via Copilot

AI tells the user which flow to use:
- **Flow A (one-shot)** — single prompt creates all 3 tables + lookups + choice + alt key. Faster.
- **Flow B (staged)** — three prompts in sequence (Asset Category → Asset → Asset Assignment). Safer for first-time use.

Default: **Flow B**.

#### Flow B — staged per-table

**Stage 2a — Asset Category**

AI says:
> "In your solution: **+ New** → **Table** → **Start with Copilot**. Paste this prompt:"

(AI pastes the Stage 2a prompt block from `copilot-prompts.md`, substituting prefix if non-`ws`.)

After Copilot creates the table:
> "Verify: 3 columns appear (Category Name, Icon, Description). Save & close. Reply 'approved' before Stage 2b."

**Gate → wait for "approved".**

---

**Stage 2b — Asset (with lookup, choice, alt key)**

AI says:
> "Inside your solution: **+ New** → **Table** → **Start with Copilot**. Paste:"

(AI pastes the Stage 2b prompt block.)

After Copilot creates the table:
> "Verify: 10 columns; Status is Choice with 5 options; Category is Lookup to Asset Category; Assigned To is Lookup to User; Serial Number alternate key in Asset → Keys (may take ~30 sec to become Active). Reply 'approved' before Stage 2c."

**Gate → wait for "approved".**

---

**Stage 2c — Asset Assignment**

AI says:
> "Inside your solution: **+ New** → **Table** → **Start with Copilot**. Paste:"

(AI pastes the Stage 2c prompt block.)

After Copilot creates the table:
> "Verify: Asset is Lookup to Asset table, Assigned To is Lookup to User. Reply 'approved' before Stage 3."

**Gate → wait for "approved".**

#### Flow A — one-shot combined prompt (alternative)

AI gives a single combined prompt (from `copilot-prompts.md` Flow A) that defines all 3 tables + alt key + choice set. User pastes once; validates everything at once.

**Gate → wait for "approved".**

---

### Stage 3 — Verify relationships + alternate key

Both were created in Stage 2 (lookups embedded in table prompts; alt key in the Asset prompt). This stage is verification only.

AI tells the user:
> "In maker portal:
>  1. Tables → ws_asset → Relationships — confirm 1:N to Asset Assignment + N:1 lookups to Asset Category and User
>  2. Tables → ws_assetassignment → Relationships — confirm N:1 lookups to Asset and User
>  3. Tables → ws_asset → Keys — confirm 'Serial Number (Unique)' is **Active**
>
> Reply 'approved' if all check out."

If something is missing, the AI provides a follow-up Copilot prompt to add it.

**Gate → wait for "approved".**

---

### Stage 4 — Views (Copilot or manual)

AI tells the user:
> "In your solution → Tables → ws_asset → **Views** → **+ New view** → Start with Copilot. Paste:"

(AI pastes the Stage 4 prompt block from `copilot-prompts.md`.)

If Copilot can't handle views (some versions can't), fall back to manual creation: 4 views on ws_asset + 1 on ws_assetassignment, configured per `schema.yaml` lines 112-148.

After views are created:
```powershell
pac solution export `
  --name <SolutionUniqueName> `
  --path "dist\asset-management-<prefix>\<SolutionUniqueName>-with-views.zip" `
  --managed false --overwrite
```

> Export goes into `dist/`, NOT `examples/`. Source template stays publisher-agnostic.

**Gate → wait for "approved".**

---

### Stage 5 — Canvas App (inside the solution)

AI tells the user:
> "In maker portal:
>  1. Solutions → `<SolutionDisplayName>` (NOT top-level Apps)
>  2. **+ New** → **App** → **Canvas app** → Phone form factor → name 'Asset Management'
>  3. Click **Create** — this places the app inside the solution
>  4. Studio opens: **Settings** (gear) → **Updates** → toggle **Coauthoring** ON
>  5. Copy the URL (must contain `appid=...`) and paste it here."

After URL provided, AI:
1. Configures canvas-authoring MCP for the Studio URL
2. Calls `mcp__canvas-authoring__compile_canvas` with `sources: examples/<app>/canvas/` (substituting `ws_` → `<prefix>_` in the YAML if needed)
3. Verifies all 5 screens compiled

**User validates:**
- App opens with all 5 screens
- Data → + Add data → add `<prefix>_asset` and `<prefix>_assetcategory`
- App functions: KPI counts populate, search works

**Gate → wait for "approved".**

---

### Stage 6 — Flows (placeholder)

> Power Automate flows are not yet defined for asset-management. Future Copilot prompts will live in `copilot-prompts.md` Stage 6 for "On asset assignment → email user", "Daily warranty expiring report", etc.
>
> For now: mark as "not yet implemented", proceed to Final.

**Gate → wait for "approved".**

---

### Final — Capture the user's complete personalized solution

```powershell
pac solution export `
  --name <SolutionUniqueName> `
  --path "dist\asset-management-<prefix>\<SolutionUniqueName>-complete.zip" `
  --managed false --overwrite
```

This is **your** complete personalized portable artifact. Re-deploy to test/staging/prod within the same tenant via:

```powershell
pac solution import --path <SolutionUniqueName>-complete.zip --publish-changes
```

**Do NOT overwrite** `examples/<app>/dataverse/AssetManagement.zip` — that's the publisher-agnostic source template for future users.

---

## What to do if Copilot misinterprets a prompt

| Symptom | Fix |
|---|---|
| Wrong column type (text instead of choice) | Follow-up: "Change <column> to be a Choice with options: <list>" |
| Lookup to wrong table | Follow-up: "Change <column> lookup target from <wrong> to <right>" |
| Missing alternate key | Add manually: Tables → ws_asset → Keys → + New key → Serial Number |
| Table orphan outside solution | User wasn't INSIDE solution when creating. Delete + redo via Solutions → +New |
| Choice option values are off | Edit manually: Tables → ws_asset → ws_status → adjust |

---

## Don't do

- ❌ Don't paste all stage prompts at once — Copilot does best with focused single-table prompts
- ❌ Don't skip approval gates — Copilot can misinterpret; user validation catches it before dependent stages
- ❌ Don't create tables from top-level Tables nav — always go through Solutions → MySolution → +New
- ❌ Don't overwrite `examples/<app>/dataverse/AssetManagement.zip` — that's the template for future users
- ❌ Don't try to run Copilot prompts via API/CLI — they're designed for maker portal's interactive Copilot

---

## Cross-references

- Source schema: [`examples/asset-management/dataverse/schema.yaml`](../examples/asset-management/dataverse/schema.yaml)
- Copilot prompts (paste-ready): [`examples/asset-management/dataverse/copilot-prompts.md`](../examples/asset-management/dataverse/copilot-prompts.md)
- Standards: [`memory/dataverse-schema-standards.md`](../memory/dataverse-schema-standards.md) → Path A
- Asset Management skill: [`skills/asset-management.md`](../skills/asset-management.md) → Path 3-COPILOT
- Fallback: [`dataverse-mcp-staged-deployment.md`](dataverse-mcp-staged-deployment.md) (when MCP works)
- One-shot import: `automation/Personalize-AssetManagement.ps1` + `pac solution import`
