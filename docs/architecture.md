# Architecture: the two-role model

> The fundamental split. If you only read one architecture document, read this one.

## Why the Spec is the contract

Modern AI-assisted development is two different jobs wearing one name — but
the Spec, not the Planner, is the bridge:

| Job | Inputs | Outputs | Tools |
|---|---|---|---|
| **Spec producer** *(Planner OR Coder)* | A fuzzy goal, constraints, users, success metrics | Specs, plans, prompts, ADRs, edge-case lists, acceptance criteria | Any AI chat (Planner) OR the Coder itself (when no Spec exists) |
| **Coder** | Spec + repo + runnable environment | Code, tests, handoffs, fixes | Dev tools with file/command access (Claude Code, Cursor, Antigravity, Aider, Codex, Windsurf) |

The Spec is the contract — full stop. The Planner is **one way** to produce it.
The Coder is **another way** (when no Spec exists, the Coder runs Discovery
itself and writes the Spec, then **stops for approval** before implementing).
Conflating "Spec" with "Planner" is the most common failure mode: teams
assume they need two sessions, two tools, two windows. They don't. They need
one Spec, approved by one human, then one Coder.

**No code generation happens until the Spec exists** — and the Spec has
`Status: in-progress`. The user is the only one who can flip the Status.

## The handoff object

Markdown files in your repo, in this exact tree:

```
docs/
├── SPEC.md                              # master product spec (planner-owned)
├── ARCHITECTURE.md                      # architectural notes
├── requirements/<feature-slug>/
│   ├── spec.md                          # per-feature contract (planner output)
│   └── plan.md                          # phased steps (planner output)
├── decisions/
│   ├── README.md
│   ├── template.md                      # ADR template (planner output)
│   └── NNNN-<slug>.md                   # sequential ADRs (planner output)
├── handoffs/
│   └── YYYY-MM-DD-<slug>.md             # coder-side session logs
└── gotchas.md                           # both roles contribute
```

Planners write to `docs/SPEC.md`, `docs/requirements/`, and `docs/decisions/`. Coders write to `docs/handoffs/` and `docs/gotchas.md`.

## How a Planner session feels

```
You:  I want to build X.

Planner prompt 01-decompose-prd.md:
  → output: docs/SPEC.md (milestone) + a feature map

Planner prompt 02-feature-spec.md:
  → for each feature: docs/requirements/<slug>/spec.md
  → ACs, edge cases, NFRs, AI-authored surface area, risks

Planner prompt 03-feature-plan.md:
  → for each feature: docs/requirements/<slug>/plan.md
  → phased, one session per phase, decisions left to make

Planner prompt 04-adr.md:
  → for each irreversible decision: docs/decisions/NNNN-<slug>.md

Planner prompt 05-edge-cases.md:
  → verifies and adds to spec.md

Planner prompt 06-handoff-to-coder.md:
  → packs the spec + plan into a single copy-paste
  → handed to the Coder tool
```

No code is written. No tests are touched. The Planner session ends with a `/vibe-handoff` (or equivalent) that points the Coder at `docs/requirements/<feature>/spec.md`.

## How a Coder session feels

```
Coder prompt (or slash command /vibe-anchor):
  → reads AGENTS.md, docs/requirements/<feature>/spec.md,
    docs/requirements/<feature>/plan.md, latest handoff

Phase-by-phase (using /vibe-plan + /vibe-verify + /vibe-ship):
  → Schema → API/Logic → UI → Tests → Docs → Ship

End of session:
  → Stop hook writes docs/handoffs/<date>-<slug>.md
  → Updates HANDOFF.md and CHANGELOG.md [Unreleased]
```

## What goes wrong when you skip the Spec

| Failure | Cause | Fix |
|---|---|---|
| AI "vibes" a spec while coding | Spec was skipped or under-specified | The Coder runs Discovery itself before writing code (spec-first gate) |
| Spec is too vague to verify | Insufficient prompt (decompose-PRD was skipped) | Run all 5 Planner prompts in order — or the Coder runs the Discovery protocol |
| Code doesn't match spec | Coder didn't read the spec (workspace load order) | Spec-first gate runs at task start; reads `docs/requirements/<feature>/spec.md` if present |
| Same mistake next session | No compound-correction persistence | Tool-level CLAUDE.md/AGENTS.md discipline |
| AI hallucinates a package | No slopsquatting rule | `kit/rules/03-no-slopsquatting.md` |

## What goes right when you use both

- A planner model has a 200k–1M+ token window: it can read all your prior specs, ADRs, and handoffs in one go. The Coder rarely has that luxury.
- A Coder tool runs your actual test suite, formatter, typechecker. The Planner can't.
- A planner knows the product, the users, the metric. A coder knows the diff and the failing line.
- Specialization compounds. Generalization doesn't.

## Hand-off packages — the boundary artifact

When you finish a Planner session and want to feed the result to a Coder:

```bash
# Pack the relevant docs into one file
cat docs/SPEC.md \
    docs/requirements/<feature>/spec.md \
    docs/requirements/<feature>/plan.md \
    > /tmp/handoff-<feature>.md

# Or use prompts/06-handoff-to-coder.md to generate a hand-curated pack.
```

That single file is the boundary. The Coder session can be on a different machine, in a different timezone, with a different model — the contract holds.

## When one tool plays both jobs

When you have one tool (Claude Code, Cursor, etc.) and no separate chat AI:

1. At task start, the spec-first gate runs.
2. If no applicable Spec exists for non-trivial work, the Coder enters
   DISCOVERY MODE (canonical source: `prompts/00-anchor.md` § Discovery
   protocol). It asks one question at a time.
3. After Discovery, the Coder writes `docs/requirements/<feature>/spec.md`
   from `kit/templates/requirements-spec.md` with `Status: awaiting-approval`.
4. The Coder **stops**. It does not implement in the same turn.
5. The user reviews, edits, and sets `Status: in-progress`.
6. The next turn, the Coder re-reads the Spec and implements.

Same workflow, one tool. The Spec is still the artifact, and the
human-approval gate is still the only one who can flip the Status.

## The principle

> **Spec clarity beats role clarity.** The strongest workflow is one with a
> clear Spec — regardless of whether one AI or two produced it.

See `playbook.md` for the full playbook. See `requirements-gathering.md` for the most important workflow.
