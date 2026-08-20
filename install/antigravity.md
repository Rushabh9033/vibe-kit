# Install: Antigravity

Antigravity reads `.claude/rules/`-compatible markdown files and supports slash-command-style invocations. The vibe-kit drops in directly.

## Step 1 — Rules (project-scoped)

```bash
# In your project directory, with vibe-kit cloned:
mkdir -p .claude/rules .claude/commands
cp ../vibe-kit/kit/rules/*.md .claude/rules/
cp ../vibe-kit/kit/commands/*.md .claude/commands/
cp ../vibe-kit/kit/CLAUDE.md ./AGENTS.md
```

## Step 2 — Scaffolding

```bash
~/path/to/vibe-kit/kit/bin/vibe-init
```

Same as for any tool. Generates docs/, AGENTS.md, CHANGELOG.md, HANDOFF.md, .github/.

## Step 3 — Two-role

- **Planner**: any chat AI + `prompts/`.
- **Coder**: Antigravity reads the rules and slash-commands identically to Claude Code.

## Notes on Antigravity's auto-features

Antigravity's auto-format / auto-review features replace the PostToolUse hook from `kit/settings.json`. The PreToolUse-on-Bash guard is enforced through a command-runner-level policy, not Bash itself — set it in your Antigravity workspace settings if available.

When Antigravity diverges from Claude Code's hook model, fall back to the kill list in `AGENTS.md` and review PRs through `/vibe-review-pr` style checks.
