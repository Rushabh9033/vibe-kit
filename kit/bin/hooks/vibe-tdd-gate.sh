#!/usr/bin/env bash
# vibe-tdd-gate — PreToolUse hook. Weapon 3.
#
# Hard gate: blocks Edit on `src/<X>.py` (or other source dirs) unless a
# corresponding test file (`tests/<X>/test_<Y>.py` etc.) has been edited
# in the same session. Forces test-first or test-along behavior.
#
# Activation: only fires when `.vibe-cache/armed` exists. Off by default.
#
# State: `.vibe-cache/session-edits` records files edited this session
# (one path per line). The Coder (or another hook, e.g. PostToolUse)
# appends to it after every successful Edit. On armed Edit to src/X,
# we check whether ANY test file matching X has been touched.
#
# When armed + src/ edit + no matching test edit:
#   - Exits 2 (BLOCK). The Coder must write the test first.
#
# When armed + src/ edit + matching test was edited:
#   - Exits 0. Edit proceeds.
#
# When not armed or not a src/ edit:
#   - Exits 0 silently.

set -uo pipefail

FILE_PATH=""
if [ ! -t 0 ] && command -v python3 >/dev/null 2>&1; then
  FILE_PATH="$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
' <&0 2>/dev/null || true)"
fi
[ -z "$FILE_PATH" ] && [ "${1:-}" != "" ] && FILE_PATH="$1"
[ -z "$FILE_PATH" ] && exit 0

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT" 2>/dev/null || exit 0

[ -f "$PROJECT_ROOT/.vibe-cache/armed" ] || exit 0

# Only gate source files. Tests, docs, config, and the kit itself are free.
case "$FILE_PATH" in
  tests/*|.vibe-cache/*|docs/*|*.md|*.json|*.yml|*.yaml|*.toml|*.cfg|*.ini|kit/*) exit 0 ;;
esac

# Extract basename without extension (foo from src/auth/foo.py).
BASENAME="$(basename "$FILE_PATH")"
STEM="${BASENAME%.*}"
[ -z "$STEM" ] && exit 0

# Look through session-edits for ANY test file mentioning the same stem.
# Match by either substring (test_foo.py → "foo") or directory (tests/foo/
# → "foo"). Use grep -F so the STEM is a literal — no regex pitfalls.
SESSION_FILE="$PROJECT_ROOT/.vibe-cache/session-edits"
if [ -f "$SESSION_FILE" ] && grep -qF "$STEM" "$SESSION_FILE" 2>/dev/null; then
  exit 0
fi

# Block.
cat >&2 <<EOF
[vibe-tdd-gate] BLOCKED.

Editing $FILE_PATH, but no test file for "$STEM" has been edited this session.

Write the test first, then the implementation:

  tests/test_${STEM}.py           # if there's one
  tests/${STEM}/test_*.py         # if there's a directory

Or, if this isn't a unit (e.g. config, scaffolding), run:
  vibe-disarm
EOF
exit 2