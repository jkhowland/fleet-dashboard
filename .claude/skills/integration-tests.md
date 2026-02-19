---
name: integration-tests
description: Run integration tests locally and post results to the current PR as a sticky comment. Use when asked to 'run integration tests', 'test integration', or before creating a PR.
---

# Integration Tests Skill

Run integration tests locally and post results to the current PR as a sticky comment.

## How to Use

This skill runs the integration test suite and posts results to the PR associated with the current branch.

## Prerequisites

- Database must be running (if tests require it)
- Test environment must be configured

## Process

### Step 1: Check Prerequisites

```bash
# Check if database is running (if needed)
# Adjust based on your database setup
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

### Step 3: Run Integration Tests

```bash
# Run integration tests and capture output
npm run test:integration 2>&1 | tee /tmp/integration-test-output.txt
TEST_EXIT_CODE=${PIPESTATUS[0]}

# Extract test summary
TOTAL_TESTS=$(grep -oP '\d+(?= passed)' /tmp/integration-test-output.txt | tail -1)
FAILED_TESTS=$(grep -oP '\d+(?= failed)' /tmp/integration-test-output.txt | tail -1)
DURATION=$(grep -oP 'Duration \K[0-9.]+s' /tmp/integration-test-output.txt | tail -1)

# Set defaults if not found
TOTAL_TESTS=${TOTAL_TESTS:-0}
FAILED_TESTS=${FAILED_TESTS:-0}
```

### Step 4: Check for Existing Comment

```bash
if [ "$POST_TO_PR" = true ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

  COMMENT_ID=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    --jq '.[] | select(.body | contains("<!-- integration-tests -->")) | .id' \
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

cat > /tmp/integration-test-report.md <<EOF
<!-- integration-tests -->
## Integration Test Results

**Run #${RUN_COUNT}** | ${TIMESTAMP}

| Status | Tests | Failed | Duration |
|--------|-------|--------|----------|
| ${STATUS} | ${TOTAL_TESTS} | ${FAILED_TESTS:-0} | ${DURATION:-N/A} |

<details>
<summary>Test Output</summary>

\`\`\`
$(tail -50 /tmp/integration-test-output.txt)
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
      --field body="$(cat /tmp/integration-test-report.md)"
    echo "Updated integration test comment (Run #$RUN_COUNT)"
  else
    gh pr comment "$PR_NUMBER" --body "$(cat /tmp/integration-test-report.md)"
    echo "Created integration test comment (Run #1)"
  fi
fi
```

### Step 7: Report to User

Report the results:
- Test status (passed/failed)
- Number of tests run
- Number of failures (if any)
- Duration
- Whether results were posted to PR
- Run count

## Output Format

The sticky comment format:

```markdown
<!-- integration-tests -->
## Integration Test Results

**Run #2** | 2025-01-15 10:30:00 UTC

| Status | Tests | Failed | Duration |
|--------|-------|--------|----------|
| PASSED | 76 | 0 | 45.6s |

<details>
<summary>Test Output</summary>

[Last 50 lines of test output]

</details>
```

## Integration with Other Skills

This skill can be invoked by:
- `create-pr` skill (as part of quality validation)
- `coverage` skill (runs integration tests as part of coverage)
- `test-all` skill
- Directly by user request

## Example Invocation

```
User: "Run integration tests"
-> Run tests, post results to PR if exists, report summary
```
