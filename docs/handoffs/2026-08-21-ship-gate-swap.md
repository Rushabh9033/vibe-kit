# 2026-08-21 — ship-gate swap (`/vibe-claim-check` is the real gate)

## TL;DR

`/vibe-verify` was overloaded. It was both the mid-development contract check AND the ship-time gate, but it doesn't actually run tests — so it could report PASS while tests were red. Split the roles:

- **`/vibe-verify`** — mid-development. Keyword-based. Fast. No test run.
- **`/vibe-claim-check`** — ship-time. Per-AC evidence + actually-run tests. Slow. The pre-push hook enforces it.

Shipped in commit `13f0fa5`. All test suites green (132 assertions, 0 failures). Pre-push hook is shipped but opt-in; install with the snippet in the README.

## Why now

The old `vibe-pre-push` hook called `vibe-verify`. Verify is correct for what it is — a fast keyword matcher that tells you whether the diff *talks about* your ACs. But at ship time, you need the test suite to have run, and verify never ran tests. Two failure modes this left open:

1. **Silent FAIL**: code claims an AC is met, verify sees the keyword, returns PASS, push goes through. The test that would have caught the regression wasn't checked.
2. **Confused docs**: README, CLAUDE.md, and the slash-command docs all called verify "the gate" with the same exit-code table claim-check has. A user reading either doc got the wrong mental model.

The fix is a semantic split: verify stays fast and mid-dev, claim-check becomes the real boundary.

## What changed

| File | Change |
|---|---|
| `kit/bin/hooks/vibe-pre-push` | Calls `vibe-claim-check` (not `vibe-verify`). New exit-code mapping: rc=0 → exit 0, rc=1 → exit 1 (FAIL cannot be overridden), rc=2 → exit 1 unless `VIBE_SHIP_OVERRIDE=1`, missing → exit 0 (skip), `--no-verify` → exit 0. |
| `kit/commands/vibe-claim-check.md` | Header now: *"This is **the ship gate.**"* New comparison table vs verify. |
| `kit/commands/vibe-verify.md` | New "When to use" section explicitly says it's mid-development and *not* at ship time. |
| `kit/CLAUDE.md` | Slash-command list updated; new line: *"Use `/vibe-verify` mid-development. Use `/vibe-claim-check` at the ship boundary."* |
| `kit/templates/CLAUDE.md` | Claude Code specifics section updated; claim-check added to slash list. |
| `README.md` | Renamed verify section to *"the contract checker (mid-development)"*. Added new *"Ship — the actual gate"* section with the two-command comparison table. |
| `CHANGELOG.md` | New entry: *"`/vibe-claim-check` is now the ship-time gate (not `/vibe-verify`)"* with rationale. |
| `tests/weapons/test-pre-push.sh` | **NEW.** 18 assertions covering hook wiring (calls claim-check, not verify, in code), behavior matrix (PASS / FAIL / BLOCK / override / missing / --no-verify), and slash-command doc alignment. |

## Exit-code mapping (the contract)

```
claim-check rc=0    → hook rc=0  (PASS)
claim-check rc=1    → hook rc=1  (FAIL — cannot be overridden)
claim-check rc=2    → hook rc=1  (BLOCK — refused without override)
claim-check rc=2 + VIBE_SHIP_OVERRIDE=1 → hook rc=0  (BLOCK lifted)
claim-check missing → hook rc=0  (skip — don't break the user)
--no-verify          → hook rc=0  (documented escape hatch)
```

## Test coverage

The new `tests/weapons/test-pre-push.sh` is the real proof. It builds a fake `vibe-claim-check` with controllable exit codes and verifies the hook does the right thing for each matrix cell. Bash 3.2–portable (no `mapfile`, no `declare -A`). Lives next to `test-weapons.sh` so the kit's CI loops catch regressions.

Other suites:
- `test-weapons.sh` — 40 ✓
- `test-prep-room.sh` — 21 ✓
- `test-spec-first-gate.sh` — 53 ✓ (exit 0, 0 failures)
- `test-pre-push.sh` — 18 ✓ (NEW)
- **Total: 132 assertions, 0 failures.**

## Gotchas (compound)

- **Opt-in is correct.** The hook is shipped but not installed. README has the install snippet. Don't auto-install on `vibe-install` — that would surprise users mid-stream. The kit is opt-in; respect it.
- **The hook references `vibe-verify` in a comment.** That's intentional — it tells future maintainers where the alternative lives. The test grep is comment-aware (`grep -E '^[^#]*vibe-verify'`) so comments don't trip the assertion.
- **`VIBE_SHIP_OVERRIDE=1` lifts BLOCK, never FAIL.** That's deliberate. Override is for "I want a human to ship this anyway despite missing evidence." Override is *not* for "I want the failing tests to not count." Documented in both `vibe-pre-push` and the README.
- **Hook's "not installed" path exits 0.** It logs a message and moves on. Reason: if a user has the kit installed but the binary is in some weird PATH state, we don't want to break their push flow. The kit is encouragement, not a fence they can't see over.

## What's still on the list

From the priority queue:

- ✅ #1: auto-arm after Spec approval (shipped earlier this session — `vibe-spec-approve`)
- ✅ #2: Spec template gallery (shipped earlier this session — 10 templates)
- ✅ #3: `/vibe-claim-check` as the real ship gate (this commit)
- ⏳ #4: Mutation testing as Rank 1
- ⏳ #5: AI-assisted intake (`vibe-spec-intake` weapon)

The ship-gate swap unblocks #4: claim-check already runs the test suite, so a mutation stage slot into the same rank-4 path is a clean add. #5 is independent.

## For the next session

If you continue this work, the hook contract is now stable. Two things worth knowing:

1. `tests/weapons/test-pre-push.sh` is the source of truth for the hook's contract. If you change the hook, update the test. If you change the test, update the hook. They lock together.
2. The `VIBE_SHIP_OVERRIDE=1` escape hatch is documented but rarely used. If you ever see it in a CI log, that's a BLOCK the user forced through. Worth surfacing in retros.
