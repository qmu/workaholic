#!/bin/sh -eu
# Create or update GitHub PR from story file
# Outputs "PR created: <URL>" or "PR updated: <URL>"

set -eu

BRANCH="${1:-}"
TITLE="${2:-}"

if [ -z "$BRANCH" ] || [ -z "$TITLE" ]; then
    echo "Usage: create-or-update.sh <branch-name> \"<title>\""
    echo "Example: create-or-update.sh feat-20260115-auth \"Add user authentication\""
    exit 1
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

STORY_FILE="${ROOT}/.workaholic/stories/${BRANCH}.md"

if [ ! -f "$STORY_FILE" ]; then
    echo "Error: Story file not found: $STORY_FILE"
    exit 1
fi

# Strip YAML frontmatter using bundled script, write to a PRIVATE per-run temp
# file. A constant, process-global body path is a cross-run data hazard:
# two concurrent /report runs on different repos race between the write and the
# read-back, so one publishes the other's story. mktemp gives each run its own
# file; the EXIT trap removes ONLY what this run created (never a foreign path).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BODY_FILE=$(mktemp "${TMPDIR:-/tmp}/workaholic-pr-body.XXXXXX")
trap 'rm -f "$BODY_FILE"' EXIT
"${SCRIPT_DIR}/strip-frontmatter.sh" "$STORY_FILE" > "$BODY_FILE"

# Bound the body under GitHub's 65,536-char PR-body limit (a large carried
# concern corpus used to hard-stop this script at gh time). Over the limit,
# section 6 is replaced with a link to the committed story file — the ship-time
# extractor reads the file, not the PR body, so extraction is unchanged.
"${SCRIPT_DIR}/shrink-pr-body.sh" "$BODY_FILE" "$BRANCH" >/dev/null

# Check if PR exists
PR_INFO=$(gh pr list --head "$BRANCH" --json number,url --jq '.[0]' 2>/dev/null || echo "")

if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "null" ]; then
    # Create new PR
    URL=$(gh pr create --title "$TITLE" --body-file "$BODY_FILE")
    echo "PR created: $URL"
else
    # Update existing PR via REST API (avoids GraphQL Projects deprecation error)
    NUMBER=$(echo "$PR_INFO" | jq -r '.number')
    URL=$(echo "$PR_INFO" | jq -r '.url')
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
    gh api "repos/${REPO}/pulls/${NUMBER}" --method PATCH \
        -f title="$TITLE" \
        -f body="$(cat "$BODY_FILE")" > /dev/null
    echo "PR updated: $URL"
fi
