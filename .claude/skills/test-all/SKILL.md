---
name: test-all
description: Run comprehensive test suite - unit, integration, e2e, and coverage. Use when asked to 'run all tests', 'test everything', or before creating a PR.
---

# Test All Skill

Run the comprehensive test suite in the correct sequence: unit tests, integration tests, E2E tests, and coverage generation.

## How to Use

This skill orchestrates all testing skills to provide a complete quality validation of the codebase.

## When to Use This Skill

Use this skill when:
- User asks to "run all tests"
- User says "test everything"
- Before creating a PR
- User wants a complete quality check

**Do NOT use this skill when:**
- User asks for a specific test type only (use individual skills)
- Time is limited and full E2E testing isn't needed

## Test Execution Strategy

### Phase 1: Unit Tests

Run unit tests first (fastest):

```
Use the unit-tests skill to run unit tests
```

- Fast execution
- No external dependencies
- Tests pure functions and component logic

### Phase 2: Integration Tests

Run integration tests:

```
Use the integration-tests skill to run integration tests
```

- Moderate execution time
- May require database
- Tests API routes and data operations

### Phase 3: Coverage Report Generation

After unit and integration tests complete, generate coverage:

```
Use the coverage skill to generate coverage report
```

- Combines test results
- Posts coverage summary to PR

### Phase 4: E2E Tests (Conditional)

Only run E2E tests if unit and integration tests PASSED:

```
Use the e2e-tests skill to run E2E tests
```

- Slowest execution
- Requires app to be running
- Tests complete user workflows

**Why Conditional**: E2E tests are expensive. If earlier tests fail, no point running E2E.

## Process

### Step 1: Check Prerequisites

```bash
# Check if database is running (needed for integration tests)
# Check if app/simulator is running (needed for E2E)
```

### Step 2: Run Phase 1 - Unit Tests

Invoke unit-tests skill. Track the result (passed/failed).

### Step 3: Run Phase 2 - Integration Tests

Invoke integration-tests skill. Track the result.

### Step 4: Check Phase 1-2 Results

```bash
if [ $UNIT_PASSED = true ] && [ $INTEGRATION_PASSED = true ]; then
  echo "Phase 1-2 PASSED - continuing to E2E"
  RUN_E2E=true
else
  echo "Phase 1-2 FAILED - skipping E2E tests"
  RUN_E2E=false
fi
```

### Step 5: Run Phase 3 - Coverage

After Phase 1-2 completes, generate coverage:

```
Use the coverage skill
```

### Step 6: Run Phase 4 - E2E (Conditional)

Only run if Phase 1-2 passed:

```
If RUN_E2E=true, use the e2e-tests skill
```

### Step 7: Generate Unified Report

```
Test Results Summary

Phase 1-2: Unit & Integration Tests
  Unit Tests:        PASSED (43/43)
  Integration Tests: PASSED (76/76)

Phase 3: Coverage
  Lines:      15.2%
  Statements: 14.8%
  Functions:  12.3%
  Branches:   10.1%

Phase 4: E2E Tests
  E2E Tests:         PASSED (38/38)

All tests passed!
```

## Output Format Examples

### All Tests Passing

```
Test Results Summary

Phase 1-2: Unit & Integration Tests
  Unit Tests:        PASSED (43/43)
  Integration Tests: PASSED (76/76)

Phase 3: Coverage
  Lines:      15.2%

Phase 4: E2E Tests
  E2E Tests:         PASSED (38/38)

All tests passed!

Test results have been posted to PR as sticky comments.
```

### Unit Tests Failing (E2E Skipped)

```
Test Results Summary

Phase 1-2: Unit & Integration Tests
  Unit Tests:        FAILED (37/43 passed, 6 failed)
  Integration Tests: PASSED (76/76)

Phase 3: Coverage
  Lines:      13.1%

Phase 4: E2E Tests
  E2E Tests:         Skipped (earlier tests failed)

Some tests failed

Next steps:
  1. Fix failing unit tests
  2. Re-run test-all skill to verify fixes
```

## Integration with Other Skills

This skill invokes:
- `unit-tests` skill (Phase 1)
- `integration-tests` skill (Phase 2)
- `coverage` skill (Phase 3)
- `e2e-tests` skill (Phase 4, conditional)

## Notes

### Total Execution Time

- Unit tests: Fast
- Integration tests: Moderate
- Coverage: Quick (uses cached results)
- E2E tests: Slowest (conditional)

### Sticky Comments

Each phase posts its results as sticky comments to the PR.

## Example Invocations

### Basic Full Test Suite

```
User: "Run all tests"
-> Runs unit, integration, coverage, E2E
-> Posts results to PR
-> Reports unified summary
```

### Before Creating PR

```
User: "Test everything then create PR"
-> Invokes test-all skill first
-> All tests pass
-> Invokes create-pr skill
```

## Success Criteria

A successful test-all execution should result in:
- Unit tests complete (pass or fail)
- Integration tests complete (pass or fail)
- Coverage report generated
- E2E tests run (if earlier tests passed) or skipped (with reason)
- Unified summary report provided
- All results posted to PR (if PR exists)
- Clear next steps if any failures occurred
