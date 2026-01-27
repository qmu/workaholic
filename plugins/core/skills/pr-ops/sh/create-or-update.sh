#!/bin/sh -eu
# Create or update GitHub PR from story file
# Outputs "PR created: <URL>" or "PR updated: <URL>"

set -eu

BRANCH="$1"
TITLE="$2"

if [ -z "$BRANCH" ] || [ -z "$TITLE" ]; then
    echo "Usage: create-or-update.sh <branch-name> \"<title>\""
    echo "Example: create-or-update.sh feat-20260115-auth \"Add user authentication\""
    exit 1
fi

STORY_FILE=".workaholic/stories/${BRANCH}.md"

if [ ! -f "$STORY_FILE" ]; then
    echo "Error: Story file not found: $STORY_FILE"
    exit 1
fi

# Strip YAML frontmatter and write to temp file
sed '1,/^---$/d;1,/^---$/d' "$STORY_FILE" > /tmp/pr-body.md

# Check if PR exists
PR_INFO=$(gh pr list --head "$BRANCH" --json number,url --jq '.[0]' 2>/dev/null || echo "")

if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "null" ]; then
    # Create new PR
    URL=$(gh pr create --title "$TITLE" --body-file /tmp/pr-body.md)
    echo "PR created: $URL"
else
    # Update existing PR via REST API (avoids GraphQL Projects deprecation error)
    NUMBER=$(echo "$PR_INFO" | jq -r '.number')
    URL=$(echo "$PR_INFO" | jq -r '.url')
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
    gh api "repos/${REPO}/pulls/${NUMBER}" --method PATCH \
        -f title="$TITLE" \
        -f body="$(cat /tmp/pr-body.md)" > /dev/null
    echo "PR updated: $URL"
fi
