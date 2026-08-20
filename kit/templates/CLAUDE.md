# CLAUDE.md

@AGENTS.md

## Claude Code specifics
- Use plan mode (Shift+Tab) for any non-trivial change in /auth, /billing, /security.
- Run `/vibe-verify` before claiming "done" on any user-visible feature.
- Run `/vibe-handoff` before ending any session that touched code.
- Hooks active: format-on-edit (PostToolUse), guard-unsafe (PreToolUse on Bash), Stop-handoff prompt.
- Slash commands global: `/vibe-init`, `/vibe-spec`, `/vibe-plan`, `/vibe-verify`, `/vibe-ship`, `/vibe-handoff`, `/vibe-decide`, `/vibe-review-pr`.
