# Install: Aider

Aider uses `CONVENTIONS.md` and a `.aider.conf.yml`. The vibe-kit's plain markdown maps cleanly.

## Step 1 — `CONVENTIONS.md`

Create `CONVENTIONS.md` at the project root with the kit's master rules:

```bash
cp kit/CLAUDE.md CONVENTIONS.md
```

## Step 2 — `.aider.conf.yml`

```yaml
read: CONVENTIONS.md
read: AGENTS.md
read: docs/SPEC.md
read: docs/requirements/<current-feature>/spec.md
read: docs/requirements/<current-feature>/plan.md
read: docs/handoffs/latest.md
```

Aider reads these at every chat invocation. Each new chat starts with all project rules + spec + plan + recent handoff in context.

## Step 3 — Per-project scaffolding

```bash
~/path/to/vibe-kit/kit/bin/vibe-init
```

This creates `AGENTS.md`, `docs/SPEC.md`, `docs/requirements/`, `docs/handoffs/`, etc. Aider picks them up via the `read:` config.

## Step 4 — Two-role

- **Planner**: use any chat AI with `prompts/`. Save outputs to `docs/`.
- **Coder**: Aider reads the spec on every chat. Use `/read` to add the latest handoff; `/diff` to see pending changes; `/commit` with conventional-commits per `kit/commands/vibe-ship.md`.

## What Aider doesn't do

- No PostToolUse-on-Edit auto-format. Use a pre-commit formatter (`pre-commit` + `prettier`).
- No PreToolUse-on-Bash guard. Run the kill list manually.
- No Stop-time handoff automation. End each session by running `kit/bin/hooks/session-end-handoff.sh` directly.

## When Aider is the right tool

- Pair-programming feel.
- Tight diff loop with chat-aware commits.
- Lightweight setup; no daemon, no MCP servers, no perms.
- Best with small, spec-bounded changes (one phase of one feature at a time).
