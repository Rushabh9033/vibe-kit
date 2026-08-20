# Security Policy

## Reporting a vulnerability

Email: security@<your-domain> (or open a private security advisory on GitHub).

Please **do not** file a public issue for security bugs.

We aim to ack within 72h and ship a fix within 14 days for critical issues.

## Slopsquatting

Up to ~20% of AI code samples include **hallucinated package names**. Attackers register the names with malicious post-install scripts. Until/unless the registry filters at scale, all new dependencies must be verified manually (see `kit/rules/03-no-slopsquatting.md`):

1. `npm view <pkg>` — must exist on the registry
2. Socket / Snyk / Dependabot / osv-scanner — must pass
3. License check — on the allowlist
4. Quarantine — install in a sandbox for high-risk deps
5. Lockfile pin — exact version

## Model outputs are untrusted

Treat any AI-generated code as untrusted input through review. Pin model versions (`latest` is a footgun). Tag every AI call with `model`, `model_version`, `prompt_template_version`.

## Secrets

- Never commit `.env*` files.
- Run `gitleaks protect` pre-commit (or in CI).
- Rotate immediately on leak.

## Prompt injection

If you build features that pass agent output back into prompts (RAG, tool loops, code-review feedback chains), apply standard prompt-injection mitigations: separate trusted/untrusted inputs, validate at boundaries, reject tool calls that violate tool schemas.
