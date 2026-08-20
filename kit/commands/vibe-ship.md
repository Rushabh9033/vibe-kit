---
description: Pre-flight + CHANGELOG + handoff + ready-to-commit
---

Ship a feature. Run the pre-flight gate, then update the user-visible artifacts, then wait for the user's explicit "go" before any git push.

## Pre-flight checklist (every box must tick before ship)

Run `/vibe-verify` first; if it returns `overall: BLOCK`, refuse to ship.

- [ ] `/vibe-verify` returned `overall: PASS`
- [ ] Edge cases enumerated and tested (per spec)
- [ ] NFRs checked (perf, a11y, security, observability)
- [ ] lint + typecheck green
- [ ] No `any` / lint-disable without justification
- [ ] No new dependency without approval + registry check (`npm view` / `pip index versions`)
- [ ] No secrets in code or logs
- [ ] Schema migrations reversible (down or compensating)
- [ ] Feature flag in place for any user-visible AI change (default: off for existing users)
- [ ] Runbook written for any new operational concern
- [ ] CHANGELOG.md `[Unreleased]` updated (one line, plain user-visible language)
- [ ] docs/handoffs/<date>-<slug>.md written

**If any box fails → block, list failures, point to fix.**

## Process when all green

1. Run `/vibe-verify`; capture output.
2. Append one line to `CHANGELOG.md [Unreleased]`.
3. Write `docs/handoffs/<date>-<slug>.md` per template.
4. Confirm any irreversible decision has a linked ADR (`docs/decisions/NNNN-*.md`).
5. Print: "Ready to commit and push. Confirm?"

**Wait for user confirmation. Don't auto-commit on AI-ship.**

## When to use

- After the Coder has finished a feature and tests are green.
- Whenever the user types `/vibe-ship`.

## Usage

```
/vibe-ship profile-photo-upload
```

If `<feature-slug>` is omitted, pick the most recent `docs/requirements/*/spec.md`.

## Output (after pre-flight + updates)

```
pre-flight: PASS
verify:     PASS  (output captured)
changelog:  +1 line in [Unreleased]
handoff:    docs/handoffs/<date>-<slug>.md
adrs:       <linked-or-none>

Ready to commit and push. Confirm?
```

## Anti-patterns

- Don't `git push` without explicit user confirmation. The user may want to squash, rebase, or add a PR description first.
- Don't auto-bump version. That's a separate decision (`/vibe-decide` if it's irreversible).
- Don't merge to main without the user's go-ahead. Ship ≠ merge.
