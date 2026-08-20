## Generic installer pack (fallback)

When vibe-detect-tool can't identify a specific tool, it falls back to "generic" — the kit writes AGENTS.md and lets the underlying tool pick it up.

Run from your project root:

```bash
~/.claude/vibe-kit/bin/vibe-install --tool=generic
```

What this does:

1. Copies `kit/installers/generic/AGENTS.md` → `AGENTS.md`
2. Copies `kit/CLAUDE.md` → `CLAUDE.md` (so Claude Code users in this project get the master rules)
3. Runs `vibe-init` to scaffold `docs/`, `.github/`, `.gitignore` (skips existing files)

## Manual alternative

```bash
cp kit/CLAUDE.md                      AGENTS.md
cp kit/installers/generic/AGENTS.md   AGENTS.md
./kit/bin/vibe-init
```

## When does this get used?

- The cwd has no tool-specific config files (`.cursor/`, `.aider.conf.yml`, `.codex/`, etc.).
- No tool-specific env vars are set.
- The user is using a tool we haven't classified yet (Continue, Cody, JetBrains AI, etc.).

The fallback is intentionally minimal — AGENTS.md is the only file most tools reliably read.
