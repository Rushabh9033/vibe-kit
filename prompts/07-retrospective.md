# 07 — Retrospective (after ship)

You are the **Planner**. The Coder has shipped the feature. Your job: **convert lessons into persistent artifacts** so the next session inherits them.

## Intake

- The feature's `spec.md`.
- The feature's `plan.md`.
- The Coder's `docs/handoffs/` — all sessions, especially the last one.
- The merged PR's review (if any).

## Output — three artifacts

### 1. Update `docs/gotchas.md`

Add one entry per non-obvious finding:

```
- <rule> (added YYYY-MM-DD; feature=<slug>; discovered in <session>)
```

Examples:

```
- Photo upload must round-trip within 5 seconds for 5MB JPEGs — ImageMagick resize is the bottleneck; we use sharp + cache. (2026-08-20; feature=profile-photo-upload)
- EXIF GPS stripping must happen at decode, not at save — we lost 3 days implementing it wrong. (2026-08-21; feature=profile-photo-upload)
```

### 2. Add or update an ADR

For every irreversible decision that emerged during implementation (and isn't already in `docs/decisions/`), use `prompts/04-adr.md`.

### 3. Update `AGENTS.md` (if the lesson is repo-wide)

If the lesson is repeated or repo-wide, append a rule to `AGENTS.md`:

```
## Gotchas (continued)
- Don't resize images in the upload path; do it in a worker queue. (2026-08-20)
```

Or to `.claude/rules/<topic>.md` if path-specific.

### 4. Append to `CHANGELOG.md [Unreleased]`

One line, user-visible, plain language:

```
### Added
- Profile photo upload with crop + 32/64/256/512 variants. (2026-08-20)
```

### 5. Confirm `HANDOFF.md` TL;DR is current

Open the project's `HANDOFF.md`. Update the 5-line TL;DR to reflect what's now true. Point at the most recent handoff doc.

## Discipline: every mistake → a rule

If you find anything in the Coder's session that you'd want to prevent next time, **write it down**. Anywhere is fine — the goal is persistence, not perfection of placement.

## Anti-patterns

- Skipping because "we'll remember." You won't.
- Putting it in a Slack message. (Lost.)
- Putting it in a long compound document nobody reads. (Lost.)
- Putting it in a code comment buried in the diff. (Lost.)
