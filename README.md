# vibe-kit

**by Rushabh Mavani** — a spec-first workflow for AI-assisted software development.

> **If this is a 3-line bug fix, you don't need vibe-kit.**
> If you've ever said *"the AI built what I asked for, but not what I meant"*, this kit exists for you.

## The pain

```
You:  "Add a profile photo upload."
AI:   builds 4 image variants, mobile-first, EXIF-stripped, idempotent,
      rate-limited, with a crop modal UI, in the wrong place.
You:  spend 2 hours unwinding.
```

The failure isn't the AI. The failure is that **intent was never made specific**.
vibe-kit forces you to write a Spec before the code exists, then makes the
ship boundary check the code against the Spec.

## The workflow

```
Spec  →  Code  →  Verify  →  Ship
```

That's it. Four steps. The Spec is where you decide; the Code is where
the AI executes; Verify is where you find out whether the AI executed
against the Spec; Ship is the boundary that holds.

For larger work, supporting workflows exist (Plan, Decide, Handoff).
You don't have to learn them. Use them when the work earns them.

### Spec-first. Planner optional.

The Spec is mandatory. The Planner is not — it is one of two entry
points to producing the Spec:

- **Planner entry**: open a chat AI (Claude.ai, ChatGPT, Gemini), run
  `prompts/00-anchor.md` → Discovery → write `docs/requirements/<feature>/spec.md`.
- **Coder entry**: open your dev tool (Claude Code, Cursor, etc.); at
  task start, the spec-first gate (`kit/templates/spec-first-gate.md`)
  runs. If no applicable Spec exists for non-trivial work, the Coder
  runs Discovery itself, writes the Spec, and **stops for your approval**
  before any code is touched.

Either path produces the same Spec. The ship gate (`vibe-verify` +
`/vibe-ship`) doesn't care which path produced it. The Planner is
useful when the planning model has a longer context window than the
coding tool, or when the user is not the coder. The Coder-as-discoverer
is useful when you want one tool, one session.

```
   Human intent (vague, one line)
        ↓
   ┌──────────────┐
   │  Spec        │  ← durable markdown; the source of product intent
   │  Goal · ACs  │
   │  Constraints │
   └──────┬───────┘
          │
   ┌──────▼───────┐
   │  Code        │  ← AI / human / both; against the Spec
   │  + tests     │
   └──────┬───────┘
          │
   ┌──────▼───────┐
   │  Verify      │  ← /vibe-verify; checks the diff against the Spec
   │  PASS / FAIL │  ← exits 0 / 1 — a real gate
   │  BLOCK       │  ← exits 2 — needs human review; override with VIBE_SHIP_OVERRIDE
   └──────┬───────�
          │
   ┌──────▼───────┐
   │  Ship        │  ← /vibe-ship + pre-push hook (opt-in)
   └──────────────┘
```

**See it in action**: [`examples/todo-cli/`](examples/todo-cli/) is a runnable demo.
Spec, implementation, verify output, a deliberate ship-blocker, and the fix.

## What this kit does NOT do

- It does **not** make the Spec self-enforce. The Spec is markdown; markdown cannot block a push on its own. Enforcement comes from the **verify + ship** boundary (see below).
- It does **not** prove the code is correct. `vibe-verify` is an evidence/tripwire system: it catches missing tests, missing implementations, and constraint violations. It cannot prove a test exercises the AC. Use mutation testing (rank 4) for that.
- It does **not** require a separate Planner session. The Coder can run Discovery itself when no Spec exists. The user is the human-approval gate between Spec and code — they decide when the Spec is ready to implement.
- It does **not** own your repository. The pre-push hook is opt-in. `git push --no-verify` and `VIBE_SHIP_OVERRIDE=1` are escape hatches, documented.

## Ceremony scales with the work

The kit recommends the workflow based on the diff — you don't pick. Run:

```bash
vibe-classify                # tiny | normal | large | critical
```

It looks at: diff size, files touched, and whether the diff touches
sensitive paths (`/auth/`, `/billing/`, `/secrets/`, etc.). Conservative
defaults — when in doubt it recommends the heavier ceremony.

| Level | When (auto-detected) | Pipeline |
|---|---|---|
| **tiny** | < 3 files, < 30 lines, no sensitive paths | edit → commit (skip the kit) |
| **normal** | typical feature change | spec.md (lite) → code → /vibe-verify → /vibe-ship |
| **large** | ≥ 15 files or ≥ 500 lines, or schema/architecture | full spec → /vibe-plan → code → /vibe-verify → /vibe-ship |
| **critical** | auth / billing / secrets / destructive migrations | full spec + /vibe-decide (mandatory) + mutation testing + 2 reviewers |

The Mandatory 11 edge-case thinking is **valuable**. It's a checklist for
your brain, not a section to fill in on every change. Use it for Normal
and above. Skip it for Tiny.

## The Spec — what it is, and what it isn't

The Spec is **markdown**. It's durable (lives in git), human-readable,
and tool-agnostic. It captures product intent at a level that survives
context loss.

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
Two Specs exist at different levels — see [Templates](#templates).

## Verify — the actual gate

`vibe-verify` extracts ACs from `docs/requirements/<feature>/spec.md`
and checks the git diff against each. Honest status model:

| Status | Meaning | Exit code |
|---|---|---|
| **PASS** | evidence in the diff for the AC | 0 |
| **FAIL** | no evidence | 1 |
| **BLOCK** | PARTIAL or UNVERIFIED — needs human review | 2 |
| (config error) | bad spec path, no git, etc. | 3 |

**`VIBE_SHIP_OVERRIDE=1`** lifts BLOCK (2 → 0). It cannot lift FAIL.

A pre-push hook is shipped (opt-in):

```bash
cp kit/bin/hooks/vibe-pre-push .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

After install, every `git push` runs `vibe-verify` first. Exit non-zero
refuses the push. `git push --no-verify` skips it (documented escape hatch).

## Templates

Two Specs at different lifecycle stages — they are NOT redundant:

| Template | Lifecycle | Scope |
|---|---|---|
| `kit/templates/SPEC.md` | Milestone | Why this milestone; goals (SMART); MoSCoW; success metrics; non-functional requirements |
| `kit/templates/requirements-spec.md` | Per-feature | Goal, ACs, Constraints, Edge Cases, Non-Goals, Verification for ONE feature |

The milestone Spec decomposes into per-feature Specs. Each feature Spec
is the input to its Coder session. Each feature AC is one test.

## Install

The kit auto-detects which AI dev tool you use and installs the right config:

```bash
git clone https://github.com/Rushabh9033/vibe-kit
cd vibe-kit
./kit/bin/vibe-install           # one-time, auto-detects Claude Code / Cursor / etc.

# Then in any project:
~/.claude/vibe-kit/bin/vibe-install
```

`vibe-install` detects Claude Code / Cursor / Antigravity / Aider / Codex
by env vars and cwd files, then drops the right rules + commands +
conventions file into your project. It also runs `vibe-init` to scaffold
`docs/`, `.github/`, and `.gitignore` — **skipping files that already
exist**, so it's safe to run in a project that's already in development.

Override detection with `--tool=cursor` (or `antigravity`, `aider`,
`codex`, `claude-code`, `generic`). For tool-specific quirks, see
`install/<your-tool>.md`.

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
│   │   ├── vibe-init           ← scaffolds a project
│   │   └── hooks/              ← format-on-edit, guard-unsafe, handoff, pre-push
│   ├── commands/               ← /vibe-* slash commands
│   ├── rules/                  ← modular rules (security, verify, cost)
│   ├── installers/             ← per-tool skill packs
│   └── templates/              ← Spec, plan, ADR, handoff, CHANGELOG
├── install/                    ← per-tool install guides
├── skills/vibe-kit/            ← packaged Claude Code Skill
├── docs/                       ← playbook, architecture, ceremony levels
├── examples/                   ← intake, spec, plan, handoff samples
│   └── todo-cli/               ← runnable Spec → Code → Verify → Ship demo
└── tests/                      ← verify + classify tests
```

## Two entry points, one Spec

| Entry point | What it does | Where it runs |
|---|---|---|
| **Planner** *(optional)* | Interviews you, surfaces ambiguity, writes the Spec | Any chat AI (Claude.ai, ChatGPT, Gemini). No file access needed. |
| **Coder** | Reads the Spec, writes code and tests. **Also runs Discovery itself when no Spec exists** for non-trivial work. | Any dev tool with file access (Claude Code, Cursor, Aider, Antigravity, Codex). |

The user is the human-approval gate. They flip `Status: awaiting-approval`
→ `Status: in-progress` when the Spec is ready to implement. Either
entry point can produce the Spec; the Coder's gate stops for approval
regardless of who wrote it.

## Principle

> **Specify small. Verify twice. Persist the lessons.**

The Spec is the durable source of intent. Implementation, tests, ADRs,
and handoffs are derived or changed artifacts. When in doubt, the Spec
wins — but markdown doesn't enforce that. The **verify + ship**
boundary does.

## License

MIT — Copyright © 2026 Rushabh Mavani. See [LICENSE](LICENSE).
