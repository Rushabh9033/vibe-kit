## Cursor installer pack

Run from your project root:

```bash
~/.claude/vibe-kit/bin/vibe-install --tool=cursor
```

What this does:

1. Copies `kit/rules/*.md` → `.cursor/rules/` (project-scoped rules)
2. Copies `kit/commands/*.md` → `.cursor/commands/` (slash commands; Composer reads them)
3. Copies `kit/installers/cursor/.cursorrules` → `.cursorrules` (conventions sink)
4. Copies `kit/CLAUDE.md` → `AGENTS.md` (master rules; Cursor reads this via @AGENTS.md mention)
5. Runs `vibe-init` to scaffold `docs/`, `.github/`, `.gitignore` (skips existing files)

After install, invoke in Composer:

- `@AGENTS.md @docs/requirements/<feature>/spec.md` then run the Composer command `/vibe-spec`, `/vibe-verify`, etc.

## Manual alternative

```bash
mkdir -p .cursor/rules .cursor/commands
cp kit/rules/*.md      .cursor/rules/
cp kit/commands/*.md   .cursor/commands/
cp kit/CLAUDE.md       AGENTS.md
cp kit/installers/cursor/.cursorrules .cursorrules
./kit/bin/vibe-init
```
