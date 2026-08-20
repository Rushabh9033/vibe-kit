## Claude Code installer pack

Run from your project root:

```bash
~/.claude/vibe-kit/bin/vibe-install --tool=claude-code
```

What this does:

1. Copies `kit/rules/*.md` → `~/.claude/rules/` (global; auto-loaded every session)
2. Copies `kit/commands/*.md` → `~/.claude/commands/` (slash commands available everywhere)
3. Copies `kit/CLAUDE.md` → `~/.claude/CLAUDE.md` (master rules)
4. Copies `kit/bin/hooks/*.sh` → `~/.claude/vibe-kit/bin/hooks/` (hooks fire automatically)
5. Copies `kit/bin/vibe-init` → `~/.claude/vibe-kit/bin/`
6. Copies `kit/bin/vibe-verify` → `~/.claude/vibe-kit/bin/`
7. Copies `kit/bin/vibe-detect-tool` → `~/.claude/vibe-kit/bin/`
8. Merges `kit/settings.json` hooks into `~/.claude/settings.json` (preserves existing config)
9. Copies `kit/installers/claude-code/SKILL.md` → `~/.claude/skills/vibe-kit/SKILL.md` (on-demand Skill bundle)

After install, run `~/.claude/vibe-kit/bin/vibe-init` in each project to scaffold docs/ and the project's own `AGENTS.md`.
