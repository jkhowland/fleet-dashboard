---
name: e2e-tests
description: Run E2E tests and post results to the current PR as a sticky comment. Use when asked to 'run e2e tests', 'test e2e', or 'run integration tests'.
---

# E2E Tests Skill

Run end-to-end tests and post results to the current PR as a sticky comment.

## How to Use

This skill runs the E2E test suite and posts results to the PR associated with the current branch.

## Prerequisites

- App must be running (simulator or device)
- Test environment must be configured
- E2E test framework (Detox, Maestro, etc.) must be installed

## Process

### Step 1: Check Prerequisites

```bash
# Check if emulator/simulator is running
# For iOS
xcrun simctl list | grep -q "Booted" || echo "No iOS simulator running"

# For Android
adb devices | grep -q "device$" || echo "No Android device connected"
```

### Step 2: Check for PR

```bash
# Get current branch
BRANCH=$(git branch --show-current)

# Check if PR exists for this branch
PR_NUMBER=$(gh pr view --json number --jq '.number' 2>/dev/null)

if [ -z "$PR_NUMBER" ]; then
  echo "No PR found for branch $BRANCH"
  POST_TO_PR=false
else
  echo "Found PR #$PR_NUMBER"
  POST_TO_PR=true
fi
```

### Step 3: Run E2E Tests

```bash
# Run E2E tests and capture output
# For Detox:
npm run test:e2e 2>&1 | tee /tmp/e2e-test-output.txt
TEST_EXIT_CODE=${PIPESTATUS[0]}

# Extract test summary
PASSED_TESTS=$(grep -oP '\d+(?= passed)' /tmp/e2e-test-output.txt | tail -1)
FAILED_TESTS=$(grep -oP '\d+(?= failed)' /tmp/e2e-test-output.txt | tail -1)
SKIPPED_TESTS=$(grep -oP '\d+(?= skipped)' /tmp/e2e-test-output.txt | tail -1)

# Set defaults
PASSED_TESTS=${PASSED_TESTS:-0}
FAILED_TESTS=${FAILED_TESTS:-0}
SKIPPED_TESTS=${SKIPPED_TESTS:-0}
TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS + SKIPPED_TESTS))
```

### Step 4: Check for Existing Comment

```bash
if [ "$POST_TO_PR" = true ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

  COMMENT_ID=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    --jq '.[] | select(.body | contains("<!-- e2e-tests -->")) | .id' \
    | head -1)

  if [ -n "$COMMENT_ID" ]; then
    CURRENT_COUNT=$(gh api "repos/${REPO}/issues/comments/${COMMENT_ID}" \
      --jq '.body' | grep -oP '(?<=Run #)\d+' | head -1)
    RUN_COUNT=$((CURRENT_COUNT + 1))
  else
    RUN_COUNT=1
  fi
fi
```

### Step 5: Format Results

```bash
if [ $TEST_EXIT_CODE -eq 0 ]; then
  STATUS="PASSED"
else
  STATUS="FAILED"
fi

TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

cat > /tmp/e2e-test-report.md <<EOF
<!-- e2e-tests -->
## E2E Test Results

**Run #${RUN_COUNT}** | ${TIMESTAMP}

| Status | Passed | Failed | Skipped | Total |
|--------|--------|--------|---------|-------|
| ${STATUS} | ${PASSED_TESTS} | ${FAILED_TESTS} | ${SKIPPED_TESTS} | ${TOTAL_TESTS} |

<details>
<summary>Test Output</summary>

\`\`\`
$(tail -100 /tmp/e2e-test-output.txt)
\`\`\`

</details>
EOF
```

### Step 6: Post or Update Comment

```bash
if [ "$POST_TO_PR" = true ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

  if [ -n "$COMMENT_ID" ]; then
    gh api "repos/${REPO}/issues/comments/${COMMENT_ID}" \
      --method PATCH \
      --field body="$(cat /tmp/e2e-test-report.md)"
    echo "Updated E2E test comment (Run #$RUN_COUNT)"
  else
    gh pr comment "$PR_NUMBER" --body "$(cat /tmp/e2e-test-report.md)"
    echo "Created E2E test comment (Run #1)"
  fi
fi
```

### Step 7: Report to User

Report the results:
- Test status (passed/failed)
- Number of tests passed/failed/skipped
- Whether results were posted to PR
- Run count
- Note about screenshots/videos if failures

## Output Format

The sticky comment format:

```markdown
<!-- e2e-tests -->
## E2E Test Results

**Run #1** | 2025-01-15 10:30:00 UTC

| Status | Passed | Failed | Skipped | Total |
|--------|--------|--------|---------|-------|
| PASSED | 38 | 0 | 0 | 38 |

<details>
<summary>Test Output</summary>

[Last 100 lines of test output]

</details>
```

## Integration with Other Skills

This skill can be invoked by:
- `create-pr` skill (optional, for thorough validation)
- `test-all` skill
- Directly by user request

## Notes

- E2E tests require the app to be built and running
- Tests run against the dev server or built app
- Screenshots/videos are captured on failure (framework dependent)

## Example Invocation

```
User: "Run e2e tests"
-> Check prerequisites, run tests, post results to PR if exists, report summary
```
