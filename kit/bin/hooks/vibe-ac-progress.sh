#!/usr/bin/env bash
# vibe-ac-progress — PostToolUse hook. Weapon 5.
#
# Telemetry layer: after each Edit/Write, parses the project's most-recent
# feature spec, counts acceptance criteria, and surfaces the progress to
# the Coder as additional context.
#
# Always runs (not gated on `armed`) — useful even without the gates.
# Surface is "telemetry, not enforcement." Cheap (<50ms on a 50-AC spec).
#
# Also records every edit to `.vibe-cache/session-edits` so the
# vibe-tdd-gate can check whether a corresponding test file has been
# touched this session.
#
# Output format (one line per spec section, to stdout):
#   [vibe-ac] <feature>: <done>/<total> ACs done · next: <AC id> <one-liner>
#
# "Done" heuristic: the AC's `automated test:` path appears in the git diff
# (added or modified). Crude but matches what /vibe-verify checks.

set -uo pipefail

# Read tool_input to know which file was just edited (for session-edits).
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

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT" 2>/dev/null || exit 0

# Record the edit for the tdd-gate.
if [ -n "$FILE_PATH" ]; then
  mkdir -p "$PROJECT_ROOT/.vibe-cache"
  printf '%s\n' "$FILE_PATH" >> "$PROJECT_ROOT/.vibe-cache/session-edits"
  # Trim to last 200 lines (avoid unbounded growth).
  if [ -f "$PROJECT_ROOT/.vibe-cache/session-edits" ]; then
    tail -n 200 "$PROJECT_ROOT/.vibe-cache/session-edits" > "$PROJECT_ROOT/.vibe-cache/session-edits.tmp" \
      && mv "$PROJECT_ROOT/.vibe-cache/session-edits.tmp" "$PROJECT_ROOT/.vibe-cache/session-edits"
  fi
fi

# Pick the most-recently-modified feature spec.
SPEC="$(ls -t "$PROJECT_ROOT/docs/requirements"/*/spec.md 2>/dev/null | head -1 || true)"
[ -z "$SPEC" ] && exit 0
[ -f "$SPEC" ] || exit 0

slug="$(basename "$(dirname "$SPEC")")"

# Extract AC IDs and their `automated test:` paths. Bash 3.2 (macOS default)
# doesn't have `mapfile` — use a while-read loop into the array.
AC_LINES=()
while IFS= read -r line; do
  [ -n "$line" ] && AC_LINES+=("$line")
done < <(awk '
  /^## Acceptance Criteria/ { in_ac = 1; next }
  /^## /                   { in_ac = 0 }
  in_ac && /^- AC[0-9]+/ {
    sub(/^- /, "")
    # First token is "AC1." or "AC1:" — keep it on the same line as the body.
    printf "%s\n", $0
  }
' "$SPEC")

# Compute done count by checking which AC test paths appear in the diff.
DIFF_PATHS="$(git -C "$PROJECT_ROOT" diff --name-only HEAD 2>/dev/null || true)"
STAGED_PATHS="$(git -C "$PROJECT_ROOT" diff --cached --name-only 2>/dev/null || true)"
ALL_PATHS="$(printf '%s\n%s\n' "$DIFF_PATHS" "$STAGED_PATHS" | sort -u)"

total=0; done=0; next_id=""
# `${ARR[@]+...}` so empty arrays don't trigger `unbound variable`.
for line in ${AC_LINES[@]+"${AC_LINES[@]}"}; do
  [ -z "$line" ] && continue
  # Format: "AC1. <description>". Split on first whitespace.
  id="$(printf '%s' "$line" | sed -nE 's/^(AC[0-9]+)\..*/\1/p' | head -1)"
  [ -z "$id" ] && continue
  total=$((total + 1))
  # Heuristic: any "tests/<X>" substring in the line counts as a test ref.
  test_path="$(printf '%s' "$line" | grep -oE 'tests?/[^[:space:]]+' | head -1 || true)"
  if [ -n "$test_path" ] && printf '%s\n' "$ALL_PATHS" | grep -qF "$test_path"; then
    done=$((done + 1))
  elif [ -z "$next_id" ]; then
    next_id="$id"
  fi
done

if [ "$total" -eq 0 ]; then
  printf '[vibe-ac] %s: spec has no Acceptance Criteria. Run vibe-spec-intake.\n' "$slug"
elif [ "$done" -eq "$total" ]; then
  printf '[vibe-ac] %s: %d/%d ACs done. Ready for /vibe-verify.\n' "$slug" "$done" "$total"
else
  printf '[vibe-ac] %s: %d/%d ACs done · next: %s\n' "$slug" "$done" "$total" "$next_id"
fi
exit 0