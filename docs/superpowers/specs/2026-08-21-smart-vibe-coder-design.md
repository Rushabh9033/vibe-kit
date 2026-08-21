# Smart Vibe Coder — design doc

**Date:** 2026-08-21
**Status:** Approved (greenlight C, combined/fast)
**Owner:** Rushabh Mavani

## Problem

Solo developers writing big one-shot prompts to AI chatbots get:

1. **Half-built apps** — the AI builds *something* that looks like the goal but misses 4-7 unstated requirements. The user spends 70% of post-build time fixing bugs that the AI either missed the first time or re-introduced after a fix.
2. **No automated test coverage** — the AI writes the code; tests are either missing, shallow, or wrong. The "90% app in one shot" promise turns into "60% app, 30% tests, 10% debugging."
3. **Context loss** — across a long session, the AI forgets what just got built, what just got fixed, and what the Spec actually said. Edits go off-topic. Fixed bugs reappear.

vibe-kit already addresses (1) at the *intent* level (Spec-first, Discovery protocol, approval boundary). It does not address (2) or (3) at runtime.

## Goal

Ship a **Smart Vibe Coder** that adds two new runtime layers to vibe-kit:

- **A test oracle** that runs the project's tests across the configured ranks and reports honest status with the same exit-code discipline as `vibe-verify`.
- **A prep-room hook** that, before each Edit/Write, surfaces relevant context (recent commits, affected tests, Spec ACs) into the Coder's view, so it doesn't forget what it was supposed to do.

Both layers are **deterministic + AI-assisted** — they don't try to generate tests or predict bugs. They expose state the Coder already has access to, in a focused way.

## Non-goals (v0.1)

- No auto-generated tests (Playwright/axe/k6/mutmut). The Coder writes tests; the oracle runs them.
- No persistent state across sessions (`.vibe-cache/` , decision journal). v0.1 reads git + Spec at hook time.
- No regression detection (catching edits that undo a recent fix). v0.1 prevents "edit-without-context," not "edit-undoing-prior-fix."
- No full ceremony-table integration. The tool exists; you invoke it. Ceremony wiring is v0.2.
- No new test runner framework. v0.1 auto-detects Python (pytest, unittest) and Node (npm test, jest, vitest). Anything else falls back to "no runner detected" with a clear hint.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Coder (Claude Code / Cursor / Aider / etc.)               │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ Edit / Write │  │ PreToolUse   │──▶ prep-room.sh         │
│  │  tool calls  │  │ hook fires   │    (collects context)  │
│  └──────────────┘  └──────────────┘                        │
│                                                           │
│  Commands available:                                       │
│    /vibe-test    ──▶   kit/bin/vibe-test                  │
│    /vibe-verify  ──▶   kit/bin/vibe-verify (existing)     │
└─────────────────────────────────────────────────────────────┘
            │
            ▼
   ┌───────────────────┐
   │  kit/bin/vibe-test │  (deterministic, no AI)
   │  - lint            │
   │  - typecheck       │
   │  - unit tests      │
   │  - integration     │
   │  (Ranks 1-2; v0.1 ships 1+2 only)
   └───────────────────┘
```

Two new artifacts, both pure determinism. No new AI calls. No new servers.

## Components

### 1. `kit/bin/vibe-test` (new)

A bash script (matching the style of `vibe-verify` and `vibe-classify`) that runs the project's tests across ranks and reports status.

**Command surface:**

```bash
vibe-test                     # autodetect + run all detected ranks
vibe-test --rank=lint         # specific rank only
vibe-test --rank=typecheck
vibe-test --rank=unit
vibe-test --integration       # --rank=integration
vibe-test --json              # machine-parseable output
vibe-test --fix               # run lint --fix if available (opt-in)
```

**Rank map (v0.1):**

| Rank | Tool | Auto-detect |
|---|---|---|
| 1 lint | `ruff check` / `eslint` / `prettier --check` | package files / pyproject / config files |
| 1 typecheck | `mypy` / `tsc --noEmit` | same |
| 2 unit | `pytest` / `npm test` / `vitest run` / `jest` | same |
| 2 integration | `pytest tests/integration` / `npm run test:integration` | folder heuristics |

**Status model (mirrors `vibe-verify`):**

| Status | Meaning | Exit code |
|---|---|---|
| PASS | all detected ranks pass | 0 |
| FAIL | detected failure in any rank | 1 |
| BLOCK | runner missing or partial; needs human | 2 |
| UNVERIFIED | no test runner detected | 3 |

**Detection rules (deterministic, no AI):**

- `pyproject.toml` with `[tool.pytest]` or `pytest.ini` → pytest
- `package.json` with `scripts.test` → npm test
- `package.json` with `vitest` dep → vitest
- `package.json` with `jest` dep → jest
- `requirements.txt` / `pyproject.toml` without pytest → unittest discover
- Otherwise → UNVERIFIED with hint to install a runner

**Output format:** human-readable by default (color status, line-by-line), `--json` for pre-push hook consumption.

**Integration with `vibe-verify`:** v0.1 ships standalone. v0.2 wires it into the pre-push hook alongside `vibe-verify`.

**File layout:**

```
kit/bin/vibe-test              # main script (~300 lines, bash)
kit/bin/vibe-test-helpers.sh   # rank detection (tested; imported)
tests/vibe-test/                # bash test suite (mirrors test-spec-first)
  ├── test-detection.sh
  ├── test-exit-codes.sh
  ├── test-pytest-fixture/
  └── test-npm-fixture/
```

### 2. `kit/bin/hooks/prep-room.sh` (new)

A PreToolUse hook (matches the `matcher: "Edit|Write|MultiEdit"` style of `kit/settings.json`) that runs before each Edit/Write and surfaces context.

**What it collects:**

- `git log --oneline -5 -- <file>` → recent commits on the file
- `git diff --name-only HEAD` → files in the current unstaged diff
- Test files in the same directory or matching `test_*` / `*_test` / `*.test.*` / `*.spec.*` patterns → affected tests
- `docs/requirements/<feature>/spec.md` (if present) → Acceptance Criteria section
- Output: a small markdown block printed to stderr (Claude Code surfaces stderr to the Coder)

**Output format (printed to stderr):**

```
[prep-room] editing src/auth/login.py
[prep-room] recent commits on this file:
  a8f3c2 fix: handle empty password
  d4e1b9 feat: add OAuth callback
[prep-room] affected tests: tests/auth/test_login.py
[prep-room] relevant ACs (from docs/requirements/auth/spec.md):
  - AC1. login() returns 401 on missing credentials
  - AC3. login() rate-limits after 5 failures
```

**Hard rule:** the hook MUST complete in <500ms. If `git log` is slow, fall back to `git log --oneline -3`. The Coder is blocked waiting for the hook; slow prep-room is worse than no prep-room.

**File layout:**

```
kit/bin/hooks/prep-room.sh           # main hook
kit/bin/hooks/prep-room-collect.sh   # helper, tested separately
tests/hooks/prep-room/               # bash test suite
```

### 3. Slash command: `/vibe-test` (new)

Mirrors `/vibe-verify`. Marked description-loaded, runs `kit/bin/vibe-test` and displays results.

```
---
description: Run the project's test suite across configured ranks
---

Run `kit/bin/vibe-test` and report status. Same exit-code discipline as /vibe-verify.
```

## Data flow

### Test oracle

1. User runs `/vibe-test` (or `bash kit/bin/vibe-test` directly).
2. Script detects project stack from `pyproject.toml` / `package.json`.
3. Runs each detected rank sequentially; captures output.
4. Emits status block + exit code.
5. v0.1: standalone. v0.2: wired into the pre-push hook.

### Prep-room

1. Coder decides to edit `src/auth/login.py`.
2. Claude Code fires `PreToolUse` hook with `tool=Edit` and `tool_input.file_path=src/auth/login.py`.
3. Hook runs `prep-room.sh` with the file path as input.
4. Hook collects: recent commits, affected tests, ACs.
5. Hook prints markdown block to stderr.
6. Claude Code receives the stderr and adds it to the Coder's context.
7. Coder sees the context before editing.

This is the same hook pattern as `guard-unsafe.sh` (existing). It must be fast, silent on no-op, and exit 0 on graceful failure (the Coder shouldn't be blocked by a slow hook).

## Error handling

- **vibe-test** mirrors `vibe-verify`'s exit-code discipline. Runtime errors in rank execution → FAIL with the rank's stderr captured.
- **prep-room** is best-effort. If `git log` fails (subshell, no repo), the hook prints nothing and exits 0. The Coder is never blocked by the prep-room.
- Both tools use `set -uo pipefail` (matches `vibe-verify` / `vibe-classify` / `vibe-install`); no `set -e` and no uncaught failures. Every error path is captured and reported.

## Testing

**For `vibe-test`:**
- Unit tests for detection (mock `pyproject.toml` / `package.json` fixtures).
- Unit tests for exit codes (run against fixtures that pass/fail/missing).
- e2e: a `tests/vibe-test/test-pytest-fixture/` (passing pytest project) and `test-npm-fixture/` (passing vitest project) that the script must run end-to-end.

**For `prep-room`:**
- Unit tests for the collector (`prep-room-collect.sh` with mocked `git log`).
- e2e: a git repo fixture where the Coder's edit is preceded by the hook output. Assert the output contains the expected sections.

**Coverage target:** ≥80% of script lines exercised by the test suite. Same standard as the existing kit.

## Rollout

**v0.1 ships as one combined release.** Both layers ship together; no phased rollout.

**Sequence:**
1. Spec self-review (this doc).
2. User review of the spec.
3. `writing-plans` skill → phased implementation plan.
4. Implementation (TDD where it fits; bash tests for both).
5. Validation: extend `examples/todo-cli/` to use `vibe-test` and verify the prep-room hook fires.
6. Update README, CHANGELOG, the `tests/` suite.
7. `vibe-verify` regression — both layers must not break existing AC↔test verification.

## Out of scope (v0.1)

- Auto-generation of test categories.
- Persistent state (`.vibe-cache/`, decision journal).
- Regression detection (catching edits that undo a recent fix).
- Full ceremony-table integration.
- Test runners other than Python (pytest, unittest) and Node (npm, jest, vitest).
- Pre-push hook integration (v0.2).

## What v0.1 promises the user

- `/vibe-test` runs the project's tests across Ranks 1 (lint, typecheck) and 2 (unit, integration) and reports honest status with exit codes.
- Before each Edit/Write, the Coder sees recent commits, affected tests, and relevant Spec ACs in its context.
- The Coder becomes measurably less likely to forget what it was building and less likely to re-introduce prior bugs.
- The kit's other guarantees (Spec-first, Planner optional, vibe-verify, vibe-classify) are unchanged.

## What v0.1 does NOT promise

- Comprehensive test coverage (you write the tests; the oracle runs them).
- Bug prediction or auto-fix.
- Cross-session memory.
- Compatibility with non-Python/Node stacks beyond reporting "no runner detected."
