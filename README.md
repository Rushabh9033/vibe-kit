# Vibe Coding Kit (`vibe-kit`)

**by Rushabh Mavani**

> Two roles. One spec. Any AI on the planning side, any dev tool on the building side.

```
                ┌─────────────────────┐
                │  Planner  (any AI)  │
                │   spec, plan,       │
                │   prompt, ADR       │
                └──────────┬──────────┘
                           │  docs/requirements/<feature>/spec.md
                           ▼
                ┌─────────────────────┐
                │  Coder (dev tools)  │
                │   Claude Code,      │
                │   Cursor, Aider,    │
                │   Antigravity, Codex│
                └──────────┬──────────┘
                           │  code + tests
                           ▼
                ┌─────────────────────┐
                │  Verify → Ship      │
                └─────────────────────┘
```

The **spec is the contract** between roles. The Planner produces it; the Coder consumes it. Code is regenerated; specs survive.

---

## What this is

A reusable kit for AI-assisted development that:

1. **Splits the work** between a **Planner** (specification, requirements, prompts, edge cases, ADRs) and a **Coder** (code, tests, deploy).
2. **Treats the spec as the primary artifact** — the only thing that survives context loss, model swaps, team turnover.
3. **Compounds** — every mistake becomes a rule, every rule lives in a file, every file shortens the next session.
4. **Works with any AI** on the planner side (Claude.ai, ChatGPT, Gemini, etc.) and any dev tool on the coder side (Claude Code, Cursor, Antigravity, Aider, Codex, Windsurf).

## Install in 60 seconds

### Option A — Claude Code Skill (preferred)

```bash
# Copy the skill folder into ~/.claude/skills/
cp -R skills/vibe-kit ~/.claude/skills/

# Then in any Claude Code session:
/skill vibe-kit
```

The Skill auto-loads the playbook, the per-feature spec prompts, the verification gates, and the compound-correction rules.

### Option B — Raw kit (any dev tool)

```bash
git clone https://github.com/Rushabh9033/vibe-kit
cd vibe-kit/kit
# See install/<your-tool>.md for tool-specific steps.
```

`install/claude-code.md`, `install/cursor.md`, `install/antigravity.md`, `install/aider.md`, etc. — pick yours.

---

## What's in this repo

```
vibe-kit/
├── README.md                            # you are here
├── LICENSE                              # MIT
├── SECURITY.md                          # security policy + slopsquatting notes
├── .gitignore
├── docs/                                # the long-form playbook
│   ├── architecture.md                  # two-role model explained
│   ├── requirements-gathering.md        # the most important workflow
│   ├── gap-analysis.md                  # comparison: kit vs current practice
│   └── playbook.md                      # the unified guide (condensed)
├── prompts/                             # planner-side prompts (any AI)
│   ├── README.md                        # two-role in 1 minute
│   ├── 00-anchor.md
│   ├── 01-decompose-prd.md
│   ├── 02-feature-spec.md
│   ├── 03-feature-plan.md
│   ├── 04-adr.md
│   ├── 05-edge-cases.md
│   ├── 06-handoff-to-coder.md
│   └── 07-retrospective.md
├── kit/                                 # raw kit (per-tool install)
│   ├── README.md
│   ├── CLAUDE.md                        # global rules
│   ├── settings.json                    # global hooks
│   ├── rules/                           # 5 modular rules
│   ├── commands/                        # 8 slash commands
│   ├── bin/                             # vibe-init + 3 hooks
│   └── templates/                       # 10 project templates
├── install/
│   ├── README.md
│   ├── claude-code.md
│   ├── claude-code-skill.md             # preferred
│   ├── cursor.md
│   ├── antigravity.md
│   ├── aider.md
│   └── other-tools.md
├── skills/
│   └── vibe-kit/
│       └── SKILL.md                     # packaged Claude Code Skill
└── examples/
    ├── README.md
    ├── intake-prd.md
    ├── planner-output-spec.md
    ├── planner-output-plan.md
    └── coder-output-handoff.md
```

---

## The principle

> **Specify small, verify twice, persist the lessons.**
>
> The spec is the only artifact that survives context loss; everything else is regenerated from it.

---

## Quick start: full pipeline in one session

```bash
# 1. Bootstrap any project
mkdir my-app && cd my-app
git init
/path/to/vibe-kit/kit/bin/vibe-init          # scaffolds 14 files

# 2. Open Claude.ai (or any chat AI) and run prompts/01-decompose-prd.md
#    on your idea → outputs docs/SPEC.md + the feature map

# 3. Per feature, run prompts/02-feature-spec.md → docs/requirements/<slug>/spec.md

# 4. Open Claude Code (or Cursor/Antigravity/Aider) in your project
/vibe-plan profile-photo-upload             # writes plan.md
/vibe-verify                                # runs the 7-rank verification matrix
/vibe-ship                                  # pre-flight + CHANGELOG + handoff
```

---

## License

MIT — Copyright © 2026 Rushabh Mavani. See [LICENSE](LICENSE).
