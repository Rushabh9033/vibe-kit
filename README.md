# vibe-kit

**by Rushabh Mavani.**

AI coding tools are amazing. They knock out a CRUD endpoint in 30 seconds. They also swing wildly past your requirements, sign the wrong things, and ship 12% of your events to `/dev/null`.

If you've ever said *"the AI built what I asked for, but not what I meant"* — yeah. This kit is for you.

> If this is a 3-line bug fix, you don't need vibe-kit. Go fix your bug.
> If you've ever opened a PR and realized the AI quietly dropped half the requirements — keep reading.

## The pain

You know this one:

```
You:  "Send a webhook when an order ships."
AI:   calls `requests.post(url, json=payload)` on the ship event.
      No retries, no signing, no idempotency key, no DLQ.
You:  ship it. A customer reports they missed 12% of shipping events.
      Another got duplicates because the worker retried.
      A third got replayed by a bad actor — you weren't signing.
      Rebuild it properly. Then backfill the missed ones.
```

The AI did what you asked. It did NOT do what you meant. The product spec lived in your head for 30 seconds, and now it's gone.

This isn't an AI problem. This is a "you didn't write down what you actually wanted" problem. vibe-kit fixes that by making you write a Spec before the code starts, and then making the ship boundary check the code against the Spec.

You find out at PR time. Not at 3am.

## The workflow

```
Spec  →  Code  →  Verify  →  Ship
```

Four steps. We tried three. We tried two. We keep coming back to four.

- **Spec** — you write down what you want. Acceptance criteria, edge cases, what this thing is NOT.
- **Code** — the AI writes it. Or you do. Or both. The Spec is the contract.
- **Verify** — checks the diff against the Spec. Catches missing tests, missing implementations, missing constraints.
- **Ship** — the part that holds. If Verify says no, you don't push.

For larger work, supporting workflows exist (Plan, Decide, Handoff). Use them when the work earns them. Not before.

### The two layers under the hood

Two deterministic runtime layers keep the AI honest while it codes and after:

- **`/vibe-test`** — runs your project's tests across the configured ranks (lint, typecheck, unit, integration) and reports honest PASS / FAIL / BLOCK / UNVERIFIED status. No AI; auto-detects pytest, unittest, npm test, jest, vitest. Pre-push hook material.
- **prep-room hook** — before every Edit/Write, the kit surfaces recent commits on the file, the affected tests, and the relevant Spec ACs into the Coder's view. The Coder can't quietly forget what it was supposed to be building.

Both layers are spec'd together in [`docs/superpowers/specs/2026-08-21-smart-vibe-coder-design.md`](docs/superpowers/specs/2026-08-21-smart-vibe-coder-design.md). Both are pure determinism — no AI calls.

### The weapon suite — *when you want the kit to enforce, not suggest*

The kit also ships **7 weapons** that turn "encouragement" into "enforcement." Off by default. Opt in with `vibe-arm`:

- `vibe-arm` — turns on the full hard-gate suite for the current project
- `vibe-disarm` — reverts

Once armed, the kit **blocks** the wrong thing from happening:

- Editing source without an active AC declared (`vibe-edit-gate`)
- Editing source without a corresponding test (`vibe-tdd-gate`)
- Editing files touched by recent `fix:` commits (`vibe-fix-detector`)
- Claiming "done" without per-AC evidence (`/vibe-claim-check`)
- …plus telemetry hooks (`vibe-ac-progress`, `vibe-bug-mirror`) so the gates are visible, not invisible

The v0.1 layers (prep-room + vibe-test) tell the Coder what's going on. The weapons make the Coder obey.

### Spec-first. Planner optional.

The Spec is mandatory. The Planner is optional.

You can write the Spec with a chat AI (Claude.ai, ChatGPT, Gemini) — that's the "Planner" mode. It asks you questions, surfaces the ambiguity, writes the Spec.

Or you can just open your dev tool (Claude Code, Cursor, etc.) and tell the AI what you want. At task start, the kit runs a "spec-first gate": if no Spec exists for non-trivial work, the Coder runs Discovery itself, writes the Spec, and **stops for your approval** before any code.

Either way you end up with a Spec. Either way, you approve it before code happens. The Planner is useful when the planning model has more context than the coding tool, or when you're not the coder. The Coder-as-discoverer is useful when you want one tool, one session.

```
   Human intent (vague, one line)
        ↓
   ┌──────────────┐
   │  Spec        │  ← durable markdown. The source of product intent.
   │  Goal · ACs  │
   │  Constraints │
   └──────┬───────┘
          │
   ┌──────▼───────┐
   │  Code        │  ← AI / human / both. Against the Spec.
   │  + tests     │
   └──────┬───────┘
          │
   ┌──────▼───────┐
   │  Verify      │  ← /vibe-verify. Checks the diff against the Spec.
   │  PASS / FAIL │  ← exits 0 / 1. A real gate.
   │  BLOCK       │  ← exits 2. Needs human review.
   └──────┬───────┘
          │
   ┌──────▼───────┐
   │  Ship        │  ← /vibe-ship + pre-push hook (opt-in).
   └──────────────┘
```

**See it in action**: [`examples/todo-cli/`](examples/todo-cli/) is a runnable demo. Spec, implementation, verify output, a deliberate ship-blocker, and the fix.

## What this kit does NOT do

Let's set expectations:

- It does **not** read your mind. The Spec is markdown, and markdown cannot block a push on its own. Enforcement comes from the **verify + ship** boundary.
- It does **not** prove the code is correct. `vibe-verify` is an evidence/tripwire system, not a proof. It catches missing tests, missing implementations, and constraint violations. It cannot prove a test actually exercises the AC. For that, mutation testing exists.
- It does **not** require a separate Planner session. The Coder can run Discovery itself. You are the human-approval gate — you decide when the Spec is ready.
- It does **not** own your repository. The pre-push hook is opt-in. `git push --no-verify` and `VIBE_SHIP_OVERRIDE=1` are documented escape hatches.

## Ceremony scales with the work

You don't pick the workflow. The kit does. Based on the diff:

```bash
vibe-classify                # tiny | normal | large | critical
```

It looks at diff size, files touched, and whether the diff touches sensitive paths (`/auth/`, `/billing/`, `/secrets/`, etc.). Conservative defaults. When in doubt, it picks the heavier ceremony.

| Level | When | What you do |
|---|---|---|
| **tiny** | < 3 files, < 30 lines, no sensitive paths | Edit → commit. Skip the kit. |
| **normal** | Typical feature change | spec (lite) → code → /vibe-verify → /vibe-ship |
| **large** | ≥ 15 files or ≥ 500 lines, or schema changes | Full spec → /vibe-plan → code → /vibe-verify → /vibe-ship |
| **critical** | auth / billing / secrets / destructive migrations | Full spec + /vibe-decide (mandatory) + mutation testing + 2 reviewers |

The Mandatory 11 edge-case thinking is a checklist for your brain, not a section to fill in on every change. Use it for Normal and above. Skip it for Tiny.

## The Spec — what it is, and what it isn't

Markdown. Lives in git. Human-readable. Tool-agnostic. Survives context loss.

What it has:
- Goal (one paragraph)
- Acceptance Criteria (each AC = one test)
- Constraints (what you may NOT do)
- Edge Cases (the failure modes you must think about)
- Non-Goals (what this feature is NOT)
- Verification (how you'll know it works)

What it doesn't have:
- Implementation details (that's the Coder's job)
- Code snippets (the Spec is not pseudocode)
- Marketing language

Template: [`kit/templates/requirements-spec.md`](kit/templates/requirements-spec.md).

Two Specs exist at different levels — see Templates below.

## Verify — the actual gate

`vibe-verify` extracts ACs from your Spec and checks the git diff against each. Honest status model:

| Status | Meaning | Exit code |
|---|---|---|
| **PASS** | evidence in the diff for the AC | 0 |
| **FAIL** | no evidence | 1 |
| **BLOCK** | PARTIAL or UNVERIFIED — needs human review | 2 |
| (config error) | bad spec path, no git, etc. | 3 |

`VIBE_SHIP_OVERRIDE=1` lifts BLOCK (2 → 0). It cannot lift FAIL. FAIL is a real no.

A pre-push hook ships (opt-in):

```bash
cp kit/bin/hooks/vibe-pre-push .git/hooks/pre-push
chmod +x .git/hooks/vibe-pre-push
```

After install, every `git push` runs `vibe-verify` first. Exit non-zero refuses the push. `git push --no-verify` skips it (documented escape hatch).

## Templates

Two Specs at different lifecycle stages — they're NOT redundant:

| Template | Lifecycle | Scope |
|---|---|---|
| `kit/templates/SPEC.md` | Milestone | Why this milestone; goals (SMART); MoSCoW; success metrics; non-functional requirements |
| `kit/templates/requirements-spec.md` | Per-feature | Goal, ACs, Constraints, Edge Cases, Non-Goals, Verification for ONE feature |

The milestone Spec decomposes into per-feature Specs. Each feature Spec is the input to its Coder session. Each feature AC is one test.

## Install

```bash
git clone https://github.com/Rushabh9033/vibe-kit
cd vibe-kit
./kit/bin/vibe-install           # one-time, auto-detects Claude Code / Cursor / etc.

# Then in any project:
~/.claude/vibe-kit/bin/vibe-install
```

`vibe-install` detects Claude Code / Cursor / Antigravity / Aider / Codex by env vars and cwd files, then drops the right rules + commands + conventions file into your project. It also runs `vibe-init` to scaffold `docs/`, `.github/`, `.gitignore` — **skipping files that already exist**, so it's safe to run in a project that's already in development.

Override detection with `--tool=cursor` (or `antigravity`, `aider`, `codex`, `claude-code`, `generic`). For tool-specific quirks, see `install/<your-tool>.md`.

## What's in the box

```
vibe-kit/
├── prompts/                    ← Planner-side prompts (any chat AI)
│   ├── 00-anchor.md            ← Discovery protocol + role boundary
│   └── 01–07                   ← spec, plan, ADR, edges, handoff, retro
├── kit/
│   ├── bin/
│   │   ├── vibe-install        ← unified installer (auto-detects tool)
│   │   ├── vibe-detect-tool    ← auto-detect claude-code|cursor|aider|...
│   │   ├── vibe-verify         ← Spec ↔ code ↔ tests contract checker
│   │   ├── vibe-classify       ← diff → tiny|normal|large|critical
│   │   ├── vibe-test           ← test oracle (lint/typecheck/unit/integration)
│   │   ├── vibe-spec-intake    ← weapon 1: 1-line intent → spec with ACs
│   │   ├── vibe-claim-check    ← weapon 6: per-AC evidence at ship
│   │   ├── vibe-arm            ← the ultimate weapon: arm all gates
│   │   ├── vibe-init           ← scaffolds a project
│   │   └── hooks/              ← prep-room, vibe-edit-gate, vibe-tdd-gate,
│   │                              vibe-fix-detector, vibe-ac-progress,
│   │                              vibe-bug-mirror, guard-unsafe, handoff, pre-push
│   ├── commands/               ← /vibe-* slash commands
│   ├── rules/                  ← modular rules (security, verify, cost)
│   ├── installers/             ← per-tool skill packs
│   └── templates/              ← Spec, plan, ADR, handoff, CHANGELOG
├── install/                    ← per-tool install guides
├── skills/vibe-kit/            ← packaged Claude Code Skill
├── docs/                       ← playbook, architecture, ceremony levels
├── examples/                   ← intake, spec, plan, handoff samples
│   └── todo-cli/               ← runnable Spec → Code → Verify → Ship demo
└── tests/                      ← verify, classify, vibe-test, prep-room, weapons tests
```

## Two entry points, one Spec

| Entry point | What it does | Where it runs |
|---|---|---|
| **Planner** *(optional)* | Interviews you, surfaces ambiguity, writes the Spec | Any chat AI (Claude.ai, ChatGPT, Gemini). No file access needed. |
| **Coder** | Reads the Spec, writes code and tests. **Also runs Discovery itself when no Spec exists** for non-trivial work. | Any dev tool with file access (Claude Code, Cursor, Aider, Antigravity, Codex). |

You are the human-approval gate. You flip `Status: awaiting-approval` → `Status: in-progress` when the Spec is ready to implement. Either entry point can produce the Spec; the Coder's gate stops for approval regardless of who wrote it.

## Principle

> **Specify small. Verify twice. Persist the lessons.**

The Spec is the durable source of intent. Implementation, tests, ADRs, and handoffs are derived or changed artifacts. When in doubt, the Spec wins — but markdown doesn't enforce that. The **verify + ship** boundary does.

## License

MIT — Copyright © 2026 Rushabh Mavani. See [LICENSE](LICENSE).
