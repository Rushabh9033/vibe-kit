# vibe-kit

**by Rushabh Mavani** — a persistent contract for AI coding.

> vibe-kit gives coding agents a **SPEC they must implement against**, and **verifies they did**. The Planner writes the contract. The Coder signs it. The verifier checks the signature.

```
              ┌─────────────────────┐
              │  Planner  (any AI)  │
              │   spec, plan,       │
              │   prompt, ADR       │
              └──────────┬──────────┘
                         │  spec.md (the contract)
                         ▼
              ┌─────────────────────┐
              │  Coder (dev tools)  │
              │   Claude Code,      │
              │   Cursor, Aider,    │
              │   Antigravity,      │
              │   Windsurf, Codex   │
              └──────────┬──────────┘
                         │  code + tests
                         ▼
              ┌─────────────────────┐
              │  /vibe-verify       │   ← contract checker
              │  AC ↔ code ↔ tests  │
              └──────────┬──────────┘
                         │  PASS / BLOCK
                         ▼
              ┌─────────────────────┐
              │  Ship               │
              └─────────────────────┘
```

**Why this exists.** Claude Code, Cursor, Copilot — they all ship code from natural language. None of them ship a **contract**. vibe-kit adds the missing layer: a `spec.md` the Coder must implement against, and a verifier (`/vibe-verify`) that confirms every acceptance criterion landed.

**Two roles. One spec.** The Planner (any chat AI — Claude.ai, ChatGPT, Gemini — or the same Claude Code session in planning mode) produces the spec. The Coder (any dev tool) consumes it. The user is the bridge.

---

## Install

The kit auto-detects which AI dev tool you use and installs the right config. Run from your project root:

```bash
git clone https://github.com/Rushabh9033/vibe-kit
# Install ~/.claude/vibe-kit/bin/ once (Claude Code only):
./kit/bin/install-claude-code.sh
# Then in any project:
~/.claude/vibe-kit/bin/vibe-install
```

`vibe-install` detects Claude Code / Cursor / Antigravity / Aider / Codex by env vars and cwd files, then drops the right rules + commands + conventions file into your project. It also runs `vibe-init` to scaffold `docs/`, `.github/`, and `.gitignore` — **skipping files that already exist**, so it's safe to run in a project that's already in development.

Override detection with `--tool=cursor` (or `antigravity`, `aider`, `codex`, `claude-code`, `generic`). For tool-specific quirks (Cursor's `@-mentions`, Aider's command-flag aliases, Antigravity's auto-format), see `install/<your-tool>.md`.

---

## Quick start

```bash
# 1. In any chat AI (or Claude Code in planning mode):
#    Run prompts/00-anchor.md → interview + spec.md

# 2. In your project, with the Coder tool:
/vibe-plan profile-photo-upload        # writes plan.md
# ... implement ...
/vibe-verify                          # AC↔code↔tests contract check
/vibe-ship                            # CHANGELOG + handoff + ready-to-commit
```

The Planner is an **interviewer**, not a stenographer. You give it the seed idea; it asks you the rest of the questions, one at a time, until the spec is complete. (See `prompts/00-anchor.md` § Discovery protocol.)

---

## What's in the box

```
vibe-kit/
├── prompts/                 ← Planner-side (any chat AI)
│   ├── 00-anchor.md         ← Discovery protocol + role
│   ├── 01–07                ← spec, plan, ADR, edges, handoff, retro
├── kit/
│   ├── bin/vibe-install        ← unified installer (auto-detects tool)
│   ├── bin/vibe-detect-tool    ← auto-detect: claude-code|cursor|antigravity|aider|codex|generic
│   ├── bin/vibe-verify         ← AC↔code↔tests contract checker
│   ├── bin/vibe-init           ← scaffolds a project (skips existing files)
│   ├── bin/hooks/              ← format-on-edit, guard-unsafe, handoff
│   ├── commands/               ← 8 slash commands
│   ├── rules/                  ← 5 modular rules (security, verify, cost…)
│   ├── installers/             ← per-tool skill packs (claude-code, cursor, aider, antigravity, codex, generic)
│   └── templates/              ← 10 project templates
├── install/                    ← per-tool install guides + auto-detect matrix
├── skills/vibe-kit/         ← packaged Claude Code Skill
├── docs/                    ← playbook, architecture, gap-analysis
└── examples/                ← intake, spec, plan, handoff samples
```

---

## Principle

> Specify small. Verify twice. Persist the lessons.

The spec is the only artifact that survives context loss; everything else is regenerated from it.

---

## License

MIT — Copyright © 2026 Rushabh Mavani. See [LICENSE](LICENSE).
