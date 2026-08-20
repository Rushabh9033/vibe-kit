---
paths:
  - "**/*"
---

# Compound corrections — every mistake becomes a rule (Boris Cherny pattern)

When the same mistake happens twice, persist the lesson.

## Where it goes

| Scope | Where to write |
|---|---|
| Repo-wide mistake | `AGENTS.md` at project root |
| Path-specific mistake | `.claude/rules/<topic>.md` with `paths:` frontmatter |
| Personal recurring mistake | `~/.claude/CLAUDE.md` (this file's parent) |
| Project-private ephemeral fact | auto-memory topic file: `~/.claude/projects/<repo>/memory/<topic>.md` |

## Rule format

```
- [What was wrong]. [Why it was wrong]. [What to do instead]. (added YYYY-MM-DD)
```

Example:

```
- Claude silently coerces `null` to `undefined` in tests; assert with `expect(x).toBeNull()` not `expect(x).toBeFalsy()`. (2026-07-18)
```

## Triggers

- Same general failure across 2+ sessions.
- Code review feedback from a human reviewer.
- Postmortem action item.

## Don't

- Don't add rules for one-offs — that bloats context.
- Don't put future intent here ("we should..."). Past lessons only.
- Don't write to `~/.claude/CLAUDE.md` for project-specific knowledge — it pollutes global context.

## Code review

When a human tags `@.claude` on a PR review, the agent converts the feedback into a repo-level rule (often an `AGENTS.md` append).
