# Feature: File Upload + Storage

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Let users upload files (images, PDFs, CSVs, videos, …) up to a configured max
size. Files are stored in S3-compatible object storage behind a pre-signed URL
flow (the browser uploads directly to S3, never proxies through our server with
the bytes). Server stores only the metadata + storage key. Virus scan runs
asynchronously before the file becomes "available."

## Acceptance Criteria

- [ ] **AC1.** `POST /upload/init` returns a pre-signed PUT URL + a `file_id` (no bytes hit our server)
  - Verification:
    - automated test: `tests/upload/test_init.py::test_init_returns_presigned_url`
    - expected behavior: 200 with `{file_id, upload_url, upload_fields, expires_at}`; URL is HTTPS, valid for 15min

- [ ] **AC2.** Browser uploads directly to S3 via the pre-signed URL
  - Verification:
    - automated test: `tests/upload/test_direct_upload.py::test_browser_to_s3`
    - expected behavior: PUT to `upload_url` with the returned fields succeeds; row in S3 exists; our server never sees the bytes

- [ ] **AC3.** `POST /upload/<file_id>/finalize` triggers virus scan + marks file `available` only on clean scan
  - Verification:
    - automated test: `tests/upload/test_finalize.py::test_finalize_after_clean_scan`
    - expected behavior: After PUT to S3, finalize → file status `scanning` → worker scans → status `available`

- [ ] **AC4.** Files flagged by virus scan are quarantined, NOT deleted (legal hold + investigation)
  - Verification:
    - automated test: `tests/upload/test_finalize.py::test_infected_quarantined`
    - expected behavior: EICAR test file → status `quarantined`; downloadable only by admins; alert logged

- [ ] **AC5.** File size limit (configurable, e.g. 100MB) enforced — uploads larger than cap rejected at S3 level
  - Verification:
    - automated test: `tests/upload/test_size_limit.py::test_oversized_rejected`
    - expected behavior: Init for a 200MB file with 100MB cap returns 413; pre-signed URL also enforces via content-length

- [ ] **AC6.** MIME type validated at finalize — claimed MIME must match S3's `Content-Type` from the upload
  - Verification:
    - automated test: `tests/upload/test_mime.py::test_mime_mismatch_rejected`
    - expected behavior: Upload claimed as `image/png` but bytes are `text/html` → finalize returns 415

- [ ] **AC7.** Files are private by default; access requires a pre-signed GET URL that expires in 5min
  - Verification:
    - automated test: `tests/upload/test_access.py::test_access_requires_presigned_url`
    - expected behavior: Direct S3 URL → 403; pre-signed GET URL → 200 with the file

- [ ] **AC8.** Authorization checks at download: user must have `viewer` role on the parent resource
  - Verification:
    - automated test: `tests/upload/test_access.py::test_access_role_gated`
    - expected behavior: Generate download URL without permission → 403; with permission → 200

## Constraints

- **Browser uploads directly to S3** (or S3-compatible: R2, GCS, MinIO). Our server NEVER proxies bytes.
- **Pre-signed URLs** are HTTPS, scoped to one operation, expire in 15 minutes (PUT) or 5 minutes (GET).
- **File size cap** enforced both at init AND at S3 (via signed policy).
- **MIME validation**: claimed MIME at init + actual MIME from upload must agree.
- **Virus scan is mandatory** before `available` status; quarantine, do NOT delete.
- **All files are private** at the bucket level; access is via pre-signed URL only.
- **Filename sanitized**: strip path traversal (`../`), null bytes, control chars; max 255 chars.
- **Storage keys are random UUIDs** (`<user-id-prefix>/<uuid>.<ext>`) — never user-supplied.

## Edge Cases

### Mandatory 11

- **Empty file (0 bytes):** init rejects; finalize rejects.
- **Max-size input:** > cap → 413 at init.
- **Unicode / non-ASCII filenames:** NFC-normalized, then sanitized; non-printable stripped.
- **Concurrent uploads of same filename:** each gets unique storage key; no collision.
- **Network failure mid-upload:** S3 multipart upload aborts cleanly; finalize returns 410 (gone).
- **Caller not authenticated:** 401.
- **User with no permission on parent resource:** 403.
- **S3 unavailable:** init returns 503.
- **Idempotent finalize:** second finalize after `available` is a no-op (returns current state).
- **Timezone / clock skew:** N/A (URL expiry is server-time).
- **Malformed Content-Type:** rejected at finalize.

### Beyond mandatory

- **Resumable uploads**: use S3 multipart upload for files > 50MB.
- **Image variants**: generate thumbnail / medium / large at finalize; serve via `?variant=` param.
- **EXIF stripping**: for images, strip EXIF on the server side before `available`.
- **PDF preview generation**: thumbnail of first page; searchable text layer.
- **Deduplication**: hash-based dedup within a user's library (optional).
- **Quota enforcement**: per-user storage quota; over-quota upload returns 507.
- **Antivirus vendor down**: graceful degradation — file goes to `pending_scan` and is held until scanner recovers; alert ops.

## Non-Goals

- Streaming uploads for files > 5GB (use multipart instead).
- File versioning / file history (separate spec).
- File sharing via public links (separate spec — public share).
- File previews for proprietary formats (Office, Keynote) — show "download to view" instead.
- Sync clients (desktop / mobile sync) — different spec.
- Direct browser-to-browser transfers.

## Verification

- `pytest tests/upload/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Manual:** upload a clean image (becomes `available`), upload EICAR test file (quarantined), upload oversized file (413), try to access without permission (403)
- **Security:** confirm bucket is private; confirm pre-signed URLs expire; try path traversal in filename
- **Load:** 100 concurrent uploads of 10MB files, verify completion within 60s each