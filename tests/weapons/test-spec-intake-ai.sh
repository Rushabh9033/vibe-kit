#!/usr/bin/env bash
# tests/weapons/test-spec-intake-ai.sh
#
# Verifies vibe-spec-intake --ai per docs/requirements/vibe-spec-intake-ai/spec.md.
# Coverage: --ai flag, claude invocation, fallback, validation, default mode.

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INTAKE="$KIT_ROOT/kit/bin/vibe-spec-intake"

PASS=0
FAIL=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }

TMPDIR_BASE="$(mktemp -d -t vibe-intake-tests.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Always operate inside TMPDIR_BASE. The intake script writes
# docs/requirements/<slug>/spec.md relative to the (non-git) cwd, so
# by keeping us in TMPDIR_BASE the writes go to a sandboxed docs/.
# Never `rm -rf docs` from the project root — that's how we learned
# this lesson.
cd "$TMPDIR_BASE"
mkdir -p bin

# Strip any system PATH entry that contains a real `claude` binary so
# tests can exercise the "AI not available" path. We add it back only
# when we WANT claude to be present.
PATH_NO_CLAUDE="$(echo "$PATH" | tr ':' '\n' | while read -r p; do
  [ -d "$p" ] || continue
  [ -x "$p/claude" ] && continue
  printf '%s\n' "$p"
done | paste -sd ':' -)"

write_fake_claude() {
  local body="$1"
  cat > "$TMPDIR_BASE/bin/claude" <<EOF
#!/usr/bin/env bash
$body
EOF
  chmod +x "$TMPDIR_BASE/bin/claude"
}

# 1. AI flag recognized — writes spec without invoking AI when claude missing.
rm -f bin/claude
out="$(PATH="$PATH_NO_CLAUDE" bash "$INTAKE" foo "x" --ai 2>&1)"
rc=$?
[ $rc -eq 0 ] && ok "test_ai_flag_recognized" || { fail "test_ai_flag_recognized"; echo "RC: $rc, OUT: $out"; }
rm -rf docs

# 2. claude invokes and writes its output as the spec.
write_fake_claude 'echo "# foo"
echo "AI intent output x"'
out="$(PATH="$TMPDIR_BASE/bin:$PATH" bash "$INTAKE" --ai --auto foo "x" 2>&1)"
grep -q "AI intent output x" "docs/requirements/foo/spec.md" && ok "test_ai_invokes_claude" || { fail "test_ai_invokes_claude"; echo "OUT: $out"; cat docs/requirements/foo/spec.md; }
rm -rf docs

# 3. fallback when no claude is on PATH.
rm -f bin/claude
out="$(PATH="$PATH_NO_CLAUDE" bash "$INTAKE" --ai --auto bar "test intent" 2>&1)"
echo "$out" | grep -q "AI not available" && ok "test_ai_fallback_no_claude" || { fail "test_ai_fallback_no_claude"; echo "OUT: $out"; }
rm -rf docs

# 4. Prompt template exists at kit/prompts/spec-intake.md and contains SLUG.
grep -q "SLUG" "$KIT_ROOT/kit/prompts/spec-intake.md" && ok "test_prompt_template_exists" || fail "test_prompt_template_exists"

# 5. Default mode (no --ai) does not invoke claude.
write_fake_claude 'echo "SHOULD NOT BE CALLED"
exit 99'
bash "$INTAKE" --auto baz "intent" >/dev/null 2>&1
! grep -q "SHOULD NOT BE CALLED" docs/requirements/baz/spec.md && ok "test_default_no_ai_call" || fail "test_default_no_ai_call (default mode called AI)"
rm -rf docs

# 6. Output validation: AI output missing intent keywords falls back.
write_fake_claude 'echo "no keyword here"'
out="$(PATH="$TMPDIR_BASE/bin:$PATH" bash "$INTAKE" --ai --auto qux "validateword" 2>&1)"
echo "$out" | grep -q "validation" && ok "test_ai_output_validation" || { fail "test_ai_output_validation"; echo "OUT: $out"; }
rm -rf docs

# 7. Default template mode is unchanged (still has the 5 generic AC stubs).
rm -f bin/claude
bash "$INTAKE" --auto quux "my intent" >/dev/null 2>&1
grep -q "AC1. <describe" docs/requirements/quux/spec.md && ok "test_default_template_unchanged" || fail "test_default_template_unchanged"
rm -rf docs

# 8. Bash 3.2 portable.
grep -qE 'mapfile|declare -A' "$INTAKE" && fail "test_bash32_portable" || ok "test_bash32_portable"

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;32mAll %d assertions passed.\033[0m\n' "$PASS"
  exit 0
else
  printf '\033[1;31m%d failed, %d passed.\033[0m\n' "$FAIL" "$PASS"
  exit 1
fi
