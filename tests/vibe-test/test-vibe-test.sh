#!/usr/bin/env bash
# tests/vibe-test/test-vibe-test.sh
#
# Verifies vibe-test (the test oracle) across its status model:
#   PASS / FAIL / BLOCK / UNVERIFIED
#
# Approach: build tiny fixtures in temp dirs, then assert that
# `kit/bin/vibe-test` returns the expected exit code and status label
# for each.
#
# Fixtures built here are throwaway. No fixtures are committed; the test
# is fully self-contained.
#
# Usage:
#   bash tests/vibe-test/test-vibe-test.sh
#
# Exit codes:
#   0 — all assertions pass
#   1 — at least one assertion fails

set -uo pipefail

# ---------- helpers ----------
KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VIBE_TEST="$KIT_ROOT/kit/bin/vibe-test"
PASS=0
FAIL=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
hdr()  { printf '\n\033[1m%s\033[0m\n' "$1"; }

assert_eq() {
  local got="$1" want="$2" label="$3"
  if [ "$got" = "$want" ]; then
    ok "$label (got $got)"
  else
    fail "$label — got '$got', want '$want'"
  fi
}

# Build a temp fixture dir; auto-cleaned on EXIT.
TMPDIR_BASE="$(mktemp -d -t vibe-test-tests.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

build_pytest_passing() {
  local d="$TMPDIR_BASE/py-pass"
  mkdir -p "$d/tests" "$d/src"
  cat > "$d/pyproject.toml" <<EOF
[tool.pytest.ini_options]
testpaths = ["tests"]
EOF
  cat > "$d/src/__init__.py" <<EOF
def add(a, b): return a + b
EOF
  cat > "$d/tests/__init__.py" <<EOF
EOF
  cat > "$d/tests/test_add.py" <<EOF
from src import add
def test_add_pass(): assert add(2, 3) == 5
EOF
  printf '%s' "$d"
}

build_pytest_failing() {
  local d="$TMPDIR_BASE/py-fail"
  mkdir -p "$d/tests" "$d/src"
  cat > "$d/pyproject.toml" <<EOF
[tool.pytest.ini_options]
testpaths = ["tests"]
EOF
  cat > "$d/src/__init__.py" <<EOF
def add(a, b): return a + b
EOF
  cat > "$d/tests/__init__.py" <<EOF
EOF
  cat > "$d/tests/test_add.py" <<EOF
from src import add
def test_add_will_fail(): assert add(2, 2) == 5
EOF
  printf '%s' "$d"
}

build_npm_passing() {
  local d="$TMPDIR_BASE/npm-pass"
  mkdir -p "$d"
  cat > "$d/package.json" <<EOF
{
  "name": "pass",
  "scripts": {
    "test": "node test.js"
  }
}
EOF
  cat > "$d/test.js" <<'EOF'
const assert = require('assert');
assert.strictEqual(1 + 1, 2);
console.log('ok');
EOF
  printf '%s' "$d"
}

build_npm_failing() {
  local d="$TMPDIR_BASE/npm-fail"
  mkdir -p "$d"
  cat > "$d/package.json" <<EOF
{
  "name": "fail",
  "scripts": {
    "test": "node test.js"
  }
}
EOF
  cat > "$d/test.js" <<'EOF'
const assert = require('assert');
assert.strictEqual(1 + 1, 3);
EOF
  printf '%s' "$d"
}

build_no_runner() {
  local d="$TMPDIR_BASE/no-runner"
  mkdir -p "$d"
  printf '%s' "$d"
}

build_pytest_missing() {
  # pyproject configured for pytest but pytest not installed.
  local d="$TMPDIR_BASE/py-missing"
  mkdir -p "$d/tests"
  cat > "$d/pyproject.toml" <<EOF
[tool.pytest.ini_options]
testpaths = ["tests"]
EOF
  cat > "$d/tests/__init__.py" <<EOF
EOF
  cat > "$d/tests/test_x.py" <<EOF
def test_x(): pass
EOF
  printf '%s' "$d"
}

# ---------- assertions ----------

hdr "[1] vibe-test binary present and executable"
if [ -x "$VIBE_TEST" ]; then
  ok "kit/bin/vibe-test exists and is executable"
else
  fail "kit/bin/vibe-test missing or not executable"
  exit 1
fi

hdr "[2] Status model — exit codes"
# 2.1 — pytest passing → PASS, exit 0
if command -v pytest >/dev/null 2>&1; then
  d="$(build_pytest_passing)"
  cd "$d"
  bash "$VIBE_TEST" >/dev/null 2>&1; rc=$?
  cd "$KIT_ROOT"
  assert_eq "$rc" "0" "pytest passing → exit 0 (PASS)"
else
  ok "skipped: pytest not installed (pytest passing)"
fi

# 2.2 — pytest failing → FAIL, exit 1
if command -v pytest >/dev/null 2>&1; then
  d="$(build_pytest_failing)"
  cd "$d"
  bash "$VIBE_TEST" --rank=unit >/dev/null 2>&1; rc=$?
  cd "$KIT_ROOT"
  assert_eq "$rc" "1" "pytest failing → exit 1 (FAIL)"
else
  ok "skipped: pytest not installed (pytest failing)"
fi

# 2.3 — npm test passing → exit 0 (if node available)
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  d="$(build_npm_passing)"
  cd "$d"
  bash "$VIBE_TEST" >/dev/null 2>&1; rc=$?
  cd "$KIT_ROOT"
  assert_eq "$rc" "0" "npm test passing → exit 0 (PASS)"
else
  ok "skipped: npm/node not installed"
fi

# 2.4 — npm test failing → exit 1
if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  d="$(build_npm_failing)"
  cd "$d"
  bash "$VIBE_TEST" >/dev/null 2>&1; rc=$?
  cd "$KIT_ROOT"
  assert_eq "$rc" "1" "npm test failing → exit 1 (FAIL)"
else
  ok "skipped: npm/node not installed"
fi

# 2.5 — no test runner → UNVERIFIED, exit 3
d="$(build_no_runner)"
cd "$d"
bash "$VIBE_TEST" >/dev/null 2>&1; rc=$?
cd "$KIT_ROOT"
assert_eq "$rc" "3" "no runner → exit 3 (UNVERIFIED)"

hdr "[3] --json output shape"
d="$(build_no_runner)"
cd "$d"
out="$(bash "$VIBE_TEST" --json 2>/dev/null)"
cd "$KIT_ROOT"
if printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["status"] == "UNVERIFIED"; assert "results" in d; assert isinstance(d["results"], list)' 2>/dev/null; then
  ok "--json output is valid JSON with status + results"
else
  fail "--json output malformed or missing keys (got: ${out:0:80})"
fi

# 2.6 — pytest missing tool → BLOCK exit 2 (requires PATH scrubbing)
if command -v pytest >/dev/null 2>&1; then
  d="$(build_pytest_missing)"
  # Strip pytest from PATH for this run
  STRIPPED_PATH="$(echo "$PATH" | tr ':' '\n' | grep -v "$(dirname "$(command -v pytest)")" | paste -sd: -)"
  cd "$d"
  PATH="$STRIPPED_PATH" bash "$VIBE_TEST" --rank=unit >/dev/null 2>&1; rc=$?
  cd "$KIT_ROOT"
  assert_eq "$rc" "2" "pytest configured but missing → exit 2 (BLOCK)"
else
  ok "skipped: pytest missing-tool test (pytest not installed here either)"
fi

hdr "[4] --rank filter"
d="$(build_pytest_passing)"
cd "$d"
out="$(bash "$VIBE_TEST" --rank=unit 2>&1 | head -10)"
cd "$KIT_ROOT"
if printf '%s' "$out" | grep -q "unit"; then
  ok "--rank=unit prints only the unit rank"
else
  fail "--rank=unit didn't filter correctly: $out"
fi

hdr "[5] --help"
out="$(bash "$VIBE_TEST" --help 2>&1)"
if printf '%s' "$out" | grep -qi "vibe-test"; then
  ok "--help prints usage"
else
  fail "--help missing usage banner"
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