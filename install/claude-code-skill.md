# Install: Claude Code (as a Skill) — **preferred**

Installs vibe-kit as a **packaged Skill** — invoked on demand, scoped to the conversation, no global rules pollution.

## Why a Skill

- Doesn't pollute every session with rules you didn't ask for.
- Loads only when the user names it (`/skill vibe-kit` or implicit invocation).
- Ships with metadata + bundled resources + a clear description.
- Lives in `~/.claude/skills/` (user-level) or `<repo>/.claude/skills/` (project-level).

## Install (one command)

```bash
# From the cloned vibe-kit repo:
cp -R skills/vibe-kit ~/.claude/skills/
```

That's it. The Skill becomes available in every session.

## Use

In any Claude Code session:

```text
You: /skill vibe-kit
You: bootstrap a new React Native app for couples
```

The Skill loads the playbook, the two-role model, the verification gates, and the slash-command index — all on-demand, none polluting other sessions.

## What's inside the Skill

`skills/vibe-kit/SKILL.md` is a self-contained bundle. It references:

- `docs/architecture.md` for the two-role model deep-dive
- `docs/requirements-gathering.md` for the most important workflow
- `kit/templates/` for spec, plan, ADR, handoff, CHANGELOG
- `kit/commands/` for the slash-command playbook
- `kit/rules/` for the global rules (when context is appropriate)

## Combine: Skill + global install

The Skill is for ad-hoc use; the global install is for always-on. You can have both:

- Global: gets you `/vibe-*` slash commands + hooks + auto-loaded rules (no Skill invocation needed).
- Skill: gets you the *narrative* of why — the principles, the two-role model, the gap analysis — when you want it.

Suggested: install the Skill + the global kit. The kit makes every session VCP-aware; the Skill explains why when asked.

## Uninstall

```bash
rm -rf ~/.claude/skills/vibe-kit
```
