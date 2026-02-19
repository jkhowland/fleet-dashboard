---
name: merge-pr
description: Merge GitHub pull requests following project conventions with cleanup. Use when asked to 'merge PR #XX', 'merge pull request', or 'merge this PR'.
---

# Merge Pull Request Skill

Merge GitHub pull requests with full cleanup of worktrees, tmux sessions, and branches.

## Staging-First Workflow

This project uses a staging-first workflow.

**All merges perform full cleanup.** If fixes are needed after merging to staging, create a new issue and branch rather than returning to an already-merged branch.

| PR Target | Cleanup Worktree? | Kill Tmux? | Delete Branch? |
|-----------|-------------------|------------|----------------|
| `staging` | YES | YES | YES |
| `main` | YES | YES | YES |

## When to Use

**Use when:**
- User asks to "merge PR #XX"
- User says "merge pull request XX"
- User requests "merge this PR"

**Do NOT use when:**
- PR is not approved or has failing checks (ask first)
- User wants to just view or review the PR

## Merge Process

### Phase 1: Validate PR

```bash
# Get PR info including target branch
gh pr view <number> --json number,title,state,mergeable,reviewDecision,statusCheckRollup,headRefName,baseRefName

# Check target branch
TARGET=$(gh pr view <number> --json baseRefName --jq '.baseRefName')
```

**Check before proceeding:**
- `state` is "OPEN" (if MERGED, inform user)
- `mergeable` is "MERGEABLE" or "UNKNOWN" (if CONFLICTING, stop)
- If checks failing or not approved, ask user to confirm

### Phase 2: Pre-Merge Cleanup

**2a. Kill tmux session (if exists):**
```bash
BRANCH_NAME="issue-42"  # from headRefName
ISSUE_NUM=$(echo "$BRANCH_NAME" | grep -o '[0-9]\+')

if tmux has-session -t "issue-${ISSUE_NUM}" 2>/dev/null; then
  tmux kill-session -t "issue-${ISSUE_NUM}"
  echo "Killed tmux session: issue-${ISSUE_NUM}"
fi
```

**2b. Remove worktree (if exists):**
```bash
# Check worktrees
git worktree list

# If worktree exists for branch, remove it
git worktree remove ../sidekick-issue-${ISSUE_NUM}
```

**CRITICAL**: If worktree removal fails due to uncommitted changes:
- **ABORT the merge immediately**
- Inform user: "Worktree has uncommitted changes. Please clean up first."
- **NEVER use `--force`** - uncommitted changes may be important

### Phase 3: Merge PR

```bash
gh pr merge <number> --merge --delete-branch
```

**Project conventions:**
- `--merge`: Preserves commit history (NEVER use `--squash`)
- `--delete-branch`: Cleans up branch after merge

### Phase 4: Post-Merge Actions

**4a. Update local branch:**
```bash
git fetch origin
git log origin/<target-branch> --oneline -3  # Verify merge commit
```

**4b. Remove in-progress label (if targeting main and branch follows issue-XX pattern):**
```bash
gh issue edit <issue-number> --remove-label "in-progress"
```

### Phase 5: Confirm to User

**For Staging Merges:**
```
Merged PR #42: [Title] -> staging

Steps completed:
1. Killed tmux session: issue-42
2. Removed worktree: ../sidekick-issue-42
3. Merged PR using --merge --delete-branch

Next steps:
1. Wait for deployment
2. Verify on staging
3. When ready: use `promote-to-main` skill
```

**For Main Merges:**
```
Merged PR #42: [Title] -> main

Steps completed:
1. Killed tmux session: issue-42
2. Removed worktree: ../sidekick-issue-42
3. Merged PR using --merge --delete-branch
4. Removed in-progress label from issue #42

Production deployment will start automatically.
```

## Special Cases

**No worktree exists**: Skip worktree cleanup, proceed with merge.

**No tmux session exists**: Skip tmux cleanup, proceed with merge.

**PR already merged**: Check `state` field. Inform user and offer to clean up remaining worktree if exists.

**Merge conflicts**: Stop and inform user conflicts must be resolved by PR author first.

**Failing CI**: Ask user to confirm before proceeding with merge.

**In worktree being merged**: Stop. User must `cd` to main worktree first.

**Uncommitted changes in worktree**: ABORT merge. User must commit/discard changes first. NEVER force remove.

## Examples

### Staging Merge

```bash
# 1. Check PR
gh pr view 42 --json state,mergeable,headRefName,baseRefName
# baseRefName=staging, state=OPEN, mergeable=MERGEABLE

# 2. Kill tmux session
tmux kill-session -t "issue-42" 2>/dev/null || true

# 3. Remove worktree
git worktree remove ../sidekick-issue-42

# 4. Merge with branch deletion
gh pr merge 42 --merge --delete-branch

# 5. Update local
git fetch origin staging
git log origin/staging --oneline -3
```

## Best Practices

**DO:**
- Always use `--merge --delete-branch`
- Always clean up worktrees and tmux sessions
- Always pull/fetch after merging
- Verify PR status before merging

**DON'T:**
- Force remove worktrees with uncommitted changes
- Merge without checking status
- Skip cleanup steps
- Use `--squash` (we preserve commit history)
- Return to merged branches for fixes (create new issue instead)
