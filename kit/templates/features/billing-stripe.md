# Feature: Billing — Stripe Subscription

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Charge customers a recurring subscription via Stripe. Customers land on a Stripe-hosted
checkout page, come back to our app with a subscription in place, and our system keeps
in sync with Stripe's state via webhook events (`customer.subscription.{created,updated,
deleted}`, `invoice.payment_{succeeded,failed}`). Dunning (failed payments → grace
period → cancellation) handled by Stripe, surfaced to our users via email.

## Acceptance Criteria

- [ ] **AC1.** Customer can pick a plan and be redirected to Stripe-hosted checkout with our `price_id`, `customer_id` (or pre-creation), `success_url`, `cancel_url`
  - Verification:
    - automated test: `tests/billing/test_checkout.py::test_checkout_redirect`
    - expected behavior: 302 to `checkout.stripe.com/...` with all required params; `success_url` and `cancel_url` are absolute HTTPS URLs

- [ ] **AC2.** Webhook `customer.subscription.created` persists `subscription_id`, `status`, `current_period_end`, `price_id` against our user
  - Verification:
    - automated test: `tests/billing/test_webhooks.py::test_subscription_created`
    - expected behavior: POST webhook with valid signature → user row gains `stripe_subscription_id`, `plan`, `renews_at`

- [ ] **AC3.** Webhook `invoice.payment_failed` marks the subscription `past_due` and triggers a dunning email
  - Verification:
    - automated test: `tests/billing/test_webhooks.py::test_payment_failed_dunning`
    - expected behavior: Status flips; dunning email queued; access NOT yet revoked (grace period)

- [ ] **AC4.** Webhook `customer.subscription.deleted` revokes access and ends entitlements
  - Verification:
    - automated test: `tests/billing/test_webhooks.py::test_subscription_deleted_revokes`
    - expected behavior: User's `plan` reset to `free`; access checks return "subscription required"

- [ ] **AC5.** Customer can upgrade / downgrade mid-cycle (proration via Stripe)
  - Verification:
    - automated test: `tests/billing/test_portal.py::test_upgrade_downgrade`
    - expected behavior: POST to billing portal session → redirect to Stripe-hosted portal where plan change emits proration

- [ ] **AC6.** Webhook signature is verified against `STRIPE_WEBHOOK_SECRET` (HMAC-SHA256) — see webhook-receiver template
  - Verification:
    - automated test: `tests/billing/test_webhooks.py::test_signature_verified`
    - expected behavior: Invalid signature returns 401; valid signature is processed exactly once

- [ ] **AC7.** Idempotency: replaying the same Stripe event does NOT double-process
  - Verification:
    - automated test: `tests/billing/test_webhooks.py::test_event_idempotent`
    - expected behavior: Same `event.id` delivered twice → second is no-op (recorded as `processed_at`, no state change)

- [ ] **AC8.** All Stripe API calls happen server-side; `STRIPE_SECRET_KEY` is never sent to the browser
  - Verification:
    - automated test: `tests/billing/test_security.py::test_secret_not_in_bundle`
    - expected behavior: Grep of compiled frontend assets for `sk_live_` or `sk_test_` returns zero hits

## Constraints

- **Stripe is the source of truth** for subscription state. Our DB is a cache.
- **Webhook signature verification** (HMAC-SHA256 via `stripe.Webhook.construct_event`) — MANDATORY, no opt-out.
- **Idempotency keys** on every Stripe API write (`idempotency_key=f"sub-{user_id}-{action}"`).
- **No PII in Stripe metadata** beyond the user ID (Stripe metadata is visible to users in their dashboard).
- **No card data** touches our servers — Stripe Elements / Checkout only.
- **All money values are integers** (cents), never floats. Currency code stored alongside.
- **TLS required** for the webhook endpoint (no HTTP fallback).
- **Webhook endpoint rate-limited** at the receiver level (see webhook-receiver template).

## Edge Cases

### Mandatory 11

- **Empty webhook body:** 400.
- **Oversized payload:** 413 (1MB cap, same as webhook-receiver).
- **Unicode in customer metadata** (names, addresses): NFC-normalized; stored as-is.
- **Stripe sends `customer.subscription.updated` with same status:** no-op (idempotent).
- **Two webhooks arrive concurrently** for the same event ID: serialized via unique constraint on `event_id`.
- **Stripe API down:** our retry logic backs off (1s, 5s, 30s, 2m, 10m).
- **Customer disputes a charge** (`charge.dispute.created`): flag the account, notify ops.
- **User deletes account in our system while subscription is active:** cancel subscription in Stripe, log it.
- **DB unavailable:** 503 + Stripe retries.
- **Refund issued** (`charge.refunded`): revoke access if refunded in full.
- **Customer changes payment method** (default update): no action; next renewal uses new method.
- **Trial conversion** (`customer.subscription.updated` with `status: active` after trial): send "trial ended" email.
- **Timezone / clock skew:** renewal cutoff times stored as Unix timestamps; rendered in user's TZ in emails.
- **Malformed Stripe payload** (missing required field): logged as `webhook_malformed`, event dropped, alert ops.

### Beyond mandatory

- **Multiple subscriptions for same user:** disallowed — reject at checkout with "you already have an active subscription".
- **Currency mismatch** between plan and customer default: Stripe rejects, we surface the error.
- **Coupon applied** that's no longer valid: Stripe handles; we record the resulting price.
- **Customer cancels during trial:** `customer.subscription.deleted` at trial end, no charge — handled gracefully.
- **Webhook ordering** (e.g., `created` before `updated`): always upsert; final state wins regardless of order.

## Non-Goals

- Building a generic payments processor (Stripe-only).
- Invoice PDF generation (use Stripe's hosted invoice URL).
- Tax calculation (use Stripe Tax).
- Multi-currency display logic (charge in customer's local currency; display only USD).
- Crypto / ACH / wire transfers.
- Marketplace / split payments / Stripe Connect (separate spec if needed).
- Refund UI (admin-only via Stripe Dashboard for v1).

## Verification

- `pytest tests/billing/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Stripe CLI:** `stripe listen --forward-to localhost:8000/billing/webhook` then `stripe trigger checkout.session.completed` — verify state in DB
- **Manual end-to-end:** use Stripe test cards (`4242 4242 4242 4242` succeeds, `4000 0000 0000 9995` fails) — verify both paths
- **Load:** simulate 1000 webhook deliveries/minute, verify P99 processing < 500ms