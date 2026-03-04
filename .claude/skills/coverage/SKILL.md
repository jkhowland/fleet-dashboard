---
name: coverage
description: Run tests with coverage and post results to the current PR as a sticky comment. Use when asked to 'run coverage', 'check coverage', or 'generate coverage report'.
---

# Coverage Skill

Run tests with coverage and post results to the current PR as a sticky comment.

## How to Use

This skill runs tests with coverage enabled, generates a report, and posts a coverage summary to the PR.

## Process

### Step 1: Check Prerequisites

```bash
# Verify test environment is ready
npm test --help > /dev/null 2>&1 || { echo "Tests not configured"; exit 1; }
```

### Step 2: Check for PR

```bash
# Get current branch
BRANCH=$(git branch --show-current)

# Check if PR exists for this branch
PR_NUMBER=$(gh pr view --json number --jq '.number' 2>/dev/null)

if [ -z "$PR_NUMBER" ]; then
  echo "No PR found for branch $BRANCH"
  echo "Results will only be displayed locally"
  POST_TO_PR=false
else
  echo "Found PR #$PR_NUMBER"
  POST_TO_PR=true
fi
```

### Step 3: Run Tests with Coverage

```bash
echo "Running tests with coverage..."
npm test -- --coverage 2>&1 | tee /tmp/coverage-output.txt
TEST_EXIT_CODE=${PIPESTATUS[0]}

# Determine status
if [ $TEST_EXIT_CODE -eq 0 ]; then
  TEST_STATUS="PASSED"
else
  TEST_STATUS="FAILED"
fi
```

### Step 4: Extract Coverage Metrics

```bash
# Extract coverage from output (format depends on test runner)
# For Jest-style output:
LINES_PCT=$(grep -oP 'Lines\s*:\s*\K[\d.]+' /tmp/coverage-output.txt | tail -1)
STATEMENTS_PCT=$(grep -oP 'Statements\s*:\s*\K[\d.]+' /tmp/coverage-output.txt | tail -1)
FUNCTIONS_PCT=$(grep -oP 'Functions\s*:\s*\K[\d.]+' /tmp/coverage-output.txt | tail -1)
BRANCHES_PCT=$(grep -oP 'Branches\s*:\s*\K[\d.]+' /tmp/coverage-output.txt | tail -1)
```

### Step 5: Check for Existing Comment

```bash
if [ "$POST_TO_PR" = true ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

  COMMENT_ID=$(gh api "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    --jq '.[] | select(.body | contains("<!-- coverage-report -->")) | .id' \
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

### Step 6: Format Results

```bash
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

cat > /tmp/coverage-report.md <<EOF
<!-- coverage-report -->
## Coverage Report

**Run #${RUN_COUNT}** | ${TIMESTAMP}

### Test Status

| Suite | Status |
|-------|--------|
| Tests | $([ $TEST_EXIT_CODE -eq 0 ] && echo "Passed" || echo "Failed") |

### Coverage Summary

| Metric | Coverage |
|--------|----------|
| Lines | ${LINES_PCT:-N/A}% |
| Statements | ${STATEMENTS_PCT:-N/A}% |
| Functions | ${FUNCTIONS_PCT:-N/A}% |
| Branches | ${BRANCHES_PCT:-N/A}% |

<details>
<summary>Coverage Details</summary>

\`\`\`
$(tail -30 /tmp/coverage-output.txt)
\`\`\`

</details>
EOF
```

### Step 7: Post or Update Comment

```bash
if [ "$POST_TO_PR" = true ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

  if [ -n "$COMMENT_ID" ]; then
    gh api "repos/${REPO}/issues/comments/${COMMENT_ID}" \
      --method PATCH \
      --field body="$(cat /tmp/coverage-report.md)"
    echo "Updated coverage comment (Run #$RUN_COUNT)"
  else
    gh pr comment "$PR_NUMBER" --body "$(cat /tmp/coverage-report.md)"
    echo "Created coverage comment (Run #1)"
  fi
fi
```

### Step 8: Report to User

Report the results:
- Overall test status
- Coverage percentages (lines, statements, functions, branches)
- Whether results were posted to PR
- Run count

## Output Format

The sticky comment format:

```markdown
<!-- coverage-report -->
## Coverage Report

**Run #2** | 2025-01-15 10:30:00 UTC

### Test Status

| Suite | Status |
|-------|--------|
| Tests | Passed |

### Coverage Summary

| Metric | Coverage |
|--------|----------|
| Lines | 15.2% |
| Statements | 14.8% |
| Functions | 12.3% |
| Branches | 10.1% |
```

## Integration with Other Skills

This skill can be invoked by:
- `create-pr` skill (after tests complete)
- `test-all` skill
- Directly by user request

## Example Invocation

```
User: "Run coverage"
-> Run tests with coverage, post results to PR if exists, report summary
```

```
User: "Check coverage"
-> Same as above
```
