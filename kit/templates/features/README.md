# Spec Templates — Feature Gallery

Ten copy-paste-ready Specs for the most common features solo devs ship.
Each template is **a complete, well-shaped Spec** with Goal, Acceptance Criteria
(each with a real `Verification:` block), Constraints, Edge Cases (Mandatory 11
+ domain-specific), Non-Goals, and Verification steps.

The point of this gallery is to **lower the cost of writing a Spec from 30 minutes
of staring at a blank file to 30 seconds of editing a working example**.

## Workflow

```bash
# 1. Pick the closest template
ls kit/templates/features/

# 2. Copy it into your project's requirements dir
cp kit/templates/features/webhook-receiver.md \
   docs/requirements/<your-slug>/spec.md

# 3. Customize:
#    - rename <slug> in the header
#    - edit the Goal for your exact use case
#    - add/remove ACs as needed (each AC = one test)
#    - remove Non-Goals that don't apply

# 4. Approve + arm the kit in one step
vibe-spec-approve <your-slug>
```

After step 4 the kit is armed and your next Edit is gated by the AC you declared.

## The gallery

| Template | When to use |
|---|---|
| [`webhook-receiver`](webhook-receiver.md) | Receiving webhooks from a provider. **The canonical README pain case**: signing, idempotency, retries, DLQ. Use this for Stripe, GitHub, Shopify, Twilio, etc. |
| [`auth-email-password`](auth-email-password.md) | Standard email + password auth. Argon2id hashing, email verification, password reset, rate-limited login. |
| [`auth-oauth-social`](auth-oauth-social.md) | OAuth2 / OIDC sign-in with Google / GitHub / Apple. State CSRF, JWKS verification, account linking. |
| [`billing-stripe`](billing-stripe.md) | Stripe subscription billing. Hosted checkout, subscription webhooks, dunning, proration. |
| [`crud-with-permissions`](crud-with-permissions.md) | Standard create/read/update/delete with role-based access. RBAC at the data layer, soft delete, owner transfer. |
| [`search-full-text`](search-full-text.md) | Full-text search with filters + pagination. Postgres `tsvector` for v1, swappable later. |
| [`file-upload-storage`](file-upload-storage.md) | File uploads to S3 via pre-signed URLs. Direct browser-to-S3, virus scan, MIME validation. |
| [`email-transactional`](email-transactional.md) | Transactional email (welcome, reset, receipts). Queue-based, template-in-code, bounce handling, CAN-SPAM. |
| [`rate-limiting`](rate-limiting.md) | Token-bucket rate limiting per user/IP/API-key. Headers, 429 + Retry-After, Redis-backed. |
| [`audit-log`](audit-log.md) | Append-only audit trail for SOC 2 / GDPR. Tamper-evident, searchable, 7-year cold retention. |

## Anatomy of a template

Every template follows the same shape (matches the kit's `requirements-spec.md`):

```
# Feature: <Name>

> Copy this to docs/requirements/<slug>/spec.md ...

## Goal                ← one paragraph, what + why
## Acceptance Criteria ← each AC = one test, with Verification block
## Constraints         ← hard rules the Coder must not violate
## Edge Cases           ← Mandatory 11 + domain-specific
## Non-Goals            ← explicit "this is NOT in scope"
## Verification         ← test commands + manual steps
```

## Why these 10

These are the **10 most-bug-prone features** a solo dev ships, ranked by
**frequency × cost-when-wrong**:

1. **Webhook receiver** — every "the AI dropped 12% of events" starts here.
2. **Auth** — every "we got pwned" starts here.
3. **Billing** — every "we lost money" starts here.
4. **CRUD + permissions** — every "user X saw user Y's data" starts here.
5. **Search** — every "the search is broken / slow" starts here.
6. **File upload** — every "users uploaded malware / ran out of space" starts here.
7. **Email** — every "we got blacklisted / users didn't get the reset email" starts here.
8. **Rate limiting** — every "we got DDoS'd / scraped" starts here.
9. **Audit log** — every "we can't answer the SOC 2 question" starts here.
10. **OAuth** — every "the OAuth flow is insecure" starts here.

## When to NOT use a template

If your feature is genuinely novel (a new algorithm, a new business model,
a new protocol), don't try to shoehorn it into one of these. Use
`kit/templates/requirements-spec.md` and write a Spec from scratch.

Templates are training wheels for the 80%. They become training brakes
on the 20% that's truly different.

## Contributing

If you build a feature Spec that's general-purpose, add it here. One template
per feature, no variants, no "lite" versions. Sharp edges > gentle curves.