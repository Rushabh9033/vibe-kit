# Install

The kit auto-detects which AI dev tool you use and installs the right config. Run:

```bash
~/.claude/vibe-kit/bin/vibe-install
```

That's it. No flag needed. The installer copies the matching bundle from `kit/installers/<tool>/` into your project, then runs `vibe-init` to scaffold `docs/`, `.github/`, and `.gitignore` (skips files that already exist).

## Auto-detection

`vibe-install` calls `kit/bin/vibe-detect-tool` first, which checks:

| Priority | Source | Detects |
|---|---|---|
| 1 | env vars (`CLAUDE_CODE`, `CURSOR_TRACE_ID`, `ANTIGRAVITY_SESSION`, `AIDER_MODEL`, `CODEX_SESSION_ID`) | the tool that set them |
| 2 | cwd files (`.cursor/`, `.cursorrules`, `.aider.conf.yml`, `.codex/`, `.agent/`) | the tool whose marker is there |
| 3 | fallback | `generic` |

Override detection with `--tool=` if you want to install for a different tool than the one detected:

```bash
vibe-install --tool=cursor
vibe-install --tool=antigravity
vibe-install --tool=aider
vibe-install --tool=codex
vibe-install --tool=generic          # bare AGENTS.md
vibe-install --tool=claude-code      # project-scoped .claude/
vibe-install --tool=claude-code --global   # global ~/.claude/
```

## Tool-specific guides

Each guide has the full per-tool install, plus the bits auto-detection can't infer (Cursor's `@-mentions`, Aider's command-flag aliases, Antigravity's auto-format quirks):

| Tool | Guide | Auto-detect marker |
|---|---|---|
| Claude Code (global) | `claude-code.md` | `CLAUDE_CODE` env var, or `--global` flag |
| Claude Code (project) | `claude-code.md` | `CLAUDE_CODE` env var, defaults to project |
| Claude Code (as Skill) | `claude-code-skill.md` | n/a — Skill is opt-in |
| Cursor | `cursor.md` | `.cursor/` or `.cursorrules` in cwd |
| Antigravity | `antigravity.md` | `.agent/` or `ANTIGRAVITY_SESSION` env var |
| Aider | `aider.md` | `.aider.conf.yml` or `CONVENTIONS.md` in cwd |
| Codex | (auto-install handled by `vibe-install`) | `.codex/` or `CODEX_SESSION_ID` env var |
| Anything else | `other-tools.md` | (no marker) |

## Existing-project behavior

`vibe-install` is **non-destructive by default**. It:

- Creates missing directories (`docs/requirements/`, `docs/decisions/`, `.claude/`, etc.).
- Skips files that already exist.
- Appends to `.gitignore` if it exists; creates it if missing.
- Never overwrites hand-curated content unless you pass `--update`.

This means you can run `vibe-install` in a project that's already in development and only the missing pieces get added. The full kit gets layered on top of whatever you already have.

To *force* a refresh of generated docs, run `vibe-install --update`.

## Per-tool skill packs

Each installer pack under `kit/installers/<tool>/` contains:

- A tool-specific conventions/rules file (e.g. `.cursorrules`, `CONVENTIONS.md`, `AGENTS.md`).
- A README.md explaining the tool's quirks and what the kit can't auto-fire.
- (Claude Code only) A `SKILL.md` for the on-demand Skill bundle.

The pack is what `vibe-install` copies. Edit it if you want to tweak what each tool gets.

## The two-role model

For both roles of the workflow:

- **Planner side** *(optional)*: any chat AI (Claude.ai, ChatGPT, Gemini). Use `prompts/` — no install needed.
- **Coder side**: any dev tool — install the relevant kit files via `vibe-install`, which auto-picks the right pack. **The Coder runs the spec-first gate at every task start; if no applicable Spec exists, it runs Discovery itself.**

The user is the bridge between Planner and Coder. The spec is the bridge between intent and code.
