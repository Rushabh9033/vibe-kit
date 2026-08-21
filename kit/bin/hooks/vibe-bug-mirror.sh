#!/usr/bin/env bash
# vibe-bug-mirror — Stop hook. Weapon 7.
#
# Tracks time spent in each phase (spec, code, test, fix) during a session.
# At session end, prints "% time fixing vs building" so the developer
# sees the cost of bad specs.
#
# Cheap to record (one timestamp per phase transition). Free to ignore
# (the output goes to stdout; the Stop hook capture already runs).

set -uo pipefail

# Read session info from stdin if piped (the hook contract).
[ ! -t 0 ] && cat >/dev/null 2>&1 || true

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT" 2>/dev/null || exit 0

CACHE="$PROJECT_ROOT/.vibe-cache"
LOG="$CACHE/phase-log"
mkdir -p "$CACHE"
[ -f "$LOG" ] || printf 'start\t%s\n' "$(date +%s)" > "$LOG"

# On Stop, finalize the session. Compute elapsed time per phase.
NOW="$(date +%s)"
START="$(awk -F'\t' '$1=="start"{print $2; exit}' "$LOG")"
[ -z "$START" ] && exit 0
ELAPSED=$((NOW - START))
[ "$ELAPSED" -lt 60 ] && { printf '%s\n' "session < 60s — no mirror."; exit 0; }

# Phase breakdown from commit timestamps within this session window.
# Heuristic: commits in the last 4h are "this session".
SINCE="$(date -u -v-4H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d '4 hours ago' +%Y-%m-%dT%H:%M:%S)"
COMMITS="$(git -C "$PROJECT_ROOT" log --since="$SINCE" --pretty=format:'%h\t%s' 2>/dev/null || true)"

spec_t=0; code_t=0; test_t=0; fix_t=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  msg="$(printf '%s' "$line" | cut -f2-)"
  case "$msg" in
    spec:*|Spec:*|spec )   spec_t=$((spec_t + 1)) ;;
    test:*|Test:*|tests:* ) test_t=$((test_t + 1)) ;;
    fix:*|bug:*|hotfix:*|Fix:* ) fix_t=$((fix_t + 1)) ;;
    * )                   code_t=$((code_t + 1)) ;;
  esac
done <<< "$COMMITS"

total=$((spec_t + code_t + test_t + fix_t))
if [ "$total" -eq 0 ]; then
  printf '%s\n' "no commits this session — no mirror."
  exit 0
fi

spec_pct=$((spec_t * 100 / total))
code_pct=$((code_t * 100 / total))
test_pct=$((test_t * 100 / total))
fix_pct=$((fix_t * 100 / total))

printf '\n[vibe-bug-mirror] session: %d commits over %ds\n' "$total" "$ELAPSED"
printf '  spec: %d (%d%%)\n'  "$spec_t"  "$spec_pct"
printf '  code: %d (%d%%)\n'  "$code_t"  "$code_pct"
printf '  test: %d (%d%%)\n'  "$test_t"  "$test_pct"
printf '  fix:  %d (%d%%)\n'  "$fix_t"   "$fix_pct"
printf '\n'

# The headline number: how much of the session was fixing vs building.
fix_ratio=$((fix_pct))
if [ "$fix_ratio" -gt 25 ]; then
  printf '  → %d%% of commits were fixes. The Spec had unstated requirements.\n' "$fix_ratio"
  printf '    Next session: tighten the Spec before coding more.\n'
else
  printf '  → fix ratio %d%% — under the 25%% threshold. Healthy session.\n' "$fix_ratio"
fi

# Reset for next session.
rm -f "$LOG"
exit 0