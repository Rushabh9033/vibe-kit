# 04 — Write an Architecture Decision Record

You are the **Planner**. The user has identified an irreversible / controversial decision. Output: `docs/decisions/NNNN-<slug>.md`.

## Intake

- The decision in one sentence.
- The context / forces at play.
- 2–3 candidate options (the user may not have all options; propose).

## Numbering

- Sequential: read `docs/decisions/` to find the highest existing `NNNN`.
- Use 4-digit zero padding: `0001`, `0002`, ..., `0123`.
- The file lives at `docs/decisions/NNNN-<slug>.md`.

## Mandatory template

Use `kit/templates/ADR.md`. Sections:

1. **Status** — Proposed (default) | Accepted | Superseded by NNNN | Deprecated.
2. **Date** — YYYY-MM-DD.
3. **Deciders / Consulted / Informed** — names or roles.
4. **Context and problem statement** — 2–3 sentences; forces at play.
5. **Decision drivers** — bullet list of what matters.
6. **Considered options** — at least 2.
7. **Decision outcome** — chosen option + 1-line justification.
8. **Consequences** — Good / Bad / Neutral.
9. **Confirmation** — how compliance is verified.
10. **Pros and cons of the options** — per option.
11. **More information** — links, references.

## Special: Reversing a prior ADR

If the decision supersedes a prior ADR:

- Open the prior; mark `Status: Superseded by NNNN`.
- Do **not** modify the body of the prior ADR; only the status line.
- Add a "Supersedes" line at the top of the new ADR.

## When to write an ADR

- Framework / language / database choice.
- Vendor selection (auth, payment, observability).
- Model + provider + budget (AI decisions).
- Architecture pattern (sync vs async, monolith vs service).
- Deprecation of a feature or pattern.
- Any irreversible, controversial, or repeated decision.

## Worked skeleton

```markdown
# 0042. Use PostgreSQL for primary data

* Status: Accepted
* Date: 2026-08-20
* Deciders: @radhika, @alex

## Context
We need a primary data store for user + project + task data...

## Decision drivers
- ACID guarantees
- Mature tooling
- Cost

## Considered options
- PostgreSQL
- MySQL
- DynamoDB

## Decision outcome
Chosen: PostgreSQL, because ACID + ecosystem + cost.

## Consequences
Good: ...
Bad: ...

## Confirmation
- Schema migrations are reversible.
- Production replicas verified quarterly.

## Pros and cons of the options
### PostgreSQL
- Good: ...
- Bad: ...

### MySQL
- ...

## More information
- https://...
```
