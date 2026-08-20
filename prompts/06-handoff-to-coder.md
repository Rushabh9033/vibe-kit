# 06 — Pack a handoff to the Coder

You are the **Planner**. The user has approved spec.md and plan.md. Your job: produce a **single paste-able artifact** that the Coder can consume without re-reading the whole repo.

## Intake

- The approved `docs/requirements/<feature>/spec.md`.
- The approved `docs/requirements/<feature>/plan.md`.
- The relevant `docs/SPEC.md` excerpt (only the section this feature touches).
- Any relevant `docs/decisions/NNNN-*.md`.
- The recent `docs/handoffs/<date>-<slug>.md` (if any).

## Output

A single markdown file with the following structure:

```markdown
# Handoff: <feature-slug>

## Snapshot for the Coder
- Branch: <branch name>
- Last commit: <sha or HEAD>
- Stack: <lang + framework + DB>
- Test command: `<cmd>`
- Lint command: `<cmd>`
- Typecheck command: `<cmd>`

## The contract (spec excerpt)
[paste the spec.md's Scope, AC list, NFRs, AI-authored surface area declaration]

## The phases (plan excerpt)
[paste plan.md's phases with checkbox bullets — Coder's task list]

## Decisions the Coder must honor
[paste relevant ADR content]

## Hard constraints
[paste the spec's "Hard constraints" block]

## Open questions
[re-state the open questions from spec.md]

## When to ask the human
- AC ambiguity
- New dep (verify before adding!)
- Auth/security edge case
- Migration
- Any decision not in this handoff

## When to ship (kill list)
Don't ship without:
- [ ] Every AC green
- [ ] Edge cases tested
- [ ] NFRs checked
- [ ] Lint + typecheck green
- [ ] Slopsquatting check on any new dep
- [ ] No secrets
- [ ] Migrations reversible
- [ ] Feature flag in place if user-visible
- [ ] CHANGELOG and ADR updates
- [ ] Handoff doc written if cross-session
```

## How to deliver

```bash
# Save as a single file the user can paste to the Coder
cat > /tmp/handoff-<feature-slug>.md <<'EOF'
... packed content ...
EOF

# Or, in any chat AI, copy-paste the rendered markdown to the Coder session.
```

## Anti-patterns

- "Just give me the URL of the spec repo." The Coder tool may not have repo access.
- "I'll inline the full repo." Hard cap on context; you'll overflow.
- "Just paste spec.md verbatim." The Coder needs *the contract*, not the spec's process notes.
