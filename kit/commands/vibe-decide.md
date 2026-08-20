---
description: Write an Architecture Decision Record (ADR)
---

Write `docs/decisions/NNNN-<slug>.md` per the template at `~/.claude/vibe-kit/templates/ADR.md`.

## Numbering

- Sequential, starting from the highest existing NNNN in `docs/decisions/`.
- Always check the existing directory before numbering.
- Use leading zeros to 4 digits: `0001`, `0002`, ..., `0042`, `0123`.

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

## If the decision reverses a prior ADR

- Open the prior ADR; mark it `Superseded by NNNN` (the new one).
- Do not edit prior ADR body — only the status.

## When to write one

- Framework / language / database choice.
- Vendor selection (auth provider, payment processor, observability stack).
- Model + provider + budget selection (AI decisions belong in ADRs).
- Architecture pattern (sync vs async, monolith vs service).
- Deprecation of a feature or pattern.
- Anything irreversible, controversial, or repeated.
