# Vibe Coding Protocol — Aider conventions
#
# Aider reads this file on every chat invocation. Drop the kit's full rules
# into AGENTS.md (which this conventions file references) for the canonical
# version.
#
# Auto-detection: vibe-install picks this pack when it sees .aider.conf.yml,
# .aider.chat.history, or CONVENTIONS.md in the cwd, or AIDER_MODEL /
# AIDER_CHAT_HISTORY in the env.

## Always

- Run lint + typecheck + tests before declaring done.
- Reject any new dep that isn't registry-verified (`pip index versions <name>` / `npm view <name>`).
- Document gotchas in `docs/gotchas.md` on discovery.
- Run `kit/bin/vibe-verify` (chat alias: `/run kit/bin/vibe-verify`) before claiming done.
- Update `CHANGELOG.md [Unreleased]` for user-visible changes.
- Write `docs/handoffs/<date>-<slug>.md` at session end (you run the hook manually).

## Never

- Edit committed migrations. → create a new one.
- Disable lint / bypass tests / `--no-verify` without justification.
- Hardcode secrets, tokens, URLs.
- Use TypeScript `any` without justification.
- Commit `.env*` files.
- Run `rm -rf`, force-push, raw disk writes without running `kit/bin/hooks/guard-unsafe.sh` first.

## Two-role model

- **Planner side**: any chat AI + `prompts/`. Save outputs to `docs/`.
- **Coder side**: Aider reads `CONVENTIONS.md` + `AGENTS.md` + `docs/SPEC.md` on every chat.
- **Verifier**: `kit/bin/vibe-verify` (run via `/run` flag).
- Spec is the contract. Update spec before code, not after.

## Per-feature workflow

Aider doesn't auto-load per-feature specs. At chat start, pass them:

```bash
aider --read docs/requirements/<feature>/spec.md \
      --read docs/requirements/<feature>/plan.md
```

Or alias:

```bash
alias vibe="aider --read CONVENTIONS.md \
                --read AGENTS.md \
                --read docs/SPEC.md \
                --read docs/requirements/\$VIBE_FEATURE/spec.md"
```

## What Aider doesn't do

- No PostToolUse-on-Edit auto-format. Use `pre-commit` + `prettier`/`black`.
- No PreToolUse-on-Bash guard. Run the kill list manually before destructive commands.
- No Stop-time handoff automation. End session with `kit/bin/hooks/session-end-handoff.sh`.

## When Aider is the right tool

- Pair-programming feel with tight diff loop.
- Lightweight setup; no daemon, no MCP, no perms.
- Small, spec-bounded changes (one phase of one feature at a time).
