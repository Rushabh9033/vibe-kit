# Install: Aider

Aider uses `CONVENTIONS.md` and `.aider.conf.yml`. The vibe-kit's plain markdown maps cleanly.

## Step 1 — `CONVENTIONS.md`

Drop the kit's master rules into `CONVENTIONS.md` at the project root. Aider reads it on every chat invocation:

```bash
cp kit/CLAUDE.md CONVENTIONS.md
```

Optionally also drop the modular rules:

```bash
mkdir -p .aider/rules
cp kit/rules/*.md .aider/rules/
# Then reference them from .aider.conf.yml (see Step 2)
```

## Step 2 — `.aider.conf.yml`

Create `.aider.conf.yml` at the project root. Aider auto-loads it on every chat start:

```yaml
# Vibe Coding Protocol — Aider config

# Read these files into every chat's context
read:
  - CONVENTIONS.md
  - AGENTS.md
  - docs/SPEC.md
  - CHANGELOG.md

# Per-feature context (Aider can't glob; use --read at chat start for the current feature)
# Example: aider --read docs/requirements/profile-photo-upload/spec.md
# Example: aider --read docs/requirements/profile-photo-upload/plan.md

# Map vibe-* slash-command intent to Aider's command flags
# (Aider doesn't have slash commands; use these aliases in chat)
commands:
  vibe-spec:    /read docs/requirements/<feature>/spec.md
  vibe-plan:    /read docs/requirements/<feature>/plan.md
  vibe-verify:  /run  ./kit/bin/vibe-verify
  vibe-handoff: /run  ./kit/bin/hooks/session-end-handoff.sh
  vibe-ship:    /commit
  vibe-decide:  /read docs/decisions/
  vibe-init:    /run  ./kit/bin/vibe-init

# Pre-commit hook (Aider's /commit fires this)
pre-commit: ./kit/bin/hooks/pre-commit-verify.sh

# Model — pick by ADR; default below is a cost/quality sweet spot
model: claude-3-5-sonnet-20241022
```

## Step 3 — Scaffolding

```bash
./kit/bin/vibe-init
```

This creates `AGENTS.md`, `CHANGELOG.md`, `docs/SPEC.md`, `docs/requirements/`, `docs/handoffs/`, `.github/`. Aider picks them up via the `read:` config.

## Step 4 — Per-feature context

Aider doesn't auto-load per-feature specs. At chat start, pass them:

```bash
aider --read docs/requirements/profile-photo-upload/spec.md \
      --read docs/requirements/profile-photo-upload/plan.md
```

Or set an alias:

```bash
alias vibe="aider --read CONVENTIONS.md \
                --read AGENTS.md \
                --read docs/SPEC.md \
                --read docs/requirements/\$(current-feature)/spec.md \
                --read docs/requirements/\$(current-feature)/plan.md"
```

## Two-role usage

- **Planner**: any chat AI + `prompts/`. Save outputs to `docs/`.
- **Coder**: Aider reads the spec on every chat. Use `/read` to add the latest handoff; `/diff` to see pending changes; `/commit` with conventional-commits per `kit/commands/vibe-ship.md`.

## What Aider doesn't do

- No PostToolUse-on-Edit auto-format. Use a pre-commit formatter (`pre-commit` + `prettier`).
- No PreToolUse-on-Bash guard. Run the kill list manually.
- No Stop-time handoff automation. End each session by running `kit/bin/hooks/session-end-handoff.sh` directly (or the `vibe-handoff` command alias from Step 2).

## Auto-detect (from this kit)

```bash
./kit/bin/vibe-detect-tool    # prints: aider | project-conventions | .
```

## When Aider is the right tool

- Pair-programming feel.
- Tight diff loop with chat-aware commits.
- Lightweight setup; no daemon, no MCP servers, no perms.
- Best with small, spec-bounded changes (one phase of one feature at a time).
