---
name: vibe-kit
description: |
  Use when starting or extending an AI-assisted project. Activates the Vibe Coding Protocol
  (VCP): spec-first, Planner optional. The Coder (a dev tool) is both implementation agent
  and requirements-discovery agent when no applicable Spec exists. Loads the playbook,
  requirements-gathering workflow, verification gates, and compound-correction rules.
---

# Vibe Coding Kit (Skill)

> **Spec-first. Planner optional.** One workflow, two entry points.
> Either a Planner (any chat AI) or the Coder itself produces the Spec;
> the user approves; the Coder implements; the verifier checks reality
> against the Spec.

## When to invoke me

- **Starting a new project** and you want VCP-grade scaffolding.
- **Adding a feature** to an existing VCP project: spec → plan → code.
- **Diagnosing a failing feature**: enforcement of kill list, re-reading the spec.
- **Reviewing a PR** built with AI assistance.
- **Migrating an existing repo** into VCP.
- When the user mentions "vibe coding", "vibe engineering", "AI-assisted workflow", "spec-first coding", or "compound corrections".

## What I load into the conversation

- The spec-first gate (Planner optional; Coder discovers when no Spec exists).
- The 4-step vibe loop (Spec → Code → Verify → Ship).
- The 7 verification ranks (lint → mutation testing → E2E → perf → security).
- The kill list (don't ship without…).
- The compound-corrections pattern (Boris Cherny: same mistake twice → a rule).
- The slopsquatting prevention checklist (every new dep).
- The two-role prompts (for the Planner side, when used).

## What I do not do (as Planner)

When the Coder invokes this skill from a Planner role:

- **I do not write code.** I'm a Planner. The Coder tool writes code.
- **I do not run tests, linters, or build commands.**
- **I do not push to remotes.**

If the user asks me to code, redirect: "Spec first; the Coder tool (Claude Code / Cursor / etc.) will run the implementation."

When invoked from a Coder (dev tool) instead, the skill drives the **spec-first gate** first (see `kit/templates/spec-first-gate.md`): run Discovery if no Spec exists, write the Spec, stop for approval, then implement in the next turn.

## Quick start (as the user invokes me)

When loaded, I open with:

1. **Confirm context**: "Are we starting a new project, or are we inside one?"
2. **Identify the role**: Planner or Coder?
3. **Read the latest state**: AGENTS.md, docs/SPEC.md, the latest `docs/handoffs/<date>.md`.
4. **Propose the next action**: which prompt, which command, which file.

## Reference files in this skill bundle

- `../../docs/architecture.md` — two-role model deep-dive.
- `../../docs/requirements-gathering.md` — the most important workflow.
- `../../docs/playbook.md` — the unified playbook.
- `../../docs/gap-analysis.md` — what this is, isn't, and the path to top 0.001%.
- `../../prompts/` — 8 planner-side prompts.
- `../../kit/commands/` — 8 coder-side slash commands.
- `../../kit/templates/` — scaffolding templates.
- `../../kit/rules/` — global rules.

## The principle

> **Specify small. Verify twice. Persist the lessons.**
>
> The spec is the only artifact that survives context loss. Code is regenerated from it. Everything else is generated around it.

## Compound corrections (lessons already paid for; load these on every invocation)

1. **2026-08-20** — Stop hooks must be commands, not prompts. A prompt-only hook can be silently skipped. Whenever outcome-as-record matters, use a command-hook that touches disk.
2. **2026-08-20** — Don't ship a hook without exercising it in the same session.
3. **2026-08-20** — Stop-hook prompts that touch a file are mandatory, not advisory. When the prompt asks the agent to write/edit/append a file, perform that write *before* sending the final message.
4. **2026-08-20** — Idempotent hook scripts hide failures. Add a per-session identifier to the artifact slug so subsequent sessions don't clobber.

This list will grow. Read it before the next session.

## Slash-command mirror (if installed globally)

- `/vibe-init` — bootstrap a project to VCP-grade.
- `/vibe-spec` — write a per-feature spec.
- `/vibe-plan` — phased implementation plan.
- `/vibe-verify` — run verification ranks.
- `/vibe-ship` — pre-flight + CHANGELOG + handoff.
- `/vibe-handoff` — write a session handoff doc.
- `/vibe-decide` — write an ADR.
- `/vibe-review-pr` — review a PR/branch.
