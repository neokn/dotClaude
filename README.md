# Claude Code Configuration Template

This is a template for the `.claude` directory used by [Claude Code](https://claude.ai/code).

## Usage

Copy this entire folder to your project root as `.claude`:

```bash
cp -r /path/to/this/template /your/project/.claude
```

Or use it as a reference to create your own configuration.

## Structure

```
.claude/
├── settings.json          # Team-shared settings (commit this)
├── settings.local.json    # Personal settings (git-ignored)
├── .mcp.json              # MCP server configurations
├── CLAUDE.md              # Project context for Claude
├── commands/              # Custom slash commands
│   ├── commit.md          # /commit - AI-generated commits
│   ├── review.md          # /review - Code review
│   ├── test.md            # /test - Run and analyze tests
│   ├── explain.md         # /explain - Explain code
│   └── refactor.md        # /refactor - Suggest improvements
├── agents/                # Specialized subagents
│   ├── code-reviewer.md   # Quality and security review
│   ├── debugger.md        # Systematic debugging
│   └── architect.md       # Design and planning
├── skills/                # Domain knowledge
│   ├── api-design/        # REST API best practices
│   └── testing-patterns/  # Testing guidelines
└── hooks/                 # Event-driven scripts
```

## Configuration Files

### settings.json
Team-shared configuration:
- **permissions**: Control tool access (allow/ask/deny)
- **hooks**: Automated event-driven actions
- **model**: Default AI model
- **attribution**: Git commit/PR attribution text

### settings.local.json
Personal overrides (auto git-ignored):
- Local environment variables
- Personal permission overrides
- Experimental settings

### .mcp.json
Model Context Protocol servers for extended capabilities:
- HTTP servers for remote services
- Stdio servers for local tools

## Customization

### Adding Commands

Create a markdown file in `commands/`:

```markdown
---
description: What this command does
allowed-tools: Bash(npm:*), Read, Write
argument-hint: [optional-args]
---

Your prompt instructions here.
Use $ARGUMENTS for user input.
Use !`command` to inject bash output.
```

### Adding Agents

Create a markdown file in `agents/`:

```markdown
---
name: agent-name
description: When to use this agent
tools: Read, Grep, Glob
model: sonnet
---

System prompt for the agent.
```

### Adding Skills

Create a directory in `skills/` with `SKILL.md`:

```markdown
---
name: skill-name
description: What this skill provides and when to use it
allowed-tools: Read, Write
---

# Skill Name

Detailed knowledge and instructions.
```

### Adding Hooks

Hooks are configured in `settings.json` and run scripts from `hooks/`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/my-script.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

#### Hook Events

| Event | Description | Uses Matcher |
|-------|-------------|--------------|
| `PreToolUse` | Before tool execution (can block) | Yes |
| `PostToolUse` | After tool completion | Yes |
| `PermissionRequest` | When permission dialog shown | Yes |
| `UserPromptSubmit` | User submits a prompt | No |
| `Stop` | Main agent stops | No |
| `SubagentStop` | Subagent stops | No |
| `SessionStart` | Session begins | Yes (special) |
| `SessionEnd` | Session ends | No |
| `PreCompact` | Before context compaction | Yes (special) |
| `Notification` | Notifications sent | Yes (special) |

#### Tool Matchers

| Matcher | Description |
|---------|-------------|
| `Bash` | Shell commands |
| `Read` | File reading |
| `Write` | File writing |
| `Edit` | File editing |
| `Glob` | File pattern matching |
| `Grep` | Content search |
| `Task` | Subagent tasks |
| `WebFetch` | Web page fetching |
| `WebSearch` | Web searching |
| `mcp__<server>__<tool>` | MCP tools |

#### Matcher Syntax (Regex)

```json
"matcher": "Write"           // Exact match
"matcher": "Edit|Write"      // OR - matches either
"matcher": "Web.*"           // Wildcard - WebFetch, WebSearch
"matcher": "mcp__.*"         // All MCP tools
"matcher": "*"               // All tools (universal)
```

#### Special Matchers

**SessionStart:**
- `startup` - New session
- `resume` - Resumed session
- `clear` - After /clear
- `compact` - After compaction

**PreCompact:**
- `manual` - User ran /compact
- `auto` - Auto-triggered

**Notification:**
- `permission_prompt` - Permission dialogs
- `idle_prompt` - Claude idle 60+ seconds

#### Hook Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Allow / success |
| `2` | Block / deny (stderr shown to Claude) |
| Other | Non-blocking error |

## Best Practices

1. **Commit settings.json** - Share team conventions
2. **Git-ignore settings.local.json** - Keep personal settings private
3. **Protect secrets** - Use deny rules for .env and keys
4. **Start simple** - Add complexity as needed
5. **Document in CLAUDE.md** - Help Claude understand your project

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Settings Reference](https://docs.anthropic.com/en/docs/claude-code/settings)
- [Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks)
