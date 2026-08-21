#!/usr/bin/env bash
# tests/weapons/test-vibe-mutate.sh
#
# Verifies vibe-mutate per docs/requirements/vibe-mutate/spec.md.
# Coverage: detection, threshold, JSON output, claim-check wiring, docs.
#
# Tests use a fake `mutmut` / `npx` on PATH (controlled exit + output)
# so no real mutation tool runs.

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MUTATE="$KIT_ROOT/kit/bin/vibe-mutate"
CLAIM="$KIT_ROOT/kit/bin/vibe-claim-check"
HOOK="$KIT_ROOT/kit/bin/hooks/vibe-pre-push"
README="$KIT_ROOT/README.md"
CHANGELOG="$KIT_ROOT/CHANGELOG.md"
VERIFY_RULES="$HOME/.claude/rules/02-verify.md"
KIT_CLAUDE="$KIT_ROOT/kit/CLAUDE.md"

PASS=0
FAIL=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
hdr()  { printf '\n\033[1m%s\033[0m\n' "$1"; }

TMPDIR_BASE="$(mktemp -d -t vibe-mutate-tests.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Make a directory with a fake toolchain on PATH.
# Usage: make_env <name> <kind>
#   kind=python   → pyproject.toml + tests/ + fake mutmut
#   kind=node     → package.json (with @stryker-mutator/core) + fake npx
#   kind=java-pom → pom.xml (with pitest) + fake mvn
#   kind=java-gradle → build.gradle (with pitest) + fake gradle
#   kind=empty    → no project files
#   kind=python-no-tool → pyproject.toml + tests/, NO mutmut on PATH
make_env() {
  local name="$1" kind="$2"
  local d="$TMPDIR_BASE/$name"
  mkdir -p "$d/fakebin" "$d/tests"
  local PATH_BACKUP="$PATH"
  export PATH="$d/fakebin:$PATH"

  case "$kind" in
    python)
      cat > "$d/pyproject.toml" <<'EOF'
[tool.pytest.ini_options]
testpaths = ["tests"]
EOF
      cat > "$d/fakebin/mutmut" <<'EOF'
#!/usr/bin/env bash
# fake mutmut: prints score 82/100 and exits 0
echo "82/100 mutations killed"
exit 0
EOF
      chmod +x "$d/fakebin/mutmut"
      ;;
    python-fail)
      cat > "$d/pyproject.toml" <<'EOF'
[tool.pytest.ini_options]
testpaths = ["tests"]
EOF
      cat > "$d/fakebin/mutmut" <<'EOF'
#!/usr/bin/env bash
# fake mutmut: prints low score and exits 0
echo "30/100 mutations killed"
exit 0
EOF
      chmod +x "$d/fakebin/mutmut"
      ;;
    python-no-tool)
      cat > "$d/pyproject.toml" <<'EOF'
[tool.pytest.ini_options]
testpaths = ["tests"]
EOF
      ;;
    node)
      cat > "$d/package.json" <<'EOF'
{
  "name": "fake-node-proj",
  "devDependencies": {
    "@stryker-mutator/core": "^8.0.0"
  }
}
EOF
      cat > "$d/fakebin/npx" <<'EOF'
#!/usr/bin/env bash
# fake npx → emits Stryker-like JSON
cat <<JSON
{"mutationScore":0.85,"files":{}}
JSON
exit 0
EOF
      chmod +x "$d/fakebin/npx"
      ;;
    node-low)
      cat > "$d/package.json" <<'EOF'
{
  "name": "fake-node-proj",
  "devDependencies": {
    "@stryker-mutator/core": "^8.0.0"
  }
}
EOF
      cat > "$d/fakebin/npx" <<'EOF'
#!/usr/bin/env bash
cat <<JSON
{"mutationScore":0.50,"files":{}}
JSON
exit 0
EOF
      chmod +x "$d/fakebin/npx"
      ;;
    java-pom)
      cat > "$d/pom.xml" <<'EOF'
<project><build><plugins>
<plugin><groupId>org.pitest</groupId><artifactId>pitest-maven</artifactId></plugin>
</plugins></build></project>
EOF
      cat > "$d/fakebin/mvn" <<'EOF'
#!/usr/bin/env bash
echo "Mutation Coverage 75%"
exit 0
EOF
      chmod +x "$d/fakebin/mvn"
      ;;
    java-pom-low)
      cat > "$d/pom.xml" <<'EOF'
<project><build><plugins>
<plugin><groupId>org.pitest</groupId><artifactId>pitest-maven</artifactId></plugin>
</plugins></build></project>
EOF
      cat > "$d/fakebin/mvn" <<'EOF'
#!/usr/bin/env bash
echo "Mutation Coverage 40%"
exit 0
EOF
      chmod +x "$d/fakebin/mvn"
      ;;
    empty)
      ;;
  esac
  printf '%s' "$d"
}

# Run vibe-mutate in a temp env, capture rc + stdout.
run_mutate() {
  local cwd="$1"
  shift
  local out rc
  out="$(cd "$cwd" && PATH="$cwd/fakebin:$PATH" bash "$MUTATE" "$@" 2>&1)"
  rc=$?
  printf '%s' "$out" > /tmp/.mutate-out
  echo "$rc" > /tmp/.mutate-rc
  RC=$(cat /tmp/.mutate-rc)
  OUT=$(cat /tmp/.mutate-out)
}

# ---------- [1] Help & syntax ----------

hdr "[1] Help + bash 3.2 portability"
out="$(bash "$MUTATE" --help 2>&1)"; rc=$?
[ "$rc" = "0" ] && ok "--help exits 0" || fail "--help rc=$rc (want 0)"
echo "$out" | grep -qF -- "--threshold" && ok "help mentions --threshold" || fail "help missing --threshold"
echo "$out" | grep -qF -- "--json" && ok "help mentions --json" || fail "help missing --json"
echo "$out" | grep -qF -- "--verbose" && ok "help mentions --verbose" || fail "help missing --verbose"

if grep -qE 'mapfile|declare -A' "$MUTATE"; then
  fail "vibe-mutate uses bash 4+ features (mapfile/declare -A)"
else
  ok "bash 3.2 portable (no mapfile/declare -A)"
fi

# ---------- [2] Detection ----------

hdr "[2] Language + runner detection"
cwd="$(make_env case-python python)"
run_mutate "$cwd"
[ "$RC" = "0" ] && ok "python + mutmut → PASS (rc=0)" || fail "python rc=$RC (want 0)"
echo "$OUT" | grep -q "language.*python" && ok "python detected" || fail "language not detected as python"
echo "$OUT" | grep -q "runner.*mutmut" && ok "mutmut runner detected" || fail "mutmut not detected"

cwd="$(make_env case-node node)"
run_mutate "$cwd"
[ "$RC" = "0" ] && ok "node + stryker → PASS (rc=0, score=85)" || fail "node rc=$RC (want 0)"
echo "$OUT" | grep -q "language.*node" && ok "node detected" || fail "language not node"

cwd="$(make_env case-java java-pom)"
run_mutate "$cwd"
[ "$RC" = "0" ] && ok "java + pitest → PASS (rc=0, score=75)" || fail "java rc=$RC (want 0)"
echo "$OUT" | grep -q "language.*java" && ok "java detected" || fail "language not java"

cwd="$(make_env case-empty empty)"
run_mutate "$cwd"
[ "$RC" = "3" ] && ok "empty project → rc=3 UNVERIFIED" || fail "empty rc=$RC (want 3)"
echo "$OUT" | grep -qiF "no language detected" && ok "empty project message says 'no language'" || fail "missing UNVERIFIED message"

cwd="$(make_env case-no-tool python-no-tool)"
run_mutate "$cwd"
[ "$RC" = "2" ] && ok "python without mutmut → rc=2 BLOCK" || fail "no-tool rc=$RC (want 2)"
echo "$OUT" | grep -qiF "pip install mutmut" && ok "BLOCK message hints install command" || fail "BLOCK missing install hint"

# ---------- [3] Threshold + JSON ----------

hdr "[3] Threshold + JSON"
cwd="$(make_env case-low python-fail)"
run_mutate "$cwd"
[ "$RC" = "1" ] && ok "score=30 < threshold=70 → FAIL (rc=1)" || fail "low-score rc=$RC (want 1)"

cwd="$(make_env case-threshold python)"
run_mutate "$cwd" --threshold=95
[ "$RC" = "1" ] && ok "--threshold=95 with score=82 → FAIL (rc=1)" || fail "threshold override rc=$RC (want 1)"

cwd="$(make_env case-threshold-pass python)"
run_mutate "$cwd" --threshold=50
[ "$RC" = "0" ] && ok "--threshold=50 with score=82 → PASS (rc=0)" || fail "low threshold rc=$RC (want 0)"

cwd="$(make_env case-json node)"
run_mutate "$cwd" --json
echo "$OUT" | grep -qE '"status":"PASS"' && ok "json: status=PASS" || fail "json status not PASS"
echo "$OUT" | grep -qE '"score":85' && ok "json: score=85" || fail "json score not 85"
echo "$OUT" | grep -qE '"threshold":70' && ok "json: threshold=70 (default)" || fail "json threshold not 70"
echo "$OUT" | grep -qE '"language":"node"' && ok "json: language=node" || fail "json language not node"

# ---------- [4] Invalid args ----------

hdr "[4] Invalid args"
out="$(bash "$MUTATE" --threshold=abc 2>&1)"; rc=$?
[ "$rc" = "4" ] && ok "--threshold=abc → rc=4 config error" || fail "bad threshold rc=$rc (want 4)"
out="$(bash "$MUTATE" --bogus 2>&1)"; rc=$?
[ "$rc" = "4" ] && ok "--bogus → rc=4 config error" || fail "bogus flag rc=$rc (want 4)"

# ---------- [5] claim-check wiring ----------

hdr "[5] vibe-claim-check wires vibe-mutate"

# Set up a fake project with a passing test and a stub mutation tool
# that exits 1 (FAIL). Claim-check should return PARTIAL (rc=2).
wiring_dir="$TMPDIR_BASE/wiring"
mkdir -p "$wiring_dir/docs/requirements/wire-test" "$wiring_dir/fakebin" "$wiring_dir/kit/bin"

cat > "$wiring_dir/docs/requirements/wire-test/spec.md" <<'EOF'
# wire-test
Status: awaiting-approval

## Acceptance Criteria

- AC1. stub evidence
  Verification:
    automated test: tests/test_wire.py::test_wire_AC1_stub
    expected behavior: passes
EOF

cat > "$wiring_dir/fakebin/mutmut" <<'EOF'
#!/usr/bin/env bash
echo "20/100 mutations killed"
exit 0
EOF
chmod +x "$wiring_dir/fakebin/mutmut"

# Fake vibe-test that always passes
cat > "$wiring_dir/kit/bin/vibe-test" <<'EOF'
#!/usr/bin/env bash
echo "vibe-test: PASS"
exit 0
EOF
chmod +x "$wiring_dir/kit/bin/vibe-test"

# Fake vibe-mutate that returns score=20 → FAIL
cat > "$wiring_dir/kit/bin/vibe-mutate" <<'EOF'
#!/usr/bin/env bash
echo "vibe-mutate: FAIL (score=20%, threshold=70%)"
exit 1
EOF
chmod +x "$wiring_dir/kit/bin/vibe-mutate"

# A test file claimed in the spec, so the diff check passes
mkdir -p "$wiring_dir/tests"
cat > "$wiring_dir/tests/test_wire.py" <<'EOF'
def test_wire_AC1_stub():
    assert True
EOF

# Initialize a git repo so diff is meaningful
(cd "$wiring_dir" && git init -q && git config user.email t@t && git config user.name t && \
  git add -A && git commit -q -m init)

# Run claim-check against the fake kit (override KIT_BIN resolution by symlinking)
# Easier: temporarily install the fake kit over the real one
backup_bin="$(mktemp -d -t vibe-mutate-bk.XXXXXX)"
cp "$KIT_ROOT/kit/bin/vibe-test" "$backup_bin/" 2>/dev/null || true
cp "$KIT_ROOT/kit/bin/vibe-mutate" "$backup_bin/" 2>/dev/null || true

cp "$wiring_dir/kit/bin/vibe-test"    "$KIT_ROOT/kit/bin/vibe-test"
cp "$wiring_dir/kit/bin/vibe-mutate"  "$KIT_ROOT/kit/bin/vibe-mutate"
chmod +x "$KIT_ROOT/kit/bin/vibe-test" "$KIT_ROOT/kit/bin/vibe-mutate"

# Run claim-check: should return rc=2 (PARTIAL) due to mutation FAIL
out="$(cd "$wiring_dir" && bash "$CLAIM" wire-test 2>&1)"
rc=$?
[ "$rc" = "2" ] && ok "claim-check + mutation FAIL → PARTIAL (rc=2)" || fail "claim-check rc=$rc (want 2)"
echo "$out" | grep -qF "Mutation evidence" && ok "claim-check reports 'Mutation evidence'" || fail "no mutation evidence section"

# With VIBE_SHIP_OVERRIDE=1, claim-check should still report PARTIAL (override is
# handled by the hook, not claim-check itself). Verify claim-check stays PARTIAL.
out="$(cd "$wiring_dir" && VIBE_SHIP_OVERRIDE=1 bash "$CLAIM" wire-test 2>&1)"
rc=$?
[ "$rc" = "2" ] && ok "claim-check + mutation FAIL + override → still PARTIAL (hook lifts it)" || fail "claim-check with override rc=$rc (want 2 — hook does the lifting)"

# Restore real binaries
cp "$backup_bin/vibe-test"   "$KIT_ROOT/kit/bin/vibe-test"
cp "$backup_bin/vibe-mutate" "$KIT_ROOT/kit/bin/vibe-mutate"
chmod +x "$KIT_ROOT/kit/bin/vibe-test" "$KIT_ROOT/kit/bin/vibe-mutate"

# ---------- [6] Docs ----------

hdr "[6] Docs mention vibe-mutate + threshold + rank"
grep -qF "vibe-mutate" "$README" && ok "README mentions vibe-mutate" || fail "README missing vibe-mutate"
grep -qiE "70|threshold" "$README" && ok "README mentions threshold" || fail "README missing threshold"
grep -qF "vibe-mutate" "$CHANGELOG" && ok "CHANGELOG mentions vibe-mutate" || fail "CHANGELOG missing vibe-mutate"

# Verification floors: either kit/CLAUDE.md or ~/.claude/rules/02-verify.md must
# call mutation "Rank 1" (or treat it as a first-class ship-time check).
rank_mentioned=0
[ -f "$VERIFY_RULES" ] && grep -qiE "mutation.*rank\s*1|rank\s*1.*mutation" "$VERIFY_RULES" && rank_mentioned=1
grep -qiE "mutation.*rank\s*1|rank\s*1.*mutation" "$KIT_CLAUDE" 2>/dev/null && rank_mentioned=1
[ "$rank_mentioned" -eq 1 ] && ok "verification floors doc mentions mutation as rank 1" || fail "no doc mentions mutation as rank 1"

# Pre-push hook still calls claim-check (regression check)
grep -qF "vibe-claim-check" "$HOOK" && ok "pre-push hook still wires claim-check (no regression)" || fail "pre-push hook lost claim-check reference"

# ---------- summary ----------

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;32mAll %d assertions passed.\033[0m\n' "$PASS"
  exit 0
else
  printf '\033[1;31m%d failed, %d passed.\033[0m\n' "$FAIL" "$PASS"
  exit 1
fi
