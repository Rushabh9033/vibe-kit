#!/usr/bin/env bash
# vibe-edit-gate — PreToolUse hook. Weapon 2.
#
# Hard gate: blocks Edit/Write/MultiEdit unless the Coder has declared an
# active Acceptance Criterion. Forces the AI to think in ACs, not files.
#
# Activation: only fires when `.vibe-cache/armed` exists in the project root.
# `vibe-arm` writes that marker; `vibe-disarm` removes it. Off by default.
#
# Active AC: stored in `.vibe-cache/current-ac` (the AC id, e.g. "AC3").
# The Coder writes the file via `vibe-ac-set <id>` (or by hand) before editing.
#
# When armed + no current AC:
#   - Exits 2 (BLOCK per Claude Code's hook convention).
#   - Prints to stderr: which spec to look at + how to set the AC.
#   - The edit does NOT happen.
#
# When armed + current AC set:
#   - Exits 0. Edit proceeds. Prep-room gets a chance to surface context.
#
# When not armed:
#   - Exits 0 silently. Same as today's behavior.

set -uo pipefail

# Read tool_input JSON from stdin; extract file_path.
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

# Gate only fires when armed.
[ -f "$PROJECT_ROOT/.vibe-cache/armed" ] || exit 0

# Don't block meta-edits inside the kit itself (docs/SPEC.md, CHANGELOG.md,
# the kit's own settings). Specs, plans, ADRs are how the developer declares
# intent — blocking them would be circular.
case "$FILE_PATH" in
  docs/*|CHANGELOG.md|README.md|.vibe-cache/*|kit/*) exit 0 ;;
esac

CURRENT_AC=""
[ -f "$PROJECT_ROOT/.vibe-cache/current-ac" ] && CURRENT_AC="$(cat "$PROJECT_ROOT/.vibe-cache/current-ac" 2>/dev/null || true)"

if [ -z "$CURRENT_AC" ]; then
  # Find the most recent spec to suggest.
  SPEC="$(ls -t "$PROJECT_ROOT/docs/requirements"/*/spec.md 2>/dev/null | head -1 || true)"
  SPEC_HINT=""
  if [ -n "$SPEC" ]; then
    slug="$(basename "$(dirname "$SPEC")")"
    SPEC_HINT=" (current spec: docs/requirements/$slug/spec.md)"
  fi
  cat >&2 <<EOF
[vibe-edit-gate] BLOCKED.

No active Acceptance Criterion. Declare one before editing source.

  echo "AC3" > .vibe-cache/current-ac      # pick the AC you're implementing
  vibe-ac-set AC3                          # or use this helper

Read$SPEC_HINT first. Each AC is one test, one change.

If this edit truly isn't covered by any AC (e.g. refactor), run:
  vibe-disarm
EOF
  exit 2
fi

# Armed + AC declared → allow.
exit 0