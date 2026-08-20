# Install: other tools

Any dev tool that reads project-root markdown will work with vibe-kit's core ideas. Adapt the rules to your tool's format.

## Step 1 — Scaffold the project

```bash
~/path/to/vibe-kit/kit/bin/vibe-init
```

This creates:

- `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`, `HANDOFF.md`
- `docs/SPEC.md`, `docs/ARCHITECTURE.md`, `docs/gotchas.md`
- `docs/requirements/`, `docs/decisions/`, `docs/handoffs/`, `docs/runbooks/`
- `.claude/settings.json` (hooks — adapt to your tool if it has a hook model)
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.gitignore`

## Step 2 — Adapt rules to your tool

Each tool has a rules convention:

| Tool | Rules location | Format |
|---|---|---|
| **Continue.dev** | `.continue/config.json` + `.continuerules/` | JSON + markdown |
| **Codeium/Windsurf** | `.windsurfrules` | markdown |
| **Tabby** | `~/.tabby/agent/config.toml` + per-project | TOML |
| **Devin/Cognition** | project-level `AGENTS.md` | markdown |
| **Replit** | `.replit` + workspace | mixed |
| **Sourcegraph Cody** | per-repo `.cody/config.json` | JSON |
| **OpenAI Codex CLI** | `~/.codex/AGENTS.md` | markdown (Claude Code compatible) |
| **JetBrains AI Assistant** | `.aiassistant/rules/` | markdown |
| **GitHub Copilot Workspace** | repo-level | markdown via `.github/copilot-instructions.md` |

Drop the kit's rules into the matching location. Most tools will pick them up unchanged; some need a preamble.

## Step 3 — Hooks (when the tool supports them)

If your tool has a hook model:

| Tool | Hook config location | Format |
|---|---|---|
| Claude Code | `~/.claude/settings.json` | JSON |
| Continue | `.continue/config.json` | JSON (custom commands) |
| OpenAI Codex CLI | `~/.codex/config.toml` | TOML |

Copy `kit/settings.json` and adapt to your tool's hook format.

## Step 4 — Two-role

- **Planner**: any chat AI + `prompts/`. No install.
- **Coder**: this tool. Reads `AGENTS.md` + spec on every invocation.

## Step 5 — Manual enforcement

If your tool fires no hooks, manual enforcement via pre-commit:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: vibe-lint
        name: Vibe kill list check
        entry: .vibe-kit/hooks/check-kill-list.sh
        language: script
        pass_filenames: false
```

Or run `/vibe-verify` manually before each commit.

## When in doubt

Start with `kit/CLAUDE.md` in your project's `AGENTS.md`. That alone gives you 80% of the value. Add rules and hooks as your tool supports them.
