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
# Throttle: by default, no more than one handoff per 10 minutes. Set
# VIBE_HANDOFF_THROTTLE=0 to disable. When throttled, prints "throttled"
# on stderr and writes nothing — the Stop-hook prompt no-ops on that signal.
#
# Per-invocation uniqueness within the throttle window: if a file for the
# current date+slug already exists at the resolved path, a uniqueness suffix
# is appended so multiple Stop fires inside one "real" session still get
# recorded. The throttle happens BEFORE uniqueness, so the throttle window
# is real wall-clock minutes, not "minutes between unique writes".

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

# Refuse if cwd-base contains unsafe characters (we control the path here;
# but be defensive against weirdness in $HOME or cwd paths).
case "$target_dir" in
  *..*) exit 0 ;;  # silently no-op rather than write somewhere weird
esac

mkdir -p "$target_dir"

# Throttle: skip writes that fall inside the throttle window.
# Rationale: Stop hook fires after every assistant message. Without throttle,
# a long back-and-forth (user ack → agent ack → user ack → ...) produces a
# new handoff file per turn, each of which the agent then re-reads and fills
# in — burning tokens for no information gain. Default 600s (10 min).
THROTTLE_SECONDS="${VIBE_HANDOFF_THROTTLE:-600}"
if [ "$THROTTLE_SECONDS" -gt 0 ]; then
  marker="$target_dir/.last-handoff-epoch"
  if [ -f "$marker" ]; then
    last_epoch="$(cat "$marker" 2>/dev/null || echo 0)"
    now_epoch="$(date +%s)"
    if [ "$last_epoch" -gt 0 ] && [ $((now_epoch - last_epoch)) -lt "$THROTTLE_SECONDS" ]; then
      echo "vibe-kit: handoff throttled (last write $((now_epoch - last_epoch))s ago, window ${THROTTLE_SECONDS}s)" >&2
      exit 0
    fi
  fi
  date +%s > "$marker"
fi

filepath="$target_dir/${date}-${slug}.md"

# Per-invocation uniqueness: if a handoff for this date+slug already
# exists, append a uniqueness suffix so each Stop-hook fire produces a
# fresh artifact (the "idempotent skip" hides multi-session days).
if [ -f "$filepath" ]; then
  uniqueness="${CLAUDE_SESSION_ID:-}"
  uniqueness="$(printf '%s' "$uniqueness" | cut -c1-8)"
  [ -z "$uniqueness" ] && uniqueness="epoch-$(date +%s)-$$"
  filepath="$target_dir/${date}-${slug}-${uniqueness}.md"
fi

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
