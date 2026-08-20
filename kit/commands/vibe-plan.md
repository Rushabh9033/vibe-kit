---
description: Write a phased implementation plan from a spec
---

Read `docs/requirements/<feature>/spec.md` and write `docs/requirements/<feature>/plan.md` using the template at `kit/templates/plan.md`.

## What it does

1. Read the spec; verify `Status` is `in-progress` (or warn the user if `awaiting-approval`).
2. Walk the AC list one-by-one; map each to a test name slot in the plan.
3. Order phases by dependency: Schema → API/Logic → UI → Tests → Docs (default).
4. For each irreversible decision in the spec, list options A/B with a recommended default — never auto-decide.
5. Surface the spec's open questions as "Decisions needed" in the plan.
6. Print the phase count + open-decisions count. **Don't start coding.**

## When to use

- After `/vibe-spec` and the user has approved the spec.
- Whenever the user types `/vibe-plan <feature-slug>`.

## Usage

```
/vibe-plan profile-photo-upload
```

If `<feature-slug>` is omitted, pick the most recent `docs/requirements/*/spec.md`.

## Rules

- **Phases** in order: 1) Schema, 2) API/Logic, 3) UI, 4) Tests, 5) Docs.
- **Each step ≤ ~30 minutes of model work.** If a step is bigger, split it.
- **Spec → test map** in the plan: every AC has a corresponding test name slot.
- **Decisions left to make** are listed with options A/B and a recommended default.
- **Risks** reference the spec's R-IDs (don't renumber).
- **Dependencies**: name the spec modules / libs / teams the work blocks or is blocked by.

## Output

```
docs/requirements/<feature>/plan.md
```

Print after writing:

```
plan written: docs/requirements/<feature>/plan.md
phases: <N>
steps: <N>
open decisions: <N>  (review before /vibe-execute)
next: paste prompts from plan.md into your Coder tool
```

## Ceremony-level shortcut

If `docs/requirements/<feature>/spec.md` has ≤ 2 ACs and no NFRs, this is a **tiny** change — write a 1-phase plan (single Coder session) and skip the schema phase. See `docs/ceremony-levels.md`.

## Limits

- The plan is a Coder prompt — not a file the Coder will edit. The Coder reads it, executes, and may produce a different artifact (handoff notes) if the spec changed mid-implementation.
- If the spec has zero ACs, refuse to plan. Go back to `/vibe-spec`.
