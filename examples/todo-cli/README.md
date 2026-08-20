# See it in action — todo-cli demo

This is a runnable demo of the vibe-kit workflow: **Spec → Code → Verify → Ship**.
It is intentionally small (a single-user todo CLI, no external deps) so you
can run it end-to-end in under a minute and see exactly what each step does.

## What you'll see

1. The Spec the Planner wrote from a one-line intent.
2. The implementation the Coder wrote against that Spec.
3. The verify output — including a deliberately missing acceptance criterion that **fails the gate**.
4. The fix.
5. A clean re-verify.
6. A simulated ship gate.

## Files

```
examples/todo-cli/
├── docs/requirements/todo-cli/spec.md    ← the Spec (input to Coder)
├── src/todo.py                            ← implementation
└── tests/test_todo.py                     ← one test per AC
```

## Step 0 — Run the tests (they should all pass)

```bash
cd examples/todo-cli
python3 -m unittest discover -s tests -p test_todo.py
```

```
......
----------------------------------------------------------------------
Ran 6 tests in 0.275s

OK
```

## Step 1 — Run the Spec against the implementation

The Spec is at `docs/requirements/todo-cli/spec.md`. The verifier reads it
and checks each Acceptance Criterion.

```bash
cd examples/todo-cli
../../kit/bin/vibe-verify
```

```
verifying feature=todo-cli
spec=docs/requirements/todo-cli/spec.md

## Acceptance criteria
  ✓  PASS        AC1. add "buy milk" creates a todo with id 1
  ✓  PASS        AC2. list prints open todos, format ID<TAB>TEXT
  ✓  PASS        AC3. done 1 marks todo complete
  ✓  PASS        AC4. rm 1 deletes the todo
  ✓  PASS        AC5. unknown subcommand prints usage and exits 1
  ✓  PASS        AC6. persistence: todos added in one invocation appear in the next

summary: 6/6 ACs PASS

## Non-Goals
  ✓  not implemented: Multi-user / sync / cloud
  ✓  not implemented: Due dates, priorities, tags
  ✓  not implemented: Shell completion
  ✓  not implemented: Colored output

## Constraints
  ✓ migrations: not edited (or spec declares strategy)
  ✓ dependencies: no manifest change

test runner: (none detected — package.json / pyproject.toml / go.mod / Cargo.toml)
  → tests not run; verify manually before ship

overall: PASS
  exit: 0 (ship-ready)
```

Exit code: **0** — ready to ship.

## Step 2 — Deliberately introduce a missing AC

This is what happens when a Coder skips an Acceptance Criterion.
We delete the test for AC5 (unknown subcommand) and re-run verify.

```bash
cd examples/todo-cli
python3 -c "
import re
with open('tests/test_todo.py') as f: s = f.read()
s = re.sub(r'\n    def test_AC5_unknown_subcommand.*?(?=\n\n)', '\n\n', s, flags=re.S)
with open('tests/test_todo.py','w') as f: f.write(s)
"
git add tests/test_todo.py
git commit -m 'demo: drop AC5 test'
../../kit/bin/vibe-verify
echo "exit=$?"
```

```
## Acceptance criteria
  ✓  PASS        AC1. add "buy milk" creates a todo with id 1
  ✓  PASS        AC2. list prints open todos, format ID<TAB>TEXT
  ✓  PASS        AC3. done 1 marks todo complete
  ⚠  PARTIAL     AC4. rm 1 deletes the todo permanently
  ⚠  PARTIAL     AC5. Unknown subcommand prints help text and exits 1
  ⚠  PARTIAL     AC6. Persistence: todos added in one invocation appear in the next

summary: 3/6 ACs PASS  ·  3 PARTIAL  ·  0 UNVERIFIED  ·  0 FAIL

overall: BLOCK
  review: PARTIAL items need a test or stronger evidence
  exit: 2 (blocks ship; set VIBE_SHIP_OVERRIDE=1 with documented reason to proceed)
```

Exit code: **2** — refused to ship (BLOCK).

Why BLOCK and not FAIL? vibe-verify is diff-based: it sees that the file
`tests/test_todo.py` was modified, and the surrounding context still
contains AC keywords (`todo` appears in `class TodoCliTests`). So AC1
and AC2 (whose keywords aren't touched) still PASS, and the affected
ACs drop to PARTIAL — "weaker evidence than before". That's a ship gate
non-zero, but it's a softer signal than a hard FAIL.

A hard FAIL fires when **no file in the diff contains any AC keyword**
(typically: a fresh commit with no implementation, or the spec is
completely missing the evidence). To trigger a hard FAIL, delete the
test file entirely:

```bash
cd examples/todo-cli
git rm tests/test_todo.py
git commit -m 'demo: drop all tests'
../../kit/bin/vibe-verify
echo "exit=$?"
```

```
summary: 0/6 ACs PASS  ·  0 PARTIAL  ·  0 UNVERIFIED  ·  6 FAIL

overall: FAIL
  exit: 1 (blocks ship; VIBE_SHIP_OVERRIDE cannot lift FAIL)
```

Exit code: **1** — refused to ship (FAIL, no override possible).

**The Spec said every AC must have evidence. The Coder wiped the test
file. vibe-verify caught it.**

## Step 3 — Fix it

Restore the tests:

```bash
cd examples/todo-cli
git checkout tests/test_todo.py
git commit --amend --no-edit
../../kit/bin/vibe-verify
echo "exit=$?"
```

```
overall: PASS
  exit: 0 (ship-ready)
```

Exit code: **0** — ship-ready.

## Step 4 — Ship gate (the boundary the kit provides)

The kit ships a pre-push hook that runs vibe-verify before every push.
Install it once:

```bash
cd /path/to/your/repo
cp kit/bin/hooks/vibe-pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

Now:

```bash
git push
# vibe-pre-push: running vibe-verify...
# overall: PASS
# vibe-pre-push: PASS — pushing.
```

If you push a broken change:

```bash
git push
# vibe-pre-push: FAIL — refusing push.
#   fix: implement missing ACs, repair tests, or correct the constraint violation.
#   override: FAIL cannot be overridden; fix and re-push.
```

The push is blocked. The hook is a gate, not a jail — `git push --no-verify`
skips it (documented in `kit/bin/hooks/vibe-pre-push`). And
`VIBE_SHIP_OVERRIDE=1 git push` lifts PARTIAL/UNVERIFIED but never FAIL.

## What this proves

The Spec is now an enforceable boundary:

- The Planner writes intent into `spec.md`.
- The Coder implements against `spec.md`.
- `vibe-verify` checks the diff against `spec.md`.
- The pre-push hook refuses to push a failing verify.

The Spec is still markdown — markdown cannot *enforce* anything on its own.
But the **verify + ship** boundary makes the Spec matter at the moment it
counts: when code is about to leave your machine.
