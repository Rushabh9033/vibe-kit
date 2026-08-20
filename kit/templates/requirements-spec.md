# Feature: <Name>

Status: draft | awaiting-approval | in-progress | shipped
Owner: @handle
Last updated: YYYY-MM-DD
Linked milestone: docs/SPEC.md ## M1

## Human approval

> The Planner does NOT auto-approve this spec. The user must read it, edit
> anything they want different, and set `Status` to `in-progress` before the
> Coder touches it. This is the only gate that catches intent errors before
> they become code errors.

- [ ] User has read spec end-to-end
- [ ] User has edited anything they want changed
- [ ] User has set `Status: in-progress`
- [ ] User has explicitly said "approved" or "ship it" in chat

## Scope
<One paragraph. What this is.>

## Not in scope
- ...

## User-facing behavior
- <What the user sees / does>
- <State transitions>

## API contract
- `METHOD /path` — auth, request, response, status codes, error shapes
- Rate limits: ...

## Data model
- New tables / columns / indexes
- Migration strategy: <forward-only with down; or new migration>

## Acceptance criteria (each = one test)
- [ ] AC1. <Verifiable behavior>
- [ ] AC2.
- [ ] AC3. <Edge case>

## Edge cases (exhaustive)
- Empty input: ...
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

## NFRs (this feature)
| Category | Requirement | Target | Check |
|---|---|---|---|
| Perf | P95 latency | < 200 ms | k6 |
| A11y | <keyboard / SR> | 100% | axe-core |
| Security | <authn/authz> | enforced | SAST |

## AI-authored surface area

AI may write (with review):
- [ ] Standard CRUD
- [ ] UI scaffolding
- [ ] Tests (with review)
- [ ] Docs drafts

Human must author (AI may assist):
- [ ] Auth / authz
- [ ] Crypto / billing
- [ ] Migrations
- [ ] Public APIs / SDKs

## Dependencies
- <Other specs / modules / teams>

## Verification plan
- Commands: `<test>`, `<lint>`, `<build>`, `<audit>`
- Manual steps: ...
- Human review: who, when

## Risks
| ID | Risk | Likelihood | Impact | Mitigation | Trigger | Owner |
|---|---|---|---|---|---|---|
| R1 | ... | 3 | 4 | ... | ... | @handle |
