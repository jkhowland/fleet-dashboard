---
name: unit-tests
description: Run unit tests locally and post results to the current PR as a sticky comment. Use when asked to 'run unit tests', 'test unit', or before creating a PR.
---

# Unit Tests Skill

Run unit tests locally and post results to the current PR as a sticky comment.

## How to Use

This skill runs the unit test suite and posts results to the PR associated with the current branch.

## Process

### Step 1: Check for PR

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

### Step 2: Run Unit Tests

```bash
# Run unit tests and capture output
npm test 2>&1 | tee /tmp/unit-test-output.txt
TEST_EXIT_CODE=${PIPESTATUS[0]}

# Extract test summary
TOTAL_TESTS=$(grep -oP '\d+(?= passed)' /tmp/unit-test-output.txt | tail -1)
FAILED_TESTS=$(grep -oP '\d+(?= failed)' /tmp/unit-test-output.txt | tail -1)
DURATION=$(grep -oP 'Duration \K[0-9.]+s' /tmp/unit-test-output.txt | tail -1)

# Set defaults if not found
TOTAL_TESTS=${TOTAL_TESTS:-0}
FAILED_TESTS=${FAILED_TESTS:-0}
```

### Step 3: Check for Existing Comment

```bash
if [ "$POST_TO_PR" = true ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

  COMMENT_ID=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    --jq '.[] | select(.body | contains("<!-- unit-tests -->")) | .id' \
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

### Step 4: Format Results

```bash
if [ $TEST_EXIT_CODE -eq 0 ]; then
  STATUS="PASSED"
else
  STATUS="FAILED"
fi

TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

cat > /tmp/unit-test-report.md <<EOF
<!-- unit-tests -->
## Unit Test Results

**Run #${RUN_COUNT}** | ${TIMESTAMP}

| Status | Tests | Failed | Duration |
|--------|-------|--------|----------|
| ${STATUS} | ${TOTAL_TESTS} | ${FAILED_TESTS:-0} | ${DURATION:-N/A} |

<details>
<summary>Test Output</summary>

\`\`\`
$(tail -50 /tmp/unit-test-output.txt)
\`\`\`

</details>
EOF
```

### Step 5: Post or Update Comment

```bash
if [ "$POST_TO_PR" = true ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

  if [ -n "$COMMENT_ID" ]; then
    gh api "repos/${REPO}/issues/comments/${COMMENT_ID}" \
      --method PATCH \
      --field body="$(cat /tmp/unit-test-report.md)"
    echo "Updated unit test comment (Run #$RUN_COUNT)"
  else
    gh pr comment "$PR_NUMBER" --body "$(cat /tmp/unit-test-report.md)"
    echo "Created unit test comment (Run #1)"
  fi
fi
```

### Step 6: Report to User

Report the results:
- Test status (passed/failed)
- Number of tests run
- Number of failures (if any)
- Whether results were posted to PR
- Run count

## Output Format

The sticky comment format:

```markdown
<!-- unit-tests -->
## Unit Test Results

**Run #3** | 2025-01-15 10:30:00 UTC

| Status | Tests | Failed | Duration |
|--------|-------|--------|----------|
| PASSED | 43 | 0 | 5.2s |

<details>
<summary>Test Output</summary>

[Last 50 lines of test output]

</details>
```

## Integration with Other Skills

This skill can be invoked by:
- `create-pr` skill (as part of quality validation)
- `coverage` skill (runs unit tests as part of coverage)
- `test-all` skill
- Directly by user request

## Example Invocation

```
User: "Run unit tests"
-> Run tests, post results to PR if exists, report summary
```

```
User: "Run unit tests and post to PR"
-> Same behavior - always posts if PR exists
```
