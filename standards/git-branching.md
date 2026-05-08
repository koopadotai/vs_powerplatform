# Git Branching Strategy

---

## Branches

```
main          ← Protected. Production-ready. Tagged on every release.
develop       ← Integration. Daily builds. Promoted to main on release.
feature/*     ← Short-lived. Branched from develop. Merged via PR.
hotfix/*      ← Branched from main for emergencies. Merged to main and develop.
release/*     ← (optional) Stabilization branch for a release.
```

---

## Branch Naming

```
feature/<ticket-id>-<short-description>
fix/<ticket-id>-<short-description>
hotfix/<ticket-id>-<short-description>
release/v<major>.<minor>.<patch>
```

Examples:
- `feature/AM-127-asset-search-by-serial`
- `fix/AM-89-version-label-not-rendering`
- `hotfix/AM-201-patch-fails-on-empty-name`
- `release/v1.2.0`

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<optional body>

<optional footer (e.g. BREAKING CHANGE: ...)>
```

| Type | When |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change without behavior change |
| `test` | Adding or fixing tests |
| `chore` | Build, deps, tooling |
| `ci` | CI/CD changes |
| `perf` | Performance improvement |

Examples:
```
feat(canvas): add asset-search screen
fix(api): handle null serial number in PATCH /assets/{id}
docs(memory): clarify Dataverse choice column syntax
chore(deps): bump Anthropic.SDK to 1.5.0
```

---

## Pull Requests

### Title
Same format as commit messages.

### Description template

```markdown
## Summary
1-3 bullets on what changed and why

## Test plan
- [ ] Unit tests pass
- [ ] Manual verification: <specific steps>
- [ ] CI green

## Related
- Ticket: AM-127
- Spec: <link>
- Screenshots: <if UI changes>
```

### Required checks
All must pass before merge:
- CI build + tests
- Linting (pa.yaml + .NET formatting)
- Security scan
- At least 1 reviewer approval (2 for PROD-bound code)

### Squash vs merge
- Default: **squash** to keep history clean
- For long branches with meaningful intermediate commits: **rebase + merge**
- Never use **merge commits** on main

---

## Releases

1. Create `release/v1.2.0` from `develop`
2. Stabilize (bug fixes only on this branch)
3. Tag `v1.2.0` on the release branch
4. Merge release branch to `main` and back to `develop`
5. Delete the release branch

For minor patches, you can tag directly on `main` without a release branch.

---

## Hotfixes

When a bug must be fixed in PROD before the next release:

1. Branch from `main`: `git checkout -b hotfix/AM-201-patch-fix main`
2. Fix the bug
3. Tag: `v1.2.1`
4. Merge to `main`
5. Merge to `develop` (so the fix isn't lost in the next release)

---

## Protected Branch Rules (`main`)

Configured in GitHub:
- Require PR before merging
- Require status checks to pass
- Require linear history (no merge commits)
- Require signed commits
- No direct pushes
- No force pushes
- No deletions
