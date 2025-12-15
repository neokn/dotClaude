#!/bin/bash
# Example PreToolUse hook for Write tool
# Prevents writing excessively large files

# Read the tool input from stdin
INPUT=$(cat)

# Extract file content length (rough check)
CONTENT_LENGTH=$(echo "$INPUT" | jq -r '.content // ""' 2>/dev/null | wc -c)

# Block files over 100KB
MAX_SIZE=102400
if [ "$CONTENT_LENGTH" -gt "$MAX_SIZE" ]; then
    echo "File content exceeds ${MAX_SIZE} bytes. Consider splitting into smaller files." >&2
    exit 2  # Block the operation
fi

exit 0
