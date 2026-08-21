# Feature: vibe-mutate (mutation testing at ship time)

Status: shipped
Owner: @Rushabh9033
Last updated: 2026-08-21
Linked milestone: docs/SPEC.md ## "v0.x weapon suite"

> Mutation testing proves your tests actually exercise the AC, not just
> talk about it. `vibe-verify` is a keyword matcher (fast, mid-dev).
> `vibe-claim-check` runs the test suite (slow, ship time). Neither
> catches "tests pass but they don't actually test the code." Mutation
> testing does.

## Goal

Ship a deterministic, language-aware `vibe-mutate` binary that runs
mutation testing on the project's changed code, reports a mutation score,
and gates ship-time when the score falls below threshold. Becomes Rank 1
in the verification floors table: the highest-leverage check, run at
ship time, opt-in everywhere else.

## Acceptance Criteria (final)

All 14 ACs shipped; see `tests/weapons/test-vibe-mutate.sh` (33 assertions).

## Constraints

- Bash 3.2 portable (no `mapfile`, no `declare -A`).
- No new dependencies added to the kit.
- Mutation tools are user-installed (mutmut / Stryker / PIT).
- Mutation is ship-time only — not in `vibe-verify` (mid-dev).

## Verification

End-to-end:

```bash
pip install mutmut
mutmut run --tests-dir tests
vibe-mutate
```

## Ship notes

- `vibe-mutate` lives at `kit/bin/vibe-mutate`. Wired into `vibe-claim-check`
  as a post-test step. rc=1 (FAIL) and rc=2 (BLOCK) from mutate become
  PARTIAL in claim-check; `VIBE_SHIP_OVERRIDE=1` lifts PARTIAL but never FAIL.
- Tests stub mutmut/Stryker/mvn on PATH so no real mutation tool runs.
- Threshold default is 70 (matches `~/.claude/rules/02-verify.md`).
