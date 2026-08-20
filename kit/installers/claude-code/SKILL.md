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

## The spec-first gate (run this at every task start)

> **Planner is optional. Spec-first is not.**

This tool is both the **implementation agent** and the **requirements-discovery agent** when no applicable Spec exists. At every task start, run the gate at `kit/templates/spec-first-gate.md`:

1. Trivial change (`vibe-classify: tiny`) → proceed without a Spec.
2. Existing in-progress Spec → resume from where it stopped.
3. Awaiting-approval Spec → stop; the user must flip Status to `in-progress`.
4. No applicable Spec, non-trivial work → **enter DISCOVERY MODE** (canonical source: `prompts/00-anchor.md` § Discovery protocol). One question at a time. Then write `docs/requirements/<feature>/spec.md` with `Status: awaiting-approval` and **stop**. Do NOT implement in the same turn.
5. After user sets `Status: in-progress`, re-read the Spec, optionally write `plan.md`, then implement.

The user is the human-approval gate between Spec and code, not a paste-bridge between two AI tools.

## The two-role model (Planner optional)

```
┌─────────────┐    spec.md  ┌──────────────┐    PR    ┌─────────────┐
│  PLANNER AI │ ──────────► │  CODER AI    │ ────────►│  /vibe-     │
│ (any chat,  │             │  (this tool, │          │  verify     │
│  optional)  │             │  or a dev    │          │             │
│             │             │  tool)       │          │             │
└─────────────┘             └──────────────┘          └─────────────┘
                                ▲                                          │
                                │                                          ▼
                          may run Discovery                          ┌─────────────┐
                          itself when no Spec                        │  HANDOFF.md │
                          exists                                     └─────────────┘
```

- **Planner side** *(optional)*: any chat AI (Claude.ai, ChatGPT, Gemini) reading `prompts/`. Produces spec.md + plan.md.
- **Coder side**: this tool (Claude Code, Cursor, Aider, etc.) reading `docs/requirements/<feature>/spec.md` + this kit's slash commands. **If no applicable Spec exists, the Coder runs Discovery itself** (per the spec-first gate above) before writing code.
- **Verifier**: `./kit/bin/vibe-verify` — diff-vs-spec check + test runner.

The Spec is the bridge between intent and code. The Planner is one way to produce it; the Coder is another.

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
