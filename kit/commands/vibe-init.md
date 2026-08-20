---
description: Bootstrap current directory to Vibe Coding Protocol (VCP) standard
---

VCP-bootstrap the current directory: detect the stack, scaffold the standard Vibe-kit files (templates, hooks, paths), and print a checklist for the next step.

## What it does

1. **Detect the stack** by looking for: `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`.
2. Run `~/.claude/vibe-kit/bin/vibe-init` (or `./kit/bin/vibe-init` if vendored).
3. The script scaffolds:
   - `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`, `HANDOFF.md`
   - `docs/SPEC.md` (stub), `docs/ARCHITECTURE.md`, `docs/gotchas.md`
   - `docs/requirements/README.md`
   - `docs/decisions/{README.md, ADR.md, 0001-record-architecture-decisions.md}`
   - `docs/handoffs/README.md`
   - `.claude/settings.json` (hooks)
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `.gitignore` appended with `.env*`, `CLAUDE.local.md`, `.vibe-cache/`
4. Print what was created (the script does this).
5. Prompt: "Fill `docs/SPEC.md` for the current milestone, then run `/vibe-spec <feature-slug>` per feature."

## When to use

- Once per project, at the start.
- Whenever the user types `/vibe-init`.

## Usage

```
/vibe-init                       # scaffold everything
/vibe-init --check               # preview: what would be created/updated, no writes
/vibe-init --update              # refresh generated docs without touching AGENTS.md / CHANGELOG / gotchas / PR template
```

## Implementation

```bash
# Locate the script (project install takes priority over global)
if [ -x "./kit/bin/vibe-init" ]; then
  ./kit/bin/vibe-init "$@"
elif [ -x "$HOME/.claude/vibe-kit/bin/vibe-init" ]; then
  $HOME/.claude/vibe-kit/bin/vibe-init "$@"
else
  echo "vibe-init not installed. Copy kit/bin/vibe-init to your PATH."
  exit 1
fi
```

## Output

After scaffolding, the script prints a list of created/updated paths. The slash command then prints:

```
vibe-init complete.
stack: <detected>
created: <N> files
next:
  1. Fill docs/SPEC.md for the current milestone
  2. /vibe-spec <feature-slug> per feature
  3. Review + edit the spec before /vibe-plan
```

## Limits

- **Idempotent by default.** Re-running `--update` refreshes generated docs without touching hand-curated ones.
- **Stack detection is heuristic.** If the project has no manifest at the root, fall back to prompting the user.
- **Does not auto-commit.** Wait for the user's go-ahead before `git add` / `git commit`.
- **Does not overwrite existing content.** If `AGENTS.md` already exists, the script asks before replacing it.
