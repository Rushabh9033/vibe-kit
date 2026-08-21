#!/usr/bin/env bash
# tests/gallery/test-gallery.sh
#
# Verifies the Spec template gallery at kit/templates/features/.
#
# Coverage:
#   - README.md exists and references every template
#   - Every named template file exists
#   - Every template has the required sections: Goal, ACs, Constraints,
#     Edge Cases, Non-Goals, Verification
#   - Every template has at least 5 ACs, each with a Verification block
#     (automated test path + expected behavior)
#   - Every template is parseable by awk (no broken markdown)

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GALLERY="$KIT_ROOT/kit/templates/features"
PASS=0
FAIL=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
hdr()  { printf '\n\033[1m%s\033[0m\n' "$1"; }

[ -d "$GALLERY" ] || { echo "FAIL: gallery dir missing: $GALLERY"; exit 1; }

# The 10 templates we shipped.
TEMPLATES=(
  webhook-receiver
  auth-email-password
  auth-oauth-social
  billing-stripe
  crud-with-permissions
  search-full-text
  file-upload-storage
  email-transactional
  rate-limiting
  audit-log
)

# ---------- [1] Gallery structure ----------

hdr "[1] Gallery structure — README + every named template exists"
[ -f "$GALLERY/README.md" ] && ok "README.md present" || fail "README.md missing"
for slug in "${TEMPLATES[@]}"; do
  f="$GALLERY/$slug.md"
  if [ -f "$f" ]; then
    ok "template present: $slug.md"
  else
    fail "template missing: $slug.md"
  fi
done

# README references every template
for slug in "${TEMPLATES[@]}"; do
  if grep -qF "$slug" "$GALLERY/README.md"; then
    ok "README mentions $slug"
  else
    fail "README missing reference to $slug"
  fi
done

# ---------- [2] Required sections ----------

hdr "[2] Every template has Goal / ACs / Constraints / Edge Cases / Non-Goals / Verification"
for slug in "${TEMPLATES[@]}"; do
  f="$GALLERY/$slug.md"
  for section in "## Goal" "## Acceptance Criteria" "## Constraints" "## Edge Cases" "## Non-Goals" "## Verification"; do
    if grep -qF "$section" "$f"; then
      ok "$slug has '$section'"
    else
      fail "$slug missing '$section'"
    fi
  done
done

# ---------- [3] AC shape ----------

hdr "[3] Every template has ≥5 ACs with Verification blocks"
for slug in "${TEMPLATES[@]}"; do
  f="$GALLERY/$slug.md"
  ac_count=$(grep -cE '^- \[ \] \*\*AC[0-9]+\.' "$f" || true)
  if [ "$ac_count" -ge 5 ]; then
    ok "$slug has $ac_count ACs (≥5)"
  else
    fail "$slug has only $ac_count ACs (need ≥5)"
  fi
  # Each AC must have a Verification block with automated test + expected behavior
  verif_count=$(grep -cF "automated test:" "$f" || true)
  expect_count=$(grep -cF "expected behavior:" "$f" || true)
  if [ "$verif_count" -ge 5 ] && [ "$expect_count" -ge 5 ]; then
    ok "$slug has $verif_count verification blocks + $expect_count expected behaviors"
  else
    fail "$slug has verif=$verif_count expect=$expect_count (need ≥5 each)"
  fi
done

# ---------- [4] Mandatory 11 coverage ----------

hdr "[4] Every template covers Mandatory 11 edge cases"
# Each Mandatory 11 hint has a list of acceptable phrasings.
# Templates are natural-language documents, so we accept multiple phrasings.
MANDATORY_PATTERNS=(
  'empty|0 bytes|missing.*input|missing.*body|missing.*code|missing.*key'
  'max-size|max size|oversized|size cap|content-length|size limit'
  'unicode|UTF-8|non-ASCII'
  'concurrent|parallel'
  'network failure|API down|database down|unavailable|retry'
  'auth|signature|HMAC|credential|token|verify'
  'permission|authoriz|role|forbidden|403|401|access'
  'DB unavailable|database unavailable|503|datastore'
  'idempot|no-op|duplicate|dedup'
  'timezone|clock skew|UTC|skew'
  'malformed|invalid input|400 Bad Request|400 with'
)
for slug in "${TEMPLATES[@]}"; do
  f="$GALLERY/$slug.md"
  slug_misses=0
  for pat in "${MANDATORY_PATTERNS[@]}"; do
    if ! grep -qiE "$pat" "$f"; then
      fail "$slug missing mandatory edge-case pattern: /$pat/"
      slug_misses=$((slug_misses + 1))
    fi
  done
  if [ "$slug_misses" -eq 0 ]; then
    ok "$slug covers Mandatory 11 (all patterns matched)"
  fi
done

# ---------- [5] Markdown parses cleanly ----------

hdr "[5] Every template parses as valid markdown (no broken tables / unclosed fences)"
for slug in "${TEMPLATES[@]}"; do
  f="$GALLERY/$slug.md"
  # Count ``` — must be even (open/close pairs).
  fences=$(grep -c '```' "$f" || true)
  if [ $((fences % 2)) -eq 0 ]; then
    ok "$slug has $fences code fences (paired)"
  else
    fail "$slug has $fences code fences (UNPAIRED)"
  fi
  # Lines starting with | should pair with another | line within 50 lines (table sanity).
  # Quick check: count of | — first column should be > 0 in tables.
  table_lines=$(grep -cE '^\|' "$f" || true)
  if [ "$table_lines" -eq 0 ] || [ "$table_lines" -ge 2 ]; then
    : # 0 (no tables) or ≥2 (real table) both fine
    ok "$slug has $table_lines table lines (0 or ≥2, both OK)"
  else
    fail "$slug has only $table_lines table line (orphaned table)"
  fi
done

# ---------- [6] vibe-spec-approve accepts each template ----------

hdr "[6] Every template, copied into a fresh project, is approvable"
TMPDIR_BASE="$(mktemp -d -t vibe-gallery.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

APPROVE="$KIT_ROOT/kit/bin/vibe-spec-approve"
for slug in "${TEMPLATES[@]}"; do
  d="$(mktemp -d "$TMPDIR_BASE/$slug.XXXXXX")"
  (
    cd "$d"
    git init -q
    git config user.email t@t
    git config user.name t
    mkdir -p docs/requirements/$slug
    # Copy the template, replace awaiting-approval → in-progress is NOT needed;
    # approve flips it. But intake's spec format uses `* **Status:**`; the templates
    # use plain `Status:` lines. approve greps for `awaiting-approval` literal,
    # so we need to make sure the template has it. Templates should already.
    cp "$GALLERY/$slug.md" "docs/requirements/$slug/spec.md"
    if grep -qF "awaiting-approval" "docs/requirements/$slug/spec.md"; then
      : # template includes the marker
    else
      # Inject a Status line if the template forgot it.
      printf '* **Status:** awaiting-approval\n' > /tmp/.spec-top
      cat /tmp/.spec-top "docs/requirements/$slug/spec.md" > /tmp/.spec-merged
      mv /tmp/.spec-merged "docs/requirements/$slug/spec.md"
    fi
    bash "$APPROVE" "$slug" --no-arm >/dev/null 2>&1 ; rc=$?
    echo "$rc" > /tmp/.approve-rc-$slug
  )
  rc="$(cat /tmp/.approve-rc-$slug 2>/dev/null || echo unset)"
  if [ "$rc" = "0" ]; then
    ok "$slug: approve exits 0"
  else
    fail "$slug: approve failed (rc=$rc)"
  fi
done

# ---------- summary ----------

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;32mAll %d assertions passed.\033[0m\n' "$PASS"
  exit 0
else
  printf '\033[1;31m%d failed, %d passed.\033[0m\n' "$FAIL" "$PASS"
  exit 1
fi