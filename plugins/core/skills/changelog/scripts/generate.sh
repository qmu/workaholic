#!/bin/bash
# Generate changelog entries from archived tickets
# Outputs formatted markdown grouped by category

set -e

BRANCH="$1"
REPO_URL="$2"

if [ -z "$BRANCH" ] || [ -z "$REPO_URL" ]; then
    echo "Usage: generate.sh <branch-name> <repo-url>"
    echo "Example: generate.sh feat-20260115-auth https://github.com/org/repo"
    exit 1
fi

ARCHIVE_DIR=".workaholic/tickets/archive/${BRANCH}"

if [ ! -d "$ARCHIVE_DIR" ]; then
    echo "No archived tickets found for branch: $BRANCH"
    exit 0
fi

# Arrays to hold entries by category
declare -a ADDED=()
declare -a CHANGED=()
declare -a REMOVED=()

# Process each ticket
for ticket in "$ARCHIVE_DIR"/*.md; do
    [ -f "$ticket" ] || continue

    # Extract frontmatter values
    commit_hash=$(grep "^commit_hash:" "$ticket" | sed 's/commit_hash: *//')
    category=$(grep "^category:" "$ticket" | sed 's/category: *//')

    # Extract title (first H1 heading)
    title=$(grep "^# " "$ticket" | head -1 | sed 's/^# //')

    # Get full commit hash for URL
    full_hash=$(git rev-parse "$commit_hash" 2>/dev/null || echo "$commit_hash")

    # Format entry
    entry="- ${title} ([${commit_hash}](${REPO_URL}/commit/${full_hash})) - [ticket](${ticket})"

    # Add to appropriate category
    case "$category" in
        Added)
            ADDED+=("$entry")
            ;;
        Removed)
            REMOVED+=("$entry")
            ;;
        *)
            CHANGED+=("$entry")
            ;;
    esac
done

# Output formatted markdown
if [ ${#ADDED[@]} -gt 0 ]; then
    echo "### Added"
    echo ""
    for entry in "${ADDED[@]}"; do
        echo "$entry"
    done
    echo ""
fi

if [ ${#CHANGED[@]} -gt 0 ]; then
    echo "### Changed"
    echo ""
    for entry in "${CHANGED[@]}"; do
        echo "$entry"
    done
    echo ""
fi

if [ ${#REMOVED[@]} -gt 0 ]; then
    echo "### Removed"
    echo ""
    for entry in "${REMOVED[@]}"; do
        echo "$entry"
    done
    echo ""
fi
