# Architecture Principles

The non-negotiable rules that shape every decision in this toolkit.

---

## 1. Separation of Concerns

UI talks to APIs. APIs talk to domain logic. Domain logic talks to repositories. Never short-circuit a layer.

```
Power App  →  API  →  Application  →  Domain  →  Repository  →  Dataverse
```

A Canvas App should never call SQL directly. An API endpoint should never contain business rules.

## 2. Source of Truth Lives in Git

Not in Studio. Not in DEV. Not in someone's email. Git.

If DEV diverges from Git, **Git wins** — re-import from the latest commit.

## 3. Convention Over Configuration

Every artifact has a name pattern. Every project has a structure. Every commit has a message format. New team members should be productive without reading 50 pages of docs.

## 4. Reusable Over Bespoke

If you write something twice, the second time you extract it into a template, named formula, or shared library. Three identical implementations is a code smell.

## 5. Fail Loud, Recover Gracefully

- **In dev**: throw exceptions, crash the app, show the stack trace
- **In prod**: catch at boundaries, log structured errors, return user-friendly messages, never expose internals

## 6. Build For Two Audiences

Every change has two audiences:
- **The user**: smooth, fast, accessible, trustworthy
- **The next developer**: readable, testable, observable, debuggable

Optimize for both.

## 7. Standards Are Enforced, Not Suggested

CI gates fail the build on:
- Naming convention violations
- Missing standards (no `/health` endpoint, no `AppVersion` formula)
- Security regressions (vulnerable packages, exposed secrets)
- Coverage drops below threshold

## 8. Observable By Default

Every service emits:
- Structured logs (JSON with correlation IDs)
- Metrics (request count, latency, errors)
- Traces (distributed across service boundaries)
- Health probes (`/health`, `/ready`)

If you can't see it, you can't operate it.

## 9. Secure By Default

- Auth required everywhere unless explicitly opted out
- Inputs validated at every boundary
- Secrets in Key Vault, never in code
- Least-privilege everywhere

## 10. Done Means Deployed

A feature isn't done until it's:
- Merged to `main`
- Tagged with a release version
- Deployed to PROD (or scheduled for the next release)
- Verified against acceptance criteria
- Monitored for 24 hours without incident

---

## When You Disagree With A Principle

These principles aren't sacred — they're the current best understanding. If you have a strong reason to deviate:

1. Document the deviation in your PR description
2. Get architect approval
3. If the deviation reveals a flaw in the principle, propose an update via PR to this doc

But **never silently violate**. Silent violations become the new convention by accident.
