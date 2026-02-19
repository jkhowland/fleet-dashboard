---
name: promote-to-main
description: Promote staging to main with deployment verification and testing. Creates a PR from staging to main. Use when asked to 'promote staging', 'promote to main', or 'merge staging to main'.
---

# Promote to Main Skill

Promote the staging branch to main with automated deployment verification and testing. This skill ensures changes are thoroughly tested on staging before reaching production.

## How to Use

This skill creates a PR from staging to main, verifies the staging deployment, and posts the results to the PR.

## When to Use This Skill

Use this skill when:
- Changes have been merged to staging and verified
- User asks to "promote staging to main"
- User says "merge staging to main"
- User wants to "release to production"

**Do NOT use this skill when:**
- Changes haven't been merged to staging yet
- Staging tests are failing
- There's nothing new on staging vs main

## Promotion Process

### Phase 1: Check for Changes

First, verify there are actually changes to promote.

```bash
# Fetch latest from remote
git fetch origin main staging

# Check if staging is ahead of main
COMMITS_AHEAD=$(git rev-list --count origin/main..origin/staging)

if [ "$COMMITS_AHEAD" -eq 0 ]; then
  echo "No changes to promote - staging is not ahead of main"
  exit 0
fi

echo "Found $COMMITS_AHEAD commits to promote"

# Get the list of commits being promoted
git log --oneline origin/main..origin/staging
```

### Phase 2: Verify Staging Health

Run tests and health checks against staging.

```bash
# Run tests against staging
npm test 2>&1 | tee /tmp/staging-test-output.txt
TEST_EXIT_CODE=${PIPESTATUS[0]}

# Parse results
if [ $TEST_EXIT_CODE -eq 0 ]; then
  TEST_STATUS="PASSED"
else
  TEST_STATUS="FAILED"
fi
```

### Phase 3: Create PR from Staging to Main

Create the promotion PR with test results.

```bash
# Check if PR already exists
EXISTING_PR=$(gh pr list --base main --head staging --json number --jq '.[0].number')

if [ -n "$EXISTING_PR" ]; then
  echo "PR #$EXISTING_PR already exists for staging -> main"
  PR_NUMBER=$EXISTING_PR
else
  # Get commits being promoted for PR description
  COMMIT_LIST=$(git log --oneline origin/main..origin/staging | head -20)
  COMMIT_COUNT=$(git rev-list --count origin/main..origin/staging)

  # Get PR numbers from merge commits
  PR_NUMBERS=$(git log origin/main..origin/staging --merges --format="%s" | grep -oE '#[0-9]+' | tr -d '#' | sort -u)

  # Find issues closed by those PRs
  ISSUES_TO_CLOSE=""
  for pr in $PR_NUMBERS; do
    CLOSED_ISSUES=$(gh pr view "$pr" --json body --jq '.body' 2>/dev/null | grep -oE '(Closes|closes|Close|close|Fixes|fixes) #[0-9]+' | grep -oE '#[0-9]+' | tr -d '#')
    for issue in $CLOSED_ISSUES; do
      ISSUES_TO_CLOSE="$ISSUES_TO_CLOSE $issue"
    done
  done

  # Create PR as the Blades account using the helper script
  ./scripts/blade-create-pr.sh

  : <<'EOF_OLD'  # original PR body kept for reference
## Summary

Promoting ${COMMIT_COUNT} commits from staging to main.

## Commits Being Promoted

\`\`\`
${COMMIT_LIST}
\`\`\`

## Test Results

Tests: ${TEST_STATUS}

---

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"

  PR_NUMBER=$(gh pr view --json number --jq '.number')
  echo "Created PR #$PR_NUMBER"
fi
```

### Phase 4: Report Results

Provide a summary to the user.

**Success Report**:
```
Staging Promotion PR Ready

PR #XX: Promote staging to main (Y commits)
URL: https://github.com/user/sidekick/pull/XX

Test Results:
  Tests passed

The PR is ready for review and merge.
```

**Failure Report**:
```
Staging Tests Failed

Test Results:
  Tests failed

Please investigate the test failures before promoting.
```

## Handling Edge Cases

### No Changes to Promote

```bash
if [ "$COMMITS_AHEAD" -eq 0 ]; then
  echo "Nothing to promote - staging and main are in sync"
  exit 0
fi
```

### Tests Fail

If tests fail:
- Still create the PR (for visibility)
- Mark PR with a warning
- Recommend investigating before merge
- User can re-run tests after fixing

### PR Already Exists

If a staging -> main PR already exists:
- Don't create a new one
- Update existing PR with new test results
- Useful for re-running verification

## Integration with Workflow

This skill is the final step before production:

```
1. Feature PR merged to staging
2. Verify on staging
3. promote-to-main skill <- YOU ARE HERE
   - Runs tests
   - Creates PR with results
4. Review and merge PR to main
5. Deploys to production
```

## Example Invocations

**Standard promotion**:
```
User: "Promote staging to main"
-> Check for changes, run tests, create PR
```

**After recent merge**:
```
User: "I just merged to staging, promote it"
-> Same process
```

**Check promotion status**:
```
User: "Is staging ready to promote?"
-> Check commits ahead, run tests, report status
```

## Success Criteria

A successful promotion should result in:
- Verified changes exist on staging vs main
- Tests pass
- PR created (or updated) with test results
- PR includes list of commits being promoted
- User informed of PR URL and next steps
