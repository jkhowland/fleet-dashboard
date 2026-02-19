---
name: batch-evaluate-issues
description: Batch process all open GitHub issues through the evaluate-issue skill with automatic context management. Use when asked to 'evaluate all issues', 'triage all issues', or 'batch evaluate issues'.
---

# Batch Evaluate Issues Skill

Batch process all open GitHub issues through the evaluate-issue skill with automatic context management. This skill handles large backlogs by processing issues in batches with compaction between batches.

## When to Use This Skill

Use this skill when:
- User asks to "evaluate all issues" or "evaluate all open issues"
- User says "triage all issues" or "batch triage issues"
- User wants to clean up the issue backlog
- User asks "evaluate P3 issues" (filtered evaluation)
- User requests "dry run: evaluate all issues" (preview mode)

**Do NOT use this skill when:**
- User wants to evaluate a single specific issue (use evaluate-issue skill)
- User is triaging only 1-2 issues manually

## Configuration

The skill supports the following configuration options:

```typescript
interface BatchConfig {
  batchSize: number;           // Issues per batch (default: 5)
  compactEvery: number;        // Batches between compactions (default: 2)
  dryRun: boolean;             // Preview mode without changes (default: false)
  filters?: {
    excludeLabels?: string[];  // Skip issues with these labels
    includeLabels?: string[];  // Only process issues with these labels
  };
}
```

## Processing Flow

```
Phase 1: Discovery
  |-- Fetch all open issues
  |-- Apply filters (labels, etc.)
  |-- Exclude protected issues
  +-- Calculate total batches needed

Phase 2: Batch Loop
  |-- For each batch:
  |     |-- Select next N issues
  |     |-- Launch evaluate-issue tasks in parallel
  |     |-- Wait for batch completion
  |     |-- Collect results
  |     +-- Run /compact if needed (every N batches)
  +-- Continue until all issues processed

Phase 3: Reporting
  |-- Generate summary of actions taken
  |-- Report issues closed
  |-- Report metadata updates
  +-- Output final statistics
```

## Phase 1: Issue Discovery

### Step 1: Fetch All Open Issues

```bash
# Get all open issues with relevant fields
gh issue list --state open --limit 500 --json number,title,labels,createdAt,updatedAt,assignees
```

### Step 2: Filter Issues

**Automatic Exclusions** (always applied):
- Issues with `do-not-evaluate`, `do-not-close`, `protected`, or `in-progress` labels

### Step 3: Calculate Batches

```bash
TOTAL_ISSUES=<count of filtered issues>
BATCH_SIZE=5
TOTAL_BATCHES=$((($TOTAL_ISSUES + $BATCH_SIZE - 1) / $BATCH_SIZE))

echo "Will process $TOTAL_ISSUES issues in $TOTAL_BATCHES batches"
```

## Phase 2: Batch Processing

### Batch Processing Loop

For each batch:

1. **Select Next Batch** - Get next N issues from the queue
2. **Launch Parallel Tasks** - Use Task tool for evaluate-issue on each
3. **Collect Results** - Track outcomes (closed/updated/unchanged/flagged/error)
4. **Context Compaction** - Run `/compact` every N batches

## Phase 3: Reporting

### Final Summary Format

```markdown
## Batch Issue Evaluation Complete

**Statistics**:
- Total issues evaluated: 47
- Batches processed: 10 (5 issues per batch)

**Results Summary**:
| Category | Count | Issues |
|----------|-------|--------|
| Closed | 8 | #10, #23, ... |
| Updated | 12 | #15, #28, ... |
| Unchanged | 25 | #22, #30, ... |
| Flagged for review | 2 | #31, #189 |
| Errors | 0 | - |

### Closed Issues (8)
| Issue | Title | Reason |
|-------|-------|--------|
| #10 | Fix login bug | Duplicate of #5 |
...
```

## Dry-Run Mode

When `dryRun: true`, the skill evaluates issues but does NOT take any actions. Useful for previewing what would happen.

Detect dry-run from user request:
- "dry run: evaluate all issues"
- "preview evaluate issues"

## Safety Features

### Protected Issues

These issues are NEVER processed:
- Issues with `do-not-evaluate`, `do-not-close`, `protected`, or `in-progress` labels

### Rate Limiting

If GitHub API rate limiting is detected:
1. Report the rate limit status
2. Wait for rate limit reset
3. Continue from where processing stopped

## Example Workflows

### Basic: Evaluate All Open Issues

```
User: "Evaluate all open issues"

Claude:
1. Fetches all open issues
2. Filters out protected issues
3. Creates batches of 5 issues
4. Processes each batch with evaluate-issue
5. Runs /compact every 2 batches
6. Reports final summary
```

### Filtered: Evaluate P3 Issues Only

```
User: "Evaluate all P3 issues"

Claude:
1. Fetches issues with P3 label
2. Filters out protected issues
3. Processes all batches
4. Reports summary for P3 issues only
```

## Success Criteria

A successful batch evaluation should result in:
- All issues processed without context exhaustion
- Clear progress tracking throughout
- Comprehensive final report
- No false closures (protected issues respected)
- Actionable flagged issues list for human review
