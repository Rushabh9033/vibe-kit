---
description: The ship-time gate — per-AC evidence before push
---

This is **the ship gate.** Runs automatically on every `git push` via the
opt-in pre-push hook. Demands evidence per Acceptance Criterion — not
assertions, not keyword matches, real proof.

The question it answers:

> **For each AC, what's the test that passes, and what diff lines implement it?**

Not: "I think it's working." Not: "The code looks right." Not: "The
verifier didn't complain."

## When to use

- **Ship time** — right before `git push`. The pre-push hook runs this
  automatically. If the hook isn't installed, run it manually.
- **End of a feature** — before you tell anyone "I'm done."
- **Never for mid-development checks** — use `/vibe-verify` for that. It's
  faster and heuristic. Claim-check is the heavy one.

## What it does

1. Reads `docs/requirements/<feature>/spec.md` for the current feature.
2. For each Acceptance Criterion, demands:
   - **Test path** in the `Verification:` block — `tests/<file>::test_<name>`
   - **Test passes** — `vibe-test` actually runs them; rc=0 required
   - **Diff evidence** — the test file appears in `git diff` (added or modified)
3. If any AC is missing evidence, the command BLOCKS. The Coder must fill the gap.
4. **The human is the final guard.** A passing claim-check doesn't mean
   the implementation is correct. It means each AC has *some* test that
   *passes* and *touches* the diff. Pair with mutation testing (rank 4)
   for actual correctness.

## Status model

| Status | Meaning | Exit |
|---|---|---|
| **PASS** | Every AC has a passing test + visible diff | 0 |
| **PARTIAL** | Some ACs have evidence; some don't | 2 (BLOCK) |
| **FAIL** | Tests don't pass | 1 |

The pre-push hook treats:

- **0** → push allowed
- **1** → push refused (FAIL cannot be overridden)
- **2** → push refused unless `VIBE_SHIP_OVERRIDE=1` is set

## Usage

```
/vibe-claim-check                  # current feature (most-recent spec)
/vibe-claim-check profile-photo    # specific feature by slug
```

## Implementation

```bash
# Locate the script
SCRIPT="$HOME/.claude/vibe-kit/bin/vibe-claim-check"
[ -x "$SCRIPT" ] || SCRIPT="./kit/bin/vibe-claim-check"

# Find the feature slug (most-recent spec dir)
SLUG="${1:-$(ls -t docs/requirements/*/spec.md 2>/dev/null | head -1 | xargs dirname | xargs basename)}"

exec "$SCRIPT" "$SLUG"
```

## Why this is different from `/vibe-verify`

The two commands check different things at different times:

| Command | When | What | Speed |
|---|---|---|---|
| `/vibe-verify` | Mid-development (every commit) | Keyword-based contract check — "is there *some* evidence for each AC in the diff?" | Fast (no test run) |
| `/vibe-claim-check` | **Ship time (pre-push)** | Per-AC evidence + actually-run tests + diff overlap | Slow (runs full test suite) |

Use verify throughout development. Use claim-check at the ship boundary.
The pre-push hook enforces claim-check; verify stays manual.

## Limits

- A test named `test_AC3_thing` passing doesn't mean it actually tests
  AC3 semantically. Pair with mutation testing (rank 4) for trust.
- The Coder can still fake evidence (copy/paste test paths into the
  Spec without writing real tests). The gate makes faking *harder*, not
  impossible. The user review is still the final guard.
- Runs the full test suite. Slow on large projects. Set `VIBE_CLAIM_FAST=1`
  to skip the test run and only check the diff overlap (matches verify's speed).