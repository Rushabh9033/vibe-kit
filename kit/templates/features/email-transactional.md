# Feature: Email — Transactional

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Send transactional emails (welcome, password reset, magic link, receipts,
notifications) via a provider (Postmark / SendGrid / SES). Emails go through
a queue, render from versioned templates, handle bounces + complaints, and
honor unsubscribe headers. Templates live in code (not the provider's UI) so
they're reviewable in PRs.

## Acceptance Criteria

- [ ] **AC1.** `send_email(to, template, context)` enqueues the email without blocking the caller
  - Verification:
    - automated test: `tests/email/test_send.py::test_enqueue_nonblocking`
    - expected behavior: Function returns within 50ms; email appears in `outbound_emails` queue within 1s

- [ ] **AC2.** Worker renders the template with the provided context and sends via the provider
  - Verification:
    - automated test: `tests/email/test_send.py::test_renders_and_sends`
    - expected behavior: HTML + plain-text versions produced; subject interpolated; provider API called with correct payload

- [ ] **AC3.** Provider webhook (`bounce`, `complaint`, `delivered`) updates the email status
  - Verification:
    - automated test: `tests/email/test_webhooks.py::test_bounce_webhook`
    - expected behavior: Bounce → email marked `bounced`; complaint → user flagged `complained`; delivered → `delivered`

- [ ] **AC4.** Hard bounce → user's email marked invalid; subsequent sends to that address queued but NOT sent
  - Verification:
    - automated test: `tests/email/test_bounce.py::test_hard_bounce_suppresses`
    - expected behavior: After hard bounce, `users.email_invalid = true`; send attempt suppressed with reason `hard_bounce`

- [ ] **AC5.** Every email has `List-Unsubscribe` header (RFC 8058) for non-transactional categories
  - Verification:
    - automated test: `tests/email/test_headers.py::test_list_unsubscribe_header`
    - expected behavior: Marketing / notification emails have `List-Unsubscribe: <https://app/unsubscribe?token=...>, <mailto:unsubscribe@app>`; transactional (password reset) do NOT

- [ ] **AC6.** All emails include the company's physical address (CAN-SPAM compliance)
  - Verification:
    - automated test: `tests/email/test_compliance.py::test_physical_address_present`
    - expected behavior: HTML + plain-text both contain the configured `COMPANY_ADDRESS`

- [ ] **AC7.** Provider API key read from env var, never embedded in templates or client code
  - Verification:
    - automated test: `tests/email/test_security.py::test_api_key_in_env`
    - expected behavior: `POSTMARK_TOKEN` / `SENDGRID_KEY` env var present; grep of source returns zero hits

- [ ] **AC8.** Template changes are reviewed in PR (no live-editing in the provider's UI)
  - Verification:
    - automated test: `tests/email/test_security.py::test_no_provider_ui_edits`
    - expected behavior: All templates exist as files in `src/emails/templates/`; no "edit in dashboard" path

## Constraints

- **Provider is configurable** (Postmark / SES / SendGrid) via env var; same API surface.
- **Templates live in code** as `.html` and `.txt.j2` (Jinja2) files, committed to git.
- **Queue-based sending** — never synchronous to the user-facing request.
- **Idempotency**: each send has an `email_id`; provider's idempotency key prevents double-send.
- **Bounce handling is automatic** — no manual cleanup.
- **Unsubscribe is honored within 10 days** of request (CAN-SPAM).
- **No email content in logs** beyond `to`, `subject`, `email_id`.
- **All emails sent over TLS** to the provider; provider must use TLS to recipients.

## Edge Cases

### Mandatory 11

- **Empty `to`:** reject at send time (400).
- **Invalid email format:** reject at send time, return 400.
- **Oversized body** (>10MB total including attachments): reject at send time.
- **Unicode in `to` display name:** NFC-normalized; RFC 2047 encoded if needed.
- **Concurrent sends to same address:** queued normally; provider dedup via idempotency key.
- **Provider down:** retry with exponential backoff (1m, 5m, 30m, 2h, 12h).
- **User unsubscribed mid-flight:** queued email goes to `suppressed` on dequeue.
- **Bounce for non-existent user (typo in `to`):** logged, dropped.
- **Provider API rate limit:** backoff per provider's `Retry-After` header.
- **Unauthorized sender domain** (SPF/DKIM/DMARC failure on our outbound IP): all sends rejected at provider; ops alerted.
- **DB unavailable:** queue DB down → emails buffered in memory, retried with backoff; never lost (durability via write-ahead log).
- **Idempotent retry:** same `email_id` never produces two provider-side sends.
- **Timezone in timestamps:** always UTC; rendered in user's TZ in the template.
- **Malformed template context:** template render fails → email goes to `failed` queue, alert ops.

### Beyond mandatory

- **Soft bounces** (mailbox full): retry for up to 3 days, then mark `bounced_soft`.
- **Spam complaint** (`feedback_type=spam`): auto-unsubscribe the user from the category.
- **Email open tracking**: pixel-based, optional via config; respects DNT.
- **Click tracking**: link rewriting via provider, optional.
- **A/B testing subject lines**: separate spec.
- **Multi-language templates**: per-user locale at send time.
- **Attachment support**: limited to specific transactional flows (e.g., invoice PDFs); max 10MB.

## Non-Goals

- Marketing email automation (drip campaigns, newsletters) — separate spec.
- Email list management (segments, audiences).
- Drag-and-drop template builder.
- Inbox placement testing (separate spec).
- Email-to-product workflows (e.g., "reply to this email to create a task").

## Verification

- `pytest tests/email/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Mailtrap / provider sandbox:** send each template, verify rendering, headers, links
- **Manual bounce:** configure mailbox to bounce, send, verify suppression
- **Manual unsubscribe:** click unsubscribe link, verify subsequent sends suppressed
- **Compliance:** send to a tool that checks CAN-SPAM (mail-tester.com or similar)