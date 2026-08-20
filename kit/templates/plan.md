# Implementation Plan: <Name>

Linked spec: `spec.md`

## Phases
1. Schema
2. Backend
3. Frontend
4. Tests
5. Docs

## Phase 1 — Schema
- [ ] Migration file (new, never edited)
- [ ] Model update
- [ ] Repository update

## Phase 2 — API
- [ ] Endpoint + contract (matches spec)
- [ ] Validation (zod / pydantic / etc.)
- [ ] Error mapping (consistent error envelope)

## Phase 3 — UI
- [ ] Page / component
- [ ] States: loading, empty, error

## Phase 4 — Tests
- [ ] Unit (one per AC)
- [ ] Integration / contract
- [ ] E2E if user-facing

## Phase 5 — Docs
- [ ] CHANGELOG `[Unreleased]`
- [ ] Update `docs/SPEC.md` if milestone claim

## Decisions left to make
- Topic. Options A/B. Default if user doesn't reply.

## Risks
- Risk + mitigation. Reference spec R-section.

## Spec → test map
| AC | Test name | Status |
|---|---|---|
| AC1 | `test_xxx_yyy` | not started |
| AC2 | `test_xxx_zzz` | not started |
