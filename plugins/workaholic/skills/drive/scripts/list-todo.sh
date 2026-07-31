#!/bin/sh -eu
# List the current user's ticket files in the todo queue, one path per line
# (empty output if none). Scoped to .workaholic/tickets/todo/<user>/ so another
# developer's leftover tickets are invisible rather than something to process.
#
# TWO EMPTY OUTPUTS THAT ARE NOT THE SAME THING, and the exit code is what tells
# them apart. `user-slug.sh` exits non-zero when `git config user.email` is unset,
# and a caller that discards the status (`$(list-todo.sh) || true`) reads an
# unreadable queue as an EMPTY one -- which is how an unattended runner with no
# configured identity reported a healthy, empty backlog while the queue was full
# (`workaholic:implementation` / observability: a masked failure is worse than a
# loud one). So:
#
#   exit 0, no output  -- the queue directory does not exist: this developer has
#                         nothing queued. A normal, healthy answer.
#   exit 3             -- IDENTITY UNRESOLVED: the queue could not be located at
#                         all, because there is no `git config user.email` to
#                         derive <user> from. Nothing is known about the backlog.
#   exit non-zero, !=3 -- anything else went wrong; equally not an empty queue.
#
# The exit code is the discriminator rather than parsed stderr text: a caller
# needs one machine-readable answer, and a reason word inside a human sentence is
# a parser waiting to drift. stderr still carries the sentence for a person.

set -eu

SCRIPT_DIR=$(dirname "$0")

USER_SLUG=$(sh "${SCRIPT_DIR}/../../gather/scripts/user-slug.sh" 2>/dev/null || true)
if [ -z "$USER_SLUG" ]; then
    echo 'identity_unresolved: git user.email is not set, so the todo queue directory cannot be resolved; run: git config user.email you@example.com' >&2
    exit 3
fi

DIR=".workaholic/tickets/todo/${USER_SLUG}"

if [ ! -d "$DIR" ]; then
    exit 0
fi

find "$DIR" -maxdepth 1 -name '*.md' -type f | sort
