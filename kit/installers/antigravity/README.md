## Antigravity installer pack

Run from your project root:

```bash
~/.claude/vibe-kit/bin/vibe-install --tool=antigravity
```

What this does:

1. Copies `kit/rules/*.md` → `.claude/rules/` (project-scoped rules)
2. Copies `kit/commands/*.md` → `.claude/commands/` (slash commands)
3. Copies `kit/CLAUDE.md` → `AGENTS.md` (master rules)
4. Copies `kit/installers/antigravity/CLAUDE.md` → `.claude/AGENTS.md` (Antigravity-specific notes)
5. Runs `vibe-init` to scaffold `docs/`, `.github/`, `.gitignore` (skips existing files)

## Manual alternative

```bash
mkdir -p .claude/rules .claude/commands
cp kit/rules/*.md     .claude/rules/
cp kit/commands/*.md  .claude/commands/
cp kit/CLAUDE.md      AGENTS.md
./kit/bin/vibe-init
```

Antigravity's Claude Code layout is identical, so the same files install cleanly.
