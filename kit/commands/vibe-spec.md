---
description: Write a per-feature spec from intake notes
---

Write `docs/requirements/<feature-slug>/spec.md` using the template at `~/.claude/vibe-kit/templates/requirements-spec.md`.

## VCP rules (non-negotiable)

- **Each acceptance criterion = one machine-checkable test or explicit human-judged gate.** If you can't name the check, the AC is incomplete.
- **Edge cases are exhaustive**, not "handled later." Cover: empty input, max-size input, unicode/non-ASCII, concurrent same-resource access, network failure mid-operation, expired auth, unauthorized user, DB unavailable, idempotency on retry, timezone/clock skew, malformed input.
- **NFRs**: perf, a11y, security, observability, privacy — each with target + check tool.
- **AI-authored surface area** declaration (mandatory): what AI may write, what humans must author.
- **Hallucination tolerance** declared per surface area (see kit rule).
- **Risks** with id, likelihood, impact, mitigation, trigger, owner.
- **Verification plan** with exact commands.

## Process

1. Read `docs/SPEC.md` if it exists; link the feature to a milestone.
2. Draft all sections; respect "not in scope" — no scope creep.
3. List 5–10 max open questions at the end with owners.
4. After writing, ask the user to confirm before any implementation.

## Intake

The user must provide: feature name, the job-to-be-done, the user, the rough API/UI, and any constraints (latency, region, model). Anything missing → ask before writing.
