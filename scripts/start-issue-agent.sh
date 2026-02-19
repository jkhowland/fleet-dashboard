#!/usr/bin/env bash
set -euo pipefail

ISSUE_NUMBER="${1:-}"  # required
if [ -z "$ISSUE_NUMBER" ]; then
  echo "Usage: $0 <issue-number>" >&2
  exit 1
fi

SESSION_NAME="ragnar-hello-agent-$ISSUE_NUMBER"

cd "$(dirname "$0")/.."

# Start Claude in tmux if not already running for this issue
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  # --dangerously-skip-permissions skips the trust/theme prompts so the agent can start working immediately
  tmux new -d -s "$SESSION_NAME" 'claude --dangerously-skip-permissions'
  echo "Started Claude in tmux session: $SESSION_NAME (skip permissions)"
else
  echo "Reusing existing tmux session: $SESSION_NAME"
fi

# Give Claude time to initialize
sleep 2

# Inject the concrete task for this issue
TASK="Implement GitHub issue #$ISSUE_NUMBER using the project .claude skills. Start by running the autonomous-prompt skill for issue #$ISSUE_NUMBER, then execute setup-worktree, create-pr, submit-pr, and review-loop. Stop once the PR is ready for human review; do not merge."

echo "Sending task to $SESSION_NAME: $TASK"
tmux send-keys -t "$SESSION_NAME:0.0" "$TASK" C-m

# Nudge once more to ensure the command is processed
sleep 1
tmux send-keys -t "$SESSION_NAME:0.0" C-m 2>/dev/null || true

echo "Kickoff complete for $SESSION_NAME"

exit 0
