---
description: Write a phased implementation plan from a spec
---

Read `docs/requirements/<feature>/spec.md`. Write `docs/requirements/<feature>/plan.md` per the template at `~/.claude/vibe-kit/templates/plan.md`.

## Rules

- **Phases** in order: 1) Schema, 2) API/Logic, 3) UI, 4) Tests, 5) Docs.
- **Each step small enough for one AI session** (≤ ~30 minutes of model work).
- **Spec → test map** in the plan: every AC has a corresponding test name slot.
- **Decisions left to make** are listed with options A/B and a recommended default.
- **Risks** reference the spec R-IDs.
- **Dependencies**: name the spec modules / libs / teams the work blocks or is blocked by.

## Process

1. Walk the AC list one-by-one. Map each to a test name.
2. Order phases by dependency: nothing downstream before upstream green.
3. If a phase requires a decision, flag it (don't auto-decide irreversible choices).
4. Print plan summary + open decisions. Wait for user.
