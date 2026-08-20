# Changelog

All notable changes to **vibe-kit** itself are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com).

## [Unreleased]

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
