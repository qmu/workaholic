#!/bin/sh -eu
# Sweep stray tickets sitting directly at the todo/ root into per-user subdirectories.
#
# For each *.md directly under .workaholic/tickets/todo/ (depth 1 only), route it
# into todo/<author-slug>/ where <author-slug> derives from the ticket's OWN
# `author:` frontmatter -- so another developer's stranded ticket lands in THEIR
# subdirectory, not the current user's. Falls back to the current user's slug when
# the author field is missing or unparseable (routing strays into the current
# user's queue would re-create the multi-developer leak this feature removes).
#
# Every move is git-staged immediately (old and new paths), matching the discipline
# promote-icebox.sh and archive.sh follow, so no dangling unstaged deletions remain.
#
# NEVER moves a ticket to the icebox -- moving a ticket to icebox is a developer
# decision, never automatic. This sweep only relocates sideways within todo/.
#
# Output: JSON summary of moves, e.g.
#   {"moved": 2, "moves": [{"from": "...", "to": "..."}, ...]}

set -eu

SCRIPT_DIR=$(dirname "$0")
SLUG_SCRIPT="${SCRIPT_DIR}/../../../../workaholic/skills/gather/scripts/user-slug.sh"
TODO_ROOT=".workaholic/tickets/todo"

DEFAULT_SLUG=$(sh "$SLUG_SCRIPT")

moves=""
count=0

if [ -d "$TODO_ROOT" ]; then
    for ticket in "$TODO_ROOT"/*.md; do
        # Glob stays literal when nothing matches; skip the non-file placeholder.
        [ -f "$ticket" ] || continue

        author=$(sed -n 's/^author:[[:space:]]*//p' "$ticket" | head -n 1)
        if [ -n "$author" ]; then
            slug=$(sh "$SLUG_SCRIPT" "$author")
        else
            slug="$DEFAULT_SLUG"
        fi
        # Guard against an empty slug (author present but all-invalid) -> current user.
        if [ -z "$slug" ]; then
            slug="$DEFAULT_SLUG"
        fi

        dest_dir="${TODO_ROOT}/${slug}"
        mkdir -p "$dest_dir"
        filename=$(basename "$ticket")
        dest="${dest_dir}/${filename}"

        mv "$ticket" "$dest"
        # Stage the new path, and the old path's deletion only when it was tracked.
        # A stray may be untracked (freshly created, never committed); `git add` on a
        # never-tracked, now-missing path is fatal, so guard it on index membership.
        git add "$dest" 2>/dev/null || true
        if git ls-files --error-unmatch "$ticket" >/dev/null 2>&1; then
            git add "$ticket" 2>/dev/null || true
        fi

        if [ -n "$moves" ]; then
            moves="${moves},"
        fi
        moves="${moves}{\"from\":\"${ticket}\",\"to\":\"${dest}\"}"
        count=$((count + 1))
    done
fi

printf '{"moved": %d, "moves": [%s]}\n' "$count" "$moves"
