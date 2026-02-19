#!/usr/bin/env bash
set -euo pipefail

SESSION_NAME="${1:-ragnar-hello-agent}"

cd "$(dirname "$0")/.."

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux new -d -s "$SESSION_NAME" 'claude'
fi

echo "Started Claude in tmux session: $SESSION_NAME"
