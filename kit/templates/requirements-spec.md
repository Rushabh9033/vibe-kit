# Feature: <Name>

Status: draft | awaiting-approval | in-progress | shipped
Owner: @handle
Last updated: YYYY-MM-DD
Linked milestone: docs/SPEC.md ## M1

> The Spec is the durable contract between planning and implementation.
> It is human-readable, tool-agnostic, and implementation-independent.
> It is the source of truth for intended behavior. When the Spec and the
> code disagree, the Spec wins — until the user explicitly revises it.

## Human approval

> The Planner does NOT auto-approve this spec. The user must read it,
> edit anything they want different, and set `Status: in-progress`
> before the Coder touches it. This is the only gate that catches
> intent errors before they become code errors.

- [ ] User has read the spec end-to-end
- [ ] User has edited anything they want changed
- [ ] User has set `Status: in-progress`
- [ ] User has explicitly said "approved" or "ship it" in chat

## Goal

<One paragraph. What this feature is for, in user-facing language. Not implementation.>

## User Stories

- As a **<persona>**, I want **<capability>**, so that **<outcome>**.
- As a **<persona>**, I want **<capability>**, so that **<outcome>**.

(3–8 stories. Each is testable. If a story cannot be tested, it is not a story — it is a wish.)

## Requirements

### Functional

<What the system does. Each bullet is a discrete capability. Use bullets, not prose.>

### API contract

- `METHOD /path` — auth, request, response, status codes, error shapes
- Rate limits: ...

### Data model

- New tables / columns / indexes
- Migration strategy: <forward-only with down; or new migration>

### Non-functional

| Category | Requirement | Target | Check |
|---|---|---|---|
| Perf | P95 latency | < 200 ms | k6 |
| A11y | keyboard / SR | 100% | axe-core |
| Security | authn/authz | enforced | SAST |
| Privacy | <field> | <rule> | <check> |

## Acceptance Criteria

> Each AC must be machine-checkable or explicitly human-judged. If you
> can't name the check, the AC is incomplete. `/vibe-verify` will block
> on ACs without tests.
>
> For each AC, fill in a `Verification:` block with the **automated
> test path** (`path::test_name`) and a one-line **expected behavior**.
> `vibe-verify` checks the test path is in the diff and the test
> function name appears in that file's diff (added or unchanged). Tests
> are then run automatically when a runner is detected.

- [ ] **AC1.** <Verifiable behavior>
  - Verification:
    - automated test: `tests/test_<feature>.py::test_<AC1>_<slug>`
    - expected behavior: <one line: what the test asserts>
- [ ] **AC2.** <Verifiable behavior>
  - Verification:
    - automated test: `tests/test_<feature>.py::test_<AC2>_<slug>`
    - expected behavior: <one line>
- [ ] **AC3.** <Edge case> — see Edge Cases section
  - Verification:
    - automated test: `tests/test_<feature>.py::test_<AC3>_<slug>`
    - expected behavior: <one line>
- [ ] **AC4.** *(human-judged)* <Behavior that needs review, not a test>

## Constraints

### Hard constraints

- Do NOT introduce new top-level dependencies without approval.
- Do NOT modify files under `/migrations/` once committed.
- Do NOT use `any` in TypeScript without justification.
- Do NOT hardcode secrets, URLs, or environment-specific values.
- Do NOT touch: <list of files outside scope>.

### AI-authored surface area

> Without this, every PR is a debate. It is the contract between human
> reviewer and AI.

AI may write (with review):
- [ ] Standard CRUD
- [ ] UI scaffolding
- [ ] Tests (with review)
- [ ] Doc drafts

Human must author (AI may assist):
- [ ] Auth / authz
- [ ] Crypto / billing
- [ ] Migrations
- [ ] Public APIs / SDKs

## Edge Cases (exhaustive)

> Edge cases are most of the work. They are listed here and tested in
> the implementation. "Handled later" is not a status.

### Mandatory 11

- Empty input (length 0): ...
- Max-size input: ...
- Unicode / non-ASCII: ...
- Concurrent same-resource access: ...
- Network failure mid-operation: ...
- Auth token expired: ...
- User with no permission: ...
- DB unavailable: ...
- Idempotency on retry: ...
- Timezone / clock skew: ...
- Malformed input: ...

### Beyond mandatory

- <domain-specific edge cases>

## Non-Goals

- <What is explicitly NOT being built in this feature>
- <Adjacent features deferred to a different spec>

## Technical Decisions

> Decisions that shape the implementation. For irreversible or
> controversial ones, link an ADR (`docs/decisions/NNNN-<slug>.md`).

- **<decision>**: <one-line rationale>
- **<decision>**: <one-line rationale> (see ADR NNNN)

## Verification

### Plan

- Commands: `<test>`, `<lint>`, `<build>`, `<audit>`
- Manual steps: ...
- Human review: who, when

### Risks

| ID | Risk | Likelihood | Impact | Mitigation | Trigger | Owner |
|---|---|---|---|---|---|---|
| R1 | ... | 3 | 4 | ... | ... | @handle |

### Dependencies

- <Other specs / modules / teams this work blocks or is blocked by>
