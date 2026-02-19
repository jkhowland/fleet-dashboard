#!/usr/bin/env bash
set -euo pipefail

# Create a PR authored by the Blades GitHub account using the Blade Github Personal Access Token.
# Assumes:
# - You are on a feature branch like issue-XX
# - Work is committed

BRANCH="$(git branch --show-current)"
ISSUE_NUM="$(echo "$BRANCH" | grep -o '[0-9]\+' | head -1 || true)"

if [ -z "$BRANCH" ]; then
  echo "Error: could not determine current branch" >&2
  exit 1
fi

# Default target branch is master for ragnar-hello
TARGET_BRANCH="${TARGET_BRANCH:-master}"

# Fetch Blade GitHub token from 1Password (Ragnar vault)
BLADE_TOKEN="$(op item get "Blade Github Personal Access Token" --vault "Ragnar" --field "credential" --reveal)"

# Ensure branch is pushed
if ! git ls-remote --heads origin "$BRANCH" | grep -q "$BRANCH"; then
  echo "Branch not found on origin. Pushing $BRANCH..."
  git push -u origin "$BRANCH"
fi

# Build a generic title if we have an issue number
if [ -n "$ISSUE_NUM" ]; then
  # Try to use issue title to make a nicer PR title
  ISSUE_TITLE="$(GITHUB_TOKEN="$BLADE_TOKEN" gh issue view "$ISSUE_NUM" --json title --jq .title 2>/dev/null || echo "Work for issue $ISSUE_NUM")"
  PR_TITLE="$ISSUE_TITLE (#$ISSUE_NUM)"
else
  PR_TITLE="Work on $BRANCH"
fi

# Create PR as the Blades account
GITHUB_TOKEN="$BLADE_TOKEN" gh pr create \
  --base "$TARGET_BRANCH" \
  --title "$PR_TITLE" \
  --label "ready-for-review" \
  --body "$(cat << 'EOF_PR'
## Summary

- [What was implemented]

## Changes

- [File changes]

## Testing

- [Test instructions]

## Related

- Closes #XX

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF_PR
)"

# Show PR URL
PR_URL="$(GITHUB_TOKEN="$BLADE_TOKEN" gh pr view --json url --jq '.url')"
echo "PR created as Blades: $PR_URL"
