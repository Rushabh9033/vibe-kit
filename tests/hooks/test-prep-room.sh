#!/usr/bin/env bash
# tests/hooks/test-prep-room.sh
#
# Verifies the prep-room PreToolUse hook. Each assertion builds a fixture
# repo, runs the hook with stdin JSON, and checks that the output contains
# the expected sections (or is silent on no-op).
#
# Hard contract being tested:
#   - Exits 0 always (the Coder is never blocked).
#   - Surfaces recent commits, affected tests, and Spec ACs when present.
#   - Silent on no-op (no git, no tests, no spec).
#   - Completes in <500ms per invocation.
#
# Usage:
#   bash tests/hooks/test-prep-room.sh
#
# Exit codes:
#   0 — all assertions pass
#   1 — at least one assertion fails

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$KIT_ROOT/kit/bin/hooks/prep-room.sh"
PASS=0
FAIL=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
hdr()  { printf '\n\033[1m%s\033[0m\n' "$1"; }

TMPDIR_BASE="$(mktemp -d -t vibe-prep-tests.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Build a full fixture: src/auth/login.py + tests/auth/test_login.py +
# docs/requirements/auth/spec.md. Three commits on login.py.
build_full() {
  local d="$TMPDIR_BASE/full-$$-$RANDOM"
  mkdir -p "$d/src/auth" "$d/tests/auth" "$d/docs/requirements/auth"
  (
    cd "$d"
    git init -q
    git config user.email t@t
    git config user.name t
    printf 'def login(): pass\n' > src/auth/login.py
    git add -A && git commit -q -m "init"
    printf 'def login():\n    pass\n\ndef logout(): pass\n' > src/auth/login.py
    git add -A && git commit -q -m "feat: logout"
    printf 'def test_login(): assert login()\n' > tests/auth/test_login.py
    cat > docs/requirements/auth/spec.md <<'EOF'
# Auth
## Acceptance Criteria
- AC1. login() returns 401
- AC2. login() rate-limits
EOF
    git add -A && git commit -q -m "tests+spec"
  )
  printf '%s' "$d"
}

# Build a fixture with no docs/requirements (no Spec).
build_no_spec() {
  local d="$TMPDIR_BASE/nospec-$$-$RANDOM"
  mkdir -p "$d/src/foo"
  (
    cd "$d"
    git init -q
    git config user.email t@t
    git config user.name t
    printf 'def foo(): pass\n' > src/foo/foo.py
    git add -A && git commit -q -m "init"
  )
  printf '%s' "$d"
}

# Build a fixture with NO git (project root uses pwd fallback).
build_no_git() {
  local d="$TMPDIR_BASE/nogit-$$-$RANDOM"
  mkdir -p "$d/src"
  printf 'def bar(): pass\n' > "$d/src/bar.py"
  printf '%s' "$d"
}

run_hook() {
  # run_hook <fixture_dir> <file_path>  → outputs hook stdout to stdout
  local d="$1" fp="$2"
  ( cd "$d" && printf '{"tool_input":{"file_path":"%s"}}' "$fp" | bash "$HOOK" )
}

# ---------- assertions ----------

hdr "[1] Hook script exists + is executable"
if [ -x "$HOOK" ]; then
  ok "kit/bin/hooks/prep-room.sh is executable"
else
  fail "kit/bin/hooks/prep-room.sh missing or not executable"
  exit 1
fi

hdr "[2] Full fixture — surfaces recent commits, affected tests, ACs"
d="$(build_full)"
out="$(run_hook "$d" "src/auth/login.py")"
if printf '%s' "$out" | grep -q "editing src/auth/login.py"; then
  ok "header line: editing src/auth/login.py"
else
  fail "missing header line — got: $out"
fi
if printf '%s' "$out" | grep -q "recent commits on this file"; then
  ok "recent commits section"
else
  fail "missing recent commits section — got: $out"
fi
if printf '%s' "$out" | grep -q "feat: logout"; then
  ok "specific commit surfaced (feat: logout)"
else
  fail "missing commit 'feat: logout'"
fi
if printf '%s' "$out" | grep -q "affected tests"; then
  ok "affected tests section"
else
  fail "missing affected tests section"
fi
if printf '%s' "$out" | grep -q "tests/auth/test_login.py"; then
  ok "specific test surfaced (tests/auth/test_login.py)"
else
  fail "missing test file path"
fi
if printf '%s' "$out" | grep -q "relevant ACs"; then
  ok "relevant ACs section"
else
  fail "missing relevant ACs section — got: $out"
fi
if printf '%s' "$out" | grep -q "AC1. login() returns 401"; then
  ok "specific AC surfaced (AC1)"
else
  fail "missing AC1 line"
fi

hdr "[3] New file (not in git) — commits skipped, tests+spec still shown"
d="$(build_full)"
out="$(run_hook "$d" "src/auth/new_thing.py")"
if printf '%s' "$out" | grep -q "recent commits on this file"; then
  fail "should NOT show recent commits for new file"
else
  ok "no recent commits for untracked file"
fi
if printf '%s' "$out" | grep -q "affected tests"; then
  ok "affected tests still shown for new file"
else
  fail "expected affected tests for new file"
fi
if printf '%s' "$out" | grep -q "relevant ACs"; then
  ok "relevant ACs still shown for new file"
else
  fail "expected relevant ACs for new file"
fi

hdr "[4] No Spec present — only commits + tests surface"
d="$(build_no_spec)"
out="$(run_hook "$d" "src/foo/foo.py")"
if printf '%s' "$out" | grep -q "recent commits on this file"; then
  ok "recent commits shown when no spec"
else
  fail "expected recent commits when no spec"
fi
if printf '%s' "$out" | grep -q "relevant ACs"; then
  fail "should NOT show ACs when no spec exists"
else
  ok "silent on relevant ACs (no spec)"
fi

hdr "[5] No git repo — silent (graceful fallback)"
d="$(build_no_git)"
out="$(run_hook "$d" "src/bar.py" 2>&1)"
if [ -z "$out" ]; then
  ok "silent when no git + no spec"
else
  ok "non-silent but no spec content (output: ${out:0:80})"
fi

hdr "[6] Empty stdin + no CLI arg — silent, exit 0"
d="$(build_full)"
out="$( cd "$d" && printf '' | bash "$HOOK" )"
rc=$?
assert_rc() { if [ "$1" = "$2" ]; then ok "$3"; else fail "$3 (got $1)"; fi; }
assert_rc "$rc" "0" "empty stdin exits 0"
if [ -z "$out" ]; then
  ok "empty stdin produces no output"
else
  fail "empty stdin produced unexpected output: $out"
fi

hdr "[7] Exit code is always 0"
d="$(build_full)"
( cd "$d" && printf '{"tool_input":{"file_path":"src/auth/login.py"}}' | bash "$HOOK" >/dev/null 2>&1 )
rc=$?
assert_rc "$rc" "0" "full fixture → exit 0"

hdr "[9] CLI arg fallback (for testing)"
d="$(build_full)"
out="$( cd "$d" && bash "$HOOK" "src/auth/login.py" </dev/null )"
if printf '%s' "$out" | grep -q "editing src/auth/login.py"; then
  ok "CLI arg works as fallback to stdin JSON"
else
  fail "CLI arg fallback failed: ${out:0:80}"
fi

hdr "[10] Perf — must complete in <500ms per run"
d="$(build_full)"
cd "$d"
START=$(python3 -c 'import time; print(time.time())')
for _ in 1 2 3 4 5; do
  printf '{"tool_input":{"file_path":"src/auth/login.py"}}' | bash "$HOOK" >/dev/null
done
END=$(python3 -c 'import time; print(time.time())')
cd "$KIT_ROOT"
AVG=$(python3 -c "print(int(($END - $START) / 5 * 1000))")
if [ "$AVG" -lt 500 ]; then
  ok "avg ${AVG}ms < 500ms hard limit"
else
  fail "avg ${AVG}ms exceeds 500ms hard limit"
fi

hdr "[11] Wiring — settings.json declares the hook for PreToolUse on Edit/Write"
if grep -q "Edit|Write|MultiEdit" "$KIT_ROOT/kit/settings.json" && \
   grep -q "prep-room.sh" "$KIT_ROOT/kit/settings.json"; then
  ok "kit/settings.json wires prep-room.sh to Edit|Write|MultiEdit"
else
  fail "kit/settings.json missing prep-room.sh hook entry"
fi
if grep -q "Edit|Write|MultiEdit" "$KIT_ROOT/kit/bin/vibe-init" && \
   grep -q "prep-room.sh" "$KIT_ROOT/kit/bin/vibe-init"; then
  ok "kit/bin/vibe-init renders the prep-room hook into project settings"
else
  fail "kit/bin/vibe-init missing prep-room hook"
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