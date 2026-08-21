# Feature: CRUD with Permissions

> Copy this to `docs/requirements/<slug>/spec.md`, customize the `<angle brackets>`,
> then run `vibe-spec-approve <slug>`.

## Goal

Standard create / read / update / delete flow for a resource (e.g. `Project`,
`Document`, `Workspace`), with **role-based access control** at the row level.
A user has a role on each resource (`owner` / `admin` / `editor` / `viewer`),
and every operation checks that role server-side. Authorization happens at the
data layer too — defense in depth — not just in the route handler.

## Acceptance Criteria

- [ ] **AC1.** `POST /<resource>` creates a new row owned by the caller (`owner` role auto-assigned)
  - Verification:
    - automated test: `tests/<resource>/test_create.py::test_create_assigns_owner`
    - expected behavior: 201; response includes `id`; row exists with `owner_id = current_user.id` and a permission row linking user → resource with role=`owner`

- [ ] **AC2.** `GET /<resource>/<id>` returns the row only if the caller has at least `viewer` role
  - Verification:
    - automated test: `tests/<resource>/test_read.py::test_read_role_gated`
    - expected behavior: Caller with no role → 404 (NOT 403 — no enumeration); caller with `viewer` → 200; caller with `editor` / `admin` / `owner` → 200

- [ ] **AC3.** `PATCH /<resource>/<id>` updates fields only if the caller has at least `editor` role
  - Verification:
    - automated test: `tests/<resource>/test_update.py::test_update_role_gated`
    - expected behavior: `viewer` → 404; `editor` → 200 with patched fields; `admin` / `owner` → 200

- [ ] **AC4.** `DELETE /<resource>/<id>` is allowed only for `owner` (or admin via override)
  - Verification:
    - automated test: `tests/<resource>/test_delete.py::test_delete_owner_only`
    - expected behavior: `viewer` / `editor` / `admin` → 404; `owner` → 204; resource gone

- [ ] **AC5.** Authorization checks happen at the data layer (model method), not just the route
  - Verification:
    - automated test: `tests/<resource>/test_security.py::test_data_layer_check`
    - expected behavior: Direct model access without role check raises `PermissionDenied`; route bypass via internal call is blocked

- [ ] **AC6.** `viewer` cannot see rows they have no permission on (no list-leak)
  - Verification:
    - automated test: `tests/<resource>/test_list.py::test_list_filters_by_permission`
    - expected behavior: `GET /<resource>` returns only rows where the caller has any role; 200 with empty `[]` if none

- [ ] **AC7.** Soft-delete: `DELETE` sets `deleted_at`, row excluded from all queries by default
  - Verification:
    - automated test: `tests/<resource>/test_soft_delete.py::test_soft_delete_excluded`
    - expected behavior: After DELETE, `GET /<resource>/<id>` returns 404; `?include_deleted=true` requires admin role

- [ ] **AC8.** Owner can transfer ownership to another user (`POST /<resource>/<id>/transfer`)
  - Verification:
    - automated test: `tests/<resource>/test_transfer.py::test_transfer_ownership`
    - expected behavior: Non-owner → 404; owner → 200; new owner has `owner` role; old owner demoted to `admin`

- [ ] **AC9.** Permission changes are atomic (transfer + role downgrade in one transaction)
  - Verification:
    - automated test: `tests/<resource>/test_transfer.py::test_atomic_transfer`
    - expected behavior: If any step fails, no partial state — old owner still has access

## Constraints

- **Authorization at two layers**: route handler (for HTTP-shaped errors) + data model (defense in depth).
- **No 403 for "not found"** — return 404 to prevent enumeration of IDs.
- **Soft delete by default** (set `deleted_at`); hard delete is admin-only and audited.
- **Owner cannot self-demote below owner** without first transferring.
- **Last owner cannot delete the resource** without first transferring.
- **Permission changes are transactional** — no partial state.
- **Audit log entry** on every write that affects permissions (see audit-log template).

## Edge Cases

### Mandatory 11

- **Empty body on POST/PATCH:** 400.
- **Oversized payload:** 413.
- **Unicode in fields:** NFC-normalized, length-checked in chars (not bytes).
- **Concurrent updates:** optimistic-lock via `version` column; lost updates return 409.
- **Network failure mid-write:** transaction rolls back; client retries safely with idempotency key.
- **Caller not authenticated:** 401, never 403.
- **Caller authenticated but no role on this resource:** 404.
- **DB unavailable:** 503.
- **Idempotent DELETE:** second DELETE returns 404 (already gone), not 500.
- **Timezone / clock skew:** N/A for CRUD; `updated_at` uses UTC.
- **Malformed JSON:** 400 with field-level errors.

### Beyond mandatory

- **Self-deletion prevention** (user cannot delete a resource they're the sole owner of without transfer).
- **Bulk operations** (`POST /<resource>/bulk-delete`): require `editor` role on every target; reject atomically if any fails.
- **Field-level permissions** (e.g., `viewer` can read `name` but not `internal_notes`): express via per-field ACLs.
- **Role inheritance** (workspace admin inherits project admin): explicit mapping, not implicit hierarchy.
- **Revoked session mid-request:** the request still completes if auth check already passed; subsequent requests fail.

## Non-Goals

- ABAC (attribute-based) or ReBAC (relationship-based) authorization — RBAC only.
- Public / unauthenticated access to resources — every row requires at least one permission.
- Multi-tenancy beyond the resource scope (no cross-tenant queries).
- Row-level encryption (separate spec).
- Versioning / draft / publish workflow (separate spec).

## Verification

- `pytest tests/<resource>/ -v`
- `vibe-test` (all ranks)
- `vibe-verify` (PASS for every AC)
- **Manual:** login as `viewer` / `editor` / `owner` — verify each sees exactly what they should
- **Security:** `bandit -r src/`, attempt direct SQL injection (parameterized only), attempt IDOR across users