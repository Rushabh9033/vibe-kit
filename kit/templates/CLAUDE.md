# CLAUDE.md

@AGENTS.md

## Spec-first gate (run at every task start)

> **Planner is optional. Spec-first is not.**

You (the Coder) are also the requirements-discovery agent when no applicable Spec exists. At every task start, before touching code:

1. Trivial change (`vibe-classify: tiny`) → proceed without a Spec.
2. Existing `docs/requirements/<feature>/spec.md` with `Status: in-progress` → resume.
3. Existing Spec with `Status: awaiting-approval` → stop; user must set `Status: in-progress`.
4. No applicable Spec, non-trivial work → **enter DISCOVERY MODE** (see `prompts/00-anchor.md` § Discovery protocol). One question at a time. Then write the Spec with `Status: awaiting-approval` and **stop**. Do NOT implement in the same turn.
5. After the user sets `Status: in-progress`, re-read the Spec, optionally write `plan.md`, then implement.

Canonical source for the gate: `kit/templates/spec-first-gate.md`.

## Claude Code specifics
- Use plan mode (Shift+Tab) for any non-trivial change in /auth, /billing, /security.
- Run `/vibe-verify` before claiming "done" on any user-visible feature.
- Run `/vibe-handoff` before ending any session that touched code.
- Hooks active: format-on-edit (PostToolUse), guard-unsafe (PreToolUse on Bash), Stop-handoff prompt.
- Slash commands global: `/vibe-init`, `/vibe-spec`, `/vibe-plan`, `/vibe-verify`, `/vibe-ship`, `/vibe-handoff`, `/vibe-decide`, `/vibe-review-pr`.
