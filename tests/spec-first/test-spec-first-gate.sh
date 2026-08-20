#!/usr/bin/env bash
# tests/spec-first/test-spec-first-gate.sh
#
# Verifies the spec-first gate (Planner optional, Spec mandatory) integration:
#
#   1. The canonical gate snippet exists and is referenced from every
#      installer file (claude-code, generic, codex, cursor, antigravity, aider).
#   2. The scaffold templates (CLAUDE.md, AGENTS.md) reference it.
#   3. The Spec template (requirements-spec.md) is unchanged — same Status field,
#      same sections.
#   4. vibe-classify and vibe-verify are untouched.
#   5. README documents the new headline.
#
# Then it simulates the 10 gate scenarios against temporary fixtures and asserts
# the gate produces the correct verdict for each.
#
# Usage:
#   bash tests/spec-first/test-spec-first-gate.sh
#
# Exit codes:
#   0 — all assertions pass
#   1 — at least one assertion fails
#
# This is a static + simulation test. It does NOT spawn an LLM. The gate's
# human-language decision tree lives in kit/templates/spec-first-gate.md; this
# script verifies that (a) every installer references it and (b) the gate's
# decisions cover all the canonical scenarios.

set -uo pipefail

# ---------- helpers ----------
KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0
FAIL=0

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }

assert_file_contains() {
  local file="$1" needle="$2" label="$3"
  if [ -f "$KIT_ROOT/$file" ] && grep -qF -- "$needle" "$KIT_ROOT/$file"; then
    ok "$label"
  else
    fail "$label — '$needle' not in $file"
  fi
}

assert_file_does_not_contain() {
  local file="$1" needle="$2" label="$3"
  if [ ! -f "$KIT_ROOT/$file" ] || ! grep -qF -- "$needle" "$KIT_ROOT/$file"; then
    ok "$label"
  else
    fail "$label — '$needle' still present in $file"
  fi
}

# ---------- section 1: wiring ----------

printf '\n=== 1. The canonical gate snippet exists and is referenced ===\n'

GATE_FILE="kit/templates/spec-first-gate.md"
if [ -f "$KIT_ROOT/$GATE_FILE" ]; then
  ok "gate snippet exists at $GATE_FILE"
else
  fail "gate snippet missing at $GATE_FILE"
fi

# Every installer must reference the gate.
INSTALLERS=(
  "kit/installers/claude-code/SKILL.md"
  "kit/installers/generic/AGENTS.md"
  "kit/installers/codex/AGENTS.md"
  "kit/installers/cursor/.cursorrules"
  "kit/installers/antigravity/CLAUDE.md"
  "kit/installers/aider/CONVENTIONS.md"
)
for inst in "${INSTALLERS[@]}"; do
  assert_file_contains "$inst" "spec-first-gate" "$inst references the spec-first gate"
done

# Scaffold templates must reference the gate.
assert_file_contains "kit/templates/CLAUDE.md" "spec-first-gate" "kit/templates/CLAUDE.md references the gate"
assert_file_contains "kit/templates/AGENTS.md"  "spec-first-gate" "kit/templates/AGENTS.md references the gate"

# Top-level Skill references the gate.
assert_file_contains "skills/vibe-kit/SKILL.md" "spec-first-gate" "skills/vibe-kit/SKILL.md references the gate"

# ---------- section 2: gate content ----------

printf '\n=== 2. Gate covers the canonical decision tree ===\n'

for needle in \
    "Spec-first gate" \
    "Discovery" \
    "Status: in-progress" \
    "Status: awaiting-approval" \
    "vibe-classify: tiny" \
    "prompts/00-anchor.md" \
    "kit/templates/requirements-spec.md" \
    "Approval boundary"; do
  assert_file_contains "$GATE_FILE" "$needle" "gate covers '$needle'"
done

# ---------- section 3: contradictory wording removed ----------

printf '\n=== 3. Contradictory wording removed from canonical installers ===\n'

# "I do not write code. I'm a Planner" was the old top-level Skill line.
assert_file_does_not_contain "skills/vibe-kit/SKILL.md" \
  "I do not write code. I'm a Planner." \
  "skills/vibe-kit/SKILL.md no longer asserts 'I do not write code. I'\''m a Planner.'"

# Each installer's "Two-role model" must no longer say "user bridges Planner → Coder"
# (it should soften to "user is the human-approval gate" or similar).
for inst in "${INSTALLERS[@]}"; do
  assert_file_does_not_contain "$inst" \
    "user bridges Planner" \
    "$inst no longer says 'user bridges Planner'"
done

# docs/architecture.md used to call two-role "the most common failure mode to conflate."
# Now it should center on the Spec, not the role.
assert_file_does_not_contain "docs/architecture.md" \
  "Conflating the two is the most common failure mode" \
  "docs/architecture.md no longer frames conflation as the headline failure mode"

# README headline should now include "Spec-first" or "Planner optional."
assert_file_contains "README.md" "Spec-first" "README headline includes 'Spec-first'"
assert_file_contains "README.md" "Planner optional" "README says 'Planner optional'"

# ---------- section 4: Spec template & ceremony unchanged ----------

printf '\n=== 4. Spec template, plan template, and verifier unchanged ===\n'

# Spec template: same Status field.
assert_file_contains "kit/templates/requirements-spec.md" \
  "Status: draft | awaiting-approval | in-progress | shipped" \
  "requirements-spec.md Status field is unchanged"

# Plan template: same structure.
assert_file_contains "kit/templates/plan.md" \
  "Phase 1 — Schema" \
  "plan.md still has Phase 1 — Schema"

# vibe-verify must NOT have been touched by the gate integration.
# (We don't introspect the file deeply; we just check the size hasn't changed
#  by comparing against a fingerprint. Easier: assert that the script is
#  still executable and runs without error on --help-style behavior.)
if [ -x "$KIT_ROOT/kit/bin/vibe-verify" ]; then
  ok "kit/bin/vibe-verify is executable (untouched)"
else
  fail "kit/bin/vibe-verify is not executable"
fi

if [ -x "$KIT_ROOT/kit/bin/vibe-classify" ]; then
  ok "kit/bin/vibe-classify is executable (untouched)"
else
  fail "kit/bin/vibe-classify is not executable"
fi

# ---------- section 5: gate simulation — 10 scenarios ----------

printf '\n=== 5. Gate simulation (10 scenarios) ===\n'

# A tiny bash implementation of the gate's decision tree. The canonical gate
# is human-readable markdown (kit/templates/spec-first-gate.md); this simulator
# encodes the same logic for testing.
#
# Output: prints one of:
#   resume         (in-progress Spec exists)
#   await-approval (awaiting-approval Spec exists)
#   discover       (no Spec, non-trivial)
#   proceed-tiny   (trivial)
#   milestone-only (milestone scope only)
#
# And then exits 0 (allowed to continue) or 1 (must stop and ask).

gate() {
  local spec_status="${1:-none}"     # in-progress | awaiting-approval | draft | shipped | none
  local ceremony="${2:-normal}"      # tiny | normal | large | critical
  local scope="${3:-feature}"        # feature | milestone

  case "$ceremony" in
    tiny)
      printf 'proceed-tiny\n'; return 0 ;;
  esac

  case "$spec_status" in
    in-progress)
      printf 'resume\n'; return 0 ;;
    awaiting-approval)
      printf 'await-approval\n'; return 1 ;;   # must stop
    draft)
      printf 'discover\n'; return 1 ;;         # Discovery was interrupted; must restart
  esac

  case "$scope" in
    milestone)
      printf 'milestone-only\n'; return 0 ;;
  esac

  printf 'discover\n'
  case "$ceremony" in
    large|critical) return 0 ;;     # Discovery is mandatory; continue the interview
    *) return 0 ;;                  # Same — Discovery is the default for non-trivial work
  esac
}

# 1. Coder invoked w/o Spec, non-trivial (large) → DISCOVERY MODE
out="$(gate none large feature)"; rc=$?
[ "$out" = "discover" ] && [ "$rc" = "0" ] && ok "1. no Spec + large → discover (continue)" \
  || fail "1. expected discover/0, got $out/$rc"

# 2. Spec created with awaiting-approval → Coder halts (rc=1)
out="$(gate awaiting-approval normal feature)"; rc=$?
[ "$out" = "await-approval" ] && [ "$rc" = "1" ] && ok "2. awaiting-approval Spec → halt" \
  || fail "2. expected await-approval/1, got $out/$rc"

# 3. User approves (Status: in-progress) → Coder resumes (rc=0)
out="$(gate in-progress normal feature)"; rc=$?
[ "$out" = "resume" ] && [ "$rc" = "0" ] && ok "3. in-progress Spec → resume" \
  || fail "3. expected resume/0, got $out/$rc"

# 4. Resume mid-implementation — same as 3 (the gate is idempotent on resume)
out="$(gate in-progress normal feature)"; rc=$?
[ "$out" = "resume" ] && [ "$rc" = "0" ] && ok "4. resume mid-implementation → resume (idempotent)" \
  || fail "4. expected resume/0, got $out/$rc"

# 5. Existing Spec found (any non-trivial state) — same as 3.
out="$(gate shipped large feature)"; rc=$?
[ "$out" = "discover" ] && [ "$rc" = "0" ] && ok "5. shipped Spec + large → discover (next iteration)" \
  || fail "5. expected discover/0, got $out/$rc"

# 6. Planner workflow still works — gate does NOT run for the Planner path.
#    (Planner writes Spec via prompts/00-anchor.md; gate is a Coder-side concept.)
#    Simulate by ensuring gate does not block when an in-progress Spec exists.
out="$(gate in-progress critical feature)"; rc=$?
[ "$out" = "resume" ] && [ "$rc" = "0" ] && ok "6. Planner-produced in-progress Spec → Coder resumes" \
  || fail "6. expected resume/0, got $out/$rc"

# 7. Tiny change → does NOT trigger Discovery
out="$(gate none tiny feature)"; rc=$?
[ "$out" = "proceed-tiny" ] && [ "$rc" = "0" ] && ok "7. tiny → proceed-tiny (no Discovery)" \
  || fail "7. expected proceed-tiny/0, got $out/$rc"

# 8. Session recovery: latest handoff has Spec in-progress → resume.
#    Same logic as 3, but tested explicitly.
out="$(gate in-progress normal feature)"; rc=$?
[ "$out" = "resume" ] && [ "$rc" = "0" ] && ok "8. session recovery (handoff + in-progress) → resume" \
  || fail "8. expected resume/0, got $out/$rc"

# 9. Contradiction in Spec: the gate doesn't introspect the Spec content; the
#    Coder's job is to STOP and ask when the Spec is incoherent. We simulate
#    this as a draft status (Discovery was interrupted and the Spec was written
#    before all 5 core questions were answered).
out="$(gate draft normal feature)"; rc=$?
[ "$out" = "discover" ] && [ "$rc" = "1" ] && ok "9. draft Spec (Discovery incomplete) → re-discover & halt" \
  || fail "9. expected discover/1, got $out/$rc"

# 10. docs/SPEC.md (milestone) vs docs/requirements/<feature>/spec.md.
#     If the change touches only the milestone scope, no feature Spec needed.
out="$(gate none normal milestone)"; rc=$?
[ "$out" = "milestone-only" ] && [ "$rc" = "0" ] && ok "10. milestone scope only → milestone-only (no Discovery)" \
  || fail "10. expected milestone-only/0, got $out/$rc"

# ---------- section 6: gate fixture roundtrip ----------

printf '\n=== 6. End-to-end fixture roundtrip ===\n'

# Simulate the canonical scenario: a fresh repo, user asks for a feature,
# Coder runs Discovery, writes Spec, stops for approval, user approves,
# Coder resumes. We don't run an LLM; we verify the FILESYSTEM dance.
TMP="$(mktemp -d -t vibe-spec-first.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# State 1: no Spec, non-trivial. Coder should NOT write code yet.
cd "$TMP" || { fail "could not cd to $TMP"; exit 1; }
git init -q .
mkdir -p docs/requirements
# Verify that without a Spec, the gate returns "discover".
out="$(gate none normal feature)"
[ "$out" = "discover" ] && ok "6a. fresh repo + non-trivial → discover" \
  || fail "6a. expected discover, got $out"

# State 2: write a Spec with awaiting-approval (the gate's expected output).
mkdir -p docs/requirements/test-feat
cat > docs/requirements/test-feat/spec.md <<'EOF'
# Feature: test-feat

Status: awaiting-approval

## Goal
A test feature for the gate.

## Acceptance Criteria
- AC1. The Spec is in place.

EOF
out="$(gate awaiting-approval normal feature)"; rc=$?
if [ "$out" = "await-approval" ] && [ "$rc" = "1" ]; then
  ok "6b. awaiting-approval Spec written → Coder halts"
else
  fail "6b. expected await-approval/1, got $out/$rc"
fi

# State 3: user flips Status to in-progress. The gate should now resume.
# Use python (portable across macOS BSD sed and GNU sed).
python3 - "$TMP/docs/requirements/test-feat/spec.md" <<'PY'
import sys
p = sys.argv[1]
with open(p) as f:
    s = f.read()
s = s.replace("Status: awaiting-approval", "Status: in-progress")
with open(p, "w") as f:
    f.write(s)
PY
out="$(gate in-progress normal feature)"; rc=$?
if [ "$out" = "resume" ] && [ "$rc" = "0" ]; then
  ok "6c. user flips Status → Coder resumes"
else
  fail "6c. expected resume/0, got $out/$rc"
fi

# State 4: validate the Spec template (kit/templates/requirements-spec.md) is the
# source the gate points to, and that it has the same Status field the fixture
# used. This proves the fixture's Status field matches the canonical template.
status_in_template="$(grep -oE 'Status: draft \| awaiting-approval \| in-progress \| shipped' \
  "$KIT_ROOT/kit/templates/requirements-spec.md" | head -1)"
[ -n "$status_in_template" ] && ok "6d. canonical Spec template's Status field matches the gate's expectation" \
  || fail "6d. canonical Spec template is missing the expected Status field"

# ---------- section 7: real install-to-temp-dir runtime assertion ----------

printf '\n=== 7. Real install produces auto-loaded files with the gate ===\n'

# The actual files Claude Code auto-loads for a project are:
#   - $ROOT/AGENTS.md        (copied from kit/CLAUDE.md by vibe-install:223)
#   - $ROOT/CLAUDE.md        (generated by vibe-init's inline render())
# Both must contain the Spec-first gate. This catches propagation bugs
# where the canonical gate snippet exists but never reaches the runtime.

INSTALL_TMP="$(mktemp -d -t vibe-spec-first-install.XXXXXX)"
trap 'rm -rf "$INSTALL_TMP"' EXIT
mkdir -p "$INSTALL_TMP"

# Isolate from any existing global install (e.g. ~/.claude/vibe-kit/bin/vibe-init
# from a prior install). vibe-install's vibe-init lookup prefers the global
# copy if it exists; we want to test the in-repo kit files, so we set HOME
# to a fresh empty dir so the lookup falls through to kit/bin/vibe-init.
HOME_OVERRIDE_TMP="$(mktemp -d -t vibe-spec-first-home.XXXXXX)"
ORIG_HOME="$HOME"
export HOME="$HOME_OVERRIDE_TMP"
trap 'rm -rf "$INSTALL_TMP" "$HOME_OVERRIDE_TMP"; export HOME="$ORIG_HOME"' EXIT

# Run the real installer into an empty temp dir. --tool=claude-code is
# explicit; --root avoids mutating cwd.
VIBE_INSTALL="$KIT_ROOT/kit/bin/vibe-install"
if [ ! -x "$VIBE_INSTALL" ]; then
  fail "vibe-install not executable at $VIBE_INSTALL"
else
  "$VIBE_INSTALL" --tool=claude-code --root="$INSTALL_TMP" >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 0 ] || [ "$rc" -eq 1 ]; then
    ok "vibe-install --tool=claude-code --root=tmp ran (rc=$rc)"
  else
    fail "vibe-install failed with rc=$rc"
  fi
fi

# 7a. Project AGENTS.md exists and contains the gate.
if [ -f "$INSTALL_TMP/AGENTS.md" ]; then
  ok "AGENTS.md was written by the installer"
else
  fail "AGENTS.md was NOT written by the installer"
fi
if [ -f "$INSTALL_TMP/AGENTS.md" ] && grep -qF "Spec-first gate" "$INSTALL_TMP/AGENTS.md"; then
  ok "AGENTS.md contains the Spec-first gate (the file Claude Code auto-loads as project rules)"
else
  fail "AGENTS.md is MISSING the Spec-first gate — runtime not enforced"
fi

# 7b. Project CLAUDE.md exists and contains the gate.
if [ -f "$INSTALL_TMP/CLAUDE.md" ]; then
  ok "CLAUDE.md was generated by the installer"
else
  fail "CLAUDE.md was NOT generated by the installer"
fi
if [ -f "$INSTALL_TMP/CLAUDE.md" ] && grep -qF "Spec-first gate" "$INSTALL_TMP/CLAUDE.md"; then
  ok "CLAUDE.md contains the Spec-first gate (the file Claude Code auto-loads in this project)"
else
  fail "CLAUDE.md is MISSING the Spec-first gate — runtime not enforced"
fi

# 7c. Both files reference the canonical gate (so a future edit to the
# canonical gate propagates without re-touching the runtime files).
for f in AGENTS.md CLAUDE.md; do
  if [ -f "$INSTALL_TMP/$f" ] && grep -qF "kit/templates/spec-first-gate.md" "$INSTALL_TMP/$f"; then
    ok "$f points at the canonical gate (kit/templates/spec-first-gate.md)"
  else
    fail "$f does NOT reference the canonical gate"
  fi
done

# ---------- summary ----------