---
description: Write a session handoff doc
---

Write a session handoff doc so the next session (or another agent) can resume without re-discovering context.

## What it does

1. Determine today's date and the current git branch slug.
2. Use the template at `kit/templates/handoff.md`.
3. Fill every section from observable state (git log, files changed since session start, recent spec/plan/ADR diffs).
4. Write to `docs/handoffs/<date>-<slug>.md` (or fallback `$HOME/.claude/projects/<cwd-base>/handoffs/`).
5. Append a 5-line TL;DR to `HANDOFF.md` pointing at the new file.

## When to use

- At the end of any session that touched code.
- Before context loss (long pause, model switch, end-of-day).
- Whenever the user types `/vibe-handoff`.

## Usage

```
/vibe-handoff
/vibe-handoff profile-photo-upload   # optional: feature slug for context
```

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

## Output

```
docs/handoffs/<date>-<slug>.md     (~1-3 KB, sections complete)
HANDOFF.md                          (+5-line TL;DR)
```

Print after writing:

```
handoff: docs/handoffs/<date>-<slug>.md
sections: <count> complete
next-session hook: <first concrete step>
```

## Limits

- Keep it tight — bullet points and one-liners only. Full prose belongs in the spec/ADR, not the handoff.
- Don't fabricate sections. If a section is empty, write `(none)` and move on.
- Don't modify the metadata footer (session_id, started, cwd, branch, written_by).
