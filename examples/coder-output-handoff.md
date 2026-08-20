# Coder output — session handoff

This is what the Coder tool writes at the end of a session (via `kit/bin/hooks/session-end-handoff.sh`). Saved as: `docs/handoffs/2026-08-20-profile-photo-upload.md`.

---

# Session: 2026-08-20 — profile-photo-upload

## Goal
Build Phase 1 (Schema) of `docs/requirements/profile-photo-upload/spec.md` per `plan.md`.

## Branch / state
`feature/profile-photo-upload` based on `main`; clean (committed before session end).

## Done
- [x] Migration `0007_create_user_photos.sql` (created; tested; reversible).
- [x] Migration `0008_user_photo_storage_key.sql` (created; tested; reversible).
- [x] Model `UserPhoto` (typed; UUID PK; FK to users).
- [x] Repository `UserPhotoRepo` (typed queries; idempotency lookup).
- [x] `pnpm test:unit` passes for schema tests.
- [x] `pnpm db:rollback` works (down migrations tested).
- [x] CHANGELOG.md `[Unreleased]` → "Profile photo schema (table + repo)" — committed.
- [x] docs/handoffs/2026-08-20-profile-photo-upload.md (this file) — written.

## In progress
- (none — Phase 1 complete)

## Blocked
- (none)

## Files touched
- `db/migrations/0007_create_user_photos.sql` — new
- `db/migrations/0008_user_photo_storage_key.sql` — new
- `src/db/models/user-photo.ts` — new (model)
- `src/db/repos/user-photo-repo.ts` — new (typed queries)
- `src/db/migrations/index.ts` — updated (register new migrations)
- `tests/db/user-photo-repo.test.ts` — new
- `CHANGELOG.md` — added `[Unreleased]` entry

## Decisions made
- **Decision**: Use `pg_trgm` extension for filename search? Decision: **NO** for V1; revisit only if search across photos becomes a feature.
- **Decision**: `user_photos.idempotency_key` stored as TEXT (not UUID-typed) — to allow free-form keys from clients without enforcing parseability.

## Decisions needed
- **Decision**: Storage quota soft/hard — user leaning soft (warn toast); confirm before Phase 2 ships.
- **Decision**: Rotate direction — user confirmed 90° CW only.

## Verification

- [x] `pnpm test:unit` — 24/24 pass
- [x] `pnpm lint` — pass
- [x] `pnpm tsc --noEmit` — pass
- [x] `pnpm db:rollback` + `pnpm db:migrate` — round-trip clean
- [ ] Mutation testing on `UserPhotoRepo` — **DEFERRED** to Phase 4 (full test suite together)
- [ ] Integration test with real Postgres testcontainer — pending Phase 2 when logic exists
- [ ] E2E — pending Phase 3 / Phase 4

(Verification ranks 1 + 2 met; ranks 3–7 deferred to later phases per plan.md.)

## Spec → test map status

| AC | Test | Status |
|---|---|---|
| AC1 | `tests/upload/photo.test.ts › AC1 5MB JPEG returns all four variants` | deferred (Phase 2+4) |
| AC2–AC10 | … | all deferred to Phase 2+4 (correct per plan) |
| (Schema ACs implicit in plan.md) | `tests/db/user-photo-repo.test.ts › CRUD + idempotency lookup` | **PASSING** |

## Next steps for next session (Phase 2)

1. Read `docs/requirements/profile-photo-upload/spec.md` and `plan.md` first. (`/vibe-anchor`-equivalent.)
2. Implement `POST /v1/users/me/photo` per Phase 2 steps in plan.md.
3. Apply `requireAuth()` middleware — **do not skip** (hard constraint).
4. Sharp processing pipeline: rotate-then-crop-then-resize, **EXIF strip before save** (AC7).
5. Write `tests/upload/photo.test.ts` with one test per AC2 / AC3 / AC4 / AC5 / AC7 (skip AC1, AC6, AC8, AC9, AC10 for this phase; they're Phase 2 / 3 / 4 work).
6. Run `/vibe-verify` — confirm rank 1 + 2 green.
7. Update CHANGELOG and write handoff.

## Gotchas learned

- `sharp.rotate()` before resize correctly strips EXIF (no separate `.withMetadata({})` call needed in current version). (added 2026-08-20)
- `pg_trgm` extension is **not** enabled by default in our test postgres; if used, must `CREATE EXTENSION` in migration. (added 2026-08-20)
- The "users add photo storage key" migration needs a default of NULL initially, populated lazily as users upload — don't backfill in the migration (avoid long-running migrations). (added 2026-08-20)

<!-- context metadata (do not edit) -->
- session_id: <session-id>
- started: 2026-08-20T14:23:00
- cwd: /Users/<you>/projects/couples-app
- branch: feature/profile-photo-upload
- written_by: vibe-kit/Stop-hook (command)
- session_end_hook_fired: true
