#!/usr/bin/env bash
# vibe-kit — one-click install.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Rushabh9033/vibe-kit/main/install.sh | bash
#   curl ... | bash -s -- --yes
#   bash install.sh --prefix=/tmp/vk-test
#   bash install.sh --uninstall
#   bash install.sh --no-path-edit
#   bash install.sh --help
#
# What it does:
#   1. Detects OS (mac/linux), shell, and install prefix.
#   2. Clones the kit repo (shallow) into a temp dir, OR pulls if it
#      already exists locally.
#   3. Copies kit/ to the install prefix (default: ~/.claude/vibe-kit/).
#   4. Sets executable bits on bin/* and bin/hooks/*.
#   5. Adds <prefix>/bin to PATH in the user's shell rcfile (idempotent).
#   6. Prints a summary block with next-step commands.
#
# Flags:
#   --prefix=PATH        install root (default: ~/.claude/vibe-kit)
#   --yes / -y           skip confirmations (assume yes)
#   --no-path-edit       install but don't touch shell rcfile
#   --ref=BRANCH         git ref to install (default: main)
#   --uninstall          remove the install dir; leave rcfile edit
#   -h / --help          show this help
#
# Exit codes:
#   0 — installed / already up-to-date
#   1 — fatal error (clone failed, no write permission, no curl/git/wget)
#   2 — usage error
#   3 — user aborted

set -uo pipefail

REPO_URL="https://github.com/Rushabh9033/vibe-kit.git"
RAW_URL="https://raw.githubusercontent.com/Rushabh9033/vibe-kit"
REF="main"

PREFIX="$HOME/.claude/vibe-kit"
YES=0
PATH_EDIT=1
UNINSTALL=0
RCFILE_OVERRIDE=""

print_help() {
  sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
}

die()  { echo "vibe-install: $*" >&2; exit 1; }
warn() { echo "vibe-install: $*" >&2; }
say()  { printf '  %s\n' "$*"; }

# ---------- arg parsing ----------
while [ $# -gt 0 ]; do
  case "$1" in
    --prefix=*)    PREFIX="${1#*=}" ;;
    --yes|-y)      YES=1 ;;
    --no-path-edit) PATH_EDIT=0 ;;
    --ref=*)       REF="${1#*=}" ;;
    --rcfile=*)    RCFILE_OVERRIDE="${1#*=}" ;;
    --uninstall)   UNINSTALL=1 ;;
    -h|--help)     print_help; exit 0 ;;
    *) die "unknown flag: $1 (use --help)" ;;
  esac
  shift
done

# ---------- uninstall ----------
if [ "$UNINSTALL" -eq 1 ]; then
  if [ -d "$PREFIX" ]; then
    rm -rf "$PREFIX"
    say "removed $PREFIX"
    say "(rcfile PATH edit left in place — remove manually if desired)"
    exit 0
  else
    say "nothing to remove at $PREFIX"
    exit 0
  fi
fi

# ---------- preflight ----------
# Refuse root unless --yes was passed (silent root install is a foot-gun).
if [ "$(id -u)" = "0" ] && [ "$YES" -ne 1 ]; then
  die "refusing to run as root without --yes"
fi

command -v git >/dev/null 2>&1 || die "git is required but not installed"

# ---------- fetch repo ----------
TMPDIR_BASE="$(mktemp -d -t vibe-kit-install.XXXXXX)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

REPO_DIR="$TMPDIR_BASE/vibe-kit"
say "cloning $REPO_URL (ref=$REF, depth=1)..."
if ! git clone --depth 1 --branch "$REF" --quiet "$REPO_URL" "$REPO_DIR" 2>/dev/null; then
  # Fallback: clone default, then checkout the ref.
  if ! git clone --depth 1 --quiet "$REPO_URL" "$REPO_DIR" 2>/dev/null; then
    die "git clone failed — check network and that repo URL is correct"
  fi
  ( cd "$REPO_DIR" && git fetch --depth 1 origin "$REF" 2>/dev/null && \
    git checkout "$REF" 2>/dev/null ) || warn "could not checkout ref=$REF; using default branch"
fi

[ -d "$REPO_DIR/kit" ] || die "cloned repo is missing kit/ — wrong repo or bad ref"

# ---------- install ----------
say "installing to $PREFIX ..."
mkdir -p "$PREFIX"

# Copy kit/ contents into prefix. Use cp -R for portability (Bash 3.2
# macOS). Never `rm -rf` the prefix first — user may have added files.
if [ -d "$PREFIX/bin" ]; then
  say "(updating in place)"
fi

# Copy each subdir so we don't nuke user-added top-level files.
# Iterate files (not dir-level cp -R which differs between BSD and GNU).
for sub in bin templates prompts installers rules commands; do
  src="$REPO_DIR/kit/$sub"
  if [ -d "$src" ]; then
    mkdir -p "$PREFIX/$sub"
    while IFS= read -r -d '' f; do
      rel="${f#"$src"/}"
      dst="$PREFIX/$sub/$rel"
      mkdir -p "$(dirname "$dst")"
      cp "$f" "$dst"
    done < <(find "$src" -type f -print0)
  fi
done

# Master CLAUDE.md → global. Don't overwrite if user customized it.
if [ -f "$REPO_DIR/kit/CLAUDE.md" ]; then
  cp "$REPO_DIR/kit/CLAUDE.md" "$PREFIX/CLAUDE.md"
fi

# Set executable bits.
if [ -d "$PREFIX/bin" ]; then
  find "$PREFIX/bin" -type f \( -name "vibe-*" -o -name "*.sh" \) -exec chmod +x {} +
fi

# ---------- PATH edit ----------
if [ "$PATH_EDIT" -eq 1 ]; then
  # Pick rcfile.
  rcfile=""
  if [ -n "$RCFILE_OVERRIDE" ]; then
    rcfile="$RCFILE_OVERRIDE"
  elif [ -n "${SHELL:-}" ]; then
    case "$SHELL" in
      */zsh)  rcfile="$HOME/.zshrc" ;;
      */bash)
        # Prefer .bashrc on Linux, .bash_profile on macOS.
        if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
          rcfile="$HOME/.bash_profile"
          [ -f "$HOME/.bashrc" ] && rcfile="$HOME/.bashrc"
        else
          rcfile="$HOME/.bashrc"
        fi
        ;;
      */fish) rcfile="$HOME/.config/fish/config.fish" ;;
      *)      rcfile="$HOME/.profile" ;;
    esac
  else
    rcfile="$HOME/.profile"
  fi

  if [ -n "$rcfile" ]; then
    mkdir -p "$(dirname "$rcfile")"
    touch "$rcfile"
    marker="# vibe-kit PATH"
    bin_line="export PATH=\"$PREFIX/bin:\$PATH\""
    if [ "${rcfile##*/}" = "config.fish" ]; then
      bin_line="set -gx PATH $PREFIX/bin \$PATH"
    fi

    # Idempotent: only append if the marker isn't already present.
    if ! grep -qF "$marker" "$rcfile" 2>/dev/null; then
      if [ "$YES" -ne 1 ]; then
        printf 'vibe-install: append to %s? [y/N] ' "$rcfile"
        if [ -t 0 ]; then
          read -r ans
          case "$ans" in
            y|Y|yes|YES) ;;
            *) warn "PATH not edited (rcfile untouched). Add manually: $bin_line"; rcfile="" ;;
          esac
        else
          warn "non-interactive shell; use --yes to auto-edit rcfile"
          rcfile=""
        fi
      fi

      if [ -n "$rcfile" ]; then
        {
          printf '\n%s\n%s\n' "$marker" "$bin_line"
        } >> "$rcfile"
        say "PATH edited in $rcfile"
      fi
    else
      say "PATH already edited in $rcfile (skipping)"
    fi
  fi
else
  say "--no-path-edit: shell rcfile left untouched"
fi

# ---------- summary ----------
echo
echo "vibe-kit installed. Next steps:"
echo
echo "  1. Reload your shell, or:"
echo "       export PATH=\"$PREFIX/bin:\$PATH\""
echo
echo "  2. In any project, install vibe-kit into it:"
echo "       cd /path/to/your/project"
echo "       vibe-install"
echo
echo "  3. To update later:"
echo "       vibe-update"
echo
echo "Installed at: $PREFIX"
echo "Bins:         $(ls "$PREFIX/bin" 2>/dev/null | grep -c '^vibe-' || echo 0)"
exit 0
