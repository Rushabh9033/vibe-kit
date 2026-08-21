#!/usr/bin/env bash
# tests/weapons/test-install-oneclick.sh
#
# Verifies install.sh and vibe-update per docs/requirements/vibe-install-oneclick/spec.md.
# Stubs `git` so no real network calls happen. Uses --prefix for isolation.

set -uo pipefail

KIT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INSTALL_SH="$KIT_ROOT/install.sh"
UPDATE_BIN="$KIT_ROOT/kit/bin/vibe-update"

PASS=0
FAIL=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
hdr()  { printf '\n\033[1m%s\033[0m\n' "$1"; }

TMPDIR_BASE="$(mktemp -d -t vibe-install-tests.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------- environment scaffold ----------
SANDBOX="$TMPDIR_BASE/sandbox"
mkdir -p "$SANDBOX/bin" "$SANDBOX/repo" "$SANDBOX/home"
export HOME="$SANDBOX/home"
mkdir -p "$HOME"

# Stub `git` that emulates `git clone` by populating $REPO_DIR with a
# representative kit/ tree. Other git invocations fall through to the
# real binary (the install script doesn't use them).
cat > "$SANDBOX/bin/git" <<'EOF'
#!/usr/bin/env bash
# Fake git: handles `git clone ... URL DEST`
if [ "$1" = "clone" ]; then
  # last positional arg = DEST
  for arg in "$@"; do :; done
  url=""
  dest=""
  # Find URL (http*) and DEST (last arg).
  for arg in "$@"; do
    case "$arg" in
      http*|git@*) url="$arg" ;;
    esac
  done
  dest="${!#}"
  mkdir -p "$dest/kit/bin" "$dest/kit/bin/hooks"
  mkdir -p "$dest/kit/templates" "$dest/kit/prompts" "$dest/kit/installers"
  mkdir -p "$dest/kit/rules" "$dest/kit/commands"
  cat > "$dest/kit/bin/vibe-install" <<'INNER'
#!/usr/bin/env bash
echo "fake vibe-install"
INNER
  cat > "$dest/kit/bin/vibe-detect-tool" <<'INNER'
#!/usr/bin/env bash
echo "fake vibe-detect-tool"
INNER
  cat > "$dest/kit/bin/vibe-verify" <<'INNER'
#!/usr/bin/env bash
echo "fake vibe-verify"
INNER
  cat > "$dest/kit/bin/vibe-mutate" <<'INNER'
#!/usr/bin/env bash
echo "fake vibe-mutate"
INNER
  cat > "$dest/kit/bin/hooks/prep-room.sh" <<'INNER'
#!/usr/bin/env bash
echo "fake prep-room"
INNER
  cat > "$dest/kit/CLAUDE.md" <<'INNER'
# Master kit rules (test stub)
INNER
  cat > "$dest/AGENTS.md" <<'INNER'
# AGENTS.md (test stub)
curl -fsSL https://raw.githubusercontent.com/Rushabh9033/vibe-kit/main/install.sh | bash
vibe-install
INNER
  cat > "$dest/kit/prompts/spec-intake.md" <<'INNER'
# fake prompt
INNER
  exit 0
fi
# Anything else: pass through to real git (unlikely needed in tests).
exec /usr/bin/env -i PATH="/usr/bin:/bin" /usr/bin/git "$@"
EOF
chmod +x "$SANDBOX/bin/git"

# Stub `curl` and `wget` (vibe-update uses them) — fail loudly so
# tests catch accidental network use.
cat > "$SANDBOX/bin/curl" <<'EOF'
#!/usr/bin/env bash
echo "FAIL: curl should not be called in tests" >&2
exit 99
EOF
cat > "$SANDBOX/bin/wget" <<'EOF'
#!/usr/bin/env bash
echo "FAIL: wget should not be called in tests" >&2
exit 99
EOF
chmod +x "$SANDBOX/bin/curl" "$SANDBOX/bin/wget"

export PATH="$SANDBOX/bin:/usr/bin:/bin"

# ---------- [1] install.sh existence + help ----------

hdr "[1] install.sh exists + bash 3.2 portable"
[ -x "$INSTALL_SH" ] && ok "install.sh is executable" || fail "install.sh not executable"
bash -n "$INSTALL_SH" && ok "bash -n clean" || fail "syntax error in install.sh"

out="$(bash "$INSTALL_SH" --help 2>&1)"; rc=$?
[ "$rc" = "0" ] && ok "--help exits 0" || fail "--help rc=$rc"
echo "$out" | grep -qF -- "--prefix" && ok "help mentions --prefix" || fail "help missing --prefix"
echo "$out" | grep -qF -- "--yes" && ok "help mentions --yes" || fail "help missing --yes"
echo "$out" | grep -qF -- "--no-path-edit" && ok "help mentions --no-path-edit" || fail "help missing --no-path-edit"
echo "$out" | grep -qF -- "--uninstall" && ok "help mentions --uninstall" || fail "help missing --uninstall"

if grep -qE 'mapfile|declare -A' "$INSTALL_SH"; then
  fail "install.sh uses bash 4+ features"
else
  ok "bash 3.2 portable (no mapfile/declare -A)"
fi

# ---------- [2] install to a custom prefix ----------

hdr "[2] install with --prefix"
PREFIX1="$TMPDIR_BASE/install1"
RC="$HOME/.zshrc"
[ -f "$RC" ] && rm "$RC"

out="$(bash "$INSTALL_SH" --prefix="$PREFIX1" --yes --no-path-edit 2>&1)"; rc=$?
[ "$rc" = "0" ] && ok "install rc=0" || { fail "install rc=$rc"; echo "$out"; }
[ -d "$PREFIX1" ] && ok "prefix dir created" || fail "prefix not created"
[ -x "$PREFIX1/bin/vibe-install" ] && ok "vibe-install copied + executable" || fail "vibe-install missing or not executable"
[ -x "$PREFIX1/bin/vibe-detect-tool" ] && ok "vibe-detect-tool copied" || fail "vibe-detect-tool missing"
[ -x "$PREFIX1/bin/vibe-verify" ] && ok "vibe-verify copied" || fail "vibe-verify missing"
[ -x "$PREFIX1/bin/vibe-mutate" ] && ok "vibe-mutate copied" || fail "vibe-mutate missing"
[ -x "$PREFIX1/bin/hooks/prep-room.sh" ] && ok "hook copied + executable" || fail "hook missing"
[ -f "$PREFIX1/CLAUDE.md" ] && ok "master CLAUDE.md copied" || fail "CLAUDE.md missing"
[ -f "$PREFIX1/prompts/spec-intake.md" ] && ok "prompts/spec-intake.md copied" || fail "prompts missing"
[ ! -e "$RC" ] && ok "--no-path-edit: rcfile untouched" || fail "--no-path-edit touched rcfile"

# ---------- [3] idempotency: run twice, no rm -rf ----------

hdr "[3] Idempotency"
# Add a sentinel file the user "owns" — make sure install doesn't delete it.
mkdir -p "$PREFIX1"
touch "$PREFIX1/user-note.txt"

# Run again.
bash "$INSTALL_SH" --prefix="$PREFIX1" --yes --no-path-edit >/dev/null 2>&1
[ -f "$PREFIX1/user-note.txt" ] && ok "user file survived second install" || fail "second install deleted user file"
[ -x "$PREFIX1/bin/vibe-mutate" ] && ok "bin still executable after re-install" || fail "re-install broke bin"

# ---------- [4] PATH edit (rcfile) ----------

hdr "[4] PATH edit (rcfile, idempotent)"
PREFIX2="$TMPDIR_BASE/install2"
RC2="$HOME/.zshrc"
[ -f "$RC2" ] && rm "$RC2"

bash "$INSTALL_SH" --prefix="$PREFIX2" --yes 2>&1 >/dev/null
[ -f "$RC2" ] && ok "rcfile created" || fail "rcfile not created"
grep -qF "# vibe-kit PATH" "$RC2" && ok "marker comment in rcfile" || fail "no marker in rcfile"
grep -qF "$PREFIX2/bin" "$RC2" && ok "PATH line references prefix" || fail "PATH line missing"

# Run again — should NOT duplicate.
count_before="$(grep -cF '# vibe-kit PATH' "$RC2")"
bash "$INSTALL_SH" --prefix="$PREFIX2" --yes >/dev/null 2>&1
count_after="$(grep -cF '# vibe-kit PATH' "$RC2")"
[ "$count_before" = "$count_after" ] && [ "$count_after" = "1" ] && ok "rcfile marker appears exactly once (idempotent)" || fail "rcfile marker count changed: before=$count_before after=$count_after"

# ---------- [5] --no-path-edit ----------

hdr "[5] --no-path-edit"
PREFIX3="$TMPDIR_BASE/install3"
RC3="$HOME/.bashrc"
[ -f "$RC3" ] && rm "$RC3"

bash "$INSTALL_SH" --prefix="$PREFIX3" --yes --no-path-edit >/dev/null 2>&1
[ ! -e "$RC3" ] && ok "--no-path-edit: rcfile untouched" || fail "--no-path-edit created rcfile"
[ -d "$PREFIX3/bin" ] && ok "--no-path-edit still installs files" || fail "--no-path-edit skipped install"

# Non-interactive (curl|bash) should auto-edit rcfile without prompting.
PREFIX_NI="$TMPDIR_BASE/install-ni"
RC_NI="$HOME/.zshrc.ni"
[ -f "$RC_NI" ] && rm "$RC_NI"
# Run with stdin redirected (not a TTY) and no --yes flag.
bash "$INSTALL_SH" --prefix="$PREFIX_NI" --rcfile="$RC_NI" </dev/null >/dev/null 2>&1
[ -f "$RC_NI" ] && ok "non-interactive (curl|bash) auto-edits rcfile" || fail "non-interactive didn't edit rcfile — curl|bash UX broken"
grep -qF "# vibe-kit PATH" "$RC_NI" && ok "non-interactive: marker present" || fail "non-interactive: marker missing"

# ---------- [6] --uninstall ----------

hdr "[6] --uninstall"
PREFIX4="$TMPDIR_BASE/install4"
bash "$INSTALL_SH" --prefix="$PREFIX4" --yes --no-path-edit >/dev/null 2>&1
[ -d "$PREFIX4" ] && ok "prefix4 exists pre-uninstall" || fail "prefix4 not created"

bash "$INSTALL_SH" --prefix="$PREFIX4" --uninstall >/dev/null 2>&1
[ ! -d "$PREFIX4" ] && ok "--uninstall removed prefix" || fail "--uninstall did not remove prefix"

# Re-running --uninstall on a missing dir is a no-op (exit 0).
bash "$INSTALL_SH" --prefix="$PREFIX4" --uninstall >/dev/null 2>&1
[ $? = "0" ] && ok "--uninstall on missing dir is a no-op" || fail "--uninstall on missing dir failed"

# ---------- [7] vibe-update ----------

hdr "[7] vibe-update"
[ -x "$UPDATE_BIN" ] && ok "vibe-update exists + executable" || fail "vibe-update missing"
bash -n "$UPDATE_BIN" && ok "vibe-update syntax clean" || fail "vibe-update syntax error"
grep -qE 'mapfile|declare -A' "$UPDATE_BIN" && fail "vibe-update uses bash 4+ features" || ok "vibe-update bash 3.2 portable"

# ---------- [8] docs ----------

hdr "[8] Docs"
grep -qF "raw.githubusercontent.com" "$KIT_ROOT/README.md" && ok "README mentions raw.githubusercontent.com (one-liner)" || fail "README missing one-liner"
grep -qF "vibe-update" "$KIT_ROOT/README.md" && ok "README mentions vibe-update" || fail "README missing vibe-update"
grep -qF "install.sh" "$KIT_ROOT/CHANGELOG.md" && ok "CHANGELOG mentions install.sh" || fail "CHANGELOG missing install.sh"

# Spec exists.
[ -f "$KIT_ROOT/docs/requirements/vibe-install-oneclick/spec.md" ] && ok "spec exists" || fail "spec missing"

# AGENTS.md exists at repo root so AI agents can discover install instantly.
[ -f "$KIT_ROOT/AGENTS.md" ] && ok "AGENTS.md exists at repo root" || fail "AGENTS.md missing — AI agents won't know how to install"
grep -qF "raw.githubusercontent.com/Rushabh9033/vibe-kit/main/install.sh" "$KIT_ROOT/AGENTS.md" && ok "AGENTS.md has the install one-liner" || fail "AGENTS.md missing install one-liner"
grep -qF "vibe-install" "$KIT_ROOT/AGENTS.md" && ok "AGENTS.md references vibe-install" || fail "AGENTS.md missing vibe-install"

# AGENTS.md should ship with the install.
[ -f "$PREFIX1/AGENTS.md" ] && ok "AGENTS.md copied to install prefix" || fail "AGENTS.md not copied"

# ---------- summary ----------

echo
if [ "$FAIL" -eq 0 ]; then
  printf '\033[1;32mAll %d assertions passed.\033[0m\n' "$PASS"
  exit 0
else
  printf '\033[1;31m%d failed, %d passed.\033[0m\n' "$FAIL" "$PASS"
  exit 1
fi
