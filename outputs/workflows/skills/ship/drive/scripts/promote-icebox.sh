#!/bin/sh -eu
# Promote a ticket from icebox to todo and stage both paths.
# Usage: promote-icebox.sh <icebox-ticket-path>
#
# The destination is the FLAT queue (`.workaholic/tickets/todo/`) since P2,
# 2026-08-06: a ticket's owner is its `assignees` field, not its directory. The
# promoter becomes the owner when the ticket names none — promoting is taking the
# work on, and an unowned promotion would otherwise land in a queue nobody is
# holding. A ticket that already names owners keeps them: promotion is a queue
# move, never a reassignment.
#
# It also runs the living migrations first, so a checkout still carrying per-user
# directories or the retired icebox/ tree converges here rather than accumulating a
# mixed tree.
#
# SINCE 2026-08-13 (issue #436) an iceboxed ticket lives at
# `archive/unbranched/<file>.md` carrying `status: icebox`, not in a directory of
# its own — so promotion now CLEARS that field as well as moving the file. Absent
# means queued, so a promoted ticket must carry no status at all; leaving the
# stamp would put a ticket in todo/ that every reader correctly refuses to offer.
# The retired `icebox/<file>.md` path is still accepted as an argument (the living
# migration above converges it first, and this resolves either shape) — the icebox
# survives as a STATE precisely because it is not `abandoned`: an iceboxed ticket
# is deferred and promotable, which is what this script is for.

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
SCRIPT_DIR=$(dirname "$0")
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

sh "${GATHER_SCRIPTS}/migrate-todo-owners.sh" >/dev/null 2>&1 || true
sh "${GATHER_SCRIPTS}/migrate-ticket-states.sh" >/dev/null 2>&1 || true

# The migration may have moved the argument out from under us; follow it.
if [ ! -f "$SRC" ]; then
    MIGRATED=".workaholic/tickets/archive/unbranched/${FILENAME}"
    if [ -f "$MIGRATED" ]; then
        SRC="$MIGRATED"
    else
        echo "Error: Ticket not found after migration: $SRC"
        exit 1
    fi
fi

DEST=".workaholic/tickets/todo/${FILENAME}"

mkdir -p ".workaholic/tickets/todo"

# Stamp the promoter as owner only when the ticket names nobody.
existing=$(sh "${GATHER_SCRIPTS}/read-assignees.sh" "$SRC" 2>/dev/null || true)
if [ -z "$existing" ]; then
    ME=$(git config user.email 2>/dev/null || true)
    if [ -n "$ME" ]; then
        tmp="${SRC}.promote.$$"
        awk -v owner="$ME" '
            NR == 1 { print; if ($0 != "---") { done = 1 } ; next }
            done { print; next }
            !placed && /^author:[ \t]*/ { print; print "assignees: [" owner "]"; placed = 1; next }
            !placed && /^---[ \t]*$/ { print "assignees: [" owner "]"; print; placed = 1; done = 1; next }
            /^---[ \t]*$/ { print; done = 1; next }
            { print }
        ' "$SRC" > "$tmp"
        mv "$tmp" "$SRC"
    fi
fi

# Clear the end state: absent means queued, and a promoted ticket IS queued.
if grep -qE '^status:' "$SRC" 2>/dev/null; then
    tmp="${SRC}.state.$$"
    awk '
        NR == 1 { print; if ($0 != "---") { fin = 1 }; next }
        fin { print; next }
        /^---[ \t]*$/ { fin = 1; print; next }
        /^status:[ \t]*/ { next }
        { print }
    ' "$SRC" > "$tmp" && mv "$tmp" "$SRC" || rm -f "$tmp" 2>/dev/null || true
fi

mv "$SRC" "$DEST"
git add "$SRC" "$DEST"

echo "$DEST"
