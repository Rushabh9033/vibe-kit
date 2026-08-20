## Aider installer pack

Run from your project root:

```bash
~/.claude/vibe-kit/bin/vibe-install --tool=aider
```

What this does:

1. Copies `kit/CLAUDE.md` → `CONVENTIONS.md` (Aider's conventions file)
2. Copies `kit/installers/aider/.aider.conf.yml` → `.aider.conf.yml` (Aider's config)
3. Copies `kit/installers/aider/CONVENTIONS.md` → `CONVENTIONS.md` (overrides — Aider pack version)
4. Copies `kit/CLAUDE.md` → `AGENTS.md` (master rules)
5. Runs `vibe-init` to scaffold `docs/`, `.github/`, `.gitignore` (skips existing files)

After install, start a coding session with:

```bash
aider --read docs/requirements/<feature>/spec.md \
      --read docs/requirements/<feature>/plan.md
```

## Manual alternative

```bash
cp kit/CLAUDE.md                          CONVENTIONS.md
cp kit/installers/aider/.aider.conf.yml   .aider.conf.yml
./kit/bin/vibe-init
```
