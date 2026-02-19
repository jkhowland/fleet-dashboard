#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-ragnar-hello-agent}"

cd "$(dirname "$0")/.."

# Wait a moment for Claude to render the trust prompt
sleep 2

# Send "1" + Enter to answer "Yes, I trust this folder"
tmux send-keys -t "$SESSION_NAME" "1" C-m || echo "Failed to send keys to $SESSION_NAME"

echo "Sent trust confirmation to session: $SESSION_NAME"
