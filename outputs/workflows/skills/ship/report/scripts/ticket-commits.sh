#!/bin/sh -eu
# Derive, for each archived ticket on a branch, the commit that implemented it.
#
# Why derive instead of reading the ticket's `commit_hash` frontmatter: a commit cannot
# carry its own hash. `archive.sh` used to stamp the hash and then `git commit --amend`
# the ticket into that same commit — which changed the hash, leaving the recorded value
# pointing at an orphaned, never-pushed commit (every /report link built from it 404s).
# No stamping order fixes that (re-stamping after the amend regresses forever), so the
# hash is not stored at all. Git is the single source of truth.
#
# The commit that ADDED `.workaholic/tickets/archive/<branch>/<ticket>.md` IS the commit
# that archived — i.e. implemented — that ticket. `--diff-filter=A` picks exactly that one
# and ignores later edits to the file (a /report or /carry touch-up must not re-point the
# link). Because it is read from git, tickets carrying a stale `commit_hash` from the old
# buggy archive script resolve correctly too — no backfill migration needed.
#
# Usage: ticket-commits.sh [branch]        (default: current branch)
# Output: [{"ticket": "<basename>.md", "commit": "<short-hash>"}, ...]
#         `commit` is "" when the ticket is not committed yet — reported rather than
#         dropped, so a caller sees the gap instead of silently losing a ticket.

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
DIR=".workaholic/tickets/archive/${BRANCH}"

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

printf '['
first=1
if [ -d "$DIR" ]; then
    for f in "$DIR"/*.md; do
        [ -e "$f" ] || continue
        hash=$(git log --diff-filter=A --format=%h -- "$f" 2>/dev/null | head -1 || true)
        [ "$first" -eq 1 ] || printf ','
        first=0
        printf '\n  {"ticket": "%s", "commit": "%s"}' \
            "$(json_escape "$(basename "$f")")" "$(json_escape "$hash")"
    done
fi
[ "$first" -eq 1 ] || printf '\n'
printf ']\n'
