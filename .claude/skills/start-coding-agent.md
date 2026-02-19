# Skill: start-coding-agent

## Goal

Start a Claude Code agent in this repo for a specific **GitHub issue** and move it past the **"Do you trust this folder?"** + initial prompts so its ready to work autonomously.

## Usage

From the repo root (`~/Projects/ragnar-hello`), run:

```bash
./scripts/start-issue-agent.sh <issue-number>
```

Examples:

```bash
./scripts/start-issue-agent.sh 1
./scripts/start-issue-agent.sh 2
```

This will:

1. Start a tmux session named `ragnar-hello-agent-<issue-number>` running `claude` in this repo.
2. Wait a few seconds for Claude Code to render its initial UI.
3. Send `1` + Enter to answer **"Yes, I trust this folder"**.
4. Send an extra Enter to accept the default theme/mode.
5. Inject the task:

   > Implement GitHub issue #`<issue-number>` using the Sidekick skills in `.claude` (`setup-worktree`, `autonomous-prompt`, `create-pr`, `review-loop`, etc.).

After this, the agent is ready to:
- Use `setup-worktree` to create an isolated branch/worktree for the issue.
- Use `autonomous-prompt` to plan and implement changes.
- Use `create-pr` / `review-loop` to open and refine a PR.

You can observe progress with:

```bash
cd ~/Projects/ragnar-hello
tmux attach -t ragnar-hello-agent-<issue-number>
```

Replace `<issue-number>` with the GitHub issue number you started.
