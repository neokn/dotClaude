---
description: Run tests and analyze failures
allowed-tools: Bash(npm:*), Bash(pnpm:*), Bash(yarn:*), Bash(pytest:*), Bash(go test:*), Read
argument-hint: [test-pattern]
---

Run the project's tests and analyze any failures.

Test pattern: $ARGUMENTS

Steps:
1. Detect the project type and test runner
2. Run tests (with pattern if provided)
3. If tests fail, analyze the failures
4. Suggest fixes for failing tests

Focus on understanding WHY tests fail, not just WHAT failed.
