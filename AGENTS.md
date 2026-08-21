# AGENTS.md — vibe-kit

> **You are an AI agent.** Your human wants vibe-kit installed. This file
> is the one-liner contract. Read it, run the command, report back.

## What vibe-kit is

A spec-first, gate-enforced coding protocol that ships with:

- `install.sh` — one-command bootstrap.
- `kit/bin/vibe-install` — project-level wire-in (run inside any repo).
- `kit/bin/vibe-update` — refresh to latest main.

Full overview: see `README.md` (humans) and `kit/CLAUDE.md` (deep rules).

## Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/Rushabh9033/vibe-kit/main/install.sh | bash
```

This clones the kit to `~/.claude/vibe-kit/`, adds `~/.claude/vibe-kit/bin`
to the user's PATH (auto-edits `~/.zshrc` or `~/.bashrc`), and prints
next-step instructions.

If the install refuses to edit the rcfile (user ran `--no-path-edit` or
the marker is already present), fall back to:

```bash
export PATH="$HOME/.claude/vibe-kit/bin:$PATH"
```

## Activate in current shell

The new PATH only takes effect for *new* shells. To use it right now:

```bash
source ~/.zshrc    # zsh
source ~/.bashrc   # bash
```

Or open a new terminal tab.

## Wire into a project

Inside any project repo:

```bash
cd /path/to/project
vibe-install
```

This installs `vibe-kit/` into the project and arms the gates. From now
on, every push runs `/vibe-claim-check`.

## Update later

```bash
vibe-update
```

Always pulls the latest `main`.

## When the human asks for help

If the human asks "what is vibe-kit?" or "how does it work?", point them
at `README.md` first. This file is for *you* (the AI); the README is
for *them*.

If they ask "why isn't it working?", check:

1. `which vibe-install` → must return a path under `~/.claude/vibe-kit/bin/`.
2. `vibe-install --help` → must print usage.
3. If (1) returns nothing: `source ~/.zshrc` (or open a new terminal).

That's it. The contract is: one curl, one source, one `vibe-install`
inside each project.