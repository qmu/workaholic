#!/bin/sh -eu
# Derive a mission slug from a title: lowercase, every run of non-[a-z0-9]
# collapsed to a single hyphen, leading/trailing hyphens trimmed.
#
# This is the single source of the mission slug rule. create.sh derives the
# mission directory name here, and the /mission worktree flow derives the
# worktree directory name here too, so `.worktrees/<slug>` always matches the
# mission's slug.
#
# Usage: slug.sh "<title>"
# Output: the slug on stdout (empty when the title contains no [a-z0-9]).

set -eu

TITLE="${1:-}"
printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | tr -s '-' | sed -e 's/^-//' -e 's/-$//'
