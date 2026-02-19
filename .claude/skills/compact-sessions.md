---
name: compact-sessions
description: Check all running autonomous implementation sessions and compact any that have reached context limits. Use when asked to 'compact sessions', 'check sessions for compact', or 'compact all tmux sessions'.
---

# Compact Sessions Skill

Check all running autonomous implementation sessions in tmux and automatically compact any that have reached context limits, then resume their work.

## How to Use

The user will ask you to check or compact sessions. You should:

1. List all tmux sessions matching the `issue-*` pattern
2. For each session, check if the associated PR has been merged or closed
3. Kill any sessions whose PRs are already merged or closed
4. For remaining sessions, capture the pane output
5. Check if output indicates context limit reached
6. If compact needed, send `/compact` command and resume
7. Report summary of killed and compacted sessions

## When to Use This Skill

Use this skill when:
- User asks to "compact sessions"
- User says "check sessions for compact"
- User requests "compact all tmux sessions"

**Do NOT use this skill when:**
- No tmux sessions are running
- User wants to compact the current session (just run `/compact` directly)

## Detection Logic

Look for these indicators in tmux pane output:

**Primary indicators**:
- `Context limit reached`
- `Context low`

```bash
tmux capture-pane -t "issue-XX" -p -S -100 | grep -iE "context (limit|low)"
```

## Compact Process

### Phase 1: List Running Sessions

```bash
tmux ls 2>/dev/null | grep "issue-" | cut -d: -f1
```

### Phase 2: Check PR Status and Kill Completed Sessions

For each session, check if the associated PR has been merged or closed:

```bash
PR_STATUS=$(gh pr list --state all \
  --json headRefName,state | jq -r '.[] | select(.headRefName == "issue-44") | .state')

if [ "$PR_STATUS" = "MERGED" ] || [ "$PR_STATUS" = "CLOSED" ]; then
  tmux kill-session -t "issue-44"
  echo "Killed issue-44 (PR $PR_STATUS)"
fi
```

### Phase 3: Check Remaining Sessions for Context Warning

```bash
OUTPUT=$(tmux capture-pane -t "issue-XX" -p -S -100)
if echo "$OUTPUT" | grep -qiE "context (limit|low)"; then
  echo "issue-XX needs compacting"
fi
```

### Phase 4: Compact Sessions That Need It

```bash
# Send /compact text (without Enter)
tmux send-keys -t "issue-XX" "/compact"

# Wait briefly, then send Enter
sleep 1
tmux send-keys -t "issue-XX" Enter

# Wait for compact to complete
sleep 5

# Send resume text (without Enter)
tmux send-keys -t "issue-XX" "keep going"

# Wait briefly, then send Enter
sleep 1
tmux send-keys -t "issue-XX" Enter
```

### Phase 5: Verify All Compacted Sessions Are Running

```bash
sleep 3
for SESSION in $COMPACTED_SESSIONS; do
  OUTPUT=$(tmux capture-pane -t "$SESSION" -p | tail -10)
  if echo "$OUTPUT" | grep -qE "(claude|>|Read|Edit|Bash)"; then
    echo "$SESSION: Running"
  else
    echo "$SESSION: WARNING - May not be running, check manually"
  fi
done
```

### Phase 6: Report Results

```
Compact sessions complete!

Sessions checked: 5

Sessions killed (PR completed): 2
  - issue-44: PR #123 MERGED
  - issue-46: PR #125 CLOSED

Sessions compacted: 1
  - issue-47: Compacted and resumed

Sessions OK (no action needed): 2
  - issue-45
  - issue-48
```

## Handling Special Cases

### Session is Actively Working
- The context warning won't appear until Claude responds
- Safe to skip - check again later

### Session Has Exited
- Skip this session - it's not running Claude
- Inform user: "issue-XX: Claude not running"

### No Tmux Available
- Inform user: "No tmux sessions available"

## Best Practices

### DO
1. Check all sessions systematically
2. Wait between commands (give Claude time to process)
3. Always send "keep going" after compact
4. Report clear summary

### DON'T
1. Don't interrupt actively working sessions unnecessarily
2. Don't send commands too fast
3. Don't forget to resume after compact

## Success Criteria

A successful compact-sessions run should:
- Find all running issue-* tmux sessions
- Check PR status for each session's branch
- Kill sessions whose PRs are merged or closed
- Check remaining sessions for context warnings
- Compact only sessions that need it
- Resume compacted sessions with "keep going"
- Verify all compacted sessions are actively running
- Report clear summary
