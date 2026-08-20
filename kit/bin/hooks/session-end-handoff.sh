#!/usr/bin/env bash
# Stop hook — writes a session handoff RELIABLY, regardless of cwd.
#
# v2: this script is now the entire handoff mechanism. It runs as a
# command-type Stop hook and writes a filled-in handoff directly. There
# is no companion prompt — the assistant is not asked to fill anything
# in, so the prompt-error loop is gone.
#
# Resolution order for the handoff directory:
#   1. cwd/docs/handoffs/         (project-primary; VCP default)
#   2. cwd/.claude/handoffs/      (project-secondary)
#   3. $HOME/.claude/projects/<cwd-base>/handoffs/  (global fallback)
#
# Throttle: by default, no more than one handoff per 10 minutes. Set
# VIBE_HANDOFF_THROTTLE=0 to disable. When throttled, the script exits
# 0 SILENTLY — no stderr, no prompt, no error.
#
# Per-invocation uniqueness within the throttle window: if a file for the
# current date+slug already exists at the resolved path, a uniqueness suffix
# is appended so multiple Stop fires inside one "real" session still get
# recorded. The throttle happens BEFORE uniqueness.
#
# What the script fills in (shell can determine):
#   - Goal: link to docs/SPEC.md or "unknown — left for next session"
#   - Branch / state: branch name + dirty/clean + ahead/behind
#   - Done: shortlog of commits by this session (since last tag, last hour)
#   - Files touched: git diff --name-only against last commit / HEAD
#   - Verification: status of common test/lint/typecheck commands
#   - Gotchas: any commit messages containing "gotcha" or "trap"
#   - Next steps: files-modified-since-N-min as a hint
#   - Field the script CAN'T determine (e.g. subjective "Decisions made"):
#     "unknown — left for next session"

set -euo pipefail

date="$(date +%Y-%m-%d)"
time="$(date +%H:%M:%S)"
session_id="${CLAUDE_SESSION_ID:-unknown}"
cwd="$(pwd)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')"
slug="$(printf '%s' "$branch" | tr '/' '-')"
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

case "$target_dir" in
  *..*) exit 0 ;;
esac

mkdir -p "$target_dir"

# --- Throttle (silent on hit) ---
THROTTLE_SECONDS="${VIBE_HANDOFF_THROTTLE:-600}"
if [ "$THROTTLE_SECONDS" -gt 0 ]; then
  marker="$target_dir/.last-handoff-epoch"
  if [ -f "$marker" ]; then
    last_epoch="$(cat "$marker" 2>/dev/null || echo 0)"
    now_epoch="$(date +%s)"
    if [ "$last_epoch" -gt 0 ] && [ $((now_epoch - last_epoch)) -lt "$THROTTLE_SECONDS" ]; then
      exit 0   # silent: no stderr, no exit code, no prompt
    fi
  fi
  date +%s > "$marker"
fi

# --- Per-invocation uniqueness ---
filepath="$target_dir/${date}-${slug}.md"
if [ -f "$filepath" ]; then
  uniqueness="${CLAUDE_SESSION_ID:-}"
  uniqueness="$(printf '%s' "$uniqueness" | cut -c1-8)"
  [ -z "$uniqueness" ] && uniqueness="epoch-$(date +%s)-$$"
  filepath="$target_dir/${date}-${slug}-${uniqueness}.md"
fi

# --- Collect what the shell can determine ---

# Branch state
branch_state="clean"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  branch_state="dirty"
fi
ahead_behind=""
ab="$(git rev-list --left-right --count '@{u}...HEAD' 2>/dev/null || true)"
if [ -n "$ab" ]; then
  ahead_behind=" (ahead $(echo "$ab" | cut -f2), behind $(echo "$ab" | cut -f1))"
fi

# Recent commits (last 10 in this session-window: today or last 4 hours)
recent_commits="$(git log --since='4 hours ago' --pretty=format:'- %s' 2>/dev/null | head -10)"
if [ -z "$recent_commits" ]; then
  recent_commits="- (no commits in the last 4 hours)"
fi

# Files touched (modified vs HEAD)
files_touched=""
if [ "$branch_state" = "dirty" ]; then
  files_touched="$(git status --porcelain 2>/dev/null | sed 's/^...//' | head -20)"
fi
if [ -z "$files_touched" ]; then
  files_touched="- (none — working tree clean)"
fi

# Verification — only run if the manifests exist; look-and-leave otherwise
verify_lines=""
[ -f package.json ]    && verify_lines="${verify_lines}- [ ] npm test — $(test -d node_modules && echo 'runnable' || echo 'needs install')\n"
[ -f pyproject.toml ]  || [ -f requirements.txt ] && verify_lines="${verify_lines}- [ ] pytest — $(command -v pytest >/dev/null && echo 'runnable' || echo 'needs install')\n"
[ -f go.mod ]          && verify_lines="${verify_lines}- [ ] go test ./...\n"
[ -f Cargo.toml ]      && verify_lines="${verify_lines}- [ ] cargo test\n"
[ -f Makefile ]        && verify_lines="${verify_lines}- [ ] make test\n"
if [ -z "$verify_lines" ]; then
  verify_lines="- (no test runner detected — package.json / pyproject.toml / go.mod / Cargo.toml)"
fi

# Gotchas — last commit messages matching "gotcha" or "trap" or "fix"
gotchas="$(git log --oneline --grep='gotcha\|trap\|fix\|bug' --since='24 hours ago' 2>/dev/null | head -5 | sed 's/^/- /')"
if [ -z "$gotchas" ]; then
  gotchas="- (none in last 24h)"
fi

# Goal — link to spec if it exists
goal_link=""
[ -f "$cwd/docs/SPEC.md" ] && goal_link="$cwd/docs/SPEC.md"
spec_link_line="- Goal: see [$([ -n "$goal_link" ] && echo 'docs/SPEC.md' || echo 'unknown — left for next session')]($([ -n "$goal_link" ] && echo 'docs/SPEC.md' || echo '#'))"

# --- Write the handoff ---
cat > "$filepath" <<EOF
# Session: ${date} — ${slug}

## Goal
${spec_link_line}

## Branch / state
\`${branch}\` — ${branch_state}${ahead_behind}

## Done
${recent_commits}

## In progress
- unknown — left for next session

## Blocked
- unknown — left for next session

## Files touched
${files_touched}

## Decisions made
- unknown — left for next session

## Decisions needed
- unknown — left for next session

## Verification
$(printf '%b' "$verify_lines")

## Next steps for next session
1. unknown — left for next session
2. Re-run \`./kit/bin/vibe-verify\` to confirm AC↔code↔tests still hold.
3. If this handoff's "Done" list is empty and the script couldn't detect commits, fill in manually based on session memory.

## Gotchas learned
${gotchas}

<!-- context metadata (do not edit) -->
- session_id: ${session_id}
- started: ${date}T${time}
- cwd: ${cwd}
- branch: ${branch}
- written_by: vibe-kit/Stop-hook (command, self-filling)
EOF
