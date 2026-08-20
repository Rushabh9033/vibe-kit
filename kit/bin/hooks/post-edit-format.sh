#!/usr/bin/env bash
# PostToolUse hook — format files Claude just edited.
# Receives file paths in $CLAUDE_FILE_PATHS (space-separated).
# Hooks must be idempotent and silent on missing tools.
set -e

# $CLAUDE_FILE_PATHS is provided by Claude Code. Fall back to argv[1] for safety.
paths="${CLAUDE_FILE_PATHS:-${1:-}}"
[ -z "$paths" ] && exit 0

format_one() {
  local file="$1"
  case "$file" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.md|*.css|*.html)
      command -v npx >/dev/null && npx --no-install prettier --write "$file" 2>/dev/null || true
      ;;
    *.py)
      command -v ruff >/dev/null && ruff format "$file" 2>/dev/null || true
      ;;
    *.go)
      command -v gofmt >/dev/null && gofmt -w "$file" 2>/dev/null || true
      ;;
    *.sh)
      command -v shfmt >/dev/null && shfmt -w "$file" 2>/dev/null || true
      ;;
    *.rs)
      command -v rustfmt >/dev/null && rustfmt "$file" 2>/dev/null || true
      ;;
    *.rb)
      command -v rubocop >/dev/null && rubocop -a "$file" 2>/dev/null || true
      ;;
  esac
}

for f in $paths; do
  [ -f "$f" ] && format_one "$f" || true
done

exit 0
