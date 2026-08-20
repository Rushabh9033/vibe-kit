---
paths:
  - "**/*"
---

# Security rules (apply to every file)

## Dependencies (slopsquatting prevention — highest-ROI rule)

- Every new dependency is untrusted input.
- Before adding, verify on the registry: `npm view <name> version` (must exist), and run Socket / Snyk / Dependabot / osv-scanner.
- Lockfile and integrity hash required (npm `package-lock.json`, pip `--require-hashes`, `Cargo.lock`).
- New high-risk deps must run in a quarantine sandbox first.
- AI may NOT add dependencies outside the allowlist (see `docs/decisions/0002-deps-allowlist.md` if present).
- License check: every dep must be on the allowlist; CI gate.
- Run audit weekly minimum: `npm audit --omit=dev`, `pip-audit`, `cargo audit`.

## Secrets

- Never hardcode secrets, tokens, URLs, env-specific values.
- `.env*` files MUST be in `.gitignore`.
- Pre-commit: gitleaks / trufflehog blocks secrets at commit.
- Rotate immediately if any credential leaks into git history.

## Auth / Authz

- Every protected endpoint requires explicit `requireAuth()` middleware.
- Authorization checks happen at the data layer too (defense in depth).
- String-interpolated SQL is banned; parameterized queries only.
- CORS and CSP defaults are deny-all-then-allow.

## Inputs

- Validate at trust boundaries with zod / pydantic / io-ts.
- Never trust client-supplied IDs in security-sensitive paths.
- Limit request body size; reject binary where JSON is expected.

## Logging

- Never log secrets, full PII, full prompt contents.
- Tag AI-generated outputs with `ai_assisted=true` (and `model`, `model_version`, `prompt_template_version`) for downstream audit.

## AI-specific

- Treat agent output as untrusted input. The compiled code is trusted; the source is reviewed.
- Pin model versions; never `latest`.
- Run prompt-injection-aware checks on any code that copies agent output into prompts.
