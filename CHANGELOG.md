# Changelog

All notable changes to **vibe-kit** itself are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

### Added — Smart Vibe Coder (v0.1)
The kit now ships two deterministic runtime layers: a **test oracle** that runs the project's tests across configured ranks with honest exit codes, and a **prep-room** PreToolUse hook that surfaces relevant context (recent commits, affected tests, Spec ACs) into the Coder's view before each Edit/Write. Both layers are pure determinism, no AI calls. See `docs/superpowers/specs/2026-08-21-smart-vibe-coder-design.md`.

- **`kit/bin/vibe-test`** — deterministic test runner. Auto-detects Python (`pytest`, `unittest`) and Node (`npm test`, `vitest`, `jest`). Ranks: `lint` (ruff/eslint/prettier), `typecheck` (mypy/tsc), `unit`, `integration`. Exit codes mirror `vibe-verify`: PASS=0, FAIL=1 (uncatchable), BLOCK=2 (liftable with `VIBE_SHIP_OVERRIDE=1`), UNVERIFIED=3 (no runner detected). `--json` for CI consumption, `--rank=<name>` for filtering, `--fix` to auto-fix lint.
- **`kit/bin/hooks/prep-room.sh`** — PreToolUse hook for `Edit|Write|MultiEdit`. Reads the JSON tool_input from stdin, looks up the file's recent commits (`git log --oneline -3`), affected tests (same dir + parallel `tests/<leaf>/` + mirror `tests/<stem>/`), and the relevant feature's Spec ACs (`docs/requirements/<feature>/spec.md`). Output goes to stdout; Claude Code surfaces it to the Coder as additional context. Hard rule: <500ms per run. Silent on no-op. Exits 0 always (the Coder is never blocked).
- **`kit/commands/vibe-test.md`** — `/vibe-test` slash command. Same shape as `/vibe-verify`: when/what/usage/limits.
- **Settings wiring** — `kit/settings.json` and `kit/bin/vibe-init`'s `.claude/settings.json` render now declare the prep-room hook for `Edit|Write|MultiEdit`. `vibe-install` copies `prep-room.sh` along with the other hooks.
- **`tests/vibe-test/test-vibe-test.sh`** — 10 assertions. Covers all four exit codes (PASS / FAIL / BLOCK / UNVERIFIED), `--json` shape, `--rank` filter, `--help` banner. Self-contained; builds fixtures in `mktemp -d` and cleans on EXIT.
- **`tests/hooks/test-prep-room.sh`** — 21 assertions. Covers full fixture (commits + tests + ACs all surface), new-file fallback (no commits), no-spec fallback (silent on ACs), no-git graceful fallback, empty-stdin silent exit, CLI arg fallback for testing, perf (<500ms hard limit), and settings.json wiring.

### Fixed — prep-room SIGPIPE under `set -o pipefail`
The first cut of `prep-room.sh` was silent on real fixtures. Two pipelines tripped on `set -o pipefail`:
1. `git log | grep -q .` — `grep -q` exits with SIGPIPE (rc=141) once it finds its first match, but `git log` keeps writing; pipefail promotes that to a non-zero pipeline rc and the `if` silently evaluates FALSE.
2. `awk | grep | head` — same trap. `head` SIGPIPEs the upstream on the 9th line.

Both pipelines were rewritten to capture first, then trim: `RECENT="$(git log ...)"` and `ACS="$(awk ... | grep ...)"` followed by a single `head`/`sed` on the variable. Also replaced BWK awk's `/start/,/end/` range pattern with a flag pattern — on macOS the range pattern stops at the start line and silently drops every AC line if the end pattern never appears in the file. Plus widened the test-search to also check the parallel `tests/<leaf>/` directory (more realistic — tests rarely live next to source) and added de-duplication so overlapping search roots don't surface the same file twice.

### Fixed — runtime propagation of the Spec-first gate
- **`kit/CLAUDE.md`** — added a "Spec-first gate (run at every task start)" section before Pre-flight. This file is copied verbatim to every project's `AGENTS.md` by `vibe-install:223` and to the global `~/.claude/CLAUDE.md` by `vibe-install:156`. The new section points at `kit/templates/spec-first-gate.md` as the canonical decision tree and summarizes the 3-step gate (trivial→proceed; awaiting-approval→halt; otherwise→Discovery then write Spec with `Status: awaiting-approval`). **Approval boundary preserved.**
- **`kit/bin/vibe-init` `render("CLAUDE.md")`** — added a one-line Spec-first gate pointer to the inline string that generates project `CLAUDE.md`. References `prompts/00-anchor.md § Discovery protocol` and `kit/templates/spec-first-gate.md`. Does NOT duplicate the full decision tree; the inline string stays terse.
- **`tests/spec-first/test-spec-first-gate.sh`** — new section 7: runs `vibe-install --tool=claude-code --root=$TMP` into a fresh temp dir with a `HOME` override (so the in-repo `kit/bin/vibe-init` is exercised, not a stale global copy). Asserts the resulting `CLAUDE.md` and `AGENTS.md` both contain the gate AND reference the canonical `kit/templates/spec-first-gate.md`. This catches future propagation regressions.

### Changed
- **`README.md`** "The pain" example swapped from a "profile photo upload" over-engineering story to an "account deletion" intent-mismatch story. The new example shows the AI doing the literal-correct thing (`DELETE FROM users WHERE id=?`) and missing every spec-worthy question (grace period, audit log, GDPR erasure-vs-anonymization). Unwinding cost is concrete (GDPR exposure + a migration). The previous example's parade of buzzwords ("4 image variants, mobile-first, EXIF-stripped, idempotent, rate-limited") conflated over-engineering with intent-mismatch and didn't model the actual failure mode vibe-kit solves.

## [Unreleased] (previous)

### Added — Spec-first gate, Planner optional
- **`kit/templates/spec-first-gate.md`** — canonical decision tree the Coder runs at every task start. Trivial work proceeds; in-progress Specs are resumed; awaiting-approval Specs halt (user must flip `Status: in-progress`); no applicable Spec on non-trivial work → Coder enters DISCOVERY MODE (single source of truth: `prompts/00-anchor.md` § Discovery protocol), writes `docs/requirements/<feature>/spec.md` from `kit/templates/requirements-spec.md`, and **stops for approval** before any code is touched.
- **Planner is now optional.** The Coder can run Discovery itself when no Spec exists. Both entry points (Planner or Coder) produce the same Spec structure and the same `Status` discipline. The ship gate (`vibe-verify` + `/vibe-ship`) is unchanged and doesn't care which path produced the Spec.
- **`tests/spec-first/test-spec-first-gate.sh`** — 46 assertions covering wiring (every installer references the gate), gate content (decision tree coverage), contradictory-wording removal, Spec/plan template invariance, vibe-verify and vibe-classify untouched, and 10-scenario gate simulation (no Spec + large → discover, awaiting-approval → halt, in-progress → resume, tiny → no Discovery, milestone scope only → no Discovery, draft (interrupted Discovery) → re-discover & halt, etc.).

### Changed
- **All 6 per-tool installers** (`kit/installers/{claude-code,generic,codex,cursor,antigravity,aider}/*`) — added a "Spec-first gate" section before the "Two-role model" section. "User bridges Planner → Coder" language softened to "user is the human-approval gate". The Coder-side line now reads "if no applicable Spec exists, runs Discovery itself".
- **`skills/vibe-kit/SKILL.md`** — tagline rewritten from "Two roles. One spec." to "Spec-first. Planner optional. One workflow, two entry points." Removed the contradictory "I do not write code. I'm a Planner." line and replaced it with a role-aware statement (Planner-role vs Coder-role behavior).
- **`kit/templates/CLAUDE.md`** and **`kit/templates/AGENTS.md`** — gained a "Spec-first gate" boundary section. AGENTS.md's `Always` block adds "Run the spec-first gate at every task start: no Spec, no code (unless trivial)".
- **`README.md`** — new "Spec-first. Planner optional." subsection under "The workflow". "Two roles, one Spec" retitled to "Two entry points, one Spec". "User is the bridge" softened to "user is the human-approval gate".
- **`docs/architecture.md`** — "Why two roles" retitled to "Why the Spec is the contract". "Conflating the two is the most common failure mode" reframed to "Conflating 'Spec' with 'Planner' is the most common failure mode". Added "When one tool plays both jobs" section describing the Coder-as-discoverer flow.
- **`docs/playbook.md`** — section 3 retitled "Spec-first workflow (the headline)"; Planner marked optional.
- **`docs/requirements-gathering.md`** — Step 4 acknowledges the Coder-as-discoverer path; same approval boundary holds.
- **`prompts/README.md`** — "When one AI is doing both roles" retitled to "When one tool plays both jobs" with the spec-first gate as the answer.
- **`install/cursor.md`** and **`install/README.md`** — softened Planner-side / Coder-side wording.

### Added — verify as a real gate + adaptive ceremony
- **`kit/bin/vibe-verify`** — evidence-based AC verification. Each AC can carry a `Verification:` block with `automated test: <path::testname>` and `expected behavior: <text>`. The verifier checks: (a) test path is in the diff (excludes DELETED files so `git rm tests/` produces a hard FAIL), (b) `def <name>` appears in the file's diff (added or unchanged), (c) the detected test runner runs and tests pass. Falls back to keyword matching when no Verification block is given. Status model: PASS / PARTIAL / UNVERIFIED / FAIL with truthful exit codes (0 / 2 / 2 / 1). `VIBE_SHIP_OVERRIDE=1` lifts BLOCK but never FAIL.
- **`kit/bin/vibe-classify`** — deterministic ceremony classifier. Reads `git status` / `diff`, returns tiny | normal | large | critical based on diff size + sensitive-path patterns (`/auth/`, `/billing/`, `/secrets/`, migrations). Conservative defaults: when in doubt it recommends the heavier ceremony. Outputs both human-readable and machine-parseable one-liner.
- **`kit/bin/hooks/vibe-pre-push`** — opt-in pre-push hook. Runs `vibe-verify` before every `git push`; refuses the push on non-zero exit. `git push --no-verify` skips it (documented escape hatch). `VIBE_SHIP_OVERRIDE=1` lifts BLOCK but not FAIL.
- **`examples/todo-cli/`** — runnable demo. Single-user Python CLI; spec.md with 6 ACs each carrying a Verification block; `src/todo.py` + `tests/test_todo.py`; README walkthrough showing PASS → BLOCK → fix → PASS, plus the hard-FAIL scenario (delete the test file entirely).
- **`kit/templates/requirements-spec.md`** — Acceptance Criteria section now shows the per-AC `Verification:` block format with `automated test:` and `expected behavior:` fields, plus the `*(human-judged)*` syntax for ACs that explicitly need human review.
- **`examples/planner-output-spec.md`** — every AC rewritten with its own `Verification:` block. Demonstrates how a Planner fills in test paths during the spec-writing session, before the Coder touches code.

### Changed
- **README.md** rewritten. Lead now reads *"If this is a 3-line bug fix, you don't need vibe-kit."* New pain framing ("the AI built what I asked for, but not what I meant"), primary workflow `Spec → Code → Verify → Ship`, honest "What this kit does NOT do" section (markdown doesn't self-enforce; verify is evidence, not proof; the user is the bridge). Templates section documents the SPEC.md (milestone) vs requirements-spec.md (per-feature) lifecycle split.
- **`kit/bin/vibe-verify`** — exit codes are now a real gate. PASS=0, FAIL=1 (cannot be overridden), BLOCK=2 (liftable with `VIBE_SHIP_OVERRIDE=1`), config error=3. The pre-push hook refuses on BLOCK and FAIL.
- **`kit/bin/vibe-verify`** — Python unittest detection added. If no `pyproject.toml` is present but `tests/test_*.py` exists, runs `python3 -m unittest discover`. Override with `VIBE_VERIFY_RUNNER`.
- **`kit/commands/vibe-ship.md`** — fixed BLOCK → FAIL reference.

### Fixed
- **`kit/bin/vibe-verify`** AC record parsing — bash strings can't hold NUL bytes, and BWK awk on macOS silently drops `\0` in `printf` format strings. Switched the per-AC record separator from NUL to SOH (`\1`, 0x01) which BWK awk emits correctly and bash reads with `read -d $'\001'`.
- **`kit/bin/vibe-verify`** duplicate `classify()` function: an older 2-arg version survived a previous rewrite; bash used whichever was defined last, so the per-AC verification path was silently ignored. Removed the stale duplicate.
- **`kit/bin/vibe-verify`** sed whitespace stripping: `sed -E 's/\s+$//'` was interpreted by BSD sed as `s/s+$//`, silently stripping trailing `s` characters from test names like `test_AC4_rm_deletes` → `test_AC4_rm_delete`. Fixed to POSIX `[[:space:]]` character class.
- **`kit/bin/vibe-verify`** deletion handling: deleted test files were treated as "still in the diff" (PARTIAL on all ACs) rather than "evidence removed" (FAIL). Added `--diff-filter=ACMR` so a `git rm tests/test_*.py` produces the hard FAIL the demo README promises.
- **`kit/bin/vibe-verify`** evidence counting: only `+` lines (added) were counted as test definitions. `-` lines (removed tests) were also matching because the grep didn't anchor on the diff prefix. Fixed to anchor on `^\+` AND context lines (` ` prefix), so deletions correctly produce PARTIAL and unchanged tests still produce PASS.
- **`README.md`** + **`install/claude-code.md`** referenced the non-existent `./kit/bin/install-claude-code.sh`. Replaced with the real `./kit/bin/vibe-install` (auto-detects tool; `--tool=claude-code` overrides).
- **`examples/todo-cli/README.md`** Step 3 used `git checkout tests/test_todo.py`, which fails when HEAD no longer contains the file (both Step 2 commits removed it). Replaced with `git reset --hard HEAD~2`, which rolls both Step 2 commits back to the original init.
- **`kit/commands/vibe-verify.md`** did not document the gate's exit-code table. Added the PASS=0 / PARTIAL=2 (BLOCK) / FAIL=1 table with explicit `VIBE_SHIP_OVERRIDE=1` liftability column.
- **`kit/commands/vibe-ship.md`** did not mention the `VIBE_SHIP_OVERRIDE=1` escape hatch. Added a single line clarifying that the override lifts BLOCK only, never FAIL.

## [0.3.1] - 2026-08-20

## [0.3.1] - 2026-08-20
### Fixed
- **Stop hook prompt-error loop eliminated.** The kit's `Stop` hook previously combined a `command`-type and a `prompt`-type hook. The prompt fired the assistant every Stop, asking it to fill in a stub the script had just written. When the script throttled (the common case after the first write), the assistant had no stub to fill, but the prompt kept firing — producing a visible "Stop hook error" at every turn. The fix:
  1. Removed the `prompt`-type `Stop` hook from `kit/settings.json` and from `kit/bin/vibe-init`'s render.
  2. Made `session-end-handoff.sh` self-filling. It now writes a 2k+ handoff with what the shell can determine: branch + dirty/clean + ahead/behind, recent commits (last 4h), files touched (current dirty tree), recent commits matching `gotcha|trap|fix|bug`, and the appropriate `unknown — left for next session` for fields the shell can't determine (Decisions, In progress, Blocked, Next steps).
  3. The script is now silent on throttle (no stderr, exit 0). The previous version printed "throttled" on stderr, which the prompt's "if it printed throttled, do nothing" check tried to interpret — but the prompt no longer exists.
- **vibe-verify AC false-positive protection**: scripts no longer match ACs against the filename-only diff (case where "upload" matches upload.ts but the file is empty). Already shipped in v0.3.0; mentioned here because the previous behavior was a known-false signal.

### Changed
- `kit/bin/hooks/session-end-handoff.sh`: rewritten. ~150 lines → ~190 lines. Self-filling. Silent on throttle.
- `kit/settings.json` and `kit/bin/vibe-init` `render()`: `Stop` hook is now a single `command`-type entry.

## [0.3.0] - 2026-08-20
### Added
- **Per-tool auto-detection + unified installer**: `kit/bin/vibe-install` detects Claude Code / Cursor / Antigravity / Aider / Codex / generic from env vars and cwd files, then drops the right rules + commands + conventions file. No flag needed.
- **Per-tool skill packs** under `kit/installers/<tool>/`:
  - `claude-code/` — Skill bundle + global-install README
  - `cursor/` — `.cursorrules` + project-scoped rules
  - `aider/` — `CONVENTIONS.md` + `.aider.conf.yml`
  - `antigravity/` — Claude Code-compatible layout
  - `codex/` — `AGENTS.md` for OpenAI Codex CLI
  - `generic/` — fallback for any tool that reads `AGENTS.md`
- **vibe-detect-tool** (`kit/bin/vibe-detect-tool`): bash auto-detection with print-once parseable output (`<tool> | <install-form> | <config-dir>`).
- **vibe-init --add / --tool=auto**: non-destructive add mode + detection-on-init. Existing-project install path skips files that exist.
- **Dev-repo templates path**: when `kit/bin/vibe-init` runs from the cloned repo, it prefers in-repo `templates/` over the global install — so edits take effect immediately.
- **install/README.md** rewritten: leads with the auto-detect + `./vibe-install` flow, then details per-tool markers.

### Changed
- `README.md` lead install section now uses `vibe-install` (auto-detect) instead of per-tool pointers.
- `install/cursor.md` and `install/aider.md` updated with embedded templates (`.cursorrules`, `.aider.conf.yml`) and step-by-step copy commands.

## [0.2.0] - 2026-08-20
### Added
- **Real AC↔test contract checker** (`kit/bin/vibe-verify`): reads the most recent `docs/requirements/<feature>/spec.md`, extracts ACs, matches each AC keyword against the git diff, runs the detected test runner, prints a structured PASS/BLOCK report.
- **8 real slash commands** (`kit/commands/vibe-{spec,plan,verify,ship,handoff,decide,review-pr,init}.md`): each follows the same shape (description / what / when / usage / output / limits).
- **Ceremony levels** (`docs/ceremony-levels.md`): tiny / normal / large / critical — picks the right intensity for the change.
- **Discovery protocol** in `prompts/00-anchor.md`: Socratic one-question-at-a-time intake. Planner queries vibe coder ~1%, vibe coder's spec carries the rest.
- **Handoff throttle**: `kit/bin/hooks/session-end-handoff.sh` skips writes if a marker was touched within `VIBE_HANDOFF_THROTTLE` seconds (default 600).
- **Human-approval gate** in `prompts/06-handoff-to-coder.md` and `kit/templates/requirements-spec.md`: spec status flow `draft → awaiting-approval → in-progress → shipped`.

### Changed
- `README.md` lead reframed from "two roles, one spec" to "persistent contract for AI coding" — `vibe-kit gives coding agents a SPEC they must implement against, and verifies they did`.

## [0.1.0] - 2026-08-20
### Added
- Initial release: kit, prompts, templates, hooks, slash commands, examples.
