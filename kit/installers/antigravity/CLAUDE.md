# Vibe Coding Protocol — Antigravity config
#
# Antigravity reads `.claude/rules/`-compatible markdown files and supports
# slash-command-style invocations. The kit drops in directly via the
# standard Claude Code layout.
#
# Auto-detection: vibe-install picks this pack when it sees .agent/ or
# .antigravity in the cwd, or ANTIGRAVITY_SESSION / ANTIGRAVITY_WORKSPACE
# in the env.

## Always

- Run lint + typecheck + tests before declaring done.
- Reject any new dep that isn't registry-verified and license-audited.
- Document gotchas in `docs/gotchas.md` on discovery.
- Run `/vibe-verify` before claiming done on any user-visible feature.
- Update `CHANGELOG.md [Unreleased]` for user-visible changes.
- Write `docs/handoffs/<date>-<slug>.md` at session end.

## Never

- Edit committed migrations. → create a new one.
- Disable lint / bypass tests / `--no-verify` without justification.
- Hardcode secrets, tokens, URLs.
- Use TypeScript `any` without justification.
- Commit `.env*` files.
- `rm -rf`, force-push, raw disk writes. → Antigravity's policy runner should block; if not, run `kit/bin/hooks/guard-unsafe.sh` first.

## Spec-first gate (run at every task start)

> **Planner is optional. Spec-first is not.**

Antigravity is the implementation agent **and** the requirements-discovery agent when no applicable Spec exists. Run the gate at `kit/templates/spec-first-gate.md`:

1. Trivial change → proceed without a Spec.
2. Existing in-progress Spec → resume.
3. Awaiting-approval Spec → stop; the user must set `Status: in-progress`.
4. No applicable Spec, non-trivial work → enter DISCOVERY MODE (`prompts/00-anchor.md` § Discovery protocol). One question at a time. Then write `docs/requirements/<feature>/spec.md` with `Status: awaiting-approval` and **stop**. Do NOT implement in the same turn.
5. After approval, implement.

The user is the human-approval gate, not a paste-bridge.

## Two-role model (Planner optional)

- **Planner side** *(optional)*: any chat AI + `prompts/`.
- **Coder side**: Antigravity reads `.claude/rules/` + `.claude/commands/` + `AGENTS.md`. **If no applicable Spec exists, runs Discovery itself** (see spec-first gate above).
- **Verifier**: `kit/bin/vibe-verify` (run manually; check Antigravity's command-runner for an auto-fire option).
- The Spec is the bridge between intent and code. The Planner is one way to produce it.

## Antigravity divergence notes

Antigravity's auto-format / auto-review features replace the PostToolUse hook from `kit/settings.json`. The PreToolUse-on-Bash guard is enforced through a command-runner-level policy, not Bash itself — set it in your Antigravity workspace settings if available.

When Antigravity diverges from Claude Code's hook model, fall back to the kill list in `AGENTS.md` and review PRs through `/vibe-review-pr` style checks.
