# Spec-first gate — what the Coder does at task start

> The Coder is **both** an implementation agent **and** a requirements-discovery agent
> when no applicable Spec exists. The Planner is an **optional** entry point —
> any chat AI (or the Coder itself) can produce the Spec. The Spec, once
> approved, is the only artifact the implementation phase consumes.

This gate runs **at every Coder task start**. It does not change the Spec
template, the Discovery protocol, or the verification gate. It adds a
decision step before any code is written.

## Decision tree

```
TASK START
    │
    ▼
1. Is the work trivial (vibe-classify: tiny)?
    │
    ├─ YES → proceed with existing ceremony (edit / commit / done)
    │
    └─ NO ↓
    │
2. Does docs/requirements/<feature>/spec.md exist?
    │
    ├─ YES, Status: in-progress → resume; read spec.md + plan.md + latest handoff
    │
    ├─ YES, Status: awaiting-approval → STOP. Tell the user the Spec is
    │                                    ready for review. Do NOT implement.
    │                                    The user must set Status: in-progress.
    │
    ├─ YES, Status: draft → continue the Discovery protocol (it was interrupted)
    │
    └─ NO ↓
    │
3. Is the change a milestone-scope edit (touching docs/SPEC.md, not a new feature)?
    │
    ├─ YES → proceed; treat docs/SPEC.md as the contract for this change
    │
    └─ NO ↓
    │
4. **Enter DISCOVERY MODE** (canonical source: prompts/00-anchor.md
   § Discovery protocol). Interview the user one question at a time until
   every core question has a non-vague answer. Then write
   docs/requirements/<feature>/spec.md from kit/templates/requirements-spec.md
   with Status: awaiting-approval.

5. **STOP after writing the Spec.** Wait for the user to set
   Status: in-progress. Do NOT proceed to implementation in the same turn.

6. After approval: re-read the Spec, optionally write plan.md
   (kit/templates/plan.md), and switch to implementation.
```

## Approval boundary (non-negotiable)

A Coder that creates a Spec must **not** continue to implementation in the
same response. The user is the only one who can flip
`Status: awaiting-approval` → `Status: in-progress`. This is the same
discipline the Planner has always had; the Coder inherits it when it
runs Discovery itself.

If the Coder finds itself wanting to "just keep going," stop and write
the handoff. The next session (or the user's reply) re-runs the gate
from step 2.

## When to skip Discovery

Discovery is **not** triggered for:

- Typo fixes, comment edits, formatting-only changes (`vibe-classify: tiny`)
- Work that touches only `docs/SPEC.md` (milestone-level edits)
- Work that resumes an in-progress Spec (gate step 2 → resume)
- Work that adds one test or one assertion to an existing Spec

If unsure, run `./kit/bin/vibe-classify` first. The classifier is the
source of truth for ceremony level; tiny means no Spec ceremony.

## When Discovery is mandatory

Discovery is **always** triggered for work that:

- Adds a new feature (new `docs/requirements/<feature>/spec.md` needed)
- Adds, removes, or changes an API surface
- Adds a new top-level dependency
- Touches `/auth`, `/billing`, `/security`, or migrations
- Is classified as `large` or `critical` by `vibe-classify`

The Discovery protocol's five core questions (job, user, success metric,
out-of-scope, hard constraints) plus a risks round are the floor. Don't
shortcut it because the user "just wants this one thing."

## What this does NOT change

- `kit/templates/requirements-spec.md` — same template, same Status field
- `prompts/00-anchor.md` § Discovery protocol — single source of truth
- `kit/templates/plan.md` — same phases, same Spec→test map
- `kit/bin/vibe-verify` — same status model, same exit codes
- `kit/bin/vibe-classify` — same thresholds
- `/vibe-spec` slash command — still works for users who want the Planner path

## Two entry points, one workflow

| Entry point | When |
|---|---|
| **Planner** (`/vibe-spec` in a chat AI, or pasting `prompts/00-*.md`) | When you want to separate planning from coding. Useful when the user is not the coder, or when the planning model has a longer context window than the coding tool. |
| **Coder as discoverer** (this gate, step 4) | When you have one tool and want to stay in it. The Coder interviews, writes the Spec, stops for approval, then implements in the next turn. |

Either path produces the same `docs/requirements/<feature>/spec.md`. The
ship gate (`vibe-verify` + `/vibe-ship`) doesn't care which entry point
produced the Spec.

## The principle

> **Spec first, code second, run forever.**
> The Planner is optional. The Spec is mandatory.