---
name: implement-review-feedback
description: Implement feedback from automated code reviews. Creates new issues for out-of-scope suggestions and implements in-scope changes. Use when asked to 'implement review feedback', 'address review comments', or 'apply review suggestions'.
---

# Implement Review Feedback Skill

Automatically implement feedback from code reviews, creating new issues for out-of-scope suggestions and implementing in-scope changes.

## How to Use

The user will provide a PR number that has a code review. You should:

1. Fetch and analyze the code review
2. Categorize feedback as in-scope or out-of-scope
3. Create issues for out-of-scope suggestions
4. Implement in-scope changes
5. Push changes
6. Re-trigger review

## Process

### Phase 1: Fetch Code Review

1. **Get PR details**
   ```bash
   gh pr view <number> --json number,title,body,headRefName
   ```

2. **Fetch PR comments**
   ```bash
   gh pr view <number> --json comments --jq '.comments[] | select(.author.login == "claude" or .author.login == "claude[bot]") | {id: .id, createdAt: .createdAt, body: .body}'
   ```

3. **Find the most recent code review**
   - Look for comments that start with "# Code Review"
   - Get the latest review (most recent createdAt)
   - Extract the full review text

### Phase 2: Analyze Review Feedback

Parse the review into categories:

**Critical Issues** - Must be addressed in this PR, blockers to merging
**Issues** - Should be addressed in this PR, important but not blocking
**Suggestions** - Nice to have improvements, may be out of scope

### Phase 3: Categorize Feedback

**IMPORTANT: Default to implementing ALL feedback.** The goal is to ship the highest quality code possible.

**In-Scope (Implement Now) - THE DEFAULT**
- ALL critical issues
- ALL issues
- ALL suggestions that can be reasonably implemented
- Any feedback that improves code quality, readability, or maintainability

**Out-of-Scope (Create Issue) - ONLY when truly necessary**
- Features that require entirely new infrastructure not present in the codebase
- Changes that would require modifying >10 unrelated files
- Performance optimizations requiring significant architectural changes

### Phase 4: Create Issues for Out-of-Scope Items

For each out-of-scope suggestion, use the `create-issue` skill:

**Issue Template:**
- Title: Brief description from review
- Body: Context from the review, why it's valuable, link to originating PR
- Labels: Appropriate labels

### Phase 5: Update Labels to In-Progress

Before implementing changes, update PR labels:

```bash
# Remove workflow labels
gh pr edit <number> --remove-label "review-complete" 2>/dev/null || true
gh pr edit <number> --remove-label "needs-changes" 2>/dev/null || true
gh pr edit <number> --remove-label "ready-for-review" 2>/dev/null || true

# Add in-progress label
gh pr edit <number> --add-label "in-progress"
```

### Phase 6: Implement In-Scope Changes

For each in-scope issue:

1. **Read the relevant files** - Use Read tool to see current code
2. **Implement the fix** - Follow the suggestion from the review
3. **Verify the fix** - Check that change addresses the feedback
4. **Create logical commits** - Clear commit messages referencing review feedback

### Phase 7: Quality Checks

Before pushing:

1. **Run tests**
   ```bash
   npm test
   ```

2. **Run build**
   ```bash
   npm run build
   ```

3. **Format code** (if applicable)

### Phase 8: Push Changes

```bash
git push
```

### Phase 9: Wait for PR Checks to Pass

After pushing changes, wait for GitHub Actions checks to complete:

```bash
# Wait for checks to complete
gh pr checks <number> --watch --fail-fast

# Verify all checks passed
gh pr checks <number>
```

### Phase 10: Finalize PR and Re-trigger Review

After all changes are implemented and checks pass:

```bash
# Clear workflow labels
gh pr edit <number> --remove-label "in-progress" 2>/dev/null || true

# Add ready-for-review to trigger second review
gh pr edit <number> --add-label "ready-for-review"
```

## When PR Has No Review

If the PR doesn't have a code review yet:
- Inform the user
- Suggest adding `ready-for-review` label to trigger a review

## When Review Has Only Positive Feedback

If the review only has "What's Good" sections with no suggestions:
- Inform the user the PR is approved with no changes needed
- Proceed to merge the PR

## Common Quick Fixes

| Pattern | Fix |
|---------|-----|
| Missing input validation | Add validation check before operation |
| Missing loading state | Add loading spinner and disabled state |
| Missing error handling | Add try/catch with appropriate error handling |
| Any types | Add proper TypeScript types |

## Example Workflow

User: "Implement review feedback for PR 48"

**Phase 1: Fetch Review**
```bash
gh pr view 48 --json comments
# Find latest review
```

**Phase 2: Analyze**
Review contains:
- Critical: Missing null check on line 45
- Issue: Should add error handling
- Suggestion: Consider extracting helper function

**Phase 3: Categorize**
- In-scope: All three items (implement them)

**Phase 4: Create Issues**
(None needed - all suggestions are being implemented)

**Phase 5-8: Implement and Push**
Fix all issues, run tests, push changes

**Phase 9-10: Wait and Finalize**
Wait for CI, then add ready-for-review label

## Success Criteria

A successful feedback implementation should result in:
- All critical/important in-scope issues fixed
- Out-of-scope suggestions tracked as issues
- Tests passing
- Build succeeding
- Changes pushed
- All CI checks passed
- Ready-for-review label added
- Review re-triggered
- User informed of what was done
