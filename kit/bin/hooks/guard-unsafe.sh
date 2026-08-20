#!/usr/bin/env bash
# Pre-tool-use guard for Bash. Blocks destructive patterns.
# Reads JSON from stdin: {"tool_input":{"command":"..."}}
# Outputs JSON for Claude Code hook protocol:
#   {"decision":"block","reason":"..."} to block
#   {"decision":"approve"} to allow
set -euo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import json,sys
try:
  d=json.load(sys.stdin)
  print(d.get("tool_input",{}).get("command",""))
except Exception:
  print("")')"

if [ -z "$cmd" ]; then
  echo '{"decision":"approve"}'
  exit 0
fi

# Block destructive patterns.
# Each case must explain why.
case "$cmd" in
  *'rm -rf /'*)            echo '{"decision":"block","reason":"recursive rm on filesystem root"}' ; exit 0 ;;
  *'rm -rf ~/'*)           echo '{"decision":"block","reason":"recursive rm on home directory"}' ; exit 0 ;;
  *'rm -rf \$HOME/'*)      echo '{"decision":"block","reason":"recursive rm on home directory"}' ; exit 0 ;;
  *'git push --force'*)    echo '{"decision":"block","reason":"force-push; ask user"}' ; exit 0 ;;
  *'git push -f '*)        echo '{"decision":"block","reason":"force-push; ask user"}' ; exit 0 ;;
  *'git push -fu'*)        echo '{"decision":"block","reason":"force-push; ask user"}' ; exit 0 ;;
  *':(){:|:&};:'*)         echo '{"decision":"block","reason":"fork bomb"}' ; exit 0 ;;
  *'mkfs.'*)               echo '{"decision":"block","reason":"filesystem format"}' ; exit 0 ;;
  *'dd if='*)              echo '{"decision":"block","reason":"raw disk write"}' ; exit 0 ;;
  *'curl '*|'wget '*|'http'*) # pass-through, allow
    ;;
esac

# Warn (but allow) on chmod 777, force-flag builds
if echo "$cmd" | grep -qE 'chmod [0-7]*7[0-7]* '; then
  echo '{"decision":"approve","reason":"allow but noted: chmod 7xx broadens perms"}'
  exit 0
fi

echo '{"decision":"approve"}'
