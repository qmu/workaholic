#!/bin/sh -eu
# Complete commit workflow: archive ticket, commit, and update ticket frontmatter

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

# Build structured commit message
COMMIT_BODY=""
if [ -n "$MOTIVATION" ]; then
    COMMIT_BODY="Motivation: ${MOTIVATION}

"
fi
COMMIT_BODY="${COMMIT_BODY}UX Change: ${UX_CHANGE}

Arch Change: ${ARCH_CHANGE}

Co-Authored-By: Claude <noreply@anthropic.com>"

echo "==> Committing..."
git add -A
git commit -m "${COMMIT_MSG}

${COMMIT_BODY}"

COMMIT_HASH=$(git rev-parse --short HEAD)

echo "==> Updating ticket frontmatter..."
if grep -q "^commit_hash:" "$ARCHIVED_TICKET"; then
    sed -i.bak "s/^commit_hash:.*/commit_hash: ${COMMIT_HASH}/" "$ARCHIVED_TICKET"
else
    sed -i.bak "/^effort:/a\\
commit_hash: ${COMMIT_HASH}" "$ARCHIVED_TICKET"
fi

if grep -q "^category:" "$ARCHIVED_TICKET"; then
    sed -i.bak "s/^category:.*/category: ${CATEGORY}/" "$ARCHIVED_TICKET"
else
    sed -i.bak "/^commit_hash:/a\\
category: ${CATEGORY}" "$ARCHIVED_TICKET"
fi

rm -f "${ARCHIVED_TICKET}.bak"

git add "$ARCHIVED_TICKET"
git commit --amend --no-edit
echo "==> Updated ticket with commit hash and category"

echo ""
echo "Done!"
echo "  Commit: ${COMMIT_HASH}"
echo "  Ticket: ${ARCHIVED_TICKET}"
