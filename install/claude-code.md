# Install: Claude Code (global kit, raw files)

Installs vibe-kit as a global, always-on configuration for **every** Claude Code session on this user account.

## Install (one command)

```bash
# From the cloned vibe-kit repo:
./kit/bin/install-claude-code.sh
```

If you'd rather run by hand:

```bash
# 1. Global rules (auto-loaded every session)
mkdir -p ~/.claude/rules
cp kit/rules/*.md ~/.claude/rules/

# 2. Slash commands (available in every session)
mkdir -p ~/.claude/commands
cp kit/commands/*.md ~/.claude/commands/

# 3. Global master rules
cp kit/CLAUDE.md ~/.claude/CLAUDE.md

# 4. Hooks (one-shot)
mkdir -p ~/.claude/vibe-kit/bin/hooks
cp kit/bin/hooks/*.sh ~/.claude/vibe-kit/bin/hooks/
chmod +x ~/.claude/vibe-kit/bin/hooks/*.sh
cp kit/bin/vibe-init ~/.claude/vibe-kit/bin/vibe-init
chmod +x ~/.claude/vibe-kit/bin/vibe-init

# 5. Settings — merge hooks into existing settings.json
#    (do NOT replace; merge with your existing config)
python3 -c "
import json, pathlib
p = pathlib.Path.home() / '.claude/settings.json'
existing = json.loads(p.read_text()) if p.exists() else {}
hooks = json.loads(pathlib.Path('kit/settings.json').read_text())['hooks']
existing.setdefault('hooks', {}).update(hooks)
p.write_text(json.dumps(existing, indent=2))
"
```

## What this gets you in every session

- `~/.claude/CLAUDE.md` loads (90 lines of master rules + kill list)
- 5 path-scoped rules auto-load by topic
- 8 slash commands available: `/vibe-init`, `/vibe-spec`, `/vibe-plan`, `/vibe-verify`, `/vibe-ship`, `/vibe-handoff`, `/vibe-decide`, `/vibe-review-pr`
- 3 hooks fire automatically: format-on-edit (PostToolUse), guard-unsafe (PreToolUse Bash), session-end-handoff (Stop)

## Bootstrap a project

```bash
cd path/to/project
~/.claude/vibe-kit/bin/vibe-init            # scaffolds 14 files
# or with flags:
~/.claude/vibe-kit/bin/vibe-init --check    # preview
~/.claude/vibe-kit/bin/vibe-init --update   # refresh generated docs
```

## Uninstall

```bash
rm -rf ~/.claude/vibe-kit
rm ~/.claude/CLAUDE.md ~/.claude/commands/vibe-*.md ~/.claude/rules/*.md
# remove the hooks from ~/.claude/settings.json manually
```
