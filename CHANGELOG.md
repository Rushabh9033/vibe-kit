# Changelog

All notable changes to **vibe-kit** itself are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

## [0.3.1] - 2026-08-20
### Fixed
- **Stop hook prompt-error loop eliminated.** The kit's `Stop` hook previously combined a `command`-type and a `prompt`-type hook. The prompt fired the assistant every Stop, asking it to fill in a stub the script had just written. When the script throttled (the common case after the first write), the assistant had no stub to fill, but the prompt kept firing — producing a visible "Stop hook error" at every turn. The fix:
  1. Removed the `prompt`-type `Stop` hook from `kit/settings.json` and from `kit/bin/vibe-init`'s render.
  2. Made `session-end-handoff.sh` self-filling. It now writes a 2k+ handoff with what the shell can determine: branch + dirty/clean + ahead/behind, recent commits (last 4h), files touched (current dirty tree), recent commits matching `gotcha|trap|fix|bug`, and the appropriate `unknown — left for next session` for fields the shell can't determine (Decisions, In progress, Blocked, Next steps).
  3. The script is now silent on throttle (no stderr, exit 0). The previous version printed "throttled" on stderr, which the prompt's "if it printed throttled, do nothing" check tried to interpret — but the prompt no longer exists.
- **vibe-verify AC false-positive protection**: scripts no longer match ACs against the filename-only diff (case where "upload" matches upload.ts but the file is empty). Already shipped in v0.3.0; mentioned here because the previous behavior was a known-false signal.

### Changed
- `kit/bin/hooks/session-end-handoff.sh`: rewritten. ~150 lines → ~190 lines. Self-filling. Silent on throttle.
- `kit/settings.json` and `kit/bin/vibe-init` `render()`: `Stop` hook is now a single `command`-type entry.

## [0.3.0] - 2026-08-20
### Added
- **Per-tool auto-detection + unified installer**: `kit/bin/vibe-install` detects Claude Code / Cursor / Antigravity / Aider / Codex / generic from env vars and cwd files, then drops the right rules + commands + conventions file. No flag needed.
- **Per-tool skill packs** under `kit/installers/<tool>/`:
  - `claude-code/` — Skill bundle + global-install README
  - `cursor/` — `.cursorrules` + project-scoped rules
  - `aider/` — `CONVENTIONS.md` + `.aider.conf.yml`
  - `antigravity/` — Claude Code-compatible layout
  - `codex/` — `AGENTS.md` for OpenAI Codex CLI
  - `generic/` — fallback for any tool that reads `AGENTS.md`
- **vibe-detect-tool** (`kit/bin/vibe-detect-tool`): bash auto-detection with print-once parseable output (`<tool> | <install-form> | <config-dir>`).
- **vibe-init --add / --tool=auto**: non-destructive add mode + detection-on-init. Existing-project install path skips files that exist.
- **Dev-repo templates path**: when `kit/bin/vibe-init` runs from the cloned repo, it prefers in-repo `templates/` over the global install — so edits take effect immediately.
- **install/README.md** rewritten: leads with the auto-detect + `./vibe-install` flow, then details per-tool markers.

### Changed
- `README.md` lead install section now uses `vibe-install` (auto-detect) instead of per-tool pointers.
- `install/cursor.md` and `install/aider.md` updated with embedded templates (`.cursorrules`, `.aider.conf.yml`) and step-by-step copy commands.

## [0.2.0] - 2026-08-20
### Added
- **Real AC↔test contract checker** (`kit/bin/vibe-verify`): reads the most recent `docs/requirements/<feature>/spec.md`, extracts ACs, matches each AC keyword against the git diff, runs the detected test runner, prints a structured PASS/BLOCK report.
- **8 real slash commands** (`kit/commands/vibe-{spec,plan,verify,ship,handoff,decide,review-pr,init}.md`): each follows the same shape (description / what / when / usage / output / limits).
- **Ceremony levels** (`docs/ceremony-levels.md`): tiny / normal / large / critical — picks the right intensity for the change.
- **Discovery protocol** in `prompts/00-anchor.md`: Socratic one-question-at-a-time intake. Planner queries vibe coder ~1%, vibe coder's spec carries the rest.
- **Handoff throttle**: `kit/bin/hooks/session-end-handoff.sh` skips writes if a marker was touched within `VIBE_HANDOFF_THROTTLE` seconds (default 600).
- **Human-approval gate** in `prompts/06-handoff-to-coder.md` and `kit/templates/requirements-spec.md`: spec status flow `draft → awaiting-approval → in-progress → shipped`.

### Changed
- `README.md` lead reframed from "two roles, one spec" to "persistent contract for AI coding" — `vibe-kit gives coding agents a SPEC they must implement against, and verifies they did`.

## [0.1.0] - 2026-08-20
### Added
- Initial release: kit, prompts, templates, hooks, slash commands, examples.
