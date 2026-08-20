# 2026-08-20 — pre-release stabilization pass

## Scope

Audit and minimal-fix pass on the gate (`vibe-verify`), the ceremony
classifier (`vibe-classify`), the pre-push hook (`vibe-pre-push`), the
demo (`examples/todo-cli/`), and the user-facing docs (top README,
install guides, slash-command docs).

## What shipped in this session (committed)

- **README.md** — replaced phantom `./kit/bin/install-claude-code.sh` with
  the real `./kit/bin/vibe-install` (auto-detect + `--tool=<name>`).
- **install/claude-code.md** — same install-path fix; kept the manual
  alternative listed.
- **examples/todo-cli/README.md** Step 3 — `git checkout tests/test_todo.py`
  was broken (HEAD had no such file after both Step 2 commits removed it).
  Replaced with `git reset --hard HEAD~2`. Verified end-to-end: clean
  PASS → BLOCK after AC5-drop → PASS after `git reset --hard HEAD~2`.
- **kit/commands/vibe-verify.md** — added the exit-code table
  (PASS=0 / PARTIAL=2 BLOCK / FAIL=1) with explicit liftability column
  for `VIBE_SHIP_OVERRIDE=1`. The README had it; the slash-command guide
  didn't.
- **kit/commands/vibe-ship.md** — added a single line noting that
  `VIBE_SHIP_OVERRIDE=1` lifts BLOCK only, never FAIL. Closes the loop
  for users who read the ship command without the verify command.
- **CHANGELOG.md [Unreleased]** — added bullet under existing Fixed
  subsection.

## What was identified but NOT shipped

Three release blockers surfaced during the 11-scenario test matrix. They
were previously fixed in a working stash (task #67/#68/#69) that was
reverted intentionally mid-session. The blockers are real, documented
below, and **not present in the code that's about to be committed**.

### Blocker F — `VIBE_SHIP_OVERRIDE` accepts any non-empty string

`kit/bin/vibe-verify` line 539 (at HEAD `73a9693`):
```bash
local override="${VIBE_SHIP_OVERRIDE:-}"
```
and later: `[ -n "$override" ]` ⇒ truthy on any non-empty value.

Reproduction:
```bash
# BLOCK state (e.g., AC5 test dropped)
VIBE_SHIP_OVERRIDE=false kit/bin/vibe-verify   # → exit 0  (BUG: should be exit 2)
VIBE_SHIP_OVERRIDE=no     kit/bin/vibe-verify   # → exit 0  (BUG)
VIBE_SHIP_OVERRIDE=0      kit/bin/vibe-verify   # → exit 0  (BUG)
```

**Risk:** a CI script that unsets the variable or sets it to `false` to
disable the override silently ships BLOCKed code. The override contract
in the README claims it must be `1` to lift; the code doesn't enforce that.

**Fix:** tighten the check to `[ "${VIBE_SHIP_OVERRIDE:-}" = "1" ]`. Two-line change.

### Blocker G/H — `die()` exits the command-substitution subshell, not the script

`kit/bin/vibe-verify` line 48 (find_spec, called via `$(find_spec)` on line 381):
```bash
die() { echo "vibe-verify: $*" >&2; exit 2; }   # line 41
...
die "no spec found at docs/requirements/*/spec.md (run /vibe-spec first)"   # line 48
```

Reproduction:
```bash
mkdir /tmp/no-spec && cd /tmp/no-spec && git init -q
kit/bin/vibe-verify
# prints the die() message, THEN prints "verifying feature=." and proceeds
# final exit: 1  (BUG: should be exit 3 per the header's exit-code contract)
```

**Why:** `exit` in a function called inside `$(...)` exits the
command-substitution subshell, not the parent. The parent sees `$spec=""`
and falls through to the rest of the verify pipeline, which produces
"0 ACs found" → FAIL (exit 1).

**Risk:** the CONFIG-error contract (exit 3, cannot be overridden) is
silently violated. A user with a missing or broken spec gets exit 1
with a misleading "FAIL — implement the ACs" message instead of "CONFIG
error — write a spec first". `VIBE_SHIP_OVERRIDE=1` therefore has nothing
to refuse, since the script never reaches the override branch.

**Fix:** either (a) make `find_spec` return non-zero on miss and let
`main()` check `$?`, or (b) call it without command substitution and
check after. ~5-line change.

### Blocker K — `vibe-classify` missing dependency/API / CI patterns

`kit/bin/vibe-classify` line 36 (LARGE_PATTERNS at HEAD):
```
'(^|/)(migrations?/|schema|migration)/|/db/|/database/|/models?/|/repositories/|/architecture|/infrastructure|/terraform|/k8s|/kubernetes|/docker-compose|/proto/'
```

Reproduction:
```bash
mkdir /tmp/cf-large && cd /tmp/cf-large && git init -q
echo "{}" > a.json && git add a.json && git commit -q -m init
echo '{"name":"x"}' > package.json && git add package.json
kit/bin/vibe-classify
# → "tiny | reason=1 files, 1 lines"   (BUG: should be "large")
```

**Risk:** a user bumping `package.json` (new dep, dep upgrade, lockfile
regen), adding a `Dockerfile`, editing `.github/workflows/`, or touching
`*.proto` / `*.sql` / `schema.prisma` gets "tiny" and skips the spec /
plan / ADR ceremony. For migrations and DB / proto / schema files,
this can ship unreviewed schema changes. For dep manifests it skips the
license audit / registry verification step that the kit's
`kit/commands/vibe-ship.md` checklist requires.

**Fix:** add the missing patterns: `package(-lock)?.json`, `yarn.lock`,
`pnpm-lock.yaml`, `requirements*.txt`, `pyproject.toml`, `go.mod`,
`Cargo.toml`, `Gemfile`, `composer.json`, `Chart.yaml`, `helmfile.yaml`,
`Dockerfile`, `api`, `(openapi|swagger)\.`, `schema\.(prisma|graphql)$`,
`\.proto$`, `\.sql$`, `\.github/workflows/`. Single regex addition.

## What was tested (11-scenario matrix)

| # | Scenario | Expected | Got | Pass? |
|---|---|---|---|---|
| A | Clean PASS (todo-cli, all ACs met) | exit 0 | exit 0 | ✓ |
| B | AC5 test dropped (BLOCK) | exit 2 | exit 2 | ✓ |
| C | All tests `git rm` (FAIL) | exit 1 | exit 1 | ✓ |
| D | BLOCK + `VIBE_SHIP_OVERRIDE=1` | exit 0 | exit 0 | ✓ |
| E | FAIL + `VIBE_SHIP_OVERRIDE=1` (cannot lift) | exit 1 | exit 1 | ✓ |
| F | BLOCK + `VIBE_SHIP_OVERRIDE=false` | exit 2 | exit 0 | ✗ BLOCKER |
| G | CONFIG (no spec) | exit 3 | exit 1 | ✗ BLOCKER |
| H | CONFIG + `VIBE_SHIP_OVERRIDE=1` (cannot lift) | exit 3 | exit 1 | ✗ BLOCKER |
| I | Classifier: README edit | tiny | tiny | ✓ |
| J | Classifier: `src/auth/login.ts` | critical | critical | ✓ |
| K | Classifier: `package.json` | large | tiny | ✗ BLOCKER |

8 / 11 pass. The 3 failures are exactly the blockers above; none of them
are intermittent.

## Reproduction commands

```bash
# F — override accepts any non-empty string
cd /tmp/demo-test && git reset --hard <init-commit> -q
python3 -c "..." # regex-drop AC5
git add tests/test_todo.py && git commit -q -m 'B'
VIBE_SHIP_OVERRIDE=false /Users/radhikamac/vibe-kit/kit/bin/vibe-verify
echo $?  # → 0 (should be 2)

# G — die() exits subshell only
mkdir /tmp/no-spec && cd /tmp/no-spec && git init -q
/Users/radhikamac/vibe-kit/kit/bin/vibe-verify
echo $?  # → 1 (should be 3)

# K — package.json classified as tiny
mkdir /tmp/cf-large && cd /tmp/cf-large && git init -q
echo "{}" > a.json && git add a.json && git commit -q -m init
echo '{"name":"x"}' > package.json && git add package.json
/Users/radhikamac/vibe-kit/kit/bin/vibe-classify 2>&1 | grep Ceremony
# → "tiny" (should be "large")
```

## Recommendation

Do NOT ship as-is. The 3 blockers are real and easy to verify. The fix
for each is ≤ 5 lines and the tests already exist (this matrix).

If the kit is being shipped at all (early public release), the safer
path is: apply the three minimal fixes, re-run scenarios F / G / K to
confirm 11 / 11, then commit and push. The previous fix-pass in this
session (tasks #67/#68/#69) covered exactly these and the verification
ran clean; it was reverted mid-session — possibly because the user
wanted only the docs/install-path changes shipped, possibly because the
revert was scoped to the hook alone and the verify/classifier fixes
came along as collateral.

Either way: the gate is currently less safe than its docs claim.

## What this session did NOT touch

- No schema changes
- No new dependencies
- No edits to `/auth` / `/billing` / `/security` / `/migrations`
- No edits to `docs/SPEC.md` non-goals
- No TypeScript `any`
- No disabled lint rules
- No hardcoded secrets, tokens, URLs, or env-specific values
- No force-push, no `rm -rf` against real trees (the PreToolUse guard
  blocked a `rm -rf /tmp/demo-final` mid-session as expected)
- Did not push to remote — commit is local on branch
  `verify-as-real-gate-plus-classifier`, ready for review

## Next session

If picking up the blockers: start by reading `kit/bin/vibe-verify`
around line 41 (die), line 381 (find_spec call), and line 539 (override
check); and `kit/bin/vibe-classify` line 36 (LARGE_PATTERNS). Each fix
is independently testable.