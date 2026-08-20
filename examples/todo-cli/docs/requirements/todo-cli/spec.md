# Feature: todo-cli

Status: in-progress
Owner: @radhika
Last updated: 2026-08-20
Linked milestone: vibe-kit demo

> The Spec is the durable source of product intent.
> vibe-verify checks the code against this Spec; it does not prove
> correctness. Mutation testing (rank 4) is still required for
> production code.

## Human approval

- [x] User has read the spec end-to-end
- [x] User has set `Status: in-progress`
- [x] User has explicitly said "approved"

## Goal

A single-user CLI todo list, persisted to a local JSON file. No server,
no accounts, no sync. The simplest thing that lets you capture a thought
and check it off.

This demo exists to show the full Spec → Code → Verify → Ship flow,
including how `vibe-verify` catches a missing acceptance criterion.

## User Stories

- As a **busy person**, I want to **add a todo from the command line**, so that **I can capture a thought without leaving the terminal**.
- As a **busy person**, I want to **list open todos**, so that **I can see what's still on my plate**.
- As a **busy person**, I want to **mark a todo done**, so that **I can track progress without deleting the history**.

## Requirements

### Functional

- `todo add <text>` — append a todo; assigns a sequential integer ID.
- `todo list` — print all open todos (one per line: `ID  TEXT`).
- `todo done <id>` — mark todo complete (no longer appears in `list`).
- `todo rm <id>` — delete todo permanently.
- Todos are persisted to `./todos.json` in the working directory.
- All commands exit 0 on success; non-zero on user error with a message on stderr.

### API contract

- Storage: `./todos.json`, JSON array of `{id, text, done, created_at}`.
- Exit codes:
  - 0 success
  - 1 unknown subcommand
  - 2 missing argument
  - 3 unknown todo id

### Non-functional

| Category | Requirement | Target | Check |
|---|---|---|---|
| Deps | Standard library only | 0 external deps | `pip check` |
| Perf | Add 1000 todos | < 1s | manual |

## Acceptance Criteria

- [ ] **AC1.** `todo add "buy milk"` creates a todo with id 1, text "buy milk", done=false.
  - Verification:
    - automated test: `tests/test_todo.py::test_AC1_add_creates_todo`
    - expected behavior: returns id 1, todo appears in list
- [ ] **AC2.** `todo list` prints open todos only, one per line, format `ID<TAB>TEXT`.
  - Verification:
    - automated test: `tests/test_todo.py::test_AC2_list_shows_open_only`
    - expected behavior: completed todos are excluded
- [ ] **AC3.** `todo done 1` marks todo 1 complete; it no longer appears in `list`.
  - Verification:
    - automated test: `tests/test_todo.py::test_AC3_done_marks_complete`
    - expected behavior: todo is hidden from subsequent `list` calls
- [ ] **AC4.** `todo rm 1` deletes todo 1 permanently.
  - Verification:
    - automated test: `tests/test_todo.py::test_AC4_rm_deletes`
    - expected behavior: `list` does not include it; `done 1` returns exit 3
- [ ] **AC5.** Unknown subcommand prints help text and exits 1.
  - Verification:
    - automated test: `tests/test_todo.py::test_AC5_unknown_subcommand`
    - expected behavior: stderr contains "usage:"; exit code is 1
- [ ] **AC6.** Persistence: todos added in one invocation appear in the next.
  - Verification:
    - automated test: `tests/test_todo.py::test_AC6_persistence_across_invocations`
    - expected behavior: subprocess calls share the same todos.json

## Constraints

### Hard constraints

- Standard library only (no `pip install`).
- No external CLI framework (no `click`, no `argparse` is fine if you want it).
- All commands read/write `./todos.json` relative to cwd.
- Exit codes as documented above.

### AI-authored surface area

AI may write (with review):
- [x] The CLI dispatch + command handlers.
- [x] The JSON persistence.
- [x] The test suite.

Human must author (AI may assist):
- [ ] (none — this is a demo)

## Edge Cases

### Mandatory 11 (selected, since this is a CLI)

- Empty input: `todo add ""` rejected with exit 2.
- Missing argument: `todo add` (no text) → exit 2.
- Unknown id: `todo done 999` → exit 3.
- Corrupt JSON file: treated as empty list, with stderr warning.
- Concurrent writes: not handled (single-user CLI; out of scope).
- Non-ASCII: UTF-8 strings accepted, preserved verbatim.

## Non-Goals

- Multi-user / sync / cloud.
- Due dates, priorities, tags.
- Shell completion.
- Colored output.

## Technical Decisions

- **JSON file, not SQLite**: simpler, no native deps, fine for hundreds of todos.
- **No `argparse`**: keeps the demo minimal; uses `sys.argv` directly.
- **One-file CLI**: `src/todo.py` is both library and entrypoint.

## Verification

### Plan

- Commands: `python -m unittest tests` (all ACs covered by tests).
- Manual: run `python src/todo.py list` and visually confirm.
- `vibe-verify` after implementation.

### Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | JSON file corruption on partial write | low | medium | Atomic write (write to .tmp, rename) |
| R2 | Race condition if user runs two `todo add` in parallel | low | low | Out of scope for single-user CLI |
