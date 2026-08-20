---
description: Write an Architecture Decision Record (ADR)
---

Write `docs/decisions/NNNN-<slug>.md` per the template at `kit/templates/ADR.md`. The number is sequential — always check the existing directory first.

## What it does

1. Find the highest existing NNNN in `docs/decisions/`.
2. Increment by 1; pad to 4 digits (`0001`, `0002`, ...).
3. Render the ADR template with the user's decision context.
4. If the decision **reverses** a prior ADR, mark the prior ADR `Superseded by NNNN` (only the Status field — never edit the body).
5. Write the file. Don't link it from anywhere else — the spec/plan that triggered the decision will pick it up.

## When to use

- Framework / language / database choice.
- Vendor selection (auth provider, payment processor, observability stack).
- Model + provider + budget selection (AI decisions belong in ADRs).
- Architecture pattern (sync vs async, monolith vs service).
- Deprecation of a feature or pattern.
- Anything irreversible, controversial, or repeated.

## Usage

```
/vibe-decide use-postgres-for-events
/vibe-decide deprecate-mongodb-usage
```

## Required sections

- **Status**: `Proposed` (default) | `Accepted` | `Superseded by NNNN` | `Deprecated`.
- **Date**: today.
- **Deciders / Consulted / Informed**: who was in the room or on the call.
- **Context and problem statement**: 2–3 sentences; forces at play.
- **Decision drivers**: bullet list.
- **Considered options**: at least 2.
- **Decision outcome**: chosen option + 1-line justification.
- **Consequences**: good / bad / neutral.
- **Confirmation**: how compliance with the ADR will be verified.
- **Pros and cons of the options**.

## Output

```
docs/decisions/NNNN-<slug>.md     Status: Proposed
```

Print after writing:

```
adr: docs/decisions/NNNN-<slug>.md
status: Proposed
supersedes: <prior-adr-or-none>
next: link from the spec/plan that triggered this decision; flip Status to Accepted once ratified
```

## Limits

- Don't auto-flip Status to `Accepted` — that's a human ratification. Default to `Proposed`.
- If the prior ADR is `Accepted`, the new one should explicitly call out the reversal in **Decision drivers**.
- Never edit a prior ADR's body — only the `Status` field can change.
