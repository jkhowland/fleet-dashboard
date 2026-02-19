---
name: submit-pr
description: Create a PR and run the full review loop (review, implement all feedback, review again). Use when asked to 'submit PR', 'create and review PR', or 'ship this'.
---

# Submit PR Skill

Create a pull request and run a complete review cycle to ensure high-quality code before human review.

## How to Use

The user will ask to submit their work. This skill orchestrates:

1. **Create PR** - Create a well-formatted PR using the `create-pr` skill
2. **Review Loop** - Run the complete review cycle using the `review-loop` skill

## Process

### Phase 1: Create the Pull Request

Use the `create-pr` skill:

```
Invoke the create-pr skill
```

This will:
- Run tests
- Create a well-formatted PR with summary and test plan
- Link to the related issue
- Create the PR via `./scripts/blade-create-pr.sh` (must author as `@thecarvedblades`)
- Return the PR number

**Never bypass this with direct `gh pr create`.**

**Capture the PR number** from the create-pr output for the next phase.

### Phase 2: Run the Review Loop

Use the `review-loop` skill with the PR number:

```
Invoke the review-loop skill for PR #<number>
```

This will:
- Perform comprehensive code review
- Implement ALL feedback (not just critical issues)
- Run a second review to verify improvements
- Report the results

### Phase 3: Report Final Status

Provide a comprehensive summary:

```
## PR Submitted and Reviewed: #<number>

### PR Created
- Title: <title>
- Link: <URL>

### Review Loop Results
- First Review: X critical, X issues, X suggestions
- Implemented: X changes
- Second Review: [Summary]

### Status
[Ready for human review / Needs attention]

The PR has been through two automated reviews with all feedback implemented.
Ready for final human review and merge.
```

## When to Use This Skill

Use this skill when:
- Work is complete and ready to be submitted
- The user says "submit PR", "create PR and review", "ship this"
- You want the full quality pipeline: create -> review -> fix -> review

## What This Skill Does

1. **Quality Gates Before PR**
   - Runs tests via create-pr skill
   - Ensures build passes

2. **PR Creation**
   - Well-formatted title and description
   - Links to related issue
   - Proper labels

3. **Two Review Cycles**
   - First review identifies all issues and suggestions
   - ALL feedback is implemented
   - Second review verifies quality

4. **Ready for Human Review**
   - By the time a human sees the PR, it has been reviewed twice
   - All automated feedback has been addressed
   - Only human judgment items remain

## What This Skill Does NOT Do

- **Does not merge** - Human review is still required
- **Does not skip reviews** - Both reviews always run
- **Does not defer suggestions** - ALL reasonable feedback is implemented

## Example Invocations

**Basic:**
```
User: "Submit this as a PR"
-> Create PR -> Review -> Implement all -> Review again -> Report
```

**Explicit:**
```
User: "Create a PR for this work and run the full review loop"
-> Same process
```

**After completing work:**
```
User: "I'm done with issue 47, ship it"
-> Same process
```

## Integration with Other Skills

This skill orchestrates:
- `create-pr` - For PR creation with tests
- `review-loop` - For the complete review cycle
  - Which in turn uses `code-review` and `implement-review-feedback`

## Prerequisites

Before using this skill:
- Work should be complete and committed
- You should be on a feature branch (not main)
- Related issue should exist (for linking)

## Success Criteria

A successful submit-pr results in:
- Tests passing
- Build succeeding
- PR created with proper formatting
- First review completed
- ALL feedback implemented
- Second review completed
- PR ready for human review
- User informed with PR link and status
