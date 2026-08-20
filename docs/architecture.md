# Architecture: the two-role model

> The fundamental split. If you only read one architecture document, read this one.

## Why two roles

Modern AI-assisted development is two different jobs wearing one name:

| Job | Inputs | Outputs | Tools |
|---|---|---|---|
| **Planner** | A fuzzy goal, constraints, users, success metrics | Specs, plans, prompts, ADRs, edge-case lists, acceptance criteria | Any AI chat (Claude.ai, ChatGPT, Gemini, etc.) — context-rich, no file/command access needed |
| **Coder** | Spec + repo + runnable environment | Code, tests, handoffs, fixes | Dev tools with file/command access (Claude Code, Cursor, Antigravity, Aider, Codex, Windsurf) |

Conflating the two is the most common failure mode. The Planner is good at synthesis, ambiguity resolution, and structured reasoning across long documents. The Coder is good at mechanical precision, type-checking, and respecting file conventions. When you make the same AI do both — and especially when you ask a chat-only model to "go code it" — you get half-plans and half-tests.

**The spec is the contract** between roles. The Planner produces it; the Coder consumes it. No code generation happens until the spec exists.

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

## What goes wrong when you mix the roles

| Failure | Cause | Fix |
|---|---|---|
| AI "vibes" a spec while coding | Wrong model set (Coder doesn't write specs well) | Use Planner role for spec |
| Spec is too vague to verify | Insufficient prompt (decompose-PRD was skipped) | Run all 5 prompts in order |
| Code doesn't match spec | Coder didn't read the spec (workspace load order) | Use the `00-anchor` prompt first |
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

## When one model has to play both roles

Sometimes you're prototyping and only have one AI. In that case:

1. Open with `prompts/00-anchor.md` — forces the model into Planner-thinking.
2. Generate spec, plan, ADR.
3. Save those to disk.
4. Then switch the session into "Coder mode" by reloading with anchor prompt + a clear "now write code" framing.
5. Run `/vibe-verify` before claiming done.

This is worse than dedicated roles but workable. The spec is still the artifact.

## The principle

> **Role clarity beats tool virtuosity.** The strongest single-AI workflow is worse than the weakest two-role workflow with a clear contract.

See `playbook.md` for the full playbook. See `requirements-gathering.md` for the most important workflow.
