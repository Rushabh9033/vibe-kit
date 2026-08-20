# Planner output — per-feature spec

This is what the Planner produces from `prompts/02-feature-spec.md` given `intake-prd.md`.

Saved as: `docs/requirements/profile-photo-upload/spec.md`

---

# Feature: Profile photo upload

**Status:** in-progress
**Owner:** @radhika
**Last updated:** 2026-08-20
**Linked milestone:** docs/SPEC.md ## M1 (Profile)

## Scope

A user can upload a single profile photo. Photo is cropped to a 1:1 square at upload time, then served at four variants (32, 64, 256, 512 px) so it looks good across the app. Replaces existing photo if one is present.

## Not in scope

- Multiple photos / carousel.
- Cover photo (separate feature).
- Filters / adjustments.
- Generated avatars (separate feature).
- Animated formats (GIF, APNG).

## User-facing behavior

- User clicks "Add photo" on profile page.
- Modal opens with file picker (drag-and-drop also supported on desktop).
- After selecting, image is shown in a 1:1 crop preview with a position slider.
- User can rotate 90° clockwise (single button).
- User clicks "Save"; photo appears throughout the app within 3 seconds.
- If a photo already exists, user sees "Replace photo" instead.

## API contract

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

## Data model

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

## Acceptance criteria (each = one test)

- [ ] **AC1.** Uploading a 5MB JPEG returns 200 with all four variants (`32`, `64`, `256`, `512`).
- [ ] **AC2.** Uploading a 12MB file returns 400 `file_too_large`.
- [ ] **AC3.** Uploading a `.gif` returns 400 `unsupported_media_type`.
- [ ] **AC4.** Uploading with no `Authorization` returns 401.
- [ ] **AC5.** Re-uploading with the same `Idempotency-Key` returns the original response and does **not** create a second asset.
- [ ] **AC6.** After upload, the photo appears in the feed within 3 seconds (cache invalidation).
- [ ] **AC7.** Cropping removes EXIF GPS data (privacy).
- [ ] **AC8.** `DELETE` removes the photo from the feed within 3 seconds.
- [ ] **AC9.** Photo appears at 32, 64, 256, 512 px on the profile page (4 distinct URLs).
- [ ] **AC10.** Concurrent uploads from the same user: last-write wins; earlier ones receive 409.

## Edge cases (exhaustive)

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

## NFRs (this feature)

| Category | Requirement | Target | Check |
|---|---|---|---|
| Perf | P95 round-trip for 5MB JPEG | < 5s | k6 load test in CI |
| A11y | Crop UI keyboard-navigable | 100% | axe-core in CI |
| Security | Auth required | 100% | SAST gate (Semgrep) |
| Security | EXIF GPS stripped | 100% | unit test (test_AC7) |
| Privacy | PII (face) not logged | 100% | log-assert in CI |
| Privacy | Original image not stored | 100% | audit: only processed variants in S3 |
| Observability | Upload latency, error rate, size | OTel tagged | `feature=profile-photo-upload`, `ai_assisted=false` |

## AI-authored surface area

AI may write (with review):
- Standard CRUD: photo CRUD endpoint, model, repo (excluding auth).
- UI scaffolding: crop modal UI (front-end only).
- Tests: most unit tests; integration test fixture helpers.

Human must author (AI may assist):
- Auth middleware (`requireAuth`) around the endpoint.
- Migrations (down blocks).
- Sharp processing pipeline (data-loss / privacy implications).
- Rate-limiter config (cost implications).

AI may not:
- Add new top-level dependencies. (`sharp` already in repo.)
- Use TypeScript `any`.
- Bypass the auth middleware on the upload route.

## Hallucination tolerance

| Surface | Autonomy | Required verification | Human review trigger |
|---|---|---|---|
| UI / crop modal | High | axe-core, visual diff | Accessibility score drop |
| Photo CRUD (no auth) | Medium | Integration tests pass | New endpoint, schema |
| Sharp processing | Low | Mutation testing on AC7 | EXIF strip test failure |
| Auth middleware | None | SAST + manual review | Always |
| Migrations | None | Manual review | Always |

## Dependencies

- `users` table (existing).
- NextAuth session middleware (existing).
- `sharp` (existing, version pinned in lockfile).
- S3 client (existing).

## Verification plan

- Commands: `pnpm test:unit` (Vitest), `pnpm test:integration` (Vitest + testcontainers Postgres), `pnpm lint`, `pnpm tsc --noEmit`, `pnpm audit --omit=dev`.
- Manual: visually confirm variants in browser.
- Human review: @radhika before merge.

## Risks

| ID | Risk | Likelihood | Impact | Mitigation | Trigger | Owner |
|---|---|---|---|---|---|---|
| R1 | `sharp` resize produces EXIF in some configs | 2 | 5 | Unit test on output (AC7); pinned version | Test failure | @radhika |
| R2 | Concurrent uploads at exactly-N boundary | 3 | 3 | Row-level lock; 409 on race | AC10 violation | @radhika |
| R3 | S3 outage during upload | 2 | 4 | Retry + idempotency; user-visible error | 500 spike | @radhika |
| R4 | 10MB limit bypassed via Content-Encoding: gzip | 2 | 4 | Decode size check after body parse | Test bypass | @radhika |

## Hard constraints for this feature

- Do NOT introduce new top-level dependencies. Use `sharp` (pinned in lockfile).
- Do NOT modify files under `/migrations/` once committed.
- Do NOT use `any` in TypeScript without an eslint-disable justification.
- Do NOT hardcode secrets, URLs, or environment-specific values.
- Do NOT touch: `src/auth/`, `src/billing/`, `src/security/`, `src/middleware/requireAuth.ts`.

## Open questions (block implementation)

- [ ] Q1. Is 10MB the right max? — Owner: @radhika — Due: 2026-08-22
- [ ] Q2. Animation support deferred to V2 or hard-no forever? — Owner: @radhika
- [ ] Q3. Is the storage quota soft (warn) or hard (422)? — Owner: @radhika
- [ ] Q4. Should rotate be 90° CW only, or both directions? — Owner: @radhika
- [ ] Q5. DELETE idempotent — soft delete (keep object for 30 days) or hard delete? — Owner: @radhika
