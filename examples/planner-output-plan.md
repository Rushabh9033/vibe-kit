# Planner output — phased implementation plan

This is what the Planner produces from `prompts/03-feature-plan.md` given `planner-output-spec.md`. Saved as: `docs/requirements/profile-photo-upload/plan.md`.

---

# Implementation Plan: Profile photo upload

Linked spec: `spec.md`

## Phases

1. Schema (migrations + model + repo)
2. Backend (endpoint + processing pipeline)
3. Frontend (UI + integration)
4. Tests (unit, integration, E2E)
5. Docs (CHANGELOG + ADR if needed)

## Phase 1 — Schema

- [ ] Migration `0007_create_user_photos.sql` (new, additive; reversible).
- [ ] Migration `0008_user_photo_storage_key.sql` (new, additive; reversible).
- [ ] Model `UserPhoto` (typed; `userId` UNIQUE).
- [ ] Repository `UserPhotoRepo` (typed queries; idempotency lookup).
- [ ] Add FK `users.photo_storage_key` → `user_photos.storage_key`.

**Done when**: migrations apply cleanly on a fresh DB and rollback works.

## Phase 2 — Backend

- [ ] `POST /v1/users/me/photo` endpoint:
  - [ ] `requireAuth()` middleware.
  - [ ] Multipart parser (use existing; no new deps).
  - [ ] Validate Content-Type, size before buffering.
  - [ ] Apply sharp: rotate (90° CW), crop to 1:1, resize to 32/64/256/512.
  - [ ] Strip EXIF (`sharp().rotate().withMetadata({ exif: {} })`).
  - [ ] Upload variants to S3.
  - [ ] Idempotency: lookup `(user_id, idempotency_key)`; if hit, return previous.
  - [ ] Write `user_photos` row in same transaction as variant upload.
  - [ ] Return photo_url + variants map.
- [ ] `DELETE /v1/users/me/photo` endpoint (idempotent).
- [ ] Rate limiter hook (5/minute per user).
- [ ] Telemetry: latency, error rate, size; OTel tagged `feature=profile-photo-upload`.

**Done when**: AC1, AC2, AC3, AC4 pass in integration tests.

## Phase 3 — Frontend

- [ ] Profile page button: "Add photo" or "Replace photo" based on existing.
- [ ] Crop modal:
  - [ ] File picker (input type="file", accept="image/jpeg,image/png,image/webp").
  - [ ] Drag-and-drop zone.
  - [ ] 1:1 crop preview with position slider.
  - [ ] Rotate 90° button.
  - [ ] Save / Cancel buttons.
  - [ ] Loading, error, success states.
  - [ ] Keyboard-navigable; ARIA roles; `aria-live="polite"` for upload progress.
- [ ] On save: generate `Idempotency-Key = uuid()`, retry on network failure.
- [ ] On error: display message; preserve crop state.
- [ ] Profile page: render `<img>` from smallest matching variant; srcset for retina.
- [ ] Feed thumbnails: replace on photo_url change within 3s (subscribe to user photo event).

**Done when**: end-to-end upload completes in a browser; AC6 verified.

## Phase 4 — Tests

- [ ] Unit: `test_AC1_through_AC10` — one per AC.
- [ ] Integration: real Postgres testcontainer; real S3 (MinIO or localstack) or mocked with strict schema.
- [ ] E2E: Playwright — upload a JPEG, verify variants render.
- [ ] Mutation (rank 4) on `UserPhotoRepo` and sharp processing functions.
- [ ] Axe-core on the crop modal.
- [ ] SAST: Semgrep rules pass; no new alerts.
- [ ] Dependency audit: `pnpm audit --omit=dev` clean.

**Done when**: all 10 ACs pass + mutation score ≥ 70% on changed lines.

## Phase 5 — Docs

- [ ] CHANGELOG.md `[Unreleased]` — one line, user-visible.
- [ ] `docs/SPEC.md` — mark M1 profile milestone claim if shipping.
- [ ] docs/decisions/NNNN-sharp-image-pipeline.md — ADR if approach is non-obvious (e.g., rotate-before-crop rationale).
- [ ] docs/requirements/profile-photo-upload/plan.md — items checked off.
- [ ] docs/handoffs/<date>-profile-photo-upload.md — written at end of last session.

**Done when**: all docs artifacts updated.

## Spec → test map

| AC | Test name (Vitest describe/it) | Status |
|---|---|---|
| AC1 | `tests/upload/photo.test.ts › AC1 5MB JPEG returns all four variants` | not started |
| AC2 | `tests/upload/photo.test.ts › AC2 12MB returns 400 file_too_large` | not started |
| AC3 | `tests/upload/photo.test.ts › AC3 .gif returns 400 unsupported_media_type` | not started |
| AC4 | `tests/upload/photo.test.ts › AC4 missing auth returns 401` | not started |
| AC5 | `tests/upload/photo.test.ts › AC5 same Idempotency-Key returns original` | not started |
| AC6 | `tests/upload/e2e/upload.test.ts › AC6 photo appears in feed within 3s` | not started |
| AC7 | `tests/upload/photo.test.ts › AC7 EXIF GPS stripped from output` | not started |
| AC8 | `tests/upload/photo.test.ts › AC8 DELETE removes within 3s` | not started |
| AC9 | `tests/upload/photo.test.ts › AC9 all four variants served` | not started |
| AC10 | `tests/upload/photo.test.ts › AC10 concurrent uploads last-write wins` | not started |

## Decisions left to make

- **Decision**: 5/minute upload rate — confirmed by user (default; per-user bucket).
- **Decision**: storage quota — soft (warn) vs hard (422). User picks; default soft + warning toast.
- **Decision**: rotate direction — 90° CW only; rationale: matches iOS/Android conventions.
- **Decision**: animation support — hard-no for V1; revisit at V2 spec.

## Risks carried over from spec

- R1 (EXIF leak via sharp config): AC7 catches via `exiftool.read(buf).gps === undefined`. Add to mutation suite.
- R2 (concurrent boundary): AC10 catches.
- R3 (S3 outage): tested via MinIO/container failure injection; not a unit test.
- R4 (gzip bypass): check at decode time, not pre-decode.

## Estimated sessions

| Phase | Effort (sessions) |
|---|---|
| 1. Schema | 0.5 |
| 2. Backend | 1.5 |
| 3. Frontend | 1.5 |
| 4. Tests | 1.5 |
| 5. Docs | 0.5 |
| **Total** | **~5.5 sessions** |

(Each session ~30 min of focused Coder work; this feature is feasible in one workday.)
