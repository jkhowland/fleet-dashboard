---
name: review-loop
description: Run a complete code review cycle - review PR, implement all feedback, then review again. Use when asked to 'review and fix PR', 'full review cycle', or 'review loop on PR #XX'.
---

# Review Loop Skill

Run a complete code review cycle: review the PR, implement ALL feedback, then review again to verify the improvements.

## How to Use

The user will provide a PR number. This skill orchestrates:

1. **Code Review** - Comprehensive review using the `code-review` skill
2. **Implement Feedback** - Implement ALL suggestions using the `implement-review-feedback` skill
3. **Second Review** - Verify improvements with another code review

## Process

### Phase 1: Initial Code Review

Use the `code-review` skill to perform a comprehensive review:

```
Invoke the code-review skill for PR #<number>
```

This will:
- Analyze the PR for correctness, quality, testing, performance, and security
- Post a detailed review comment to the PR
- Identify critical issues, issues, and suggestions

### Phase 2: Implement ALL Feedback

Use the `implement-review-feedback` skill:

```
Invoke the implement-review-feedback skill for PR #<number>
```

**IMPORTANT**: The implement-review-feedback skill is configured to implement ALL suggestions by default, not just critical issues. Every suggestion that can be reasonably implemented will be implemented.

This will:
- Parse all feedback from the review
- Implement ALL suggestions (critical, issues, and suggestions)
- Only create issues for items requiring entirely new infrastructure
- Run tests and build
- Push changes
- Wait for CI to pass

### Phase 3: Second Code Review

Use the `code-review` skill again:

```
Invoke the code-review skill for PR #<number>
```

This verifies:
- All previous feedback was addressed
- No new issues were introduced
- The PR is ready for human review

### Phase 4: Report Results

Provide a summary to the user:

```
## Review Loop Complete for PR #<number>

### First Review
- Critical Issues: X
- Issues: X
- Suggestions: X

### Feedback Implemented
- Changes made: X
- Issues created: X (only if truly out of scope)

### Second Review
- [Summary of second review results]
- PR Status: [Ready for human review / Needs attention]

Link: <PR URL>
```

## When to Use This Skill

Use this skill when:
- You want a complete review cycle without manual intervention
- You want to ensure ALL feedback is implemented
- You want a final verification review before human review
- The user asks for "full review", "review and fix", or "review loop"

## What This Skill Does NOT Do

- **Does not merge the PR** - Human review is still required
- **Does not skip suggestions** - ALL reasonable feedback is implemented
- **Does not stop at "approved"** - Even if first review approves, suggestions are still implemented

## Example Invocations

**Basic:**
```
User: "Run the review loop on PR 48"
-> Review PR 48 -> Implement all feedback -> Review again -> Report
```

**After creating PR:**
```
User: "I just created PR 52, run the review loop"
-> Same process
```

**Explicit:**
```
User: "Review PR 47, implement everything, then review again"
-> Same process
```

## Integration with Other Skills

This skill orchestrates:
- `code-review` - For comprehensive PR analysis
- `implement-review-feedback` - For implementing all suggestions

## Success Criteria

A successful review loop results in:
- First review completed and posted
- ALL feedback implemented (not just critical issues)
- Tests passing
- Build succeeding
- Changes pushed
- Second review completed and posted
- PR ready for human review
- User informed of results
