---
name: setup-worktree
description: Set up a git worktree with isolated Expo and Supabase environment. Use for ANY worktree creation - both issue-based ('set up worktree for issue #XX', 'implement XX') and ad-hoc ('set up worktree for [name]'). NEVER use manual git worktree commands.
---

# Setup Worktree Skill

Set up a complete development environment in a git worktree with isolated Expo dev server and local Supabase instance.

**IMPORTANT**: This skill handles ALL worktree creation. Per CLAUDE.md, NEVER use manual `git worktree` commands.

## Worktree Types

| Type | Branch Pattern | Directory Pattern | Labels | Mode |
|------|---------------|-------------------|--------|------|
| **Issue-based** | `issue-XX` | `../sidekick-issue-XX` | `in-progress` | Autonomous (default) or Local |
| **Ad-hoc** | user-provided | `../sidekick-{name}` | None | Local only |

**Trigger phrases**:
- Issue-based: "set up worktree for issue #XX", "implement XX", "start working on issue XX"
- Ad-hoc: "set up worktree for [name]", "create worktree called [name]"

## Port Isolation for Parallel Development

Each worktree gets isolated ports to enable parallel autonomous development without cross-contamination.

**Port assignment formulas**:
- Expo dev server: `19000 + (issue_number % 100)`
- Supabase API: `54330 + issue_number`
- Supabase DB: `54320 + issue_number`

| Worktree | Expo Port | Supabase API | Supabase DB |
|----------|-----------|--------------|-------------|
| main (Sidekick) | 19000 | 54330 | 54320 |
| issue-1 | 19001 | 54331 | 54321 |
| issue-42 | 19042 | 54372 | 54362 |
| issue-101 | 19001 | 54431 | 54421 |
| ad-hoc | 19000 | 54330 | 54320 |

**Benefits**:
- Multiple autonomous implementations can run simultaneously
- No port conflicts between worktrees
- Each Claude Code instance connects to its own app and database

**Ad-hoc worktrees**: Use default ports (no isolation) since they're typically for local manual work.

## Branch Base

**Default**: Branch from `staging` (staging-first workflow). The skill fast-forwards staging to main before branching.

**Exception**: For hotfixes, explicitly request: "set up worktree for issue XX from main".

## Setup Modes

| Mode | When | Creates Tmux? | Opens VS Code? |
|------|------|---------------|----------------|
| **Autonomous** (default) | Issue-based without "local" keyword | Yes | No |
| **Local Development** | Explicit "local/manual" OR ad-hoc worktrees | No | Yes |

**Local mode triggers**: "for local development", "I'll work on it myself", "(local)", "manual work"

## CRITICAL: Scope of This Skill

After setup completes, **STOP**. Do NOT:
- cd into the new worktree in the current session
- Read or modify files in the new worktree
- Start implementing changes

Implementation happens in the background tmux session (autonomous) or by the user (local).

## Setup Process

### Phase 1: Validate

**For issue-based worktrees**:
```bash
gh issue view <number> --json number,title,state,labels,assignees
git worktree list | grep -i "issue-<number>"
```
- Verify issue is OPEN
- Warn if `blocked` or `in-progress` by someone else
- Check no existing worktree

**For ad-hoc worktrees**:
- Derive or ask for branch name from user's description
- Check no existing worktree with that name

### Phase 2: Create Worktree

```bash
# From main worktree
cd $HOME/Desktop/AI/learning/Sidekick

# Fast-forward staging to main
git fetch origin && git checkout staging && git merge origin/main --ff-only && git push origin staging && git checkout main

# Create worktree from staging
git worktree add ../sidekick-issue-<number> -b issue-<number> origin/staging

# Verify
git worktree list
```

### Phase 3: Install Dependencies

```bash
cd ../sidekick-issue-<number>
npm install
```

### Phase 4: Configure Port Isolation (Issue-Based Only)

**CRITICAL**: This phase enables parallel development by giving each worktree its own ports.

**Step 4a: Calculate ports**
```bash
ISSUE_NUM=<number>
EXPO_PORT=$((19000 + (ISSUE_NUM % 100)))
SUPABASE_API_PORT=$((54330 + ISSUE_NUM))
SUPABASE_DB_PORT=$((54320 + ISSUE_NUM))

echo "Expo port: ${EXPO_PORT}"
echo "Supabase API port: ${SUPABASE_API_PORT}"
echo "Supabase DB port: ${SUPABASE_DB_PORT}"
```

**Step 4b: Create .env.local with ports**
```bash
cd ../sidekick-issue-<number>
cat > .env.local << EOF
# Worktree-specific configuration for issue-${ISSUE_NUM}
EXPO_PORT=${EXPO_PORT}

# Local Supabase (isolated per worktree)
EXPO_PUBLIC_SUPABASE_URL=http://localhost:${SUPABASE_API_PORT}
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-local-anon-key

# Supabase ports for this worktree
SUPABASE_API_PORT=${SUPABASE_API_PORT}
SUPABASE_DB_PORT=${SUPABASE_DB_PORT}
EOF

echo "Created .env.local with isolated ports"
```

**Step 4c: Start local Supabase**
```bash
cd ../sidekick-issue-<number>
# Start Supabase with custom ports
npx supabase start --api-port ${SUPABASE_API_PORT} --db-port ${SUPABASE_DB_PORT}

echo "Supabase started on API port ${SUPABASE_API_PORT}, DB port ${SUPABASE_DB_PORT}"
```

**Ad-hoc worktrees**: Skip this phase (use default ports).

### Phase 5: Add In-Progress Label (Issue-Based Only)

```bash
gh issue edit <number> --add-label "in-progress"
```

### Phase 6: Push Branch

```bash
git push -u origin issue-<number>
```

### Phase 7: Start Session

**Autonomous Mode** (default for issue-based):

**CRITICAL**: Each step below must be a SEPARATE Bash tool call. Do NOT combine them.

**Step 7a: Check for existing session**
```bash
if tmux has-session -t "issue-<number>" 2>/dev/null; then
  echo "Session exists, attaching..."
  tmux attach-session -t "issue-<number>"
  exit 0
fi
```

**Step 7b: Create session and start dev server in background**
```bash
ISSUE_NUM=<number>
EXPO_PORT=$((19000 + (ISSUE_NUM % 100)))
WORKTREE_DIR="$HOME/Desktop/AI/learning/sidekick-issue-${ISSUE_NUM}"
LOG_FILE="/tmp/expo-server-issue-${ISSUE_NUM}.log"

# Create tmux session
tmux new-session -d -s "issue-${ISSUE_NUM}" -c "${WORKTREE_DIR}"

# Start Expo dev server as background process
tmux send-keys -t "issue-${ISSUE_NUM}" "npx expo start --port ${EXPO_PORT} > ${LOG_FILE} 2>&1 &" Enter
tmux send-keys -t "issue-${ISSUE_NUM}" "echo 'Expo dev server starting on port ${EXPO_PORT}... (logs: ${LOG_FILE})'" Enter
```

**Step 7c: Wait for dev server to be ready (SEPARATE call)**
```bash
ISSUE_NUM=<number>
EXPO_PORT=$((19000 + (ISSUE_NUM % 100)))
LOG_FILE="/tmp/expo-server-issue-${ISSUE_NUM}.log"

# Wait for server to be ready
for i in {1..30}; do
  if grep -q "Metro waiting" "${LOG_FILE}" 2>/dev/null || nc -z localhost ${EXPO_PORT} 2>/dev/null; then
    echo "Expo dev server ready on port ${EXPO_PORT}"
    break
  fi
  sleep 1
done
```

**Step 7d: Start Claude (SEPARATE call)**
```bash
tmux send-keys -t "issue-<number>" "claude --dangerously-skip-permissions" Enter
```

**Step 7e: Wait for Claude to initialize (SEPARATE call)**
```bash
sleep 8
```

**Step 7f: Send the autonomous prompt text (WITHOUT Enter)**
```bash
tmux send-keys -t "issue-<number>" "Implement issue <number>. Read 'gh issue view <number>' for requirements. Use pnpm. Work autonomously: implement the fix, write tests, commit, push, create a PR targeting staging, then run code review loop (review code, implement ALL feedback, review again). Include 'Closes #<number>' in PR description. STOP after code review loop completes - do NOT merge. Report PR URL when done."
```

**Step 7g: Wait, then send Enter (SEPARATE call)**
```bash
sleep 2
tmux send-keys -t "issue-<number>" Enter
```

**Step 7h: Verify command was submitted (SEPARATE call)**
```bash
sleep 3
tmux capture-pane -t "issue-<number>" -p | tail -15
```

Check the output:
- If you see Claude responding/working → Success
- If you see the prompt text still in the input line → Enter wasn't received, retry step 7g
- If you see errors → Report to user

**Local Development Mode** (or if tmux unavailable):
```bash
code $HOME/Desktop/AI/learning/sidekick-issue-<number>
```

### Phase 8: Confirm and Stop

Report to user:
- Worktree location and branch name
- Setup completed (deps installed, .env.local created)
- **Expo port assigned** (e.g., "Expo dev server port: 19042")
- **Supabase ports assigned** (API, DB)
- **Dev server running** in background
- Issue labeled (if issue-based)
- Branch pushed
- Session status (tmux running OR opened in VS Code)
- How to attach: `issue <number>` or `tmux attach -t issue-<number>`

**Then STOP**. Do not continue working.

## Special Cases

| Case | Detection | Action |
|------|-----------|--------|
| Worktree exists | `git worktree list \| grep issue-XX` | Offer: use existing, recreate, or cancel |
| Issue in-progress | Has `in-progress` label + different assignee | Warn and ask for confirmation |
| Issue blocked | Has `blocked` label | Warn and allow user to decide |
| Issue closed | `state=CLOSED` | Stop - cannot set up for closed issue |
| Branch exists remotely | Push fails | Set up tracking: `git branch --set-upstream-to=origin/issue-XX` |
| npm install fails | Error during setup | Retry once, then report error |
| Tmux unavailable | Command not found | Fall back to local mode (open VS Code) |
| Tmux session exists | `tmux has-session` returns 0 | Attach to existing session |
| Docker not installed | Command not found | Warn user to install Docker (required for Supabase local) |

## Best Practices

**Always**:
- Validate issue is open before creating worktree
- Follow naming: `issue-XX` branch, `../sidekick-issue-XX` directory
- Use npm (never pnpm or yarn)
- Run `npm install`
- Add `in-progress` label (issue-based)
- Push branch immediately
- Start local Supabase for issue-based worktrees

**Never**:
- Skip dependency installation
- Skip .env.local creation
- Create worktrees in main directory
- Use pnpm or yarn commands

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `fatal: 'issue-XX' is already checked out` | Worktree exists | `git worktree remove ../sidekick-issue-XX` |
| `npm: command not found` | npm not installed | Install Node.js |
| Expo port in use | Another worktree on same port | Check port calculation, kill conflicting process |
| Supabase start fails | Port conflict or Docker not running | Check Docker, run `npx supabase start` |
| Prompt typed but not submitted | Enter not received by tmux | Retry: `tmux send-keys -t "issue-XX" Enter` |

## Success Criteria

**All modes**:
- [ ] Worktree created with correct naming
- [ ] `npm install` completed
- [ ] Branch pushed to origin
- [ ] Issue labeled `in-progress` (if issue-based)

**Issue-based worktrees (additional)**:
- [ ] `.env.local` created with unique ports
- [ ] Expo port follows formula: 19000 + (issue_number % 100)
- [ ] Local Supabase started on isolated ports

**Autonomous mode (additional)**:
- [ ] Expo dev server started in background on assigned port
- [ ] Dev server logs available at `/tmp/expo-server-issue-XX.log`
- [ ] Tmux session created
- [ ] Claude running with autonomous-prompt sent
- [ ] User can attach with `issue <number>`

**Local mode (additional)**:
- [ ] Worktree opened in VS Code
- [ ] User informed of next steps

## Example Invocations

| Request | Mode | Branch Base |
|---------|------|-------------|
| "Set up worktree for issue 44" | Autonomous | staging |
| "Implement 44" | Autonomous | staging |
| "Set up worktree for issue 44 for local development" | Local | staging |
| "Set up worktree for spike-auth" | Local (ad-hoc) | staging |
| "Set up worktree for issue 44 from main" | Per request | main (hotfix) |

## Related Documentation

- Project conventions: @CLAUDE.md
- Merge PR skill: @.claude/skills/merge-pr.md
