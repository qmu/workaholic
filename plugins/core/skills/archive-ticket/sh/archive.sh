#!/bin/bash
# Complete commit workflow: archive ticket, commit, and update ticket frontmatter
# Single script handles everything after user approves implementation

set -e

TICKET="$1"
COMMIT_MSG="$2"
REPO_URL="$3"
DESCRIPTION="$4"
shift 4 2>/dev/null || true
FILES=("$@")

if [ -z "$TICKET" ] || [ -z "$COMMIT_MSG" ]; then
    echo "Usage: archive.sh <ticket-path> <commit-message> <repo-url> [description] [files...]"
    echo "Example: archive.sh .workaholic/tickets/todo/20260115-feature.md 'Add new feature' https://github.com/org/repo 'Enables authentication' src/foo.ts"
    exit 1
fi

if [ ! -f "$TICKET" ]; then
    echo "Error: Ticket not found: $TICKET"
    exit 1
fi

BRANCH=$(git branch --show-current)

if [ -z "$BRANCH" ]; then
    echo "Error: Cannot archive ticket: not on a named branch."
    echo "       Please checkout a branch first (e.g., git checkout -b feature-branch)"
    exit 1
fi

# Find tickets root (parent of todo/, icebox/, or archive/)
TICKET_DIR=$(dirname "$TICKET")
TICKETS_ROOT=$(echo "$TICKET_DIR" | sed 's|/todo$||; s|/icebox$||')
ARCHIVE_DIR="${TICKETS_ROOT}/archive/${BRANCH}"
TICKET_FILENAME=$(basename "$TICKET")

# Step 1: Determine category based on commit message verb
CATEGORY="Changed"
case "$COMMIT_MSG" in
    Add*|Create*|Implement*|Introduce*)
        CATEGORY="Added"
        ;;
    Remove*|Delete*)
        CATEGORY="Removed"
        ;;
esac

# Step 2: Move ticket to archive
echo "==> Archiving ticket..."
mkdir -p "$ARCHIVE_DIR"
mv "$TICKET" "$ARCHIVE_DIR/"
ARCHIVED_TICKET="${ARCHIVE_DIR}/${TICKET_FILENAME}"
echo "    ${ARCHIVED_TICKET}"

# Step 3: Stage all changes and commit
echo "==> Committing..."
git add -A
git commit -m "${COMMIT_MSG}

Co-Authored-By: Claude <noreply@anthropic.com>"

COMMIT_HASH=$(git rev-parse --short HEAD)

# Step 4: Update ticket frontmatter with commit_hash and category
echo "==> Updating ticket frontmatter..."

# Use sed to update frontmatter fields
if grep -q "^commit_hash:" "$ARCHIVED_TICKET"; then
    sed -i.bak "s/^commit_hash:.*/commit_hash: ${COMMIT_HASH}/" "$ARCHIVED_TICKET"
else
    # Insert after effort: line
    sed -i.bak "/^effort:/a\\
commit_hash: ${COMMIT_HASH}" "$ARCHIVED_TICKET"
fi

if grep -q "^category:" "$ARCHIVED_TICKET"; then
    sed -i.bak "s/^category:.*/category: ${CATEGORY}/" "$ARCHIVED_TICKET"
else
    # Insert after commit_hash: line
    sed -i.bak "/^commit_hash:/a\\
category: ${CATEGORY}" "$ARCHIVED_TICKET"
fi

rm -f "${ARCHIVED_TICKET}.bak"

# Step 5: Amend commit to include updated ticket
git add "$ARCHIVED_TICKET"
git commit --amend --no-edit
echo "==> Updated ticket with commit hash and category"

echo ""
echo "Done!"
echo "  Commit: ${COMMIT_HASH}"
echo "  Ticket: ${ARCHIVED_TICKET}"
