# Vibe Coding Protocol — Codex config
#
# OpenAI Codex CLI reads `AGENTS.md` at the project root.
#
# Auto-detection: vibe-install picks this pack when it sees .codex/ in the cwd,
# or CODEX_SESSION_ID / CODEX_HOME in the env.

## Always

- Run lint + typecheck + tests before declaring done.
- Reject any new dep that isn't registry-verified and license-audited.
- Document gotchas in `docs/gotchas.md` on discovery.
- Run `kit/bin/vibe-verify` before claiming done on any user-visible feature.
- Update `CHANGELOG.md [Unreleased]` for user-visible changes.
- Write `docs/handoffs/<date>-<slug>.md` at session end.

## Never

- Edit committed migrations. → create a new one.
- Disable lint / bypass tests / `--no-verify` without justification.
- Hardcode secrets, tokens, URLs.
- Use TypeScript `any` without justification.
- Commit `.env*` files.
- `rm -rf`, force-push, raw disk writes. → Codex must run `kit/bin/hooks/guard-unsafe.sh` first.

## Two-role model

- **Planner side**: any chat AI + `prompts/`.
- **Coder side**: Codex reads `AGENTS.md` + `docs/SPEC.md` on every command.
- **Verifier**: `kit/bin/vibe-verify` (run manually; Codex has no hook model).
- The user bridges Planner → Coder. The spec is the bridge between intent and code.

## Codex notes

Codex CLI's hook model is experimental. Check upstream `~/.codex/config.toml` for current support. Until hooks land, manual enforcement only:

- Run `kit/bin/vibe-verify` before each commit.
- Run `kit/bin/hooks/guard-unsafe.sh` before destructive bash.
- Run `kit/bin/hooks/session-end-handoff.sh` at session end.
