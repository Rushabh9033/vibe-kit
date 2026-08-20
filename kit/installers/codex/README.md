## Codex installer pack

Run from your project root:

```bash
~/.claude/vibe-kit/bin/vibe-install --tool=codex
```

What this does:

1. Copies `kit/CLAUDE.md` → `AGENTS.md` (Codex's master rules file)
2. Copies `kit/installers/codex/AGENTS.md` → `AGENTS.md` (overrides — Codex-pack version)
3. Runs `vibe-init` to scaffold `docs/`, `.github/`, `.gitignore` (skips existing files)

## Manual alternative

```bash
cp kit/CLAUDE.md                            AGENTS.md
cp kit/installers/codex/AGENTS.md           AGENTS.md
./kit/bin/vibe-init
```

## Verification

```bash
kit/bin/vibe-verify   # before each commit
```
