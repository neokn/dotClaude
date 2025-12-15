---
description: Review code changes for quality and issues
allowed-tools: Bash(git:*), Read, Grep, Glob
argument-hint: [file-or-branch]
---

Review the code changes for:
- Bugs and logic errors
- Security vulnerabilities
- Performance issues
- Code style and best practices
- Missing error handling

Target: $ARGUMENTS

If no target specified, review unstaged changes:
!`git diff`

Provide specific, actionable feedback with file:line references.
