#!/bin/sh -eu
# List every ticket file in the todo queue, one path per line (empty output if the
# queue is empty). THE WHOLE QUEUE — not one developer's slice of it.
#
# It was user-scoped until 2026-08-06 (P2), because a ticket's owner was its
# directory: `.workaholic/tickets/todo/<user-slug>/`. That made reading the queue
# depend on the reader's identity, which produced the failure this file's exit
# codes used to exist to signal — with no `git config user.email` there was no
# directory to open, so an unreadable queue and an empty one were the same
# observation. Ownership is a FIELD now (`assignees`, read through
# `gather/scripts/owners.sh`), so the queue is readable by anyone and WHOSE a
# ticket is becomes a separate question the caller asks per ticket, through
# `gather/scripts/owns.sh`. The identity-unresolved exit is gone with the
# dependency that created it: this script can no longer fail that way.
#
#   exit 0, no output  -- the queue is empty. A normal, healthy answer, and now
#                         genuinely the only meaning an empty output can carry.
#   exit non-zero      -- the queue could not be read at all.
#
# BOTH LAYOUTS ARE READ (`-maxdepth 2`), deliberately and indefinitely. The living
# migration (`gather/scripts/migrate-todo-owners.sh`) converges `todo/<user>/X.md`
# to `todo/X.md` at the write seams, but a reader that only saw the flat form would
# make the migration a GATE — a checkout that had not yet run one would report an
# empty queue, which is the exact class of failure being removed. Tolerating both
# costs one directory level of `find` and makes the migration purely convergent.

set -eu

DIR=".workaholic/tickets/todo"

if [ ! -d "$DIR" ]; then
    exit 0
fi

find "$DIR" -maxdepth 2 -name '*.md' -type f | sort
