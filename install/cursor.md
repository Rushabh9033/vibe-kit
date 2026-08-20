# Install: Cursor

Cursor reads its own conventions format (`.cursorrules`) plus project-root markdown rules. The vibe-kit drops in via `.cursor/rules/`.

## Step 1 — One-shot installer

```bash
# From your project root:
KIT="$(git rev-parse --show-toplevel)/vendor/vibe-kit"
test -d "$KIT" || KIT="$HOME/.claude/vibe-kit/.."
test -f "$KIT/kit/CLAUDE.md" || KIT="$(dirname "$(command -v vibe-init)")/.."

mkdir -p .cursor/rules .cursor/commands
cp "$KIT/kit/rules/"*.md  .cursor/rules/
cp "$KIT/kit/commands/"*.md .cursor/commands/
cp "$KIT/kit/CLAUDE.md" AGENTS.md
"$KIT/kit/bin/vibe-init"          # scaffolds the rest, skips existing files
```

Or do it by hand (see Steps 2–4 below).

## Step 2 — `.cursor/rules/` (project-scoped)

Drop the kit's modular rules into `.cursor/rules/`. Cursor's Composer reads these as advisory context for every chat.

```bash
mkdir -p .cursor/rules
cp kit/rules/01-security.md   .cursor/rules/
cp kit/rules/02-verify.md     .cursor/rules/
cp kit/rules/03-no-slopsquatting.md .cursor/rules/
cp kit/rules/04-compound.md   .cursor/rules/
cp kit/rules/05-cost.md       .cursor/rules/
```

## Step 3 — `.cursorrules` (project-root conventions sink)

Create `.cursorrules` at the project root with a one-line pointer plus the kit's master rules. Cursor reads this on every Composer invocation:

```bash
cp kit/CLAUDE.md .cursorrules
```

Or inline a condensed version:

```markdown
# Vibe Coding Protocol — see .cursor/rules/

## Always
- Run lint + typecheck + tests before declaring done.
- Reject any new dep that isn't registry-verified + license-audited.
- Document gotchas in `docs/gotchas.md`.
- Run `/vibe-verify` before claiming done on any user-visible feature.

## Never
- Edit committed migrations; create a new one.
- Disable lint rules or bypass tests without justification.
- Hardcode secrets, tokens, URLs.
- Use TypeScript `any` without justification.
- Commit `.env*` files.

## Two-role model
- Planner side: any chat AI with `prompts/` files.
- Coder side: Cursor reads `.cursor/rules/` + `.cursor/commands/` per this install.
- Spec at `docs/requirements/<feature>/spec.md` is the contract.
- User bridges Planner → Coder.
```

## Step 4 — `.cursor/commands/` (slash-command equivalents)

The kit's slash commands work as-is in Cursor (same `.md` format):

```bash
cp kit/commands/*.md .cursor/commands/
```

Then invoke in Composer: `/vibe-spec profile-photo-upload`, `/vibe-verify`, etc.

## Step 5 — Scaffolding the rest

```bash
./kit/bin/vibe-init
```

This creates `AGENTS.md`, `docs/SPEC.md`, `docs/requirements/`, `.claude/settings.json`, `.github/PULL_REQUEST_TEMPLATE.md`. Cursor reads `docs/` files via its `@docs` mention system.

## What's NOT auto-fired in Cursor

Cursor doesn't fire the same hooks as Claude Code:

| Claude Code | Cursor equivalent |
|---|---|
| PostToolUse-on-Edit (format) | Cursor's built-in formatter on save |
| PreToolUse-on-Bash (guard-unsafe) | **No equivalent** — run `kit/bin/hooks/guard-unsafe.sh` manually before destructive Bash |
| Stop-time handoff automation | **No equivalent** — call `/vibe-handoff` at session end |

You'll do the kill list manually. The rules in `.cursor/rules/` are advisory — Cursor's Composer reads them but doesn't *enforce*.

## Two-role usage

- **Planner side**: Claude.ai / ChatGPT / Gemini with `prompts/` files.
- **Coder side**: in Cursor, Cmd+K with the spec loaded via `@docs/requirements/<feature>/spec.md`.

## Auto-detect (from this kit)

The kit can detect Cursor and install the right config automatically:

```bash
./kit/bin/vibe-detect-tool    # prints: cursor | project-advisory | .cursor
./kit/bin/vibe-init --tool=auto  # same, via vibe-init
```

## When to switch from Cursor to Claude Code

- When you need the destructive-pattern guard on Bash.
- When you need Stop-time handoff automation.
- When you want per-session memory persistence.

Or run both: Cursor for editing, Claude Code as a second pair of eyes on `/vibe-review-pr`.
