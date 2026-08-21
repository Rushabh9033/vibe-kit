# Feature: Webhook Receiver

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Receive webhooks from an external provider (Stripe / GitHub / Shopify / etc.), verify
their HMAC signature, persist them idempotently, and deliver them to a processing
queue with exponential-backoff retry. The receiver is the **trust boundary** between
your system and the outside world — every event must be authenticated, deduped, and
observable. **Without these properties, you'll ship the README's pain example**: 12%
of shipping events dropped, duplicates, replays.

## Acceptance Criteria

- [ ] **AC1.** Webhook with valid signature is accepted (HTTP 200), persisted, and enqueued
  - Verification:
    - automated test: `tests/webhooks/test_receiver.py::test_valid_signature_accepted`
    - expected behavior: POST with `X-Signature: sha256=<valid_hmac>` returns 200; payload stored with `provider_event_id`; one job enqueued

- [ ] **AC2.** Webhook with missing or invalid signature is rejected (HTTP 401)
  - Verification:
    - automated test: `tests/webhooks/test_receiver.py::test_invalid_signature_rejected`
    - expected behavior: POST without signature, with wrong secret, or with bad HMAC returns 401; nothing persisted or enqueued

- [ ] **AC3.** Duplicate delivery with the same `provider_event_id` is a no-op (idempotency)
  - Verification:
    - automated test: `tests/webhooks/test_receiver.py::test_duplicate_idempotent`
    - expected behavior: Two POSTs with the same `event_id` both return 200, but only one job is enqueued

- [ ] **AC4.** Replay attack (signature valid, but timestamp > 5 min old) is rejected
  - Verification:
    - automated test: `tests/webhooks/test_receiver.py::test_replay_attack_rejected`
    - expected behavior: POST with timestamp 10 minutes in the past returns 401 even with valid signature

- [ ] **AC5.** Worker retries failed processing with exponential backoff up to N attempts
  - Verification:
    - automated test: `tests/webhooks/test_worker.py::test_retry_with_backoff`
    - expected behavior: Worker that throws attempts delivery at 1m, 5m, 30m, 2h, 12h before dead-lettering

- [ ] **AC6.** Permanent failures land in a dead-letter queue with full payload + error log
  - Verification:
    - automated test: `tests/webhooks/test_worker.py::test_dead_letter`
    - expected behavior: After max retries, payload appears in DLQ with original headers + last error

- [ ] **AC7.** Receiver returns 200 within 200ms P99 even when downstream is slow
  - Verification:
    - automated test: `tests/webhooks/test_receiver.py::test_latency_p99`
    - expected behavior: P99 < 200ms under 100 RPS sustained (k6 load test)

- [ ] **AC8.** Payload contents are NEVER logged (PII / secret-leak risk)
  - Verification:
    - automated test: `tests/webhooks/test_receiver.py::test_payload_not_logged`
    - expected behavior: Grep of log output for a sample payload substring returns zero hits

## Constraints

- HMAC-SHA256 verification is **MANDATORY** for every request — no opt-out, even in dev.
- Signing secret MUST come from env var (e.g. `STRIPE_WEBHOOK_SECRET`); never hardcoded.
- Replay window: 5 minutes (configurable via env, default 5min).
- Idempotency keys (`provider_event_id`) stored for **24 hours minimum**.
- Payload size hard cap: **1MB**. Reject larger with HTTP 413.
- All log lines MUST redact `payload`, `headers[authorization]`, `headers[cookie]`.
- No webhook body content in any log, metric, trace span, or error message.

## Edge Cases

### Mandatory 11

- **Empty body:** 400 Bad Request.
- **Max-size input:** 413 Payload Too Large (1MB cap).
- **Unicode / non-ASCII in JSON:** parsed as UTF-8; no truncation.
- **Concurrent same-resource:** provider sends same `event_id` twice in parallel → second is no-op via unique constraint.
- **Network failure mid-operation:** receiver persists *before* responding, so retries succeed.
- **DB unavailable:** 503 + provider retries (provider-side resilience).
- **Idempotency on retry:** provider retries never cause duplicate processing.
- **Timezone / clock skew:** tolerate 5min skew via timestamp window.
- **Malformed JSON:** 400 with structured error code.

### Beyond mandatory

- **Signature header case variants** (`x-signature` vs `X-Signature`): accepted (case-insensitive).
- **`Content-Type: application/x-www-form-urlencoded`** (Stripe legacy): body parsed accordingly.
- **Worker killed mid-retry:** job requeued on next worker startup.
- **Provider clock drift > 5min:** all requests rejected; alert ops.
- **Secret rotation:** receiver hot-reloads new secret without restart.
- **Different events with different IDs at different times:** treated as distinct.

## Non-Goals

- Outbound webhook firehose (different spec).
- Webhook UI / dashboard for retry / replay management.
- Multi-tenant signing key rotation UI (env var only).
- Webhook payload schema validation (consumer's responsibility).
- Webhook signing algorithm choice (always HMAC-SHA256).

## Verification

- `pytest tests/webhooks/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Manual:** send 1 valid + 1 invalid + 1 replay attempt via `curl`
- **Load:** `k6 run --vus 50 --duration 5m tests/load/webhook.js` (verify P99 < 200ms)