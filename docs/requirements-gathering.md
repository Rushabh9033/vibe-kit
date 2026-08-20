# Requirements Gathering — the most important workflow

> Spec first, code second, run forever.

If your team only adopts **one** part of this kit, adopt this one. The single highest-leverage change you can make is to never write code without a spec; the spec is what the AI consumes.

## The canonical pipeline

```
DISCOVERY       SPEC              TASK-BREAKDOWN     IMPLEMENT        VERIFY         HARDEN
story map /     contract:         per-feature plan:  per phase        AC vs impl:    tests + NFRs +
JTBD /          ACs + edge        schema/api/ui/    update plan.md   mutation-      a11y + SAST +
interviews      cases + NFRs +    tests/docs       + handoff        tolerated      secrets +
                AI surface                                            
   │                │                 │                │                │              │
output:        output:            output:          output:          output:         output:
journey        spec.md            plan.md          code + tests     green / red     ready-to-ship
```

## Step 1 — Discovery (you cannot skip this)

The deliverable is a **journey story** for the user, not a feature list. Outputs:

- Job-to-be-done statements: *"When [situation], I want [motivation], so that [outcome]."*
- Story map at the journey level (Jeff Patton).
- 3–5 user personas; who they are; what they need; what they sacrifice.

If you skip this, the AI will hallucinate a user. The first wrong AC will poison every downstream decision. Story maps are cheap; AI guesses are expensive.

## Step 2 — Spec (the contract)

For each feature, write `docs/requirements/<feature-slug>/spec.md` using `kit/templates/requirements-spec.md`. Mandatory sections:

1. **Scope** (1 paragraph) and **not in scope** (bulleted).
2. **User-facing behavior**.
3. **API contract** with exact method, path, headers, body, response, status codes, rate limits.
4. **Data model**: new tables / columns / indexes; migration strategy.
5. **Acceptance criteria** — each MUST be machine-checkable or explicitly human-judged. If you can't name the check, the AC is incomplete.
6. **Edge cases (exhaustive)** — empty, max-size, unicode, concurrent, network-failure, auth-expired, unauthorized, DB-down, idempotency, timezone, malformed input.
7. **NFRs** with target + check tool (perf / a11y / security / observability / privacy).
8. **AI-authored surface area** declaration:
   - AI may write (with review): standard CRUD, UI scaffolding, tests with review, doc drafts.
   - Human must author (AI may assist): auth, crypto, billing, PII, migrations, public APIs, legal copy.
9. **Dependencies** (other specs / modules / teams).
10. **Verification plan** with exact commands.
11. **Risks** with ID, likelihood, impact, mitigation, trigger, owner.

See `examples/planner-output-spec.md` for a complete worked example.

## Step 3 — Task breakdown

Convert the spec into `plan.md` using `kit/templates/plan.md`. Phases in order:

```
1. Schema      — migrations, model, repo
2. API/Logic   — endpoint, validation, error mapping
3. UI          — component, states (loading/empty/error)
4. Tests       — one per AC; integration; E2E for customer-facing
5. Docs        — CHANGELOG entry, SPEC update
```

Each phase should be small enough for **one Coder session** — about 30 minutes of model work. Larger phases increase the risk of context loss mid-implementation.

For each AC in the spec, write a corresponding test name in `plan.md`'s spec→test map table. If you can't write a test name for an AC, the AC is wrong.

## Step 4 — Implement (the Coder's job)

The Coder reads `spec.md` + `plan.md` + the latest handoff, and walks the phases. The roles:

- **Planner should not write code.** Planner output is the Spec, the plan, ADRs.
- **Coder should not rewrite the Spec.** If something's wrong, file an issue; the Planner (or the user) revises; the Coder re-reads.

When the Coder is the same tool that produced the Spec, the **spec-first gate**
(`kit/templates/spec-first-gate.md`) enforces this: the Coder writes the
Spec, stops for approval, and only implements after the user sets
`Status: in-progress`. The user is always the only one who can flip Status.

## Step 5 — Verify (don't accept "tests pass")

**Verification ranks** — every project has a floor:

| Rank | Check | When |
|---|---|---|
| 1 | lint + format + typecheck | every edit |
| 2 | unit tests against ACs | every feature |
| 3 | integration / contract | every API |
| 4 | mutation testing | production code |
| 5 | E2E | customer-facing |
| 6 | perf / load | production |
| 7 | security / pen-test | regulated |

**Don't ship under your project's rank.** For MVP: rank 2. For production: rank 4+ on production code paths.

The phrase "tests pass" is theater without mutation testing. If you only run unit tests, the AI can write code that satisfies every test while being subtly wrong. Mutation testing flips the lens — does the suite *catch* mutations? If not, the suite is decoration.

## Step 6 — Harden

NFRs, accessibility, security, performance, license, observability. These are not "extra"; they're the floor for production.

## Hard constraints for any AI-assisted spec

```markdown
## Hard constraints for this feature
- Do NOT introduce new top-level dependencies without approval.
- Do NOT modify files under `/migrations/` (run-only).
- Do NOT use `any` in TypeScript without an eslint-disable justification.
- Do NOT hardcode secrets, URLs, or environment-specific values.
- Do NOT touch: <list of files outside scope>.
```

When the Coder hits any of these, it stops and asks.

## AI-authored surface area declaration

This is mandatory — it's the contract between human reviewer and AI. Without it, every PR is a debate.

```markdown
## AI may write (with review):
- Standard CRUD endpoints
- UI scaffolding
- Tests (with review)
- Documentation drafts

## AI may write autonomously (no review):
- Throwaway prototypes
- Test fixtures
- Generated client code from OpenAPI specs

## Human must author (AI may assist):
- Authentication / authorization
- Cryptography
- Database migrations
- Billing / financial logic
- PII-handling code
- Legal-facing copy
- Public APIs / SDKs
```

## Definition of Ready (gate to start work)

A feature can't be worked on until all of these are true:

- [ ] User story is written.
- [ ] Acceptance criteria defined (each = one test).
- [ ] Edge cases enumerated.
- [ ] NFRs called out with measurable targets.
- [ ] Dependencies identified and unblocked.
- [ ] Story is estimated (small enough for one Coder session).
- [ ] Out-of-scope list written.
- [ ] AI-authored surface area agreed.
- [ ] Test data / environment available.
- [ ] Linked to milestone in `docs/SPEC.md`.

## Definition of Done (gate to finish work)

A feature isn't done until all of these are true:

- [ ] Code written and reviewed.
- [ ] Unit tests pass; coverage threshold met on changed lines.
- [ ] Integration tests pass.
- [ ] Linter passes with zero warnings.
- [ ] Typecheck passes.
- [ ] Every AC verified by a test (or explicit human judgment).
- [ ] Edge cases all tested.
- [ ] NFRs checked.
- [ ] SAST / secret scan / dependency audit clean.
- [ ] `CHANGELOG.md [Unreleased]` updated.
- [ ] `docs/requirements/<feature>/plan.md` items checked.
- [ ] `docs/handoffs/<date>-<slug>.md` written.
- [ ] ADRs filed for any new irreversible decision.
- [ ] Deployed to staging.
- [ ] No P0/P1 bugs open.
- [ ] Documentation reflects the final design.

## Worked example — minimal

See `examples/planner-output-spec.md` for a complete feature spec, and `examples/planner-output-plan.md` for the matching plan.

## Common mistakes

1. **"We'll write the spec later."** No. The spec is the input; without it, the AI is hallucinating.
2. **"Just one AC for now."** Edge cases are most of the work. List them.
3. **"NFRs are an afterthought."** NFRs in the spec means each AC gets measured as it's written; an afterthought is a postmortem.
4. **"Reviews are slow."** Reviews are cheap. Production bugs are expensive.
5. **"Spec is too detailed; AI will figure it out."** The AI will figure it out *consistently with the spec*. Without a spec, it figures it out differently every session.

## The principle

> **Requirements gathering is the work.** Coding is the easy part. If you can't write the spec, you don't understand the problem yet — and the AI won't understand it for you.
