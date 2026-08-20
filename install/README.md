# Install

Pick your tool. Each guide is ~2 minutes.

| Tool | Guide | Install form |
|---|---|---|
| Claude Code (as global kit) | `claude-code.md` | raw files at `~/.claude/` |
| Claude Code (as Skill) | `claude-code-skill.md` | `~/.claude/skills/vibe-kit/` |
| Cursor | `cursor.md` | `.cursor/rules/`, `.cursorrules` mirror |
| Antigravity | `antigravity.md` | `.claude/rules/` (compatible) |
| Aider | `aider.md` | `CONVENTIONS.md`, `.aider.conf.yml` |
| Anything else | `other-tools.md` | generic raw-file install |

For the **two-role model**:
- **Planner side**: any chat AI (Claude.ai, ChatGPT, Gemini). Use `prompts/` — no install needed.
- **Coder side**: any dev tool — install the relevant kit files per the guides below.

## The two-line summary

```bash
# Pick your tool's guide; most are 2–5 commands.
cat install/<your-tool>.md
```

If your tool isn't listed, `other-tools.md` covers the generic raw-file install.
