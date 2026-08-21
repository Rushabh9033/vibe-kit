#!/usr/bin/env bash
# tests/weapons/test-weapons.sh
#
# Verifies the Smart Vibe Coder weapon suite + vibe-arm bundle.
#
# Coverage:
#   - vibe-edit-gate    blocks without AC, allows with AC
#   - vibe-tdd-gate     blocks src/ edit without test, allows after test edit
#   - vibe-ac-progress  surfaces [vibe-ac] <done>/<total>
#   - vibe-fix-detector blocks edits to files touched by recent fix: commits
#   - vibe-spec-intake  writes docs/requirements/<slug>/spec.md awaiting-approval
#   - vibe-claim-check  runs vibe-test + per-AC evidence check
#   - vibe-arm / --disarm writes/removes the .vibe-cache/armed marker +
#                     wires/unwires the hooks into .claude/settings.json

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ARM="$KIT_ROOT/kit/bin/vibe-arm"
HOOKS="$KIT_ROOT/kit/bin/hooks"
INTAKE="$KIT_ROOT/kit/bin/vibe-spec-intake"
CLAIM="$KIT_ROOT/kit/bin/vibe-claim-check"
PASS=0
FAIL=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
hdr()  { printf '\n\033[1m%s\033[0m\n' "$1"; }

TMPDIR_BASE="$(mktemp -d -t vibe-weapons-tests.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Build a fixture with: git repo, src/, tests/, spec.md with ACs.
build_full() {
  local d="$TMPDIR_BASE/full-$$-$RANDOM"
  mkdir -p "$d/src/auth" "$d/tests/auth" "$d/docs/requirements/auth"
  (
    cd "$d"
    git init -q
    git config user.email t@t
    git config user.name t
    printf 'def login(): pass\n' > src/auth/login.py
    git add -A && git commit -q -m "init" >/dev/null
    printf 'def test_login(): pass\n' > tests/auth/test_login.py
    git add -A && git commit -q -m "add test" >/dev/null
    cat > docs/requirements/auth/spec.md <<'EOF'
# Auth
## Acceptance Criteria
- AC1. login() returns 401 on missing creds
  Verification:
    automated test: tests/auth/test_login.py::test_login
- AC2. login() rate-limits after 5 failures
  Verification:
    automated test: tests/auth/test_login.py::test_rate_limit
EOF
    git add -A && git commit -q -m "add spec" >/dev/null
  )
  printf '%s' "$d"
}

# helper: run hook with stdin JSON, write rc+stderr to globals via /tmp files.
# (Subshells don't propagate variables in bash, so we use temp files.)
RC_FILE="$TMPDIR_BASE/.rc"
STDERR_FILE="$TMPDIR_BASE/.stderr"

run_hook_capture() {
  # run_hook_capture <hook> <file_path> [stdin_json]
  local hook="$1" fp="$2" json="${3:-}"
  : > "$RC_FILE"
  : > "$STDERR_FILE"
  if [ -n "$json" ]; then
    printf '%s' "$json" | bash "$hook" >/dev/null 2>"$STDERR_FILE"
  else
    printf '{"tool_input":{"file_path":"%s"}}' "$fp" | bash "$hook" >/dev/null 2>"$STDERR_FILE"
  fi
  echo $? > "$RC_FILE"
}

assert_rc() {
  local got
  got="$(cat "$RC_FILE" 2>/dev/null || echo unset)"
  if [ "$got" = "$1" ]; then
    ok "$2"
  else
    fail "$2 — got rc=$got, want $1"
  fi
}

assert_stderr_contains() {
  if grep -qF -- "$1" "$STDERR_FILE" 2>/dev/null; then
    ok "$2"
  else
    fail "$2 — stderr missing '$1'"
  fi
}

# ---------- [1] vibe-arm / --disarm ----------

hdr "[1] vibe-arm writes marker + wires hooks"
d="$(build_full)"
(
  cd "$d"
  bash "$ARM" >/dev/null 2>&1
)
[ -f "$d/.vibe-cache/armed" ] && ok ".vibe-cache/armed marker created" || fail ".vibe-cache/armed not created"
[ -f "$d/.claude/settings.json" ] && ok ".claude/settings.json written" || fail ".claude/settings.json not written"
if grep -q "vibe-edit-gate" "$d/.claude/settings.json"; then
  ok "settings.json references vibe-edit-gate"
else
  fail "settings.json missing vibe-edit-gate"
fi
if grep -q "vibe-tdd-gate" "$d/.claude/settings.json"; then
  ok "settings.json references vibe-tdd-gate"
else
  fail "settings.json missing vibe-tdd-gate"
fi
if grep -q "vibe-fix-detector" "$d/.claude/settings.json"; then
  ok "settings.json references vibe-fix-detector"
else
  fail "settings.json missing vibe-fix-detector"
fi
if grep -q "vibe-ac-progress" "$d/.claude/settings.json"; then
  ok "settings.json references vibe-ac-progress"
else
  fail "settings.json missing vibe-ac-progress"
fi

hdr "[2] vibe-arm --disarm removes marker + unwires hooks"
(
  cd "$d"
  bash "$ARM" --disarm >/dev/null 2>&1
)
[ ! -f "$d/.vibe-cache/armed" ] && ok "armed marker removed" || fail "armed marker still present"
if ! grep -q "vibe-edit-gate" "$d/.claude/settings.json"; then
  ok "settings.json no longer references vibe-edit-gate"
else
  fail "settings.json still has vibe-edit-gate after disarm"
fi

hdr "[3] vibe-arm is idempotent"
(
  cd "$d"
  bash "$ARM" >/dev/null 2>&1
  bash "$ARM" >/dev/null 2>&1
)
count=$(grep -c "vibe-edit-gate" "$d/.claude/settings.json" 2>/dev/null || echo 0)
if [ "$count" -eq 1 ]; then
  ok "second arm did not duplicate hook entries (count=1)"
else
  fail "second arm duplicated entries (count=$count)"
fi

# ---------- [4] vibe-edit-gate ----------

hdr "[4] vibe-edit-gate — blocks without AC, allows with AC"
(
  cd "$d"
  run_hook_capture "$HOOKS/vibe-edit-gate.sh" "src/auth/login.py"
)
assert_rc "2" "no AC declared → exit 2 (BLOCK)"
assert_stderr_contains "BLOCKED" "stderr says BLOCKED"
(
  cd "$d"
  echo "AC1" > .vibe-cache/current-ac
  run_hook_capture "$HOOKS/vibe-edit-gate.sh" "src/auth/login.py"
)
assert_rc "0" "AC declared → exit 0 (allow)"
(
  cd "$d"
  bash "$ARM" --disarm >/dev/null 2>&1
  run_hook_capture "$HOOKS/vibe-edit-gate.sh" "src/auth/login.py"
)
assert_rc "0" "not armed → exit 0 (silent)"

# ---------- [5] vibe-tdd-gate ----------

hdr "[5] vibe-tdd-gate — blocks src/ edit without test, allows after"
(
  cd "$d"
  bash "$ARM" >/dev/null 2>&1
  # session-edits is empty → src/foo.py should block
  echo "AC1" > .vibe-cache/current-ac
  run_hook_capture "$HOOKS/vibe-tdd-gate.sh" "src/foo.py"
)
assert_rc "2" "src/foo.py without test in session → exit 2"
assert_stderr_contains "BLOCKED" "stderr says BLOCKED"
(
  cd "$d"
  # Pretend a test for "foo" was edited this session
  echo "tests/test_foo.py" >> .vibe-cache/session-edits
  run_hook_capture "$HOOKS/vibe-tdd-gate.sh" "src/foo.py"
)
assert_rc "0" "src/foo.py after test_foo.py edited → exit 0"
(
  cd "$d"
  # Editing a test file is always allowed
  run_hook_capture "$HOOKS/vibe-tdd-gate.sh" "tests/test_bar.py"
)
assert_rc "0" "editing a test file is free"
(
  cd "$d"
  bash "$ARM" --disarm >/dev/null 2>&1
  run_hook_capture "$HOOKS/vibe-tdd-gate.sh" "src/foo.py"
)
assert_rc "0" "not armed → exit 0"

# ---------- [6] vibe-ac-progress ----------

hdr "[6] vibe-ac-progress — surfaces done/total"
AC_OUT="$TMPDIR_BASE/.ac-out"
: > "$AC_OUT"
(
  cd "$d"
  bash "$ARM" >/dev/null 2>&1
  echo "tests/auth/test_login.py" >> .vibe-cache/session-edits
  git add tests/auth/test_login.py
  printf '{"tool_input":{"file_path":"src/auth/login.py"}}' \
    | bash "$HOOKS/vibe-ac-progress.sh" > "$AC_OUT" 2>&1
)
if grep -qE "\[vibe-ac\] auth: [0-9]+/[0-9]+ ACs" "$AC_OUT"; then
  matched="$(grep -oE "\[vibe-ac\] auth: [0-9]+/[0-9]+ ACs done( · next: [A-Z0-9]+)?" "$AC_OUT" | head -1)"
  ok "output: $matched"
else
  fail "missing [vibe-ac] line — got: $(cat "$AC_OUT")"
fi

# ---------- [7] vibe-fix-detector ----------

hdr "[7] vibe-fix-detector — warns/blocks on fix: file"
(
  cd "$d"
  bash "$ARM" --disarm >/dev/null 2>&1
  # Add a fix: commit touching src/auth/login.py
  printf 'def login(): raise ValueError("auth fail")\n' > src/auth/login.py
  git add -A && git commit -q -m "fix: handle missing creds" >/dev/null
  # Editing the same file → should at least warn (exit 0 in warn mode, 2 in armed)
  run_hook_capture "$HOOKS/vibe-fix-detector.sh" "src/auth/login.py"
)
assert_rc "0" "not armed → exit 0 (warn)"
assert_stderr_contains "WARNING" "warn mode prints WARNING"
(
  cd "$d"
  bash "$ARM" >/dev/null 2>&1
  run_hook_capture "$HOOKS/vibe-fix-detector.sh" "src/auth/login.py"
)
assert_rc "2" "armed → exit 2 (block)"
assert_stderr_contains "BLOCKED" "armed prints BLOCKED"
(
  cd "$d"
  run_hook_capture "$HOOKS/vibe-fix-detector.sh" "src/foo.py"
)
assert_rc "0" "unrelated file → exit 0"

# ---------- [8] vibe-spec-intake ----------

hdr "[8] vibe-spec-intake — writes spec with awaiting-approval"
d2="$(build_full)"
spec_out="$( cd "$d2" && bash "$INTAKE" "login-feature" "users log in with email" 2>&1 )"
[ -f "$d2/docs/requirements/login-feature/spec.md" ] && ok "spec.md written" || fail "spec.md not written"
# Spec file format: `* **Status:** awaiting-approval`. Grep with -F for the value only.
grep -qF "awaiting-approval" "$d2/docs/requirements/login-feature/spec.md" \
  && ok "Status: awaiting-approval set" || fail "Status field wrong"
grep -qF "users log in with email" "$d2/docs/requirements/login-feature/spec.md" \
  && ok "intent captured in spec" || fail "intent missing"

# ---------- [9] vibe-claim-check ----------

hdr "[9] vibe-claim-check — runs + reports per-AC evidence"
d3="$(build_full)"
CLAIM_OUT="$TMPDIR_BASE/.claim-out"
( cd "$d3" && bash "$CLAIM" "auth" > "$CLAIM_OUT" 2>&1 ) || true
if grep -q "verdict:" "$CLAIM_OUT"; then
  ok "prints a verdict"
else
  fail "no verdict line — got: $(head -c 200 "$CLAIM_OUT")"
fi
if grep -qE "AC1\.|AC2\." "$CLAIM_OUT"; then
  ok "iterates over ACs"
else
  fail "no AC iteration — got: $(head -c 200 "$CLAIM_OUT")"
fi

# ---------- summary ----------

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;32mAll %d assertions passed.\033[0m\n' "$PASS"
  exit 0
else
  printf '\033[1;31m%d failed, %d passed.\033[0m\n' "$FAIL" "$PASS"
  exit 1
fi