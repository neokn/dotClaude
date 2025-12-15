---
description: Suggest refactoring improvements
allowed-tools: Read, Grep, Glob
argument-hint: <file-path>
---

Analyze the code at: $ARGUMENTS

Identify opportunities for:
1. **Code clarity**: Better naming, structure, comments
2. **DRY violations**: Repeated code that could be extracted
3. **SOLID principles**: Single responsibility, dependencies
4. **Performance**: Obvious inefficiencies
5. **Maintainability**: Complex logic that could be simplified

Present suggestions with:
- Current code snippet
- Proposed improvement
- Rationale for the change
- Impact assessment (low/medium/high effort)

Do NOT make changes - only suggest and explain.
