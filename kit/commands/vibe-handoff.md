---
description: Write a session handoff doc
---

Write `docs/handoffs/$(date +%Y-%m-%d)-<slug>.md` using the template at `~/.claude/vibe-kit/templates/handoff.md`. Branch-name slug if no other slug.

## Required sections

- **Goal** — what was set out (link to spec/feature).
- **Branch / state** — clean or dirty; base branch.
- **Done** — file paths where work landed.
- **In progress** — concrete file + state.
- **Blocked** — what's blocking + decision needed.
- **Files touched** — every file with one-line change description.
- **Decisions made** — short title; why; link to ADR if it grew one.
- **Decisions needed** — options A/B + recommendation.
- **Verification** — per-rank pass/fail with command.
- **Next steps for next session** — concrete, ordered.
- **Gotchas learned** — non-obvious things the next session will hit.

After writing, update `HANDOFF.md` with a 5-line TL;DR pointing at the new file.
