---
name: testing-patterns
description: Write effective tests with proper structure and coverage. Use when writing unit tests, integration tests, or improving test quality.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Testing Patterns Skill

Help write clear, maintainable, effective tests.

## Test Structure (AAA Pattern)

```
// Arrange - Set up test data and conditions
// Act - Execute the code under test
// Assert - Verify the expected outcome
```

## Naming Convention

```
test_[unit]_[scenario]_[expected result]

Examples:
- test_calculateTotal_withEmptyCart_returnsZero
- test_login_withInvalidPassword_throwsAuthError
- test_fetchUser_whenNotFound_returns404
```

## What to Test

### Unit Tests
- Pure functions and calculations
- Business logic
- Edge cases and boundaries
- Error conditions

### Integration Tests
- API endpoints
- Database operations
- External service interactions
- Authentication flows

### Do NOT Test
- Framework/library internals
- Private methods directly
- Trivial getters/setters
- Third-party code

## Test Quality Checklist

- [ ] Tests one thing only
- [ ] Clear test name describes behavior
- [ ] Independent (no test order dependency)
- [ ] Fast (mock external dependencies)
- [ ] Deterministic (no flaky tests)
- [ ] Readable (future you is the audience)

## Mocking Guidelines

Mock:
- External APIs
- Database (for unit tests)
- Time/dates
- Random values
- File system (when appropriate)

Don't mock:
- The thing you're testing
- Simple value objects
- Everything (leads to brittle tests)

## Coverage Strategy

Focus on:
- Critical business logic: 90%+
- Happy paths: 100%
- Error paths: 80%+
- Edge cases: Case by case

Avoid:
- Chasing 100% blindly
- Testing implementation details
- Duplicate coverage
