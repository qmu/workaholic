#!/bin/sh -eu
# Complete archive workflow: move ticket, commit via commit skill, update frontmatter

set -eu

TICKET="$1"
COMMIT_MSG="$2"
REPO_URL="$3"
MOTIVATION="${4:-}"
UX_CHANGE="${5:-None}"
ARCH_CHANGE="${6:-None}"
shift 6 2>/dev/null || true

if [ -z "$TICKET" ] || [ -z "$COMMIT_MSG" ]; then
    echo "Usage: archive.sh <ticket-path> <commit-message> <repo-url> [motivation] [ux-change] [arch-change] [files...]"
    exit 1
fi

if [ ! -f "$TICKET" ]; then
    echo "Error: Ticket not found: $TICKET"
    exit 1
fi

BRANCH=$(git branch --show-current)

if [ -z "$BRANCH" ]; then
    echo "Error: Cannot archive ticket: not on a named branch."
    exit 1
fi

TICKET_DIR=$(dirname "$TICKET")
TICKETS_ROOT=$(echo "$TICKET_DIR" | sed 's|/todo$||; s|/icebox$||')
ARCHIVE_DIR="${TICKETS_ROOT}/archive/${BRANCH}"
TICKET_FILENAME=$(basename "$TICKET")

CATEGORY="Changed"
case "$COMMIT_MSG" in
    Add*|Create*|Implement*|Introduce*) CATEGORY="Added" ;;
    Remove*|Delete*) CATEGORY="Removed" ;;
esac

echo "==> Archiving ticket..."
mkdir -p "$ARCHIVE_DIR"
mv "$TICKET" "$ARCHIVE_DIR/"
ARCHIVED_TICKET="${ARCHIVE_DIR}/${TICKET_FILENAME}"
echo "    ${ARCHIVED_TICKET}"

# Stage all changes including the archived ticket
echo "==> Staging changes..."
git add -A

# Delegate to commit skill (with --skip-staging since we already staged)
SCRIPT_DIR=$(dirname "$0")
COMMIT_SCRIPT="${SCRIPT_DIR}/../../commit/sh/commit.sh"

bash "$COMMIT_SCRIPT" --skip-staging "$COMMIT_MSG" "$MOTIVATION" "$UX_CHANGE" "$ARCH_CHANGE"

COMMIT_HASH=$(git rev-parse --short HEAD)

echo "==> Updating ticket frontmatter..."
UPDATE_SCRIPT="${SCRIPT_DIR}/../../update-ticket-frontmatter/sh/update.sh"
bash "$UPDATE_SCRIPT" "$ARCHIVED_TICKET" "commit_hash" "$COMMIT_HASH"
bash "$UPDATE_SCRIPT" "$ARCHIVED_TICKET" "category" "$CATEGORY"

git add "$ARCHIVED_TICKET"
git commit --amend --no-edit
echo "==> Updated ticket with commit hash and category"

echo ""
echo "Archive complete!"
echo "  Commit: ${COMMIT_HASH}"
echo "  Ticket: ${ARCHIVED_TICKET}"
