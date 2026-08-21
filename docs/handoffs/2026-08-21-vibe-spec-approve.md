# 2026-08-21 — `vibe-spec-approve` shipped (auto-arm bridge)

## What

New command `kit/bin/vibe-spec-approve <slug> [--no-arm]` that bridges a
human's "yes, ship this Spec" to the kit's hard gates in a single step.

Three side effects, one command:

1. **Flips status** — `Status: awaiting-approval` → `Status: in-progress`
   in `docs/requirements/<slug>/spec.md`. Refuses any other source state
   (so a closed Spec stays closed; re-running on an in-progress Spec is a
   no-op).
2. **Writes the blessing** — `.vibe-cache/spec-approved-<slug>` so other
   scripts (`/vibe-claim-check`) can reference the human approval without
   re-parsing the Spec.
3. **Auto-arms the kit** — calls `vibe-arm` to turn on the hard gates.
   Skip with `--no-arm` if you want to keep vibe-kit in "encouragement"
   mode.

The fresh-project workflow is now:
```
vibe-spec-intake <slug> "<intent>"
  → fill the ACs
  → vibe-spec-approve <slug>
  → start coding under the gates
```
No separate `vibe-arm` step on a fresh project.

## Why

v0.2 ships 7 weapons + a `vibe-arm` bundle, but arming was opt-in. A solo
dev who runs `vibe-install` and then `vibe-spec-intake` would still ship
ungated unless they remembered to also run `vibe-arm`. The Spec-first gate
in `kit/CLAUDE.md` required humans to flip status; this command makes
that transition also arm the kit, so the first ship from a fresh project
is gated by default.

This is the #1 item from "What we need to do to fix the solo developer
problem" (see the prior conversation turn).

## Commit

`c935b26` — `feat(spec-approve): auto-arm the kit the moment a Spec is blessed`
pushed to `origin/main` and verified.

## Files

| File | Change |
|---|---|
| `kit/bin/vibe-spec-approve` | new (~70 lines, awk-based status flip, macOS/Linux portable, `set -uo pipefail`, friendly `--help`) |
| `tests/weapons/test-weapons.sh` | +11 assertions: status flip, auto-arm, `--no-arm` skip, idempotency, refusal of non-awaiting-approval, missing-slug error |
| `kit/CLAUDE.md` | spec-first-gate section now points at `vibe-spec-approve` |
| `README.md` | weapon section + tree entry |
| `CHANGELOG.md` | `[Unreleased]` entry with rationale + test count |

## Tests

| Suite | Assertions | Status |
|---|---|---|
| spec-first | 53 | ✓ green |
| vibe-test | 10 | ✓ green |
| prep-room | 21 | ✓ green |
| weapons | 40 (was 29, +11 new) | ✓ green |
| **Total** | **124** (was 113, +11 new) | **all green** |

## What's next (from the priority list)

The remaining items from "fix the solo developer problem":

2. **Spec template gallery** — 10 common features (2 days)
3. **`/vibe-claim-check` as the ship gate** — replace `/vibe-verify` in the docs (1 day)
4. **Mutation testing as Rank 1** — wrap mutmut/Stryker behind `vibe-test --rank=mutation` (2 days)
5. **AI-assisted intake** — single-purpose Planner model invocation, gated by the same approval boundary (3 days)

#1 (auto-arm after Spec approval) is **done**. Next move: #2 (Spec template gallery).