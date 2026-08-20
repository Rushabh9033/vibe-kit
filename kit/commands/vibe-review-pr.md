---
description: Review a PR/branch with the AI-specific checklist
---

Review `$ARGUMENTS` (PR number, or branch name if no PR), or the current branch if no argument.

## AI-specific checklist (canonical, the only default)

- Behavior matches spec; every AC verifiable.
- No invented packages, APIs, methods, env vars.
- Comments/docstrings accurate.
- Inputs validated at trust boundaries; auth/authz present where touched.
- Error handling doesn't swallow.
- Tests fail when the code is broken (mutation-tested if prod).
- No secrets, PII, tokens in code or logs.
- No copy-pasted licenses.
- Migrations reversible; new migrations are additive (no edits to committed).
- Telemetry added for new behavior (`ai_assisted` tag where relevant).
- Conventions enforced (lint, format, types) — CI green.
- AI-assisted label on the PR.

## Process

1. Triage by surface area (auth, billing, persistence, network, crypto = priority).
2. Walk the diff; cross-check claims in comments against behavior.
3. Verify every new dependency against the lockfile and the registry.
4. Look for AI telltales: overly defensive `try/except: pass`, unrequested helpers, "balanced" code symmetry, exhaustive comments.
5. Run the test suite yourself if not already in CI.
6. Output a numbered list of issues with `file:line`, severity (`blocker | major | minor | nit`), and a recommendation.
7. End with: `approve` / `request changes` / `rewrite in place`.
