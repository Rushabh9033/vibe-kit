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

```bash
git clone https://github.com/Rushabh9033/vibe-kit
# For Claude Code (preferred):
cp -R skills/vibe-kit ~/.claude/skills/
# Then in any Claude Code session:
/skill vibe-kit
```

For other tools (Cursor, Antigravity, Aider, etc.): `cd vibe-kit/kit && cat install/<your-tool>.md`. Pick yours from `install/`.

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
│   ├── bin/vibe-verify      ← AC↔code�tests contract checker (real script)
│   ├── bin/vibe-init        ← scaffolds a project
│   ├── bin/hooks/           ← format-on-edit, guard-unsafe, handoff
│   ├── commands/            ← 8 slash commands (Claude Code)
│   ├── rules/               ← 5 modular rules (security, verify, cost…)
│   └── templates/           ← 10 project templates
├── install/                 ← per-tool steps (Cursor, Aider, …)
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
