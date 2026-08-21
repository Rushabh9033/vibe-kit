# CLAUDE.md — global, user-level (auto-loaded every session)

## Vibe Coding Protocol (VCP) is active.

This file applies in every project unless overridden by a project-level `AGENTS.md` / `CLAUDE.md`.
Project-level rules win on conflict. Per-file rules in `.claude/rules/<topic>.md` are auto-scoped by the `paths:` frontmatter.

## Spec-first gate (run at every task start)

The kit enforces Spec-first. The Planner is optional — you can also be the Coder.
Before any non-trivial edit, run this gate:

1. Is the work trivial? (`vibe-classify` → `tiny`) → proceed.
2. Does an applicable Spec exist?
   - `Status: in-progress` → resume.
   - `Status: awaiting-approval` → STOP. The user must flip it to `in-progress` (recommended: `vibe-spec-approve <slug>` — it flips the status **and** auto-arms the gates so a fresh project is gated from the first commit).
   - `Status: draft` or no Spec on non-trivial work → enter Discovery (single source of truth: `prompts/00-anchor.md` § Discovery protocol), write `docs/requirements/<feature>/spec.md` from `kit/templates/requirements-spec.md`, set `Status: awaiting-approval`, **stop**.
3. **Approval boundary:** the user is the only one who can flip `Status: awaiting-approval → in-progress`.

Full decision tree: `kit/templates/spec-first-gate.md`.

## Pre-flight (any non-trivial edit)

1. Find the spec for current work: `docs/SPEC.md` (milestone) or `docs/requirements/<feature>/spec.md` (feature). If neither exists and the work is more than a typo, **propose one before coding**.
2. Each acceptance criterion = one test.
3. Run the project's verification commands before claiming done.
4. Update `CHANGELOG.md [Unreleased]` for user-visible changes; write `docs/handoffs/<date>-<slug>.md` at session end.

## Always

- Run lint + typecheck + tests before declaring done.
- Reject any new dependency that isn't on the allowlist, hasn't been registry-verified (`npm view <pkg>` / `pip index versions <pkg>`), and hasn't passed the license audit.
- Document gotchas in `docs/gotchas.md` on discovery.
- Update the project `AGENTS.md` (or `~/.claude/CLAUDE.md` if global) when a mistake repeats (Boris Cherny's compound-corrections pattern).
- Re-inject the spec at the start of any response after context > 60%.

## Ask first

- Adding a top-level dependency.
- Schema / migration changes.
- Edits in `/auth`, `/billing`, `/security`, `/migrations`.
- Changes to `docs/SPEC.md` non-goals.

## Never

- Edit committed migrations; create a new migration instead.
- Disable lint rules or bypass tests (`--no-verify`, `skip-ci`, `eslint-disable` without justification).
- Hardcode secrets, tokens, URLs, or environment-specific values.
- Use TypeScript `any` without justification.
- Commit `.env*` files.
- Force-push, recursive `rm -rf`, raw disk writes, fork bombs (the PreToolUse guard will block — and that's intended).
- Add a dependency without verifying it exists on the registry (slopsquatting).
- Ship without: every AC green, edge cases tested, NFRs checked, lint/typecheck green, CHANGELOG and ADR updated if appropriate, handoff written if cross-session.

## Don't ship without

- [ ] Every AC has a green test
- [ ] Edge cases enumerated and tested
- [ ] NFRs checked (perf, a11y, security, observability)
- [ ] lint + typecheck green
- [ ] No `any` / lint-disable without justification
- [ ] No new dependency without approval and registry check
- [ ] No secrets in code or logs
- [ ] CHANGELOG and ADR updated if appropriate
- [ ] Handoff doc written if cross-session
- [ ] Schema migrations reversible
- [ ] Feature flag in place for any user-visible AI change
- [ ] Runbook for any new operational concern

## Available slash commands (global)

- `/vibe-init` — bootstrap current directory to VCP-grade
- `/vibe-spec` — write per-feature spec from intake
- `/vibe-plan` — write phased implementation plan from a spec
- `/vibe-verify` — run verification ranks against current changes
- `/vibe-ship` — ship a feature (CHANGELOG + handoff + ready-to-commit)
- `/vibe-handoff` — write a session handoff doc
- `/vibe-decide` — write an ADR
- `/vibe-review-pr` — review a PR/branch with the AI-specific checklist

## Memory hierarchy (broadest → most specific; later wins)

1. This file (`~/.claude/CLAUDE.md`)
2. `~/.claude/rules/*.md`
3. Project `CLAUDE.md` walking down the directory tree
4. `CLAUDE.local.md` (gitignored, personal overrides)
5. `.claude/rules/*.md` (project rules; path-scoped via `paths:` frontmatter)
6. `MEMORY.md` index (auto-memory)
7. Active session buffer

## When this file should change

- Same global mistake twice → add a rule here.
- A *project-specific* mistake twice → update that project's `AGENTS.md`.
- Decision reverses an earlier global rule → write an ADR; don't silently edit.

## Compound corrections (lessons already paid for)

- **2026-08-20 — Stop hooks must be commands, not prompts.** A prompt-only Stop hook can be silently skipped. Whenever an outcome must produce a record on disk, use a `command`-type hook that touches the file. Pair a "skip if X missing" clause with a fallback path (e.g., `~/.claude/projects/<cwd-base>/handoffs/`).
- **2026-08-20 — Don't ship a hook without exercising it in the same session.** A hook that hasn't fired is a hook that doesn't exist. After adding any hook, run it (or simulate cwd state) to confirm it produces the expected artifact.
- **2026-08-20 — Stop-hook prompts that touch a file are mandatory, not advisory.** When the Stop-hook prompt asks the assistant to write/edit/append a file, perform that file write **before** sending the final message of the session. The assistant treats "fill in stub" as optional; it isn't.
- **2026-08-20 — Idempotent hook scripts hide session-end failures.** When `session-end-handoff.sh` skips because the file exists, the failure of subsequent sessions to fill in is masked. Add `${CLAUDE_SESSION_ID}` (or a per-session counter) to the handoff slug so each session gets its own artifact.

## The principle (one line)

Specify small, verify twice, persist the lessons. The spec is the only artifact that survives context loss; everything else is regenerated from it.
