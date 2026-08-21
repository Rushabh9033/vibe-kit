# 2026-08-21 — Spec template gallery shipped

## What

New directory `kit/templates/features/` ships **10 copy-paste-ready Spec
templates** for the most-bug-prone features a solo dev ships. Each template
is a complete, well-shaped Spec — Goal, ACs (each with a `Verification:` block),
Constraints, Edge Cases (Mandatory 11 + domain-specific), Non-Goals, and
Verification steps. Not stubs.

## The 10 templates

Ranked by **frequency × cost-when-wrong**:

| # | Template | Why it's here |
|---|---|---|
| 1 | `webhook-receiver` | The canonical README pain case: signing, idempotency, retries, DLQ. Every "12% of events dropped" starts here. |
| 2 | `auth-email-password` | Argon2id hashing, email verification, rate-limited login, password reset. |
| 3 | `auth-oauth-social` | OAuth2 / OIDC with state CSRF, JWKS verification, account linking. |
| 4 | `billing-stripe` | Hosted checkout, subscription webhooks, dunning, proration. |
| 5 | `crud-with-permissions` | RBAC at the data layer (defense in depth), soft delete, owner transfer. |
| 6 | `search-full-text` | Postgres `tsvector` for v1, with filters + pagination. |
| 7 | `file-upload-storage` | Pre-signed S3 URLs, direct browser-to-S3, virus scan, MIME validation. |
| 8 | `email-transactional` | Queue-based, template-in-code, bounce handling, CAN-SPAM. |
| 9 | `rate-limiting` | Token bucket per user/IP/API-key, headers, 429 + Retry-After. |
| 10 | `audit-log` | Append-only, tamper-evident, 7-year cold retention. |

## Workflow

```bash
# Pick the closest template, copy it, customize, approve.
cp kit/templates/features/webhook-receiver.md \
   docs/requirements/<your-slug>/spec.md
# edit the slug, Goal, and any ACs that don't match your exact case
vibe-spec-approve <your-slug>     # approve + arm in one step
```

After step 3, the kit is armed. Your next Edit is gated by the AC you declared.

## Why

The Spec is the bottleneck. Most solo devs stare at a blank `requirements-spec.md`
for 20 minutes and give up, then ship unstated requirements — the exact problem
the README pain example describes. The gallery drops the cost of writing a Spec
from 20 minutes to 20 seconds. Each template is a working example of what good
looks like.

This is #2 from the priority list ("Spec template gallery").

## Commit

`72e78b1` — `feat(gallery): 10 copy-paste-ready Spec templates for the most-bug-prone features`
pushed to `origin/main` and verified.

## Files

| File | Change |
|---|---|
| `kit/templates/features/webhook-receiver.md` | new (~115 lines) |
| `kit/templates/features/auth-email-password.md` | new (~135 lines) |
| `kit/templates/features/auth-oauth-social.md` | new (~125 lines) |
| `kit/templates/features/billing-stripe.md` | new (~135 lines) |
| `kit/templates/features/crud-with-permissions.md` | new (~140 lines) |
| `kit/templates/features/search-full-text.md` | new (~115 lines) |
| `kit/templates/features/file-upload-storage.md` | new (~140 lines) |
| `kit/templates/features/email-transactional.md` | new (~135 lines) |
| `kit/templates/features/rate-limiting.md` | new (~130 lines) |
| `kit/templates/features/audit-log.md` | new (~135 lines) |
| `kit/templates/features/README.md` | new — gallery index + workflow + ranking rationale |
| `tests/gallery/test-gallery.sh` | new — 141 assertions |
| `README.md` | "Spec templates" subsection + tree entry |
| `CHANGELOG.md` | `[Unreleased]` entry |

## Tests

| Suite | Assertions | Status |
|---|---|---|
| spec-first | 53 | ✓ green |
| vibe-test | 10 | ✓ green |
| prep-room | 21 | ✓ green |
| weapons | 40 | ✓ green |
| gallery | 141 (new) | ✓ green |
| **Total** | **265** (was 124, +141 new) | **all green** |

The gallery suite covers:
- All 10 templates + `README.md` present
- Every template has all 6 required sections (Goal / ACs / Constraints / Edges / Non-Goals / Verification)
- Every template has ≥5 ACs each with Verification blocks
- Every template covers Mandatory 11 edge cases (with semantic pattern matching)
- Every template parses as valid markdown (paired fences, no orphan tables)
- **Every template, copied into a fresh project, is approvable** by `vibe-spec-approve` end-to-end

## Process notes

- First pass had 17 false failures because the test was checking for the
  *literal* Mandatory 11 wording ("Max-size input", "Idempotency on retry").
  Templates are natural-language documents, not form fields — they say
  things like "Oversized payload" instead of "Max-size input". Loosened
  the patterns to accept semantically equivalent phrasing.
- Second pass surfaced **5 real gaps** in the templates (Unicode missing
  from billing-stripe, Malformed missing from billing-stripe, DB-unavailable
  missing from email-transactional, etc.). Fixed the templates directly —
  a good outcome, because consistency across the gallery matters.
- 1 final failure (rate-limiting DB unavailable) was a true gap in the
  template, not a test artifact. Added a "Datastore unavailable" line to
  the "Beyond mandatory" edge cases.

## What's next (from the priority list)

3. **`/vibe-claim-check` as the ship gate** — replace `/vibe-verify` in the docs (1 day)
4. **Mutation testing as Rank 1** — wrap mutmut/Stryker behind `vibe-test --rank=mutation` (2 days)
5. **AI-assisted intake** — single-purpose Planner model invocation, gated by the same approval boundary (3 days)

#1 (auto-arm after Spec approval) ✓ done in `c935b26`.
#2 (Spec template gallery) ✓ done in `72e78b1`.

Next move: **#3 — make `/vibe-claim-check` the real ship gate.**