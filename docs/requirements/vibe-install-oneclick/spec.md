# Feature: vibe-kit one-click install

Status: shipped
Owner: @Rushabh9033
Last updated: 2026-08-21

## Goal

A user can go from "I want vibe-kit" to "it's installed and ready" with a
single command. No `git clone`. No `cd`. No PATH juggling for first-run
users.

## What "one-click" means

The user runs **one command** — typically a `curl ... | bash` — and ends
up with:

1. The kit installed globally to `~/.claude/vibe-kit/` (binaries + rules +
   commands + skill bundle + master CLAUDE.md).
2. `~/.claude/vibe-kit/bin` on their PATH (so `vibe-install` works from any
   directory, no re-sourcing).
3. A clear printed summary: what was installed, where, what to do next.

After one-click, in any project they run `vibe-install` to wire that
project. That's the second command, but it's project-scoped, not setup.

## User Stories

- As a **Claude Code user trying vibe-kit for the first time**, I want to
  paste one command in my terminal and have it Just Work — no `git clone`,
  no editing my shell config, no reading 5 paragraphs of setup docs.
- As a **user who already has vibe-kit installed**, I want a one-liner
  that updates to the latest release — so I can refresh after a PR is
  merged.
- As a **CI / automation user**, I want `--yes` to skip the
  "this will modify your shell config" confirmation so I can install
  non-interactively.

## Requirements

### Functional

- New `install.sh` at repo root, served via raw GitHub URL.
- Steps:
  1. Detect OS (mac vs linux), shell (`$SHELL`).
  2. Choose install location: `~/.claude/vibe-kit/` (existing convention).
  3. Clone repo (shallow, `--depth 1`) to a temp dir OR a local dir.
  4. Copy `kit/` contents into `~/.claude/vibe-kit/`.
  5. Set executable bits on `bin/*` and `bin/hooks/*`.
  6. Add `~/.claude/vibe-kit/bin` to PATH in the user's shell rcfile
     (`.zshrc` / `.bashrc` / `.profile`). Detect existing entries; skip
     duplicates.
  7. Print a summary block: install path, PATH status, next-step commands.
- Non-destructive: if `~/.claude/vibe-kit/` exists, upgrade in place
  (overwrite kit files, never touch user-added files).
- `--yes` / `-y`: skip all confirmations.
- `--no-path-edit`: install but don't touch shell rcfile.
- `--prefix=PATH`: install to a custom prefix (for testing/CI).
- `--uninstall`: remove the install (PATH edit remains; user can clean
  manually).
- Companion command `vibe-update` (in `kit/bin/`): re-runs the install
  with current defaults. Bash 3.2 portable.
- `--version` / `--help`.

### API contract

- `curl -fsSL https://raw.githubusercontent.com/Rushabh9033/vibe-kit/main/install.sh | bash`
- `curl ... | bash -s -- --yes`
- `bash install.sh --prefix=/tmp/vk-test`
- `vibe-update`
- `bash install.sh --uninstall`

Exit codes:
- 0 — installed (or already up-to-date)
- 1 — fatal: clone failed, write permissions, etc.
- 2 — usage error
- 3 — user aborted (e.g., declined rcfile edit without `--yes`)

### Data model

None. Files only. The install is a set of file operations on `~/.claude/`.

### Non-functional

| Category | Requirement | Target | Check |
|---|---|---|---|
| Speed | cold install (clone + copy) | < 30s | manual timing |
| Idempotency | re-run with no changes | exits 0, no diff | test |
| Safety | never overwrites user files outside `vibe-kit/` | yes | test |
| Network | one curl to raw GitHub; no other network calls | yes | grep install.sh |
| Portability | bash 3.2 (no `mapfile`, no associative arrays) | yes | shellcheck + bash -n |

## Acceptance Criteria

- [ ] **AC1.** `install.sh` exists at repo root, is executable, and `--help`
      prints usage.
- [ ] **AC2.** With `--prefix=/tmp/X`, the kit lands at `/tmp/X/`.
- [ ] **AC3.** Re-running the install when files exist does NOT corrupt
      them (no `rm -rf` of the target).
- [ ] **AC4.** PATH edit block is appended to `.zshrc` exactly once even
      after multiple runs.
- [ ] **AC5.** `--no-path-edit` does NOT touch any rcfile.
- [ ] **AC6.** `--yes` skips confirmations.
- [ ] **AC7.** Bash 3.2 portable (no `mapfile`, no `declare -A`).
- [ ] **AC8.** `vibe-update` exists at `kit/bin/vibe-update`, is
      executable, re-runs the install with current defaults.
- [ ] **AC9.** `--uninstall` removes the install dir.
- [ ] **AC10.** README has the one-liner as the FIRST install command
      shown.
- [ ] **AC11.** CHANGELOG entry: "one-click install".
- [ ] **AC12.** Test file `tests/weapons/test-install-oneclick.sh` with
      at least 12 assertions.

## Constraints

- Bash 3.2 portable.
- No new dependencies (no `wget`, no `jq`, no `python3` requirement —
  pure bash + standard unix tools).
- Never run as root silently; warn if `$EUID` is 0.
- The `install.sh` script is the only file that needs to live at repo
  root. All other logic stays in `kit/bin/`.
- Idempotent: re-running is a no-op + exit 0.

## Edge Cases

1. **`~/.claude/` doesn't exist** — created.
2. **No shell rcfile exists** — created.
3. **`~/.zshrc` and `~/.bashrc` both exist** — pick the one matching
   `$SHELL`; warn if ambiguous.
4. **PATH already contains the install dir** — no duplicate edit.
5. **`curl` not installed** — fall back to `wget`; if neither, fail with
   a clear message.
6. **GitHub is unreachable** — clear error, exit 1.
7. **No `git` binary** — fail with hint.
8. **Running on Windows / WSL** — out of scope; print "Windows not
   supported yet" and exit 2.
9. **`--prefix` doesn't exist** — created.
10. **Install was partial (clone OK, copy failed)** — print recovery hint;
    do NOT leave the user in a broken state.
11. **Existing `vibe-kit` repo at target** — git pull instead of clone.

## Non-Goals

- Homebrew tap.
- npm install.
- Windows installer.
- Auto-running `vibe-install` in the current directory at end of bootstrap.
- A GUI.

## Verification

Run the test file: `tests/weapons/test-install-oneclick.sh`. Tests use a
fake `git`, `curl`, etc. on PATH so no real network calls happen.

End-to-end manual test (in a fresh user dir):

```bash
# Clean state
rm -rf ~/.claude/vibe-kit
sed -i '/vibe-kit\/bin/d' ~/.zshrc

# One command
curl -fsSL https://raw.githubusercontent.com/Rushabh9033/vibe-kit/main/install.sh | bash

# Verify
which vibe-install    # ~/.claude/vibe-kit/bin/vibe-install
ls ~/.claude/vibe-kit/bin/ | grep -c vibe-  # many
cat ~/.zshrc | grep vibe-kit  # PATH line
```
