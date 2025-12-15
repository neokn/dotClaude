#!/bin/bash
# Example PreToolUse hook for Bash(git commit:*)
# Checks for common issues before committing

# Check for debug statements
if git diff --cached | grep -E "(console\.log|debugger|print\(|pdb\.)" > /dev/null; then
    echo "Warning: Debug statements found in staged files" >&2
    # Exit 0 to allow (warning only), exit 2 to block
    exit 0
fi

# Check for TODO/FIXME in new code
if git diff --cached | grep -E "^\+" | grep -E "(TODO|FIXME|XXX)" > /dev/null; then
    echo "Note: New TODO/FIXME comments found" >&2
    exit 0
fi

exit 0
