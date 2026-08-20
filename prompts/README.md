# Prompts — for the Planner role

> The Planner can be **any AI**: Claude.ai, ChatGPT, Gemini, Claude Code's chat mode, anything with a long context window and a chat interface.
> The Coder role is the dev tool (Claude Code, Cursor, Antigravity, Aider, Codex, Windsurf). See `kit/commands/`.

## The two-role model in 60 seconds

```
1. Open a chat AI → run prompts in order
   01-decompose-prd.md    → docs/SPEC.md + feature map
   02-feature-spec.md     → docs/requirements/<slug>/spec.md
   03-feature-plan.md     → docs/requirements/<slug>/plan.md
   04-adr.md              → docs/decisions/NNNN-<slug>.md
   05-edge-cases.md       → verify spec is complete
   06-handoff-to-coder.md → packed file for the dev tool

2. Open a dev tool → run kit/commands/ in order
   /vibe-anchor           → load context
   /vibe-plan  <slug>     → already written by planner
   /vibe-verify           → run verification ranks
   /vibe-ship             → pre-flight + CHANGELOG + handoff

3. End of session → the dev tool's Stop hook writes docs/handoffs/<date>-<slug>.md

4. After ship (planner again) → prompts/07-retrospective.md
   → updates docs/gotchas.md, ADRs, etc.
```

## The prompts

| # | Prompt | Output | When |
|---|---|---|---|
| 00 | `00-anchor.md` | Reads / confirms | First message of every Planner session |
| 01 | `01-decompose-prd.md` | `docs/SPEC.md` + feature map | Once at project start |
| 02 | `02-feature-spec.md` | `docs/requirements/<slug>/spec.md` | Per feature |
| 03 | `03-feature-plan.md` | `docs/requirements/<slug>/plan.md` | Per feature |
| 04 | `04-adr.md` | `docs/decisions/NNNN-<slug>.md` | Per irreversible decision |
| 05 | `05-edge-cases.md` | Edge-case additions to spec.md | After spec is drafted |
| 06 | `06-handoff-to-coder.md` | `/tmp/handoff-<feature>.md` | Before handoff to dev tool |
| 07 | `07-retrospective.md` | Updates to gotchas / ADRs / CLAUDE.md | After ship |

## Usage pattern

```text
# In ChatGPT, Claude.ai, or any chat AI:

You: [paste contents of prompts/00-anchor.md]
You: [paste your project idea, e.g., "Todo app for couples"]

AI:  [reads anchor; asks 3–5 clarifying questions]

You: [answers]

You: [paste prompts/01-decompose-prd.md]
You: [paste the project idea with the answers]

AI:  [outputs docs/SPEC.md content + a feature map]
You: [save it to docs/SPEC.md in your repo]

You: [for each feature, paste prompts/02-feature-spec.md + the feature name]
You: [save the output as docs/requirements/<slug>/spec.md]
...
```

Each prompt's body has its own intake format. See the file for what to give it.

## When one AI is doing both roles

If you only have one AI:

1. Open the session with `00-anchor.md`.
2. Run prompts 01–05 to produce specs, plans, ADRs.
3. Save those files to disk.
4. Re-open the session (or use a "now switch to coder mode" cue) and run `/vibe-anchor`-equivalent in the dev tool.

The two-role discipline still holds even with one model.

## What these prompts are not

- Not copilots. They are templates you fill in.
- Not exhaustive. Each project adds its own.
- Not opinionated about *language*. They shape the contract; the dev tool chooses the syntax.

## Customization

Add a `prompts/` directory in *your* project. Mirror this one; replace prompts as you learn what works.
