# Security Standards

These rules apply to every project in this toolkit — Power Apps, .NET, Power Automate, integrations.

---

## Identity & Access

### Power Platform
- All Canvas Apps require Microsoft Entra ID authentication (no anonymous access)
- Dataverse security roles follow least-privilege (see `dataverse-schema-standards.md`)
- Service principals for unattended scenarios — never personal accounts

### .NET APIs
- JWT Bearer tokens issued by Microsoft Entra ID
- Validate `iss`, `aud`, `exp`, `signature` on every request
- Token lifetime ≤ 60 minutes; refresh via OAuth flows

---

## Secrets Management

| Where secrets live | When |
|---|---|
| **Azure Key Vault** | Production, staging, any non-local environment |
| **User Secrets** (`dotnet user-secrets`) | Local development only |
| **Environment variables** | Container/runtime config |
| **`appsettings.Local.json`** (gitignored) | Local development convenience |

Never commit:
- API keys, client secrets, connection strings
- JWT signing keys
- Tenant IDs or app IDs that aren't already public
- `.env`, `secrets.json`, `appsettings.Production.json`

The `.gitignore` blocks the common patterns; verify before committing anything in `infrastructure/` or `config/`.

---

## Input Validation

- Validate at the API boundary (FluentValidation)
- Validate in Canvas Apps **and** at the API — never trust client-side alone
- Reject inputs that don't match expected schema
- Sanitize text destined for HTML or SQL contexts

---

## OWASP Top 10 — Mitigations

| Risk | Mitigation |
|---|---|
| **A01: Broken Access Control** | Authorization policies on every endpoint; row-level security in Dataverse |
| **A02: Cryptographic Failures** | TLS 1.2+ everywhere; AES-256 for data at rest |
| **A03: Injection** | Parameterized queries (EF Core); no string-built SQL or OData |
| **A04: Insecure Design** | Threat-model new features; document trust boundaries |
| **A05: Security Misconfiguration** | Container image scanning; baseline `Microsoft Defender for Cloud` |
| **A06: Vulnerable Components** | `dotnet list package --vulnerable` in CI; renovate-bot for updates |
| **A07: ID & Auth Failures** | Entra ID for auth; MFA enforced via Conditional Access |
| **A08: Software Integrity Failures** | Signed packages; SBOM generation in CI |
| **A09: Logging & Monitoring Failures** | Structured logging + Application Insights with alerts |
| **A10: SSRF** | Allowlist external URLs; block private-IP ranges from outbound |

---

## Logging — What NOT to Log

| Never log | Always redact |
|---|---|
| Passwords, tokens, API keys | First 4 + last 4 of credit card |
| Full credit card numbers | Email — log domain only when not required |
| Full SSNs / national IDs | Phone numbers — last 4 digits |
| Encryption keys | Personal addresses |
| Session tokens | Health information |

Use a redaction pipeline (Serilog filter or middleware).

---

## Power Automate Flows

- Connection references — never embed credentials in actions
- Service-account connections for shared flows
- Use **HTTP with Azure AD** action over **HTTP** action whenever possible
- Sensitive inputs flagged with the `Secure Input` toggle
- Sensitive outputs flagged with the `Secure Output` toggle

---

## Data Classification

| Class | Examples | Storage Rules |
|---|---|---|
| **Public** | Marketing content | Any |
| **Internal** | Asset names, project metadata | Dataverse, with role-based access |
| **Confidential** | Customer PII, financial data | Encrypted at rest; audit enabled |
| **Restricted** | Authentication secrets, encryption keys | Key Vault only; no copies |

Tag tables with their classification in `examples/<app>/docs/schema.md`.

---

## API Hardening

- HTTPS only — HSTS header set with 1-year max-age
- Rate limiting via `Microsoft.AspNetCore.RateLimiting`
- CORS — allowlist origins, never `*`
- Security headers (`Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`)
- Disable directory listings; remove default banners

---

## Container Security

- Use Microsoft official base images (`mcr.microsoft.com/...`)
- Run as non-root user (`USER $APP_UID`)
- Scan images in CI (`docker scout` or `trivy`)
- Rebuild monthly to pull security patches

---

## Code Review Security Checklist

Reviewer must confirm:
- [ ] No secrets in committed files
- [ ] All endpoints require auth (or have explicit `[AllowAnonymous]`)
- [ ] All user inputs validated
- [ ] No raw SQL strings
- [ ] No `Console.WriteLine` of sensitive data
- [ ] New dependencies pass vulnerability scan

---

## Incident Response

If a secret is committed:
1. Immediately rotate the secret in the source system
2. Force-remove from history (`git filter-repo`)
3. Notify the security team
4. Document in the postmortem

If a vulnerability is disclosed:
1. Assess severity (CVSS)
2. Patch and deploy within SLA (Critical: 48h, High: 7 days, Medium: 30 days)
3. Communicate with stakeholders
