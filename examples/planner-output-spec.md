# Planner output — per-feature spec

This is what the Planner produces from `prompts/02-feature-spec.md` given `intake-prd.md`.

Saved as: `docs/requirements/profile-photo-upload/spec.md`

---

# Feature: Profile photo upload

**Status:** in-progress
**Owner:** @radhika
**Last updated:** 2026-08-20
**Linked milestone:** docs/SPEC.md ## M1 (Profile)

> The Spec is the durable contract between planning and implementation.
> When the Spec and the code disagree, the Spec wins — until the user
> explicitly revises it.

## Human approval

- [x] User has read the spec end-to-end
- [x] User has edited anything they want changed
- [x] User has set `Status: in-progress`
- [x] User has explicitly said "approved" or "ship it" in chat

## Goal

A user can upload a single profile photo. The photo is cropped to a 1:1
square at upload time, then served at four variants (32, 64, 256, 512 px)
so it looks good across the app. Replaces existing photo if one is
present. Mobile-first. Privacy-first (EXIF GPS stripped). Idempotent
(network drops retry safely).

## User Stories

- As a **new user**, I want to **upload a profile photo from my phone**, so that **other users recognize me in the feed**.
- As a **security-conscious user**, I want **EXIF location data stripped on upload**, so that **my home address isn't leaked from camera-roll photos**.
- As a **user on a flaky network**, I want **a retry to not double-upload**, so that **I don't get charged twice for storage or see my photo twice in the feed**.
- As a **mobile user**, I want **the photo to appear within 3 seconds**, so that **my profile feels responsive**.

## Requirements

### Functional

- User can upload 1 image file (JPEG / PNG / WebP, max 10MB).
- Server crops to 1:1 client-side, then resize-pipeline produces 4 variants server-side.
- User can rotate 90° clockwise before save.
- Replace existing photo atomically (no flash of empty between old and new).
- Server returns 4 variant URLs after successful upload.

### API contract

- `POST /v1/users/me/photo` — multipart/form-data
  - Headers: `Authorization: Bearer <jwt>`, `Idempotency-Key: <uuid>`
  - Body: `file` (image/jpeg | image/png | image/webp), max 10MB
  - Success: 200 with `{ photo_url, variants: { "32": url, "64": url, "256": url, "512": url } }`
  - Errors:
    - 400 `unsupported_media_type`
    - 400 `file_too_large`
    - 400 `corrupted_image`
    - 401 (no/bad token)
    - 409 (concurrent upload lost the race)
    - 413 (request body too large)
    - 429 (rate limit)
    - 500 / 503 (server / upstream image-processing failure)
- `DELETE /v1/users/me/photo` — 204 on success; idempotent (also 204 if no photo exists).
- `GET /v1/users/:id` — response includes `photo_url` and `variants`.

### Data model

- New table: `user_photos`
  - `id` UUID PK
  - `user_id` UUID FK → users(id), UNIQUE
  - `storage_key` TEXT NOT NULL (S3 path)
  - `mime_type` TEXT NOT NULL
  - `bytes` INTEGER NOT NULL
  - `idempotency_key` TEXT NOT NULL
  - `created_at` TIMESTAMPTZ NOT NULL DEFAULT now()
  - Index: `user_photos_user_id_key` UNIQUE (user_id, idempotency_key)
- Existing table: `users` — add `photo_storage_key` (FK to user_photos.storage_key, denormalized for fast read).

Migrations: `0007_create_user_photos.sql` (new, additive). `0008_user_photo_storage_key.sql` (new, additive).

Migration strategy: forward-only with `down` blocks; each migration reversible; rollback tested in CI.

### Non-functional

| Category | Requirement | Target | Check |
|---|---|---|---|
| Perf | P95 round-trip for 5MB JPEG | < 5s | k6 load test in CI |
| A11y | Crop UI keyboard-navigable | 100% | axe-core in CI |
| Security | Auth required | 100% | SAST gate (Semgrep) |
| Security | EXIF GPS stripped | 100% | unit test (AC7) |
| Privacy | PII (face) not logged | 100% | log-assert in CI |
| Privacy | Original image not stored | 100% | audit: only processed variants in S3 |
| Observability | Upload latency, error rate, size | OTel tagged | `feature=profile-photo-upload`, `ai_assisted=false` |

## Acceptance Criteria

> Each AC is machine-checkable or explicitly human-judged. The Coder
> writes one test per AC. `/vibe-verify` confirms every AC has evidence
> by checking the `automated test:` path is in the diff and the test
> function name appears in that file's diff (added or unchanged).

- [ ] **AC1.** Uploading a 5MB JPEG returns 200 with all four variants (`32`, `64`, `256`, `512`).
  - Verification:
    - automated test: `tests/api/uploads.test.ts::test_AC1_upload_5mb_jpeg_returns_200_with_variants`
    - expected behavior: response status 200; body lists 4 variant URLs
- [ ] **AC2.** Uploading a 12MB file returns 400 `file_too_large`.
  - Verification:
    - automated test: `tests/api/uploads.test.ts::test_AC2_upload_12mb_returns_400_file_too_large`
    - expected behavior: status 400; body error code `file_too_large`
- [ ] **AC3.** Uploading a `.gif` returns 400 `unsupported_media_type`.
  - Verification:
    - automated test: `tests/api/uploads.test.ts::test_AC3_upload_gif_returns_400_unsupported`
    - expected behavior: status 400; error code `unsupported_media_type`
- [ ] **AC4.** Uploading with no `Authorization` returns 401.
  - Verification:
    - automated test: `tests/api/uploads.test.ts::test_AC4_upload_without_auth_returns_401`
    - expected behavior: status 401
- [ ] **AC5.** Re-uploading with the same `Idempotency-Key` returns the original response and does **not** create a second asset.
  - Verification:
    - automated test: `tests/api/uploads.test.ts::test_AC5_idempotency_key_returns_original`
    - expected behavior: identical response body; row count for asset unchanged
- [ ] **AC6.** After upload, the photo appears in the feed within 3 seconds (cache invalidation).
  - Verification:
    - automated test: `tests/integration/feed-cache.test.ts::test_AC6_upload_appears_in_feed_within_3s`
    - expected behavior: GET /feed returns the new asset within 3s
- [ ] **AC7.** Cropping removes EXIF GPS data (privacy).
  - Verification:
    - automated test: `tests/api/uploads.test.ts::test_AC7_crop_removes_exif_gps`
    - expected behavior: output JPEG has no GPS IFD
- [ ] **AC8.** `DELETE` removes the photo from the feed within 3 seconds.
  - Verification:
    - automated test: `tests/api/uploads.test.ts::test_AC8_delete_removes_from_feed_within_3s`
    - expected behavior: GET /feed no longer lists the asset within 3s
- [ ] **AC9.** Photo appears at 32, 64, 256, 512 px on the profile page (4 distinct URLs).
  - Verification:
    - automated test: `tests/web/profile.test.ts::test_AC9_profile_renders_4_variants`
    - expected behavior: profile HTML contains 4 img tags with the expected widths
- [ ] **AC10.** Concurrent uploads from the same user: last-write wins; earlier ones receive 409.
  - Verification:
    - automated test: `tests/api/uploads.test.ts::test_AC10_concurrent_uploads_conflict`
    - expected behavior: 2 parallel POSTs; one wins, one returns 409

## Constraints

### Hard constraints

- Do NOT introduce new top-level dependencies. Use `sharp` (pinned in lockfile).
- Do NOT modify files under `/migrations/` once committed.
- Do NOT use `any` in TypeScript without an eslint-disable justification.
- Do NOT hardcode secrets, URLs, or environment-specific values.
- Do NOT touch: `src/auth/`, `src/billing/`, `src/security/`, `src/middleware/requireAuth.ts`.

### AI-authored surface area

AI may write (with review):
- [x] Standard CRUD: photo CRUD endpoint, model, repo (excluding auth).
- [x] UI scaffolding: crop modal UI (front-end only).
- [x] Tests: most unit tests; integration test fixture helpers.
- [ ] Doc drafts.

Human must author (AI may assist):
- [x] Auth middleware (`requireAuth`) around the endpoint.
- [x] Migrations (down blocks).
- [x] Sharp processing pipeline (data-loss / privacy implications).
- [x] Rate-limiter config (cost implications).

AI may NOT:
- Add new top-level dependencies. (`sharp` already in repo.)
- Use TypeScript `any`.
- Bypass the auth middleware on the upload route.

## Edge Cases (exhaustive)

### Mandatory 11

- Empty input (zero-byte file): rejected with 400 `empty_file`.
- Max-size input (>10MB): rejected with 413.
- Unicode / non-ASCII filenames: NFC-normalized; tests use both NFC and NFD.
- Concurrent same-resource access: row-level lock; second concurrent request returns 409.
- Network failure mid-operation: client retries with same `Idempotency-Key`; original asset returned.
- Auth token expired: 401; UI redirects to login.
- User with no permission (writing for another user): 403 `not_your_resource`.
- Database unavailable: 503 with `retry-after: 30`.
- Idempotency on retry: returns original; no double charge.
- Timezone / clock skew: stored as UTC; serialization includes offset.
- Malformed multipart body (incomplete): 400 `malformed_request`.

### Beyond mandatory

- Filetype spoofing (PNG renamed `.jpg`): rejected by sharp's decoder (`400 decode_failed`).
- Filetype-from-magic-byte mismatch: rejected.
- Virus / malware in image: not detected (out of scope for MVP — flagged in follow-up).
- Crop to less than 64×64: rejected with 400 `image_too_small` (would produce a poor avatar).
- Multiple variants in single upload URL — distinct, not aliased.
- S3 outage: 503; request retryable.
- Rate-limit boundary: 5 uploads/minute per user; 6th request 429.
- Storage quota: 100MB total per user; over-quota returns 422 `quota_exceeded`.

## Non-Goals

- Multiple photos / carousel.
- Cover photo (separate feature).
- Filters / adjustments.
- Generated avatars (separate feature).
- Animated formats (GIF, APNG).

## Technical Decisions

- **Use `sharp` for processing** (rotate-then-crop-then-resize): owned by the existing project; locks in via pinned version. EXIF strip happens at `sharp.rotate()` before resize.
- **Last-write-wins on concurrent uploads**: matches user expectation; 409 on the loser.
- **Idempotency key without time window**: same `Idempotency-Key` returns original forever. Simpler than TTL.
- **Storage quota soft (warn) for V1**: hard quota (422) flagged in next-spec.

> For irreversible decisions, write an ADR (`docs/decisions/NNNN-<slug>.md`).
> The above are routine; deeper tradeoffs (e.g. switching to a CDN-fronted
> signed-URL variant) would warrant an ADR.

## Verification

### Plan

- Commands: `pnpm test:unit` (Vitest), `pnpm test:integration` (Vitest + testcontainers Postgres), `pnpm lint`, `pnpm tsc --noEmit`, `pnpm audit --omit=dev`.
- Manual: visually confirm variants in browser.
- Mutation testing (rank 4) on `UserPhotoRepo` and sharp processing — required for Critical ceremony level.
- Human review: @radhika before merge.

### Risks

| ID | Risk | Likelihood | Impact | Mitigation | Trigger | Owner |
|---|---|---|---|---|---|---|
| R1 | `sharp` resize produces EXIF in some configs | 2 | 5 | Unit test on output (AC7); pinned version | Test failure | @radhika |
| R2 | Concurrent uploads at exactly-N boundary | 3 | 3 | Row-level lock; 409 on race | AC10 violation | @radhika |
| R3 | S3 outage during upload | 2 | 4 | Retry + idempotency; user-visible error | 500 spike | @radhika |
| R4 | 10MB limit bypassed via Content-Encoding: gzip | 2 | 4 | Decode size check after body parse | Test bypass | @radhika |

### Dependencies

- `users` table (existing).
- NextAuth session middleware (existing).
- `sharp` (existing, version pinned in lockfile).
- S3 client (existing).

## Open questions

- [ ] Q1. Is 10MB the right max? — Owner: @radhika — Due: 2026-08-22
- [ ] Q2. Animation support deferred to V2 or hard-no forever? — Owner: @radhika
- [ ] Q3. Is the storage quota soft (warn) or hard (422)? — Owner: @radhika
- [ ] Q4. Should rotate be 90° CW only, or both directions? — Owner: @radhika
- [ ] Q5. DELETE idempotent — soft delete (keep object for 30 days) or hard delete? — Owner: @radhika
