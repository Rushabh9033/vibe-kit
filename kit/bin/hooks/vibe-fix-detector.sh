#!/usr/bin/env bash
# vibe-fix-detector — PreToolUse hook (also runnable as pre-commit). Weapon 4.
#
# Catches "fixed bug reappears" failure mode. Before allowing an Edit/Write,
# scans recent commits for "fix:" patterns. If the current edit touches
# lines that were added in a fix commit, warn loudly (or block, if armed).
#
# Activation: warn-mode is always on. Block-mode is on when `.vibe-cache/armed`.
#
# Heuristic: cheap version (Ponytail: not perfect, but catches obvious cases):
#   - Find recent "fix:" or "bug:" commits in the last 30 days.
#   - For each, list the files they touched.
#   - If the upcoming edit's path is in that list, warn (armed: block).
#
# Smarter-but-deferred version (v0.2): line-level overlap via `git blame`.

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

# Find recent fix: commits' touched files.
FIX_FILES="$(git -C "$PROJECT_ROOT" log --since='30 days ago' \
  --grep='^fix' --grep='^bug' --grep='^hotfix' \
  --pretty=format: --name-only 2>/dev/null | sort -u || true)"

if [ -z "$FIX_FILES" ]; then
  exit 0
fi

if printf '%s\n' "$FIX_FILES" | grep -qxF "$FILE_PATH" 2>/dev/null; then
  RELEVANT_FIXES=$(git -C "$PROJECT_ROOT" log --since='30 days ago' \
    --grep='^fix' --grep='^bug' --grep='^hotfix' \
    --pretty='format:%h %s' -- "$FILE_PATH" 2>/dev/null | head -3 || true)

  ARMED=0
  [ -f "$PROJECT_ROOT/.vibe-cache/armed" ] && ARMED=1

  if [ "$ARMED" -eq 1 ]; then
    cat >&2 <<EOF
[vibe-fix-detector] BLOCKED.

You're editing $FILE_PATH. Recent fix commits touched this file:

$RELEVANT_FIXES

If your edit undoes a fix, you'll re-introduce the bug.

If you're sure this is correct:
  git log -p -- "$FILE_PATH" | less   # review the fix in detail
  vibe-disarm                        # or disable the gate

If you're adding a NEW concern that happens to be in this file:
  proceed by first explaining WHY this edit doesn't undo it.
EOF
    exit 2
  else
    cat >&2 <<EOF
[vibe-fix-detector] WARNING (not armed).

$FILE_PATH was touched by recent fix commits:

$RELEVANT_FIXES

Run \`vibe-arm\` to make this a hard block. Until then, this is a heads-up.
EOF
    exit 0
  fi
fi

exit 0