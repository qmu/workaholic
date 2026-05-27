#!/bin/sh -eu
# List ticket files in the todo queue, one path per line (empty output if none).

set -eu

DIR=".workaholic/tickets/todo"

if [ ! -d "$DIR" ]; then
    exit 0
fi

find "$DIR" -maxdepth 1 -name '*.md' -type f | sort
