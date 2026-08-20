---
name: vibe-kit
description: Stands up Vibe Coding Protocol (VCP) — a two-role AI dev workflow where one AI writes a spec and another AI verifies the code against it. Use this when the user asks to "bootstrap", "init", "set up vibe-kit", "add VCP", "install vibe-kit", "configure VCP", "code against a spec", "verify against acceptance criteria", or any wording that maps to spec/plan/verify/handoff/ship. Loads on demand and scopes itself to the current conversation.
---

# vibe-kit — Vibe Coding Protocol

A persistent contract for AI coding. One AI writes a spec. Another AI implements the code. A third check (this kit) verifies the code matches the spec, line by line.

## When to invoke

- User says: "bootstrap", "init", "set up vibe-kit", "add VCP", "make this VCP-grade"
- User says: "I want specs first", "I want AI to verify what AI wrote"
- User says: "code against a spec", "track acceptance criteria"
- User runs: `/vibe-*` slash commands (the framework fires this Skill implicitly)

## When NOT to invoke

- The user is asking a single quick question (`what's TypeScript?`).
- The user is in a non-coding context (writing an essay, debugging one bash command).
- The user has explicitly opted out of structured workflows.

## The two-role model

```
┌─────────────┐    spec.md  ┌──────────────┐    PR    ┌─────────────┐
│  PLANNER AI │ ──────────► │  CODER AI    │ ────────►│  /vibe-     │
│  (any chat) │             │  (this tool) │          │  verify     │
└─────────────┘             └──────────────┘          └─────────────┘
       ▲                                                    │
       │                                                    ▼
       │                                            ┌─────────────┐
       └────────────────────────────────────────────│  HANDOFF.md │
                                                    └─────────────┘
```

- **Planner side**: any chat AI (Claude.ai, ChatGPT, Gemini) reading `prompts/`. Produces spec.md + plan.md.
- **Coder side**: this tool (Claude Code, Cursor, Aider, etc.) reading `docs/requirements/<feature>/spec.md` + this kit's slash commands.
- **Verifier**: `./kit/bin/vibeverify` — diff-vs-spec check + test runner.

The user is the bridge between Planner and Coder. The spec is the bridge between intent and code.

## The 8 slash commands

| Command | Purpose |
|---|---|
| `/vibe-init` | Bootstrap a project to VCP grade (skips files that exist) |
| `/vibe-spec` | Write `docs/requirements/<feature>/spec.md` from intake |
| `/vibe-plan` | Phase the spec into a `plan.md` with ACs per phase |
| `/vibe-verify` | AC↔test contract checker — runs against git diff |
| `/vibe-ship` | CHANGELOG + handoff + ready-to-commit, in one shot |
| `/vibe-handoff` | Write a session handoff doc |
| `/vibe-decide` | Write an ADR |
| `/vibe-review-pr` | Review a PR/branch with the AI-specific checklist |

## The kill list (live in `AGENTS.md`)

- ❌ Edit committed migrations. → create a new one.
- ❌ Disable lint / bypass tests / `--no-verify`. → justify in the PR.
- ❌ Hardcode secrets, tokens, URLs. → env vars.
- ❌ `any` without justification. → narrow the type.
- ❌ Commit `.env*`. → `.gitignore`.
- ❌ `rm -rf`, force-push, raw disk writes. → the PreToolUse hook blocks these.

## The compound-correction rule

When the same mistake happens twice, persist it. Either write to `AGENTS.md` (repo-wide) or `.claude/rules/<topic>.md` (path-scoped). See `~/.claude/CLAUDE.md` for the format.

## The handoff rule

Every session that touches code writes a handoff. The Stop hook fires once at session end. The handoff goes to `docs/handoffs/<date>-<branch>-<feature>.md` and updates `HANDOFF.md`'s TL;DR.

## Hooks fired by this kit (Claude Code only)

- `PostToolUse` on Edit/Write/MultiEdit → format-on-save
- `PreToolUse` on Bash → block destructive patterns
- `Stop` → write handoff doc

## Auto-detection

The kit detects which tool you're running in. Run `./kit/bin/vibe-detect-tool` to see what it picks. The default install (no flags) is non-destructive: it skips files that already exist.

```bash
./kit/bin/vibe-install                # auto-detect + install
./kit/bin/vibe-install --tool=cursor  # override
./kit/bin/vibe-install --root=/path   # install into a specific project
```

## See also

- `docs/architecture.md` — the two-role model in depth
- `docs/requirements-gathering.md` — the most important workflow
- `kit/commands/` — slash command playbooks
- `kit/rules/` — global rules (security, verify, cost, compound)
- `kit/CLAUDE.md` — master kill list (always loaded in Claude Code)
