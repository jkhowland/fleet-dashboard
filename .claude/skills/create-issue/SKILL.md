---
name: create-issue
description: Create well-structured GitHub issues for autonomous implementation. Use when asked to 'create issue', 'file bug report', 'create feature request', or 'generate issue'.
---

# Create GitHub Issue Skill

Generate comprehensive, well-structured GitHub issues that contain everything needed for autonomous implementation.

## How to Use

The user will provide a request like:
- "Create an issue for [description]"
- "File a bug report for [issue]"
- "Create a feature request for [idea]"

You should:
1. Gather necessary information
2. Determine issue type
3. Generate comprehensive issue content
4. Create the GitHub issue with appropriate labels
5. Report the issue number to user

## Issue Creation Process

### Phase 1: Gather Information

**Ask yourself**:
- What is being requested?
- Is this a bug, feature, test, refactoring, or documentation?
- What problem does this solve?
- What are the acceptance criteria?
- Is there existing context (plan documents, related issues)?

**Search for context**:
```bash
# Check for related issues
gh issue list --search "keyword"

# Check for plan documents
ls plans/*.md | grep -i "keyword"
```

### Phase 2: Determine Issue Type

Choose the appropriate type based on what's being requested:

1. **Bug Fix** - Something is broken or incorrect
2. **Feature** - New functionality to add
3. **Testing** - Add or improve tests
4. **Refactoring** - Improve code structure without changing behavior
5. **Documentation** - Improve docs, comments, or guides
6. **Chore** - Dependency updates, tooling, etc.

### Phase 3: Generate Issue Content

#### Feature Template

```markdown
## Feature Description

[Clear description of the feature to add]

## Problem Statement

**Current State**: [What we have now]

**Pain Point**: [What's difficult or missing]

**User Need**: [Why users need this]

## Proposed Solution

[High-level description of the solution]

### Key Capabilities

1. **[Capability 1]**: [Description]
2. **[Capability 2]**: [Description]

## Technical Approach

**Files to Modify**:
- `src/components/Component.tsx` - [What changes]
- `src/lib/utils.ts` - [What changes]

**Files to Create**:
- `src/features/new-feature.ts` - [Purpose]

## Testing Strategy

- [ ] Unit tests for [component/function]
- [ ] Integration tests for [workflow]
- [ ] Manual testing on iOS simulator

## Success Criteria

- [ ] Feature works as described
- [ ] All tests pass
- [ ] Dark mode supported (if UI)
- [ ] No TypeScript errors

## Acceptance Criteria

- [ ] [Specific criterion 1]
- [ ] [Specific criterion 2]
- [ ] [Specific criterion 3]
```

#### Bug Fix Template

```markdown
## Bug Description

[Clear, concise description of what's wrong]

## Current Behavior

[What happens now - be specific]

**Example**:
```typescript
// Code that demonstrates the bug
```

**Result**: [What you get]

## Expected Behavior

[What should happen instead]

## Root Cause

[Analysis of why this bug exists - if known]

**Location**: `file.ts:123-145`

**Problem**: [Technical explanation]

## Proposed Fix

```typescript
// Suggested fix with code example
```

## Impact Analysis

**Severity**: [Critical/High/Medium/Low]

**Affected Users**: [Who experiences this]

## Steps to Reproduce

1. [Step 1]
2. [Step 2]
3. [Step 3]
4. Observe: [What happens]

## Test Plan

- [ ] Add regression test that would have caught this bug
- [ ] Verify test fails with current code
- [ ] Verify test passes after fix

## Success Criteria

- [ ] Bug is fixed at root cause
- [ ] Regression test added
- [ ] No new issues introduced
- [ ] All existing tests pass
```

#### Testing Template

```markdown
## Testing Goal

[What needs to be tested]

## Current Coverage

[What exists now]

## Proposed Tests

### Unit Tests
- [ ] Test [function/component 1]
- [ ] Test [function/component 2]

### Integration Tests
- [ ] Test [workflow 1]
- [ ] Test [workflow 2]

## Files to Create/Modify

- `__tests__/component.test.tsx` - [New tests]

## Success Criteria

- [ ] All new tests pass
- [ ] Coverage improved
- [ ] Edge cases covered
```

#### Documentation Template

```markdown
## Documentation Goal

[What needs to be documented]

## Current State

[What exists now]

## Proposed Changes

- [Change 1]
- [Change 2]

## Success Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
```

#### Chore Template

```markdown
## Task

[What needs to be done]

## Context

[Why this is needed]

## Steps

- [ ] [Step 1]
- [ ] [Step 2]
```

### Phase 4: Set Issue Metadata

#### GitHub Labels

**Type label** (exactly one): `bug`, `feature`, `testing`, `refactoring`, `documentation`, `chore`

**Other optional labels:**
- `ui` - User interface changes
- `blocked` - Cannot proceed due to dependency
- `security` - Security-related issue

### Phase 5: Create the Issue

```bash
gh issue create \
  --title "[Clear, descriptive title]" \
  --body "$(cat <<'EOF'
[Generated issue content]
EOF
)" \
  --label "feature" \
  --assignee "@me"
```

**Title format**: `[Verb] [specific thing] [context if needed]`

Examples:
- "Add student chat interface"
- "Fix token counting on message send"
- "Add unit tests for auth service"

### Phase 6: Report to User

Provide summary:
- Issue number and link
- Brief summary
- Next steps

**Example**:
```
Created issue #12: Add student chat interface

Link: https://github.com/user/sidekick/issues/12

Next steps:
- Use "issue 12" to start working on it
- Or set up a worktree: "set up worktree for issue 12"
```

## Quality Guidelines

### Title Guidelines

**Bad**: "Fix bug" | **Good**: "Fix token counting on message send"
**Bad**: "Add feature" | **Good**: "Add student chat interface"

### Body Guidelines

- **Be Specific**: Name exact files, functions, components
- **Be Comprehensive**: Include all context, link related work
- **Be Structured**: Use headers, checklists, code blocks
- **Be Actionable**: Clear success criteria, specific steps

### Common Pitfalls

- Vague descriptions without specifics
- Missing context or related links
- No acceptance criteria
- No test plan
- Missing labels on issue creation

## Integration with autonomous-prompt Skill

A well-written issue should contain everything needed for autonomous implementation:

- Clear goal: What needs to be accomplished
- Context: Why this matters, background info
- Acceptance criteria: How to know when done
- Technical details: Files, functions, approach
- Testing strategy: What tests to write
- Success criteria: Definition of done

The autonomous-prompt skill will read the issue and generate a comprehensive implementation prompt automatically.
