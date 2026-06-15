#!/bin/sh -eu
# List the current user's ticket files in the todo queue, one path per line
# (empty output if none). Scoped to .workaholic/tickets/todo/<user>/ so another
# developer's leftover tickets are invisible rather than something to process.

set -eu

SCRIPT_DIR=$(dirname "$0")
USER_SLUG=$(sh "${SCRIPT_DIR}/../../../../core/skills/gather/scripts/user-slug.sh")
DIR=".workaholic/tickets/todo/${USER_SLUG}"

if [ ! -d "$DIR" ]; then
    exit 0
fi

find "$DIR" -maxdepth 1 -name '*.md' -type f | sort
