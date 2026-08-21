#!/usr/bin/env bash
# prep-room — PreToolUse hook for the Smart Vibe Coder.
#
# Runs before Edit/Write/MultiEdit. Surfaces relevant context into the
# Coder's stderr stream so it sees recent commits, affected tests, and
# Spec ACs before editing a file.
#
# Hard rules:
#   - MUST complete in <500ms. If git log is slow, fall back to -3.
#   - MUST exit 0 on graceful failure. The Coder is never blocked.
#   - MUST be silent on no-op (no stderr output if there's nothing to say).
#   - Reads stdin for the JSON tool_input from Claude Code; extracts file_path.
#
# stderr output is captured by Claude Code and surfaced to the Coder as
# additional context in the next message.
#
# Usage: invoked by Claude Code's PreToolUse hook. Not run directly.
# For testing: printf '{"tool_input":{"file_path":"src/foo.py"}}' | prep-room.sh

set -uo pipefail

# ---------- read tool input ----------
FILE_PATH=""
if [ ! -t 0 ]; then
  # stdin may carry the tool_input JSON. Use python for portability.
  if command -v python3 >/dev/null 2>&1; then
    FILE_PATH="$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    fp = d.get("tool_input", {}).get("file_path", "")
    if fp:
        print(fp)
except Exception:
    pass
' <&0 2>/dev/null || true)"
  fi
fi

# Fallback: CLI arg (for testing).
if [ -z "$FILE_PATH" ] && [ "${1:-}" != "" ]; then
  FILE_PATH="$1"
fi

# Nothing to do without a file path.
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ---------- project root ----------
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT" 2>/dev/null || exit 0

# ---------- decide what to print ----------
HEADER=""
NEED_NEWLINE=0

print_header() {
  [ "$NEED_NEWLINE" -eq 1 ] && echo
  HEADER="printed"
  NEED_NEWLINE=1
  echo "[prep-room] $1"
}

# 1. Recent commits on the file (only if file exists in the tree).
# NOTE: do not pipe `git log` into `grep -q` under `set -o pipefail`. `grep -q`
# exits with SIGPIPE (rc=141) once it finds its first match, but git is still
# writing — pipefail promotes that to a non-zero pipeline rc, the if condition
# silently evaluates FALSE, and the recent-commits block never prints.
# Capture into a variable first, then check non-empty.
RECENT="$(git -C "$PROJECT_ROOT" log --oneline -3 -- "$FILE_PATH" 2>/dev/null || true)"
if [ -f "$PROJECT_ROOT/$FILE_PATH" ] && [ -n "$RECENT" ]; then
  print_header "editing $FILE_PATH"
  echo "  recent commits on this file:"
  printf '%s\n' "$RECENT" | sed 's/^/    /'
fi

# 2. Affected tests. Search heuristics, in priority order:
#    (a) same dir as the source file
#    (b) parallel tests/<leaf>/ for the source's leaf dir
#    (c) mirror: tests/<stem>/...
# Skip (a) when the file is at repo root (`DIR="."`) to avoid sweeping
# the whole tree — that produces duplicates with (b) and (c).
DIR="$(dirname "$FILE_PATH")"
BASENAME="$(basename "$FILE_PATH")"
STEM="${BASENAME%.*}"
DIR_LEAF="$(basename "$DIR")"
SEARCH_DIRS=()
if [ "$DIR" != "." ] && [ -d "$PROJECT_ROOT/$DIR" ]; then
  SEARCH_DIRS+=("$PROJECT_ROOT/$DIR")
fi
# Parallel tests/<leaf> (e.g. src/auth/login.py → tests/auth/).
if [ -n "$DIR_LEAF" ] && [ "$DIR_LEAF" != "." ] && [ -d "$PROJECT_ROOT/tests/$DIR_LEAF" ]; then
  SEARCH_DIRS+=("$PROJECT_ROOT/tests/$DIR_LEAF")
fi
# Mirror tests/<stem>/... (e.g. tests/login/...).
[ -n "$STEM" ] && [ -d "$PROJECT_ROOT/tests/$STEM" ] && SEARCH_DIRS+=("$PROJECT_ROOT/tests/$STEM")

TESTS=()
SEEN=""
# `${ARRAY[@]+"${ARRAY[@]}"}` makes `set -u` happy with empty arrays.
for sd in ${SEARCH_DIRS[@]+"${SEARCH_DIRS[@]}"}; do
  while IFS= read -r -d '' t; do
    [ "${#TESTS[@]}" -ge 10 ] && break 2
    # De-dupe by absolute path. `find` may emit the same file from
    # overlapping search roots (e.g. tests/. and tests/auth).
    case "$SEEN" in
      *"|$t|"*) continue ;;
    esac
    SEEN="$SEEN|$t|"
    TESTS+=("$t")
  done < <(find "$sd" -maxdepth 3 -type f \( \
      -name "test_*" -o -name "*_test.*" -o -name "*.test.*" -o -name "*.spec.*" \
    \) -print0 2>/dev/null)
done

if [ "${#TESTS[@]}" -gt 0 ]; then
  [ "$NEED_NEWLINE" -eq 0 ] && print_header "editing $FILE_PATH"
  echo "  affected tests:"
  for t in "${TESTS[@]}"; do
    # Strip both `$PROJECT_ROOT/` and `./` so paths render cleanly.
    rel="${t#$PROJECT_ROOT/}"
    rel="${rel#./}"
    printf '    %s\n' "$rel"
  done
fi

# 3. Spec ACs (only if we're under docs/requirements or src/).
SPEC=""
for f in "$PROJECT_ROOT/docs/requirements"/*/spec.md; do
  [ -f "$f" ] || continue
  # crude heuristic: if the file path contains the feature slug, this is its spec.
  slug="$(basename "$(dirname "$f")")"
  case "$FILE_PATH" in
    *"$slug"*)  SPEC="$f"; break ;;
  esac
done
# Fallback: pick the most recently modified spec.
if [ -z "$SPEC" ]; then
  SPEC="$(ls -t "$PROJECT_ROOT/docs/requirements"/*/spec.md 2>/dev/null | head -1 || true)"
fi

if [ -n "$SPEC" ] && [ -f "$SPEC" ]; then
  # Pull the Acceptance Criteria block. Use a flag pattern, not `/start/,/end/`
  # — BWK awk on macOS stops at the start match if the end pattern never
  # appears in the file, silently dropping every AC line.
  ACS="$(awk '
    /^## Acceptance Criteria/ { in_ac = 1; next }
    /^## /                    { in_ac = 0 }
    in_ac && /^- AC[0-9]/      { print }
  ' "$SPEC" 2>/dev/null)"
  if [ -n "$ACS" ]; then
    [ "$NEED_NEWLINE" -eq 0 ] && print_header "editing $FILE_PATH"
    slug="$(basename "$(dirname "$SPEC")")"
    echo "  relevant ACs (from $slug/spec.md):"
    printf '%s\n' "$ACS" | head -8 | sed 's/^/    /'
  fi
fi

# If absolutely nothing was printed (no git, no tests, no spec), exit silently.
[ "$NEED_NEWLINE" -eq 0 ] && exit 0

exit 0
