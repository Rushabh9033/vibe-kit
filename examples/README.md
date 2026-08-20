# Examples

A complete feature worked through the two-role pipeline. Use it as a reference when you have a similar feature to ship.

## Files

| File | What it is | Role |
|---|---|---|
| `intake-prd.md` | What the user typed into the Planner chat to start | user → planner |
| `planner-output-spec.md` | The Planner produced this with `prompts/02-feature-spec.md` | planner → coder |
| `planner-output-plan.md` | The Planner produced this with `prompts/03-feature-plan.md` | planner → coder |
| `coder-output-handoff.md` | The Coder wrote this at session end (using kit's session-end-handoff.sh + slash commands) | coder → next-session |

## The flow

```
1. User types intake (intake-prd.md) → Planner chat
2. Planner runs prompts/00-anchor.md → confirms context
3. Planner runs prompts/01-decompose-prd.md → outputs docs/SPEC.md (not shown — see docs/architecture.md)
4. Planner runs prompts/02-feature-spec.md → planner-output-spec.md
5. User reviews the spec
6. Planner runs prompts/03-feature-plan.md → planner-output-plan.md
7. User reviews the plan
8. Planner runs prompts/06-handoff-to-coder.md → packed file
9. Coder (Claude Code / Cursor / etc.) opens in the project
10. Coder runs /vibe-anchor + walks the plan phases
11. End of session: Coder's stop hook fires; writes coder-output-handoff.md
12. Planner runs prompts/07-retrospective.md → updates docs/gotchas.md, ADRs, AGENTS.md
```

## Why these four files exist

Each is a **distinct role boundary**:

- **Intake** is the user's only input. Everything else is generated.
- **Spec** is the contract. The Planner produces it; the Coder can verify against it.
- **Plan** is the work breakdown. Each phase is small enough for one Coder session.
- **Handoff** is the cross-session continuity. Without it, every session starts from zero.

## Tip

When you start your own project, copy these four files into your own `examples/` directory, walk through them as a template, and replace with your own. The structure is the lesson; the words are filler.

## Honest note

This worked example was produced from earlier conversation transcripts and condensed — it's representative of vibe-kit's expected outputs, not a literal trace. Use it to see the *shape* of each artifact.
