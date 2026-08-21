---
description: Run the project's test suite across configured ranks
---

Run the project's tests across detected ranks (lint, typecheck, unit, integration)
and report honest status with the same exit-code discipline as `/vibe-verify`.

The question it answers:

> **Do the tests pass — for every rank I have configured?**

Not just: "Does the code compile?"

## What it does

Auto-detects the project's stack and runner:

- **Python:** pytest, unittest
- **Node:** npm test, vitest, jest

Then runs each detected rank sequentially and aggregates status. Lint/typecheck run first
(Rank 1), unit/integration second (Rank 2). Each rank gets its own status; the worst one wins.

## Status model

The oracle uses four statuses. The smallest vocabulary that says what matters.

| Status | Symbol | Meaning | Exit code |
|---|---|---|---|
| **PASS** | ✓ | All detected ranks pass | 0 |
| **FAIL** | ✗ | At least one rank failed | 1 |
| **BLOCK** | ⚠ | Runner configured but tool not installed | 2 |
| **UNVERIFIED** | ? | No test runner detected | 3 |

`VIBE_SHIP_OVERRIDE=1` lifts BLOCK (2 → 0). It cannot lift FAIL. FAIL is a real no.

## When to use

- After the Coder finishes implementing a feature, before `/vibe-verify`.
- Before claiming "tests pass" on a PR.
- As part of the pre-push gate (v0.2 wires this in automatically).

## Usage

```
/vibe-test                # run all detected ranks
/vibe-test --rank=lint    # just lint
/vibe-test --rank=typecheck
/vibe-test --rank=unit
/vibe-test --rank=integration
/vibe-test --json         # machine-parseable output
/vibe-test --fix          # run lint --fix if available
```

## Implementation

This command runs the script at `kit/bin/vibe-test` (or its installed
equivalent at `~/.claude/vibe-kit/bin/vibe-test`).

```bash
# Locate the script (project install takes priority over global)
if [ -x "./kit/bin/vibe-test" ]; then
  ./kit/bin/vibe-test "$@"
elif [ -x "$HOME/.claude/vibe-kit/bin/vibe-test" ]; then
  $HOME/.claude/vibe-kit/bin/vibe-test "$@"
else
  echo "vibe-test not installed. Run kit/bin/vibe-init or copy the script."
  exit 1
fi
```

## Reading the output

```
vibe-test: PASS

  lint         PASS
  typecheck    PASS
  unit         PASS
  integration  PASS
```

A failing run:

```
vibe-test: FAIL

  lint         PASS
  typecheck    FAIL   rc=2
  unit         FAIL   rc=1
  integration  BLOCK  runner=pytest configured but executable not found in PATH

  --- last rank output (top 30 lines) ---
  ...
```

## Detection rules

The script is deterministic. No AI. It looks at:

- `pyproject.toml` with `[tool.pytest.ini_options]` → pytest
- `pytest.ini` or `conftest.py` → pytest
- `package.json` with `scripts.test` → npm test
- `package.json` with `vitest` / `jest` dep → that runner
- `tests/test_*.py` without pytest → `python3 -m unittest discover`

Otherwise → UNVERIFIED with a hint to install a runner.

## Limits

- The script cannot prove semantic correctness. It only knows whether tests run and pass.
  Use mutation testing (rank 4) to know whether they exercise the AC.
- It does not auto-generate tests. You write the tests; the oracle runs them.
- It does not detect Python `tox` / `nox` / `hatch` runners yet. v0.2 if there's demand.
- It does not detect Go / Java / Rust / Elixir. v0.2 if there's demand.

## Companion tool: prep-room

The kit also ships a **prep-room** PreToolUse hook (`kit/bin/hooks/prep-room.sh`)
that surfaces recent commits, affected tests, and Spec ACs *before* every Edit/Write.
It's the other half of the Smart Vibe Coder: this oracle verifies the work after,
prep-room reminds the Coder what it was doing during. See `docs/superpowers/specs/2026-08-21-smart-vibe-coder-design.md`.