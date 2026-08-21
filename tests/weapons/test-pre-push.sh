#!/usr/bin/env bash
# tests/weapons/test-pre-push.sh
#
# Verifies that the vibe-pre-push hook calls vibe-claim-check (not vibe-verify)
# at the ship boundary. This is the #3 ship-gate swap.
#
# Coverage:
#   - vibe-pre-push script calls vibe-claim-check, not vibe-verify (the executable)
#   - vibe-pre-push passes through --no-verify
#   - vibe-pre-push exits 0 on PASS, 1 on FAIL, 2 on PARTIAL
#   - vibe-pre-push VIBE_SHIP_OVERRIDE=1 lifts PARTIAL but not FAIL
#   - kit/commands/vibe-claim-check.md says "ship gate"
#   - kit/commands/vibe-verify.md says it's NOT for ship time

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$KIT_ROOT/kit/bin/hooks/vibe-pre-push"
CLAIM_MD="$KIT_ROOT/kit/commands/vibe-claim-check.md"
VERIFY_MD="$KIT_ROOT/kit/commands/vibe-verify.md"
PASS=0
FAIL=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
hdr()  { printf '\n\033[1m%s\033[0m\n' "$1"; }

TMPDIR_BASE="$(mktemp -d -t vibe-prepush-tests.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Make a fake claim-check at a path the hook will resolve.
# The hook tries ./kit/bin/vibe-claim-check first; we satisfy that.
make_fake_claim() {
  local target_dir="$1"
  local exit_code="$2"
  mkdir -p "$target_dir/kit/bin"
  cat > "$target_dir/kit/bin/vibe-claim-check" <<FAKE_EOF
#!/usr/bin/env bash
echo "fake claim-check: exit=$exit_code"
exit $exit_code
FAKE_EOF
  chmod +x "$target_dir/kit/bin/vibe-claim-check"
}

# Run the hook in a temp dir, capture rc + output.
# HOME is redirected to an empty sandbox dir so the hook's fallback path
# (`$HOME/.claude/vibe-kit/bin/vibe-claim-check`) is not satisfied by a
# real install on this machine. Without this, CASE 6 (missing claim-check)
# would silently find the real global install and the test would flake.
run_hook() {
  local cwd="$1"
  shift
  (
    cd "$cwd"
    HOME="$TMPDIR_BASE/empty-home" bash "$HOOK" "$@" > /tmp/.prepush-out 2>&1
    echo $? > /tmp/.prepush-rc
  )
  RC=$(cat /tmp/.prepush-rc)
  OUT=$(cat /tmp/.prepush-out)
}

# ---------- [1] Hook script wiring ----------

hdr "[1] vibe-pre-push hook calls vibe-claim-check (not vibe-verify)"
if grep -qF "vibe-claim-check" "$HOOK"; then
  ok "hook references vibe-claim-check"
else
  fail "hook does NOT reference vibe-claim-check"
fi
# It should NOT call vibe-verify as an executable — only mention it in a comment.
if grep -E '^[^#]*vibe-verify' "$HOOK" >/dev/null; then
  fail "hook has a non-comment reference to vibe-verify"
else
  ok "hook has no non-comment reference to vibe-verify"
fi
if grep -qF 'VIBE_CLAIM="./kit/bin/vibe-claim-check"' "$HOOK"; then
  ok "hook resolves ./kit/bin/vibe-claim-check"
else
  fail "hook does not resolve ./kit/bin/vibe-claim-check"
fi

# ---------- [2] Hook behavior matrix ----------

hdr "[2] vibe-pre-push behavior matrix"

# CASE 1: claim-check exits 0 → hook exits 0
d1="$TMPDIR_BASE/case1"
make_fake_claim "$d1" 0
run_hook "$d1"
[ "$RC" = "0" ] && ok "claim-check rc=0 → hook rc=0" || fail "claim-check rc=0 → hook rc=$RC (want 0)"
echo "$OUT" | grep -q "vibe-pre-push: PASS" && ok "hook reports PASS" || fail "hook did not report PASS"

# CASE 2: claim-check exits 1 → hook exits 1, FAIL cannot be overridden
d2="$TMPDIR_BASE/case2"
make_fake_claim "$d2" 1
run_hook "$d2"  # with VIBE_SHIP_OVERRIDE=1 set below to confirm override does NOT apply to FAIL
echo "VIBE_SHIP_OVERRIDE=1"
VIBE_SHIP_OVERRIDE=1 run_hook "$d2"
[ "$RC" = "1" ] && ok "claim-check rc=1 + override → hook rc=1 (FAIL not lifted)" || fail "claim-check rc=1 + override → hook rc=$RC (want 1)"
echo "$OUT" | grep -q "cannot be overridden" && ok "hook says FAIL cannot be overridden" || fail "hook did not refuse override on FAIL"

# CASE 3: claim-check exits 2 without override → hook exits 1 (refused)
d3="$TMPDIR_BASE/case3"
make_fake_claim "$d3" 2
unset VIBE_SHIP_OVERRIDE
run_hook "$d3"
[ "$RC" = "1" ] && ok "claim-check rc=2 no override → hook rc=1 (refused)" || fail "claim-check rc=2 no override → hook rc=$RC (want 1)"
echo "$OUT" | grep -q "BLOCK" && ok "hook reports BLOCK" || fail "hook did not report BLOCK"

# CASE 4: claim-check exits 2 WITH override → hook exits 0 (lifted)
d4="$TMPDIR_BASE/case4"
make_fake_claim "$d4" 2
VIBE_SHIP_OVERRIDE=1 run_hook "$d4"
[ "$RC" = "0" ] && ok "claim-check rc=2 + override → hook rc=0 (lifted)" || fail "override rc=$RC (want 0)"
echo "$OUT" | grep -q "BLOCK lifted" && ok "hook reports BLOCK lifted" || fail "hook did not report BLOCK lifted"

# CASE 5: --no-verify short-circuits
d5="$TMPDIR_BASE/case5"
make_fake_claim "$d5" 1
run_hook "$d5" --no-verify
[ "$RC" = "0" ] && ok "--no-verify → hook rc=0 (skipped)" || fail "--no-verify rc=$RC (want 0)"
! echo "$OUT" | grep -q "fake claim-check" && ok "--no-verify did not call claim-check" || fail "--no-verify still called claim-check"

# CASE 6: missing claim-check → hook exits 0 (skip, don't break the user)
d6="$TMPDIR_BASE/case6"
mkdir -p "$d6"
run_hook "$d6"
[ "$RC" = "0" ] && ok "missing claim-check → hook rc=0 (skip)" || fail "missing claim-check rc=$RC (want 0)"
echo "$OUT" | grep -q "not installed" && ok "missing claim-check reports 'not installed'" || fail "missing claim-check missing diagnostic"

# ---------- [3] Slash-command docs ----------

hdr "[3] Slash command docs match the new split"
grep -qiF "ship gate" "$CLAIM_MD" && ok "vibe-claim-check.md says 'ship gate'" || fail "vibe-claim-check.md does NOT say 'ship gate'"
grep -qiF "mid-development" "$VERIFY_MD" && ok "vibe-verify.md says it's mid-development" || fail "vibe-verify.md does NOT clarify mid-development role"
grep -qiE "not at ship time|NOT for ship|never at ship" "$VERIFY_MD" && ok "vibe-verify.md says NOT at ship time" || fail "vibe-verify.md does NOT explicitly say NOT at ship time"

# ---------- summary ----------

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;32mAll %d assertions passed.\033[0m\n' "$PASS"
  exit 0
else
  printf '\033[1;31m%d failed, %d passed.\033[0m\n' "$FAIL" "$PASS"
  exit 1
fi