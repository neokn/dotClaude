# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code configuration template** - a reusable `.claude` directory structure with pre-configured settings, commands, agents, skills, and hooks. Users copy this to their projects as `.claude/`.

## Repository Structure

```
.claude/                     # This is the template (copy as .claude/)
├── settings.json            # Team-shared configuration
├── settings.local.json      # Personal settings (git-ignored)
├── .mcp.json                # MCP server configurations
├── CLAUDE.md                # This file - project context
├── commands/                # Slash commands (/commit, /review, etc.)
├── agents/                  # Subagents (code-reviewer, debugger, architect)
├── skills/                  # Domain knowledge (api-design, testing-patterns)
└── hooks/                   # Event-driven shell scripts
```

## File Conventions

### Commands (`commands/*.md`)
- YAML frontmatter: `description`, `allowed-tools`, `argument-hint`
- Use `$ARGUMENTS` or `$1`, `$2` for user input
- Use `` !`command` `` to inject bash output into prompt

### Agents (`agents/*.md`)
- YAML frontmatter: `name`, `description`, `tools`, `model`
- Model options: `sonnet`, `opus`, `haiku`
- Description determines when Claude auto-selects the agent

### Skills (`skills/*/SKILL.md`)
- YAML frontmatter: `name`, `description`, `allowed-tools`
- Can include supporting files (REFERENCE.md, examples, scripts)

### Hooks (`hooks/*.sh`)
- Must be executable (`chmod +x`)
- Exit 0 = allow, Exit 2 = block
- Configured in `settings.json` under `hooks` field

## When Editing This Template

- Keep examples minimal but functional
- Use comments to explain non-obvious configurations
- Test hooks with both success and failure cases
- Ensure `settings.local.json` stays in `.gitignore`
