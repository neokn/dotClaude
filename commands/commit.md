---
description: Create a git commit with AI-generated message
allowed-tools: Bash(git:*)
---

Analyze the staged changes and create a meaningful commit message.

Current git status:
!`git status --short`

Staged diff:
!`git diff --cached`

Guidelines:
1. Use conventional commit format: type(scope): description
2. Types: feat, fix, docs, style, refactor, test, chore
3. Keep the first line under 72 characters
4. Add a body if the changes need explanation

Create the commit with the generated message.
