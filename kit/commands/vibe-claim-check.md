---
description: Force per-AC evidence before claiming a feature is done
---

Before you say "done," prove it. This command requires evidence per
Acceptance Criterion — not assertions.

The question it answers:

> **For each AC, what's the test that passes?**

Not: "I think it's working." Not: "The code looks right."

## What it does

1. Reads `docs/requirements/<feature>/spec.md` for the current feature.
2. For each Acceptance Criterion, demands:
   - **Test path:** `tests/<file>::test_<name>` (or "human-judged")
   - **Test status:** passes (must actually run; `vibe-test` will execute)
   - **Diff:** `git diff` lines that implement the AC
3. If any AC is missing evidence, the command BLOCKS. The Coder must fill the gap.

## Status model

| Status | Meaning | Exit |
|---|---|---|
| **PASS** | Every AC has a passing test + visible diff | 0 |
| **PARTIAL** | Some ACs have evidence; some don't | 2 |
| **FAIL** | Tests don't pass | 1 |

## Usage

```
/vibe-claim-check                  # current feature
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

- `/vibe-verify` checks *evidence in the diff* (keyword matching, AC↔test path).
- `/vibe-claim-check` checks *evidence per AC* — the Coder must enumerate and
  prove, AC by one. The Coder can't claim "everything passes" without showing
  the work for each one.

Use `/vibe-verify` as the contract checker. Use `/vibe-claim-check` when you
want the Coder to prove it actually read and satisfied each AC.

## Limits

- Evidence is still heuristic. A test named `test_AC3_thing` passing doesn't
  mean it actually tests AC3. Pair with mutation testing (rank 4) for trust.
- The Coder can still fake evidence (copy/paste test paths). The gate makes
  faking *harder*, not impossible. The user review is still the final guard.