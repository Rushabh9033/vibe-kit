# Install: Cursor

Cursor reads its own conventions format (`.cursorrules`) plus project-root markdown rules. The vibe-kit can be adapted.

## Step 1 — `.cursorrules` at project root

Create `.cursorrules` at the project root with the rules summarized. Either reference the kit files or inline a condensed version:

```bash
cp kit/CLAUDE.md .cursor/rules/vcp-core.md
mkdir -p .cursor/rules
for f in kit/rules/*.md; do
  cp "$f" ".cursor/rules/$(basename $f)"
done
```

Then add a one-line `.cursorrules` at the project root:

```
# Vibe Coding Protocol — see .cursor/rules/
```

## Step 2 — Per-project scaffolding

```bash
# Use the kit's installer (works regardless of dev tool)
~/path/to/vibe-kit/kit/bin/vibe-init
```

This creates `AGENTS.md`, `docs/SPEC.md`, `docs/requirements/`, etc. Cursor reads these via its `@docs` mention system.

## Step 3 — Two-role usage

- **Planner side**: use Claude.ai or ChatGPT with `prompts/` files.
- **Coder side**: in Cursor, use Cmd+K with the spec loaded via `@docs/requirements/<feature>/spec.md`.

## What's not auto-fired

Cursor doesn't fire the same hooks as Claude Code (no PreToolUse-on-Bash or PostToolUse-on-Edit equivalents). You'll do the killing list manually. The rules in `.cursor/rules/` are advisory — Cursor's Composer reads them but doesn't *enforce*.

## When to switch from Cursor to Claude Code

- When you need the destructive-pattern guard on Bash.
- When you need Stop-time handoff automation.
- When you want per-session memory persistence.

Or run both: Cursor for editing, Claude Code as a second pair of eyes on `/vibe-review-pr`.
