#!/bin/sh -eu
# Promote a ticket from icebox to todo and stage both paths.
# Usage: promote-icebox.sh <icebox-ticket-path>

set -eu

SRC="${1:-}"

if [ -z "$SRC" ]; then
    echo "Usage: promote-icebox.sh <icebox-ticket-path>"
    exit 1
fi

if [ ! -f "$SRC" ]; then
    echo "Error: Ticket not found: $SRC"
    exit 1
fi

FILENAME=$(basename "$SRC")
DEST=".workaholic/tickets/todo/${FILENAME}"

mkdir -p .workaholic/tickets/todo
mv "$SRC" "$DEST"
git add "$SRC" "$DEST"

echo "$DEST"
