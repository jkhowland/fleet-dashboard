---
name: evaluate-issue
description: Evaluate a single GitHub issue for validity, relevance, completeness, and metadata. Use when asked to 'evaluate issue #XX', 'check issue #XX', or 'triage issue #XX'.
---

# Evaluate Issue Skill

Evaluate a single GitHub issue for validity, relevance, completeness, and proper metadata, then take appropriate action (close if invalid, update metadata if needed, or confirm the issue is current).

## How to Use

The user will provide an issue number. You should:

1. Fetch and analyze the issue
2. Check codebase for referenced files/features
3. Evaluate against criteria (validity, completeness, priority, dependencies, metadata)
4. Take appropriate action (close, update, comment, or confirm valid)
5. Report findings

## Evaluation Process

### Phase 1: Fetch Issue Data

```bash
# Get issue details
gh issue view <number> --json number,title,body,state,labels,assignees,comments,createdAt,updatedAt

# Get issue timeline (linked PRs, cross-references)
gh api repos/{owner}/{repo}/issues/<number>/timeline --jq '[.[] | select(.event == "cross-referenced" or .event == "referenced")]'
```

### Phase 2: Codebase Analysis

1. **Extract references from issue**
   - Parse file paths mentioned
   - Extract function names mentioned
   - Identify component names

2. **Search codebase**
   - Check if referenced files exist (use Glob tool)
   - Search for function/component names (use Grep tool)

3. **Check recent activity**
   ```bash
   # Search for keywords in recent PRs
   gh pr list --state merged --search "<keyword>" --limit 20 --json number,title,mergedAt

   # Check recent commits
   git log --oneline --since="3 months ago" --grep="<keyword>" -- .
   ```

### Phase 3: Dependency Analysis

1. **Parse dependencies from issue body**
   - Look for "Depends on #XX" or "Blocked by #XX"

2. **Check dependency status**
   ```bash
   gh issue view <dep_number> --json state,closedAt
   ```

### Phase 4: Metadata Validation

1. **Check labels**
   - Has type label? (bug, feature, testing, etc.)
   - Labels match content?

2. **Check assignee**
   - Is assignee still appropriate?
   - Should someone be assigned?

### Phase 5: Decision & Action

Based on findings, determine the appropriate action.

## Evaluation Criteria

### 1. Validity/Applicability

| Factor | Valid | Invalid |
|--------|-------|---------|
| Referenced files exist | Files found in codebase | Files were deleted/moved |
| Feature not implemented | No matching PRs found | Feature exists (show PR link) |
| Bug not fixed | Bug still reproducible | Bug fixed (show PR link) |
| Not duplicate | Unique issue | Duplicate of #XX |

### 2. Completeness

| Factor | Complete | Incomplete |
|--------|----------|------------|
| Description | Clear problem statement | Vague or missing details |
| Acceptance criteria | Defined success criteria | No criteria specified |
| Technical context | Files/components mentioned | No technical reference |

### 3. Priority Assessment

| Factor | Indicator | Priority Impact |
|--------|-----------|-----------------|
| User impact | Many users affected | Higher priority |
| Severity | Critical bug vs enhancement | Higher for bugs |
| Blocking others | Is dependency for other work | Higher priority |
| Security | Security vulnerability | P0 always |

## Actions

### Action 1: Close with Comment

**When to close:**
- Already implemented (with link to PR/commit)
- Duplicate (with link to original issue)
- No longer applicable (referenced code removed)
- Invalid/unclear after extended period with no response

```bash
gh issue close <number> --comment "$(cat <<'EOF'
Closing this issue because [reason].

[Additional context, links to relevant PRs]

---
*This issue was evaluated by the evaluate-issue skill.*
EOF
)"
```

### Action 2: Update Metadata

```bash
# Add labels
gh issue edit <number> --add-label "blocked"

# Remove labels
gh issue edit <number> --remove-label "P2"
```

### Action 3: Add Comment

**When to comment:**
- Need more information
- Dependencies resolved
- Suggest related issues
- Flag for human review

```bash
gh issue comment <number> --body "$(cat <<'EOF'
[Comment content]

---
*This comment was added by the evaluate-issue skill.*
EOF
)"
```

### Action 4: No Action (Valid)

When the issue is valid and properly configured, report findings without making changes.

## Safety Guardrails

### Never Close Issues That:

1. Have `do-not-close`, `protected`, or `keep-open` labels
2. Have active (open) PRs linked
3. Were updated recently (within 7 days)
4. Have `in-progress` label

### When Uncertain:

1. Add a comment asking for clarification
2. Flag for human review
3. **Don't close** - err on the side of caution

## Output Format

```markdown
## Issue Evaluation: #XX - [Title]

### Status: [Valid | Needs Update | Should Close | Needs Review]

### Findings

**Validity**: [Valid / Invalid / Uncertain]
- [Finding 1]
- [Finding 2]

**Completeness**: [Complete / Partial / Incomplete]
- [Finding 1]

**Priority**: [Accurate / Needs Update]
- Current: [P0-P3 or None]
- Recommended: [P0-P3] (reason)

**Dependencies**: [None / Resolved / Blocked]
- [Finding]

**Metadata**: [Accurate / Needs Update]
- Labels: [Current] -> [Recommended]

### Actions Taken

1. [Action 1]
2. [Action 2]

### Recommendations

- [Any follow-up actions for human review]
```

## Example Workflow

User: "evaluate issue #150"

1. Fetch issue data
2. Extract references (e.g., `src/lib/utils.ts`)
3. Check if file exists
4. Check recent PRs for related work
5. Validate metadata
6. Report findings

## Common Pitfalls

1. **Don't close too aggressively** - When in doubt, leave it open
2. **Don't ignore protection labels** - Always check for do-not-close
3. **Don't skip linked PR check** - Active work might be in progress
4. **Don't assume duplicates** - Similar titles don't mean duplicate
