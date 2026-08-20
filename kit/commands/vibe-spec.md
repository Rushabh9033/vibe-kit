---
description: Write a per-feature spec from intake answers
---

Write `docs/requirements/<feature-slug>/spec.md` from the user's intake answers, using the template at `kit/templates/requirements-spec.md`.

## What it does

1. Read `docs/SPEC.md` if present; link the feature to a milestone.
2. Run the **Discovery protocol** from `prompts/00-anchor.md` § Discovery protocol — interview the user one question at a time (job-to-be-done, user, success metric, out-of-scope, hard constraints, risks). Don't proceed past vague answers.
3. After the interview, render `kit/templates/requirements-spec.md` with the captured answers.
4. Write the file with `Status: awaiting-approval`. The user must review and edit before it becomes `in-progress`.
5. Print a 5-line summary + the file path. **Do not start coding.**

## When to use

- After the user has a one-line idea and the Discovery protocol interview is complete.
- Whenever the user types `/vibe-spec <feature-slug>`.
- Before `/vibe-plan`.

## Usage

```
/vibe-spec profile-photo-upload
/vibe-spec profile-photo-upload   # name + intake already in chat
```

If `<feature-slug>` is omitted, derive from the user's intake (kebab-case, ≤ 40 chars).

## VCP rules (non-negotiable)

- **Each AC = one machine-checkable test or explicit human-judged gate.** If you can't name the check, the AC is incomplete. `/vibe-verify` will block on ACs without tests.
- **Edge cases are exhaustive**, not "handled later." Cover: empty input, max-size input, unicode/non-ASCII, concurrent same-resource access, network failure mid-operation, expired auth, unauthorized user, DB unavailable, idempotency on retry, timezone/clock skew, malformed input.
- **NFRs** with target + check tool: perf, a11y, security, observability, privacy.
- **AI-authored surface area** declaration: what AI may write, what humans must author.
- **Risks** with id, likelihood, impact, mitigation, trigger, owner.

## Output

```
docs/requirements/<feature-slug>/spec.md     Status: awaiting-approval
```

Print after writing:

```
spec written: docs/requirements/<feature-slug>/spec.md
ACs: <count>
open questions: <count>
next: review the spec, set Status to in-progress, then /vibe-plan
```

## Limits

- The Planner does not auto-approve. The user must read, edit, and set `Status: in-progress` before the Coder touches the file.
- If `docs/SPEC.md` doesn't exist, link the feature to "(no milestone yet)" and flag it as an open question — the user may want to write the milestone spec first.
- Don't import code or test stubs into the spec — the spec is contract, not implementation.
