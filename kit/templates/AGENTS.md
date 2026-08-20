# AGENTS.md

## What is this
<Two sentences. Stack. Audience. Why it exists.>

## Build / run / test
- Install: `<cmd>`
- Dev: `<cmd, default port>`
- Test: `<cmd>` (single run; watch only interactively)
- Lint: `<cmd>`
- Typecheck: `<cmd>`
- Format: `<cmd>`
- Database: `<start cmd>` before integration tests

## Repo layout
- `src/` — application
- `tests/` — <framework>; mirrors `src/`
- `db/migrations/` — <ORM> (NEVER edit committed; create new)
- `docs/requirements/` — per-feature contracts (input to AI)
- `docs/decisions/` — ADR log
- `docs/handoffs/` — session-to-session

## Conventions
- <indent, quotes, semicolons, naming>
- <errors: throw AppError; never raw strings>
- <exports: named only; no defaults except X>
- <compositional: dependency direction, layering>

## Boundaries (Always / Ask First / Never)

### Always
- Run lint + typecheck + tests before pushing
- Add tests for any new public function
- Update `CHANGELOG.md [Unreleased]` after user-visible change
- Update `docs/requirements/<feature>/plan.md` as work progresses
- **Run the spec-first gate** (`kit/templates/spec-first-gate.md`) at every task start: no Spec, no code (unless trivial)

### Ask first
- Adding a new dependency
- Schema / migration changes
- Editing /auth, /billing, /security, /migrations
- Changes to `docs/SPEC.md` non-goals

### Never
- Edit files under /migrations/ once committed
- Disable lint rules
- Bypass tests (`--no-verify`, `skip-ci`)
- Hardcode secrets, URLs, environment-specific values
- Use TypeScript `any` without justification
- Commit `.env*` files

## Non-obvious rules (traps)
- <library bug and workaround>
- <perf constraint>
- <auth signature MUST be verified even in tests>

## Where to look
- Spec: `docs/SPEC.md`
- Per-feature: `docs/requirements/<feature>/spec.md`
- Decisions: `docs/decisions/`
- Gotchas: `docs/gotchas.md`
- Handoffs: `docs/handoffs/`
- Memory index: `HANDOFF.md`

## When unsure
Ask. Don't guess. If guessing persisted, add a decision to `docs/decisions/NNNN-*.md`.

## AI labels
- Mark every AI-assisted PR with `ai-assisted` label and the model id.
- Update `docs/handoffs/<date>.md` at end of session.
