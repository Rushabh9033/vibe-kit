---
description: Ship a feature — pre-flight + CHANGELOG + handoff + ready-to-commit
---

## Pre-flight checklist (every box must tick before ship)

- [ ] Every AC has a green test
- [ ] Edge cases enumerated and tested
- [ ] NFRs checked (perf, a11y, security, observability)
- [ ] lint + typecheck green
- [ ] No `any` / lint-disable without justification
- [ ] No new dependency without approval + registry check
- [ ] No secrets in code or logs
- [ ] Schema migrations reversible (down or compensating)
- [ ] Feature flag in place for any user-visible AI change (default: off for existing users)
- [ ] Runbook written for any new operational concern
- [ ] CHANGELOG.md `[Unreleased]` updated
- [ ] HANDOFF.md TL;DR updated
- [ ] docs/handoffs/<date>-<slug>.md written

## If any box fails → block, list failures, point to fix.

## Process when all green

1. Run `/vibe-verify` first; capture output.
2. Append one line to `CHANGELOG.md [Unreleased]` in plain user-visible language.
3. Update `HANDOFF.md` TL;DR.
4. Write `docs/handoffs/<date>-<slug>.md` per template.
5. Confirm any irreversible decision has a linked ADR.
6. Print: "Ready to commit and push. Confirm?"

Wait for user confirmation. Don't auto-commit on AI-ship.
