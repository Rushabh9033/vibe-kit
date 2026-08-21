# 2026-08-21 — one-click install

## TL;DR

Vibe-kit now installs with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/Rushabh9033/vibe-kit/main/install.sh | bash
```

What ships:
- `install.sh` at repo root — clone + copy + PATH edit, idempotent.
- `vibe-update` companion — re-runs install.sh against latest main.
- README Install section now leads with the one-liner.
- Test coverage: 36 assertions in `tests/weapons/test-install-oneclick.sh`.

209 / 209 assertions across 7 suites, 0 failures.

## Why

The previous Install flow was 4 commands (clone, cd, install, then `cd
<project> && ~/.claude/vibe-kit/bin/vibe-install`). That works for power
users but is friction for first-timers. The new flow: one curl, then
`vibe-install` in any project. Same outcome, half the steps.

## What changed

| File | Why |
|---|---|
| `install.sh` | NEW. Bootstrap script served via raw GitHub URL. |
| `kit/bin/vibe-update` | NEW. Re-runs install.sh with current defaults. Resolves install.sh locally first, falls back to fetching from GitHub. |
| `README.md` | Install section leads with the one-liner. Manual clone is documented as a fallback. |
| `CHANGELOG.md` | New entry under [Unreleased]. |
| `docs/requirements/vibe-install-oneclick/spec.md` | NEW. Spec (12 ACs). |
| `tests/weapons/test-install-oneclick.sh` | NEW. 36 assertions. Stubs `git` so no real network calls happen. |

## install.sh behavior

- **Flags**: `--yes`, `--no-path-edit`, `--prefix=PATH`, `--ref=BRANCH`,
  `--rcfile=PATH`, `--uninstall`, `--help`.
- **PATH edit**: detects `$SHELL`, picks `.zshrc` / `.bashrc` /
  `.bash_profile` / `.config/fish/config.fish` / `.profile`. Idempotent
  (marker `# vibe-kit PATH` — second run skips).
- **Refuses root** without `--yes` (silent root install is a foot-gun).
- **Never `rm -rf` the target prefix** — user files in `~/.claude/vibe-kit/`
  survive re-runs (test verifies with a sentinel file).
- **Per-file copy** instead of `cp -R src/. dst/` — the trailing-slash-after-dot
  idiom is GNU-cp-only and breaks on macOS BSD cp. Find loop is portable.

## vibe-update behavior

- Resolves `install.sh` in this order:
  1. Sibling of the running `vibe-update` (kit local install).
  2. Two dirs up from bin (kit dev checkout).
  3. Fetch from GitHub raw URL.
- Always passes `--yes` to install.sh (update is intentional).

## Test design

The test stubs `git` on PATH so `git clone` is intercepted and produces a
sandbox `kit/` tree. Tests use `--prefix=/tmp/X` to install into
isolated dirs and `--no-path-edit` to keep the user's real `~/.zshrc`
untouched. The `HOME` env var is redirected to a sandbox dir so any
fallback PATH edits land in `$TMPDIR_BASE/home/`.

That's a real lesson: when a test could touch `~/.zshrc`, redirect HOME.

## Gotchas (compound)

- **`cp -R src/. dst/` is non-portable.** BSD cp on macOS treats
  `src/.` as `src` literally and creates a `.` named file. Find + cp per
  file is portable across GNU and BSD. (Captured in install.sh comment.)
- **Don't overwrite `~/.claude/vibe-kit/` blindly.** User may have added
  files (custom commands, hooks). The install only overwrites kit-shipped
  paths (`kit/bin/`, `kit/CLAUDE.md`, etc.). Test AC3 verifies with a
  sentinel file.
- **Refuse root silently installing** is the same class of mistake as
  `rm -rf` — a script that helps in normal use and breaks in abnormal
  conditions. Add a hard refusal + clear message.
- **`install.sh` ships with `--yes` as the default for `vibe-update`**,
  but NOT for the first-time install. Reason: first run is irreversible;
  update is intentional.

## What's still on the list

- Homebrew tap (out of scope for v0.2; would let macOS users do
  `brew install Rushabh9033/tap/vibe-kit`).
- npm wrapper (`npx vibe-kit-install` — debatable whether it adds value
  over curl|bash).
- Windows installer (out of scope — the kit assumes POSIX shell).
- A one-command "fresh-project bootstrap": `vibe-install --bootstrap`
  that runs `vibe-spec-intake --ai` + `vibe-arm` in sequence. Spec-first.

## For the next session

If you extend the installer:

1. **`--check` mode** — print what install.sh would do, no writes.
   Useful for dry-run in CI. The existing `vibe-install --check` does
   this for project installs; bootstrap doesn't have it.
2. **Update notifications** — `vibe-update` could check the local SHA
   vs. remote and print "you're up to date" instead of always pulling.
3. **Multiple shells** — current code writes to one rcfile. If a user
   uses both bash and zsh, they'll get PATH only in one. Detecting
   `.bashrc` + `.zshrc` both existing would be a nice-to-have.
