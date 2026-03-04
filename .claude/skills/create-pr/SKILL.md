---
name: create-pr
description: Create or update pull requests with quality standards and proper issue linking. Use when asked to 'create PR', 'create pull request', or 'submit PR'.
---

# Create PR Skill

Create or update pull requests following project best practices and conventions.

## Target Branch

**Default**: PRs target the `staging` branch (staging-first workflow).

**CRITICAL**: NEVER create PRs directly to `main` unless the user explicitly requests it for a quick/hotfix.

## PR Authorship Requirement (`@thecarvedblades` account)

**HARD RULE**: Do **not** run `gh pr create` directly.

- Always create new PRs via `./scripts/blade-create-pr.sh`
- That script injects `GITHUB_TOKEN` from 1Password so the PR is authored by `@thecarvedblades`
- If PR creation with the script fails, fix the failure (1Password auth/token/branch state) — do not bypass with plain `gh pr create`

## How to Use

The user will ask to create a PR, or you should invoke this skill after completing an implementation. You should:

1. Check for existing PR on current branch
2. Gather issue context
3. Validate code quality
4. Create structured PR description
5. Create or update the PR (targeting `staging` by default)
6. Confirm success with PR URL

## PR Creation Process

### Phase 1: PR Detection and Branch Analysis

First, check if a PR already exists for the current branch.

1. **Get current branch name**
   ```bash
   BRANCH=$(git branch --show-current)
   echo "Current branch: $BRANCH"
   ```

2. **Extract issue number from branch name**
   ```bash
   # Pattern: issue-XX or issue-XXX
   ISSUE_NUM=$(echo "$BRANCH" | grep -o '[0-9]\+' | head -1)
   echo "Issue number: $ISSUE_NUM"
   ```

3. **Check for existing PR**
   ```bash
   # Check if PR exists for this branch
   gh pr view --json number,title,body,url 2>/dev/null
   ```

4. **Decision Point**
   - **If PR exists**: Analyze current quality, offer to update/enhance
   - **If no PR**: Proceed to create new PR

### Phase 2: Issue Context Gathering

Fetch issue details to inform PR creation.

1. **Fetch issue details**
   ```bash
   gh issue view "$ISSUE_NUM" --json number,title,body,labels
   ```

2. **Extract issue context**
   - Issue title for PR summary
   - Issue body for context
   - Labels for PR categorization

### Phase 3: Code Quality Validation

Before creating/updating PR, validate code quality.

#### 1. Check for Uncommitted Changes

```bash
# Ensure all changes are committed
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Uncommitted changes detected"
  echo "Please commit all changes before creating PR"
  git status --short
  exit 1
fi
```

#### 2. Verify Branch is Pushed

```bash
# Check if branch is pushed to remote
if ! git ls-remote --heads origin "$BRANCH" | grep -q "$BRANCH"; then
  echo "Branch not pushed. Pushing now..."
  git push -u origin "$BRANCH"
fi
```

#### 3. TypeScript Type Checking

```bash
# Run typecheck
npm run typecheck

if [ $? -ne 0 ]; then
  echo "Error: TypeScript type errors detected"
  echo "Please fix all type errors before creating PR"
  exit 1
fi
```

#### 4. Run Tests

```bash
# Run tests
npm test

if [ $? -ne 0 ]; then
  echo "Error: Tests failing"
  echo "Please fix all failing tests before creating PR"
  exit 1
fi
```

#### 5. Build Verification

```bash
# Verify build succeeds
npm run build

if [ $? -ne 0 ]; then
  echo "Error: Build failed"
  echo "Please fix build errors before creating PR"
  exit 1
fi
```

### Phase 4: PR Size Analysis

Analyze PR size and warn if too large.

```bash
# Get lines changed (compare against staging)
LINES_CHANGED=$(git diff origin/staging --stat | tail -1 | grep -o '[0-9]\+ insertion' | grep -o '[0-9]\+')
FILES_CHANGED=$(git diff origin/staging --name-only | wc -l)

echo "PR Statistics:"
echo "  Lines changed: $LINES_CHANGED"
echo "  Files changed: $FILES_CHANGED"

# Warn if PR is too large
if [ "$LINES_CHANGED" -gt 500 ]; then
  echo ""
  echo "Warning: This PR has >500 lines changed"
  echo "Consider breaking into smaller PRs for easier review"
fi
```

### Phase 5: PR Description Generation

Generate a comprehensive, structured PR description.

#### Title Format

**Convention**: `[Descriptive Title] (#XX)`

```bash
# Generate title
PR_TITLE="[Feature description from implementation] (#${ISSUE_NUM})"

# Example titles:
# "Add dark mode toggle to settings (#42)"
# "Fix double-counting in user metrics (#35)"
```

#### Description Template

```markdown
## Summary

- [Primary change/feature implemented]
- [Secondary change if applicable]

## Changes

- `path/to/file.ts`: [What changed and why]
- `path/to/other.tsx`: [What changed and why]

## Testing

- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Dark mode tested (if UI)

## Test Instructions

1. [Step to test the changes]
2. [Another step]
3. [Expected result]

## Checklist

- [ ] Code follows project conventions (CLAUDE.md)
- [ ] Tests pass (`npm test`)
- [ ] Build succeeds (`npm run build`)
- [ ] No `any` types introduced
- [ ] Dark mode supported (if UI changes)

## Related

- Closes #XX

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Phase 6: Create or Update PR

#### Creating New PR

```bash
# REQUIRED: use helper script so PR is authored as Blades account
./scripts/blade-create-pr.sh
```

```bash
# Verify PR author after creation (must be @thecarvedblades)
AUTHOR=$(gh pr view --json author --jq '.author.login')
if [ "$AUTHOR" != "thecarvedblades" ]; then
  echo "ERROR: PR author is @$AUTHOR, expected @thecarvedblades"
  exit 1
fi
gh pr view --json author,url --jq '"PR " + .url + " authored by @" + .author.login'
```

#### Updating Existing PR

```bash
PR_NUMBER=$(gh pr view --json number --jq '.number')

# Update title if needed
gh pr edit "$PR_NUMBER" --title "Updated title (#${ISSUE_NUM})"

# Update body with enhanced description
gh pr edit "$PR_NUMBER" --body "$(cat <<'EOF'
[Updated description]
EOF
)"

echo "PR #$PR_NUMBER updated"
```

### Phase 7: Verify and Report

Verify the PR was created successfully and report to user.

```bash
# Verify PR exists
PR_INFO=$(gh pr view --json number,title,url,state)
PR_NUMBER=$(echo "$PR_INFO" | jq -r '.number')
PR_URL=$(echo "$PR_INFO" | jq -r '.url')
PR_STATE=$(echo "$PR_INFO" | jq -r '.state')

if [ "$PR_STATE" = "OPEN" ]; then
  echo ""
  echo "PR #$PR_NUMBER created successfully!"
  echo ""
  echo "PR URL: $PR_URL"
  echo ""
  echo "Next steps:"
  echo "  - Review the PR description"
  echo "  - Wait for CI checks to pass"
  echo "  - Request review from team members"
fi
```

## Error Handling

### No Issue Number in Branch Name

```bash
if [ -z "$ISSUE_NUM" ]; then
  echo "Warning: Could not extract issue number from branch name"
  echo "Options:"
  echo "  1. Provide issue number manually"
  echo "  2. Create PR without issue reference"
fi
```

### Tests Failing

```bash
if ! npm test 2>/dev/null; then
  echo ""
  echo "Warning: Some tests are failing"
  echo "Options:"
  echo "  1. Fix failing tests before creating PR (recommended)"
  echo "  2. Create PR with 'needs-work' label"
fi
```

## Success Criteria

A successful PR creation should result in:
- PR is created on GitHub (or existing PR is updated)
- PR title follows `[Description] (#XX)` format
- PR description includes all required sections
- PR includes "Closes #XX" reference
- All code is committed and pushed
- PR is labeled `ready-for-review`
- PR URL is provided to user
- TypeScript typecheck passes
- Build succeeds
- Tests pass

## Best Practices

### DO

1. **Always include issue number** in title: `(#XX)`
2. **Always include "Closes #XX"** in description
3. **Run typecheck** before creating PR
4. **Run quality checks** before creating PR
5. **Provide clear test instructions**
6. **Use structured templates** for consistency

### DON'T

1. **Don't skip typecheck** - type errors will fail in CI
2. **Don't skip quality validation** - catches issues early
3. **Don't create oversized PRs** - warn if >500 lines
4. **Don't skip the issue reference** - breaks linking
5. **Don't use "Fixes" or "Resolves"** - use "Closes" for consistency
6. **Don't run `gh pr create` directly** - always use `./scripts/blade-create-pr.sh`
