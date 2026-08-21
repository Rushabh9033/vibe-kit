# Feature: Audit Log

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Append-only record of every security- and compliance-relevant event in the system:
who did what, when, from where, with what data, and the resulting state. Required
for SOC 2, GDPR data-access requests, post-incident forensics, and "who deleted
this row?" investigations. Events are write-once, retained for N years (typically
7 for SOC 2), and searchable by operators.

## Acceptance Criteria

- [ ] **AC1.** Every privileged action writes an event with `actor_id, action, resource_type, resource_id, before, after, ip, user_agent, request_id, timestamp`
  - Verification:
    - automated test: `tests/audit/test_write.py::test_event_shape`
    - expected behavior: Triggered on auth login, password change, role change, resource delete, billing change — all required fields present

- [ ] **AC2.** Events are append-only — UPDATE or DELETE on the audit table fails
  - Verification:
    - automated test: `tests/audit/test_append_only.py::test_update_rejected`
    - expected behavior: DB-level constraint rejects UPDATE/DELETE; admin `psql` session can read but not modify

- [ ] **AC3.** `GET /audit?actor_id=X` returns events for that user (operator-only endpoint)
  - Verification:
    - automated test: `tests/audit/test_search.py::test_search_by_actor`
    - expected behavior: Returns paginated events for the actor; non-operator gets 403

- [ ] **AC4.** `GET /audit?resource_type=X&resource_id=Y` returns events for that resource
  - Verification:
    - automated test: `tests/audit/test_search.py::test_search_by_resource`
    - expected behavior: All changes to that resource across all actors; sorted by timestamp DESC

- [ ] **AC5.** `GET /audit?from=YYYY-MM-DD&to=YYYY-MM-DD` filters by date range
  - Verification:
    - automated test: `tests/audit/test_search.py::test_search_by_date_range`
    - expected behavior: Events within range returned; `from > to` returns 400

- [ ] **AC6.** Failed audit writes do NOT roll back the original action — log a warning, alert ops
  - Verification:
    - automated test: `tests/audit/test_failure.py::test_audit_failure_does_not_block_action`
    - expected behavior: Mock audit table unavailable → original action still succeeds; warning emitted with correlation ID

- [ ] **AC7.** PII fields are redacted in `before`/`after` snapshots (passwords, tokens, card numbers)
  - Verification:
    - automated test: `tests/audit/test_redaction.py::test_pii_redacted`
    - expected behavior: Event triggered by password change shows `password: "[REDACTED]"` not the hash

- [ ] **AC8.** Events are exported to S3 (cold storage) every 24 hours, retained for 7 years
  - Verification:
    - automated test: `tests/audit/test_export.py::test_export_to_s3`
    - expected behavior: Cron / worker writes `audit-YYYY-MM-DD.json.gz` to S3; S3 lifecycle rule retains for 7 years

## Constraints

- **Append-only at DB level** — REVOKE UPDATE, DELETE on the audit table from the app role.
- **Operator-only read access** — only the `audit_reader` role can SELECT.
- **Every privileged action audited**: auth events, role changes, billing changes, data deletes, exports, permission grants.
- **PII redaction**: passwords, tokens, API keys, card numbers, SSNs are redacted before write.
- **Retention**: 90 days hot in DB, 7 years cold in S3.
- **Fail-open on audit write**: if the audit table is unavailable, the original action proceeds; warning logged + alert.
- **No bulk export to user-facing endpoints** — only operators via the `/audit` admin endpoint.
- **Schema changes to the audit table are migrations** — never direct ALTER.

## Edge Cases

### Mandatory 11

- **Empty event context (no actor_id for system action):** use `actor_id = "system"` and `actor_type = "system"`.
- **Oversized `before`/`after` snapshots:** truncate at 64KB; link to full snapshot in object storage.
- **Unicode in actor names / resource labels:** NFC-normalized.
- **Concurrent writes to audit table:** serialized via DB-level locking; no events lost.
- **Network failure to S3 export:** retry with backoff; alert ops if persistent.
- **Operator without `audit_reader` role:** 403, never silent.
- **User with no permission:** event still written (system actions always audited).
- **DB unavailable for audit:** fail-open per AC6.
- **Idempotent writes:** same event_id never duplicates.
- **Timezone:** all timestamps stored UTC; rendered in operator's TZ via `?tz=` param.
- **Malformed search query:** 400 with field-level error.

### Beyond mandatory

- **Streaming export**: operators can request a streaming JSON dump for a date range.
- **GDPR data-access requests**: `?actor_id=X` returns all events for X — required for SAR fulfillment.
- **Tamper detection**: each event signed with HMAC of its content + previous event's hash → chain of custody.
- **Operator actions audited too**: every access to `/audit` endpoint itself is an event.
- **Reconstruction**: given an event_id, reconstruct the full state of the resource at that point in time.

## Non-Goals

- Real-time alerting on suspicious patterns (separate spec — SIEM integration).
- Long-term storage beyond 7 years (regulatory requirement varies).
- Per-user activity feeds ("you changed your password 3 days ago").
- Audit log UI for end-users.
- Compliance report generation (separate spec — SOC 2 / ISO 27001 reports).
- Fine-grained event taxonomy beyond security/compliance scope.

## Verification

- `pytest tests/audit/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Manual:** trigger a privileged action, search for it in `/audit`, verify all fields present and PII redacted
- **DB-level:** `psql -c "UPDATE audit_events SET ..."` → permission denied
- **Forensics scenario:** "user X claims their account was hacked" → query audit for X, review IP / device timeline
- **Retention:** verify 90-day hot purge + 7-year cold retention in S3