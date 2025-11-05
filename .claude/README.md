# Claude Code Configuration

This directory contains Claude Code configuration for the SuperDeck project.

## Files

### settings.json

Team-wide Claude Code settings:
- **sessionStart hook**: Runs `scripts/setup.sh` automatically when Claude Code session starts
- **Default model**: Uses Sonnet (can be overridden with opus or haiku)
- **Default shell**: Uses bash

### settings.local.json (git-ignored)

Personal overrides for team settings. Create this file if you want to customize:
- Model preferences
- Custom hooks
- Personal environment variables

Example:
```json
{
  "model": {
    "default": "opus"
  }
}
```

## Settings Precedence

1. User settings (`~/.claude/settings.json`) - Lowest
2. Project settings (`settings.json`) - This file
3. Project local (`settings.local.json`) - Personal overrides
4. Command-line arguments
5. Enterprise policies - Highest (cannot override)

## Context Files

- **CLAUDE.md** (project root): Imports AGENTS.md to provide full project context
- **CLAUDE.local.md** (git-ignored): Personal instructions that override CLAUDE.md
- **AGENTS.md** (project root): Architecture documentation and development guidelines

## Setup Script

The `scripts/setup.sh` script automatically:
1. Verifies AGENTS.md and CLAUDE.md exist
2. Configures PATH for pub-cache and FVM
3. Installs/verifies FVM (Flutter Version Management)
4. Installs Flutter via FVM (reads `.fvmrc`)
5. Installs/verifies Melos (monorepo workspace manager)
6. Installs/verifies DCM (Dart Code Metrics)
7. Bootstraps workspace (`melos bootstrap`)
8. Generates code (`melos run build_runner:build`)
9. Verifies setup with Flutter doctor

## Resources

- Claude Code Docs: https://docs.claude.com/en/docs/claude-code
- Memory & Imports: https://docs.claude.com/en/docs/claude-code/memory.md
- Settings Reference: https://docs.claude.com/en/docs/claude-code/settings.md
