#!/usr/bin/env bash
# Stop hook — writes a session handoff stub RELIABLY, regardless of cwd.
# Rationale: a prompt-only hook can be silently skipped. A command-hook that
# touches disk always lands.
#
# Resolution order:
#   1. cwd/docs/handoffs/         (project-primary; VCP default)
#   2. cwd/.claude/handoffs/      (project-secondary)
#   3. $HOME/.claude/projects/<cwd-base>/handoffs/  (global fallback)
#
# Writes only if the file doesn't exist (idempotent — don't clobber).
# The agent (via the Stop hook prompt) is then asked to enrich the stub.

set -euo pipefail

date="$(date +%Y-%m-%d)"
time="$(date +%H:%M:%S)"
session_id="${CLAUDE_SESSION_ID:-unknown}"
cwd="$(pwd)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')"
slug="$(printf '%s' "$branch" | tr '/' '-')"
# Append session id so per-session artifacts don't clobber each other.
if [ "$session_id" != "unknown" ]; then
  short_sid="$(printf '%s' "$session_id" | cut -c1-8)"
  slug="${slug}-${short_sid}"
fi
[ -z "$slug" ] && slug="no-branch"

target_dir=""
if [ -d "$cwd/docs/handoffs" ]; then
  target_dir="$cwd/docs/handoffs"
elif [ -d "$cwd/.claude/handoffs" ]; then
  target_dir="$cwd/.claude/handoffs"
else
  base="$(basename "$cwd")"
  target_dir="$HOME/.claude/projects/$base/handoffs"
fi

mkdir -p "$target_dir"
filepath="$target_dir/${date}-${slug}.md"

# Idempotent: skip if file already exists.
[ -f "$filepath" ] && exit 0

# Refuse if cwd-base contains unsafe characters (we control the path here;
# but be defensive against weirdness in $HOME or cwd paths).
case "$target_dir" in
  *..*) exit 0 ;;  # silently no-op rather than write somewhere weird
esac

cat > "$filepath" <<EOF
# Session: ${date} — ${slug}

> Stub written by Stop hook (\`session-end-handoff.sh\`).
> Next: the agent should fill in the sections below.

## Goal
<!-- What was set out — link to spec/feature. -->

## Branch / state
\`${branch}\` based on \`<base>\`; clean | dirty

## Done
- [ ]

## In progress
- ...

## Blocked
- ...

## Files touched
- ...

## Decisions made
- **Decision**: ...

## Decisions needed
- **Decision**: ...

## Verification
- [ ] <test cmd> — pass | fail
- [ ] <lint cmd> — pass
- [ ] <typecheck cmd> — pass

## Next steps for next session
1. ...

## Gotchas learned
- ...

<!-- context metadata (do not edit) -->
- session_id: ${session_id}
- started: ${date}T${time}
- cwd: ${cwd}
- branch: ${branch}
- written_by: vibe-kit/Stop-hook (command)
EOF

echo "vibe-kit: stub handoff written to ${filepath}" >&2
exit 0
