---
name: component-testing
description: Validate component testing coverage and documentation for new/modified components. Use when reviewing PRs, before creating a PR, or when asked to 'check component tests' or 'validate components'.
---

# Component Testing Skill

Validate that new or modified React Native components meet quality standards for testing.

## Purpose

This skill ensures component quality by:
- Identifying new/modified components in the current branch
- Checking if appropriate tests exist
- Categorizing components and recommending test patterns
- Providing actionable guidance for missing test coverage

## When to Use

Use this skill:
- Before creating a PR that includes component changes
- When reviewing component PRs
- When asked to "check component tests" or "validate component testing"
- As part of the create-pr workflow

## Process

### Phase 1: Detect Changed Components

Identify components that have been added or modified compared to the base branch.

```bash
# Get the base branch (usually staging or main)
BASE_BRANCH="${BASE_BRANCH:-origin/staging}"

# Get list of changed/added component files
CHANGED_COMPONENTS=$(git diff "$BASE_BRANCH" --name-only --diff-filter=ACMR | grep -E '^src/components/.*\.tsx$' | grep -v '__tests__' | grep -v '\.test\.' | grep -v '\.spec\.')

if [ -z "$CHANGED_COMPONENTS" ]; then
  echo "No component changes detected."
  exit 0
fi

echo "Found changed components:"
echo "$CHANGED_COMPONENTS"
```

### Phase 2: Analyze Each Component

For each changed component, perform validation checks.

#### Check for Test File

```bash
for COMPONENT_FILE in $CHANGED_COMPONENTS; do
  BASENAME=$(basename "$COMPONENT_FILE" .tsx)
  DIRNAME=$(dirname "$COMPONENT_FILE")

  # Check common test file locations
  TEST_FOUND=false
  for TEST_PATH in "${DIRNAME}/__tests__/${BASENAME}.test.tsx" "src/components/__tests__/${BASENAME}.test.tsx"; do
    if [ -f "$TEST_PATH" ]; then
      echo "Test found: $TEST_PATH"
      TEST_FOUND=true
      break
    fi
  done

  if [ "$TEST_FOUND" = false ]; then
    echo "Missing test for: $COMPONENT_FILE"
  fi
done
```

#### Check TypeScript Types

```bash
for COMPONENT_FILE in $CHANGED_COMPONENTS; do
  # Check for 'any' type usage (warning)
  ANY_COUNT=$(grep -c ': any' "$COMPONENT_FILE" 2>/dev/null || echo "0")
  if [ "$ANY_COUNT" -gt 0 ]; then
    echo "Warning: $COMPONENT_FILE has $ANY_COUNT 'any' type usage(s)"
  fi
done
```

### Phase 3: Categorize Components

Determine component category based on content analysis:

| Category | Indicators | Test Priority |
|----------|------------|---------------|
| Presentational | No state/hooks | HIGH (easy wins) |
| Interactive | useState, onClick, onChange | MEDIUM-HIGH |
| Form | onSubmit, input, textarea | HIGH (data integrity) |
| Modal/Drawer | isOpen, onClose, Modal | MEDIUM |
| Context-dependent | useContext, Context.Provider | MEDIUM |

### Phase 4: Generate Report

```markdown
## Component Testing Analysis

### Summary
- Components analyzed: X
- With tests: Y
- Missing tests: Z

### Detailed Findings

#### Component: `ComponentName.tsx`
- **Category**: Presentational
- **Test Status**: Missing
- **TypeScript**: No issues
- **Recommendation**: Add unit tests

### Testing Recommendations by Category

#### Presentational Components (Priority: HIGH - Easy wins)
- Test all prop variations
- Verify accessibility attributes
- Check edge cases (empty data, null values)

#### Interactive Components (Priority: MEDIUM-HIGH)
- Use `userEvent` for interactions
- Test state transitions
- Verify callback invocations
```

### Phase 5: Provide Actionable Guidance

For each component missing tests, provide specific test templates:

**Presentational Component Template:**
```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react-native'
import { ComponentName } from '../component-name'

describe('ComponentName', () => {
  it('renders with default props', () => {
    render(<ComponentName />)
    expect(screen.getByText('expected text')).toBeDefined()
  })

  it('handles edge cases gracefully', () => {
    render(<ComponentName data={null} />)
    // Assert appropriate behavior
  })
})
```

**Interactive Component Template:**
```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react-native'
import { ComponentName } from '../component-name'

describe('ComponentName', () => {
  it('updates state on user interaction', () => {
    render(<ComponentName />)

    fireEvent.press(screen.getByRole('button'))

    expect(screen.getByText('Updated')).toBeDefined()
  })

  it('calls onChange callback', () => {
    const onChange = vi.fn()
    render(<ComponentName onChange={onChange} />)

    fireEvent.press(screen.getByRole('button'))

    expect(onChange).toHaveBeenCalled()
  })
})
```

## Integration with Other Skills

### Called by create-pr Skill

The `create-pr` skill invokes this skill during quality validation.

### Standalone Usage

```
User: "Check component tests"
-> Analyze components, generate report, provide guidance

User: "Validate component testing for this PR"
-> Full component analysis against base branch
```

## Success Criteria

A successful component-testing validation should:
- Identify all new/modified components
- Check for corresponding test files
- Categorize components correctly
- Provide specific, actionable test templates
- Not block PRs (warnings only, not errors)
