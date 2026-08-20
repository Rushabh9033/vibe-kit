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
3. Verify every new dependency against the lockfile and the registry (`npm view` / `pip index versions`).
4. Look for AI telltales: overly defensive `try/except: pass`, unrequested helpers, "balanced" code symmetry, exhaustive comments.
5. Run the test suite yourself if not already in CI.
6. Output a numbered list of issues with `file:line`, severity (`blocker | major | minor | nit`), and a recommendation.
7. End with: `approve` / `request changes` / `rewrite in place`.

## When to use

- Whenever a PR or branch needs review.
- Before merging a Coder-produced branch.
- Whenever the user types `/vibe-review-pr`.

## Usage

```
/vibe-review-pr                  # current branch
/vibe-review-pr feature/foo      # branch name
/vibe-review-pr 42               # PR number (uses gh pr diff 42)
```

## Output

```
reviewing: <branch-or-PR>
surface area: <list> (triage)
diff: <N> files, <+M> / <-N>

issues:
  [blocker] src/auth.ts:42 — invented env var LOGIN_PROVIDER; not in lockfile
  [major]   src/upload.ts:88 — error swallowed; user sees 200 on partial write
  [minor]   tests/upload.test.ts:15 — no assertion for >5MB case
  [nit]     src/upload.ts:3 — unused import

verdict: request changes
```

## Severity guide

| Severity | Means | Action |
|---|---|---|
| `blocker` | Security, data loss, fabricated dep, swallowed auth | Reject; rewrite required |
| `major` | Spec deviation, missing test for AC, missing auth at boundary | Request changes |
| `minor` | Style, naming, missing edge case test | Suggest; not blocking |
| `nit` | Subjective / cleanup | Optional |

## Limits

- This is a heuristic review. Always pair with human review for auth, billing, migrations.
- AI telltales are patterns, not proof. Don't flag a `try/except: pass` if the comment explains why it's intentional.
