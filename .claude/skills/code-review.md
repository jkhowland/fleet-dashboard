---
name: code-review
description: Perform comprehensive code reviews of GitHub pull requests. Use when asked to 'review PR #XX', 'code review', or 'check pull request'.
---

# Code Review Skill

Perform a comprehensive, thorough code review of a GitHub pull request.

## How to Use

The user will provide a PR number or ask you to review a specific PR. You should:

1. Fetch the PR details and diff
2. Read all modified files
3. Understand the context and purpose
4. Perform systematic analysis
5. Provide detailed, actionable feedback

## Review Process

### Phase 1: Context Gathering

1. **Fetch PR information**
   ```bash
   gh pr view <number> --json number,title,body,headRefName,files
   ```

2. **Get the full diff**
   ```bash
   gh pr diff <number>
   ```

3. **Read all modified files completely**
   - Don't just read the diff - read the entire files for context
   - Understand how changes fit into the broader codebase
   - Check imports, types, and dependencies

4. **Review related files**
   - Check files that import the modified code
   - Look at test files if they exist
   - Review documentation if relevant

### Phase 2: Systematic Analysis

Analyze the PR across these dimensions:

#### 1. **Correctness & Logic**
- Does the code do what it claims to do?
- Are there any logical errors or edge cases missed?
- Will this work correctly in all scenarios?
- Are there any potential race conditions or timing issues?

#### 2. **Code Quality**
- Is the code clear and readable?
- Are variable and function names descriptive?
- Is the code properly typed (no `any` types)?
- Are there any code smells or anti-patterns?
- Is error handling appropriate?

#### 3. **Project Conventions**
From CLAUDE.md, check:
- Package manager (npm not yarn, pnpm, or bun)
- Commit practices (clear messages, push immediately after commit)
- No emojis unless requested
- Dark mode support for new components
- Accessibility requirements

#### 4. **Testing**
- Are tests included where needed?
- Do tests cover edge cases?
- Are test names clear and descriptive?
- Do all tests pass?

#### 5. **Performance**
- Are there any obvious performance issues?
- Could anything be optimized without adding complexity?
- Are there unnecessary re-renders (React)?

#### 6. **Security**
- Are there any security vulnerabilities?
- Is user input properly validated?
- Is sensitive data properly handled?
- Check OWASP top 10 vulnerabilities

#### 7. **Dependencies & Side Effects**
- Are new dependencies necessary?
- Will this change break existing functionality?
- Are there unintended side effects?
- Is this change properly scoped?

#### 8. **Documentation**
- Is code self-documenting or are comments needed?
- Are complex algorithms explained?
- Is documentation updated if needed?
- Are commit messages clear?

### Phase 3: Categorized Feedback

Organize your feedback into these categories:

#### CRITICAL ISSUES (Must Fix)
Issues that:
- Will cause bugs or breakage
- Introduce security vulnerabilities
- Violate core project conventions
- Break existing functionality

#### ISSUES (Should Fix)
Issues that:
- Could cause problems in certain scenarios
- Don't follow best practices
- Make code harder to maintain
- Miss important edge cases

#### SUGGESTIONS (Nice to Have)
Improvements that:
- Would make code cleaner
- Could improve performance
- Would enhance readability
- Are minor style issues

#### WHAT'S GOOD
Explicitly call out:
- Well-written code
- Good patterns followed
- Excellent test coverage
- Clear documentation
- Smart solutions

### Phase 4: Write and Post Review to GitHub

**CRITICAL**: The review MUST be posted to GitHub as a PR review comment. Do NOT just provide the review in the chat session - it must go to GitHub where it's useful.

Structure your review as a GitHub comment:

```markdown
# Code Review - PR #XX: [Title]

## Overall Assessment

**Quality**: [Excellent/Good/Needs Work]
**Recommendation**: [Approve/Request Changes/Needs Discussion]

[1-2 paragraph summary]

---

## CRITICAL ISSUES - Must Fix

### 1. [Issue Title]

**Location**: `file.ts:123-145`

**Problem**: [Clear description of what's wrong]

**Why This Matters**: [Impact and consequences]

**Fix Required**:
```[language]
// Suggested fix with code example
```

**Impact**: [High/Medium/Low]

---

## ISSUES - Should Fix

[Same structure as Critical Issues]

---

## SUGGESTIONS - Nice to Have

[Same structure, but optional improvements]

---

## WHAT'S GOOD

[List positive aspects with specific examples]

---

## SUMMARY OF REQUIRED CHANGES

**Must fix before merge**:
1. [Critical issue 1]
2. [Critical issue 2]

**Should fix**:
3. [Issue 1]
4. [Issue 2]

**Nice to have**:
5. [Suggestion 1]

---

## RECOMMENDATION

[Clear recommendation: Approve, Request Changes, or Needs Discussion]

[Final summary paragraph]
```

### Phase 5: Post Review to GitHub (Sticky Comment)

**CRITICAL STEP - DO NOT SKIP**: After writing the review, you MUST post it to GitHub immediately.

#### Sticky Comment Workflow

Reviews use **sticky comments** - a single comment that gets updated on each review, rather than creating multiple comments. This keeps the PR clean and shows the latest review status.

#### Step 1: Check for Existing Review Comment

Search for an existing review comment with the marker:
```bash
# Get existing comment ID if it exists
COMMENT_ID=$(gh api "repos/{owner}/{repo}/issues/<number>/comments" \
  --jq '.[] | select(.body | contains("<!-- code-review -->")) | .id' \
  | head -1)
```

#### Step 2: Post or Update the Comment

```bash
# Write review to temp file
cat > /tmp/review.md <<'EOF'
<!-- code-review -->
# Code Review - PR #XX: [Title]

**Review #[N]** | Updated: [timestamp]

[Rest of review content]
EOF

if [ -n "$COMMENT_ID" ]; then
  # Update existing comment
  gh api "repos/{owner}/{repo}/issues/comments/$COMMENT_ID" \
    --method PATCH \
    --field body="$(cat /tmp/review.md)"
  echo "Updated existing review comment (Review #$REVIEW_COUNT)"
else
  # Create new comment
  gh pr comment <number> --body "$(cat /tmp/review.md)"
  echo "Created new review comment (Review #1)"
fi
```

#### Step 3: Update PR labels

Apply labels based on review outcome:
```bash
# Remove any trigger labels that might be present
gh pr edit <number> --remove-label "ready-for-review" 2>/dev/null || true

# Add review-complete label
gh pr edit <number> --add-label "review-complete"

# Apply outcome label based on review
# If there are CRITICAL ISSUES or significant issues requiring changes:
gh pr edit <number> --add-label "needs-changes"

# If NO critical issues and recommendation is Approve:
gh pr edit <number> --add-label "ready-to-merge"
```

## Review Guidelines

### Be Specific
- "This could be better" (bad)
- "This function should validate input before processing. Add a check for null/undefined at line 45." (good)

### Provide Examples
- Show code examples for fixes
- Link to similar patterns in the codebase
- Reference documentation or best practices

### Explain Impact
- Why does this issue matter?
- What could go wrong?
- How does it affect users/developers?

### Be Constructive
- Focus on the code, not the person
- Phrase as questions when appropriate: "Could we use X instead of Y here?"
- Acknowledge good work

### Prioritize Ruthlessly
- Don't nitpick minor style issues if critical bugs exist
- Focus on what actually matters
- Save suggestions for when critical issues are addressed

## Example Invocation

User: "Review PR 30"

You should:
1. Fetch PR 30 details
2. Read all modified files completely
3. Perform systematic analysis
4. Write comprehensive review
5. **POST REVIEW TO GITHUB** (critical - do not skip!)
6. Report summary to user confirming review was posted

Remember: The goal is to improve code quality while being respectful and constructive. Every review should make the codebase better and help the developer grow. **Reviews are only useful if they're on GitHub where the PR author can see them.**
