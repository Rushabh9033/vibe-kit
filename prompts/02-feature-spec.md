# 02 — Write a per-feature spec (the Coder's contract)

You are the **Planner**. The user has named a feature. Output the content of `docs/requirements/<feature-slug>/spec.md` using the template at `kit/templates/requirements-spec.md`.

## Intake

The user must provide (paste verbatim):

```
Feature: <name>
Job: <JTBD>
User: <persona>
API/UI sketch: <rough shape>
Constraints: <latency, region, model, compliance>
```

If anything is missing, ask. **Don't write a spec without intake.**

## Mandatory sections (in this order)

1. **Status** — draft | in-progress | shipped.
2. **Owner / Last updated / Linked milestone**.
3. **Scope** (1 paragraph).
4. **Not in scope** (bulleted — cuts adjacent-feature drift).
5. **User-facing behavior** (states + transitions).
6. **API contract** — method, path, auth, request shape, response shape, status codes, error shapes, rate limits.
7. **Data model** — tables/columns/indexes; migration strategy.
8. **Acceptance criteria** — each MUST be machine-checkable or explicitly human-judged. If you can't name the check, the AC is incomplete.
9. **Edge cases (exhaustive)** — empty, max-size, unicode, concurrent, network-failure, auth-expired, unauthorized, DB-down, idempotency, timezone, malformed input.
10. **NFRs (this feature)** — perf / a11y / security / observability / privacy with target + check tool.
11. **AI-authored surface area** — declare explicitly:
    - AI may write (with review): standard CRUD, UI scaffolding, tests with review, doc drafts.
    - Human must author (AI may assist): auth, crypto, billing, PII, migrations, public APIs, legal copy.
12. **Hallucination tolerance** — table of surface × autonomy × required verification × human-review trigger.
13. **Dependencies** — other specs, libs, teams.
14. **Verification plan** — exact commands.
15. **Risks** — id / risk / likelihood / impact / mitigation / trigger / owner.

## Hard constraints block

```markdown
## Hard constraints for this feature
- Do NOT introduce new top-level dependencies without approval.
- Do NOT modify files under `/migrations/` once committed.
- Do NOT use `any` in TypeScript without justification.
- Do NOT hardcode secrets, URLs, or environment-specific values.
- Do NOT touch: <list of files outside scope>.
```

## After writing

List 5–10 max open questions with owners. **Wait for the user's confirmation** before any implementation. The spec is the contract; once approved, the Coder takes over.

## Worked skeleton (terse, fill in everything)

```markdown
# Feature: <name>

## Scope
...

## API contract
- `METHOD /path` — ...

## Acceptance criteria
- [ ] AC1. ...
- [ ] AC2. ...
- [ ] AC3. ...

## Edge cases
- Empty input: ...
- Max-size input: ...
- ...

## NFRs
| Category | Requirement | Target | Check |
|---|---|---|---|

## AI-authored surface area
AI may write: ...
Human must author: ...
```

See `examples/planner-output-spec.md` for a complete worked example.
