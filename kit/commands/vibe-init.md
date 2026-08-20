---
description: Bootstrap current directory to Vibe Coding Protocol (VCP) standard
---

VCP-bootstrap current directory. Determine stack first (look for `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`). Then run `~/.claude/vibe-kit/bin/vibe-init` — it scaffolds:

- `AGENTS.md`, `CLAUDE.md`, `CHANGELOG.md`, `HANDOFF.md`
- `docs/SPEC.md` (stub), `docs/ARCHITECTURE.md`, `docs/gotchas.md`
- `docs/requirements/README.md`
- `docs/decisions/{README.md, template.md, 0001-record-architecture-decisions.md}`
- `docs/handoffs/README.md`
- `.claude/settings.json` (hooks)
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.gitignore` appended with `.env*`, `CLAUDE.local.md`, `.vibe-cache/`

After scaffolding:

1. Tell the user what was created (`vibe-init` printed this).
2. Prompt: "Fill `docs/SPEC.md` for the current milestone, then run `/vibe-spec <feature-slug> <intake>` per feature."
3. Don't auto-commit; wait for user.

Use `vibe-init --check` first if the user wants to preview.
Use `vibe-init --update` to refresh generated docs without touching AGENTS.md / CHANGELOG / gotchas / PR template.
