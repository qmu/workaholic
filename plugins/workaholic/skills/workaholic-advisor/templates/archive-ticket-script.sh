#!/bin/bash
# Archive a ticket to the branch-specific archive folder

set -e

TICKET="$1"

if [ -z "$TICKET" ]; then
    echo "Usage: archive.sh <ticket-path>"
    echo "Example: archive.sh doc/tickets/20260115-feature.md"
    exit 1
fi

if [ ! -f "$TICKET" ]; then
    echo "Error: Ticket not found: $TICKET"
    exit 1
fi

BRANCH=$(git branch --show-current)
ARCHIVE_DIR="doc/tickets/archive/${BRANCH}"

mkdir -p "$ARCHIVE_DIR"
mv "$TICKET" "$ARCHIVE_DIR/"

echo "Archived to ${ARCHIVE_DIR}/$(basename "$TICKET")"
