#!/bin/sh -eu
# Prepare a /carry checkpoint. Emits the resumption-ticket path and the
# frontmatter metadata a fresh /drive session needs, plus whether a trip is in
# progress so the skill can also checkpoint the trip's plan.md / event-log.md,
# plus the mission worktrees present so the skill can carry a /monitor run
# (one resumption ticket per in-flight mission, in that mission's own worktree).
#
# The skill authors the resumption ticket's prose from conversation context;
# this script owns only the deterministic parts (dynamic metadata, the
# per-user todo path, trip detection, mission-worktree enumeration) so no
# conditional shell lives in markdown.
#
# Usage: carry-checkpoint.sh <slug> [worktree_path]
#   <slug>          — short kebab-case description for the resumption ticket filename.
#   [worktree_path] — OPTIONAL. When given, the returned ticket_path is scoped
#                     into that worktree's .workaholic/ (the /monitor case: a
#                     mission's resumption ticket lands in its own worktree
#                     queue, where the next /monitor leaf drains it). Omit for
#                     the drive/trip case, which routes to the main-tree queue.
# Output: JSON { created_at, author, filename_timestamp, user_slug, slug,
#                ticket_path, trips_present, trips, missions_present, missions }
#   missions[] = { slug, worktree_path } — one per .worktrees/<slug>/ that
#   checks out its own active mission.md.

set -eu

SLUG="${1:-}"
if [ -z "$SLUG" ]; then
    echo 'usage: carry-checkpoint.sh <slug> [worktree_path]' >&2
    exit 1
fi
WORKTREE="${2:-}"

SCRIPT_DIR=$(dirname "$0")

CREATED_AT=$(date -Iseconds)
AUTHOR=$(git config user.email || true)
[ -n "$AUTHOR" ] || { echo 'git user.email is not set; run: git config user.email you@example.com' >&2; exit 1; }
FILENAME_TS=$(date +%Y%m%d%H%M%S)
USER_SLUG=$(sh "${SCRIPT_DIR}/../../gather/scripts/user-slug.sh")

if [ -n "$WORKTREE" ]; then
    TICKET_PATH="${WORKTREE}/.workaholic/tickets/todo/${USER_SLUG}/${FILENAME_TS}-${SLUG}.md"
else
    TICKET_PATH=".workaholic/tickets/todo/${USER_SLUG}/${FILENAME_TS}-${SLUG}.md"
fi

TRIPS_DIR=".workaholic/trips"
TRIPS_JSON="[]"
TRIPS_PRESENT=false
if [ -d "$TRIPS_DIR" ]; then
    items=""
    for d in "$TRIPS_DIR"/*/; do
        [ -d "$d" ] || continue
        name=$(basename "$d")
        items="${items},\"${name}\""
    done
    if [ -n "$items" ]; then
        TRIPS_JSON="[${items#,}]"
        TRIPS_PRESENT=true
    fi
fi

# A mission worktree is a .worktrees/<slug>/ that checks out its own active
# mission.md (slug.sh keys the worktree dir 1:1 to the mission slug), so the
# basename is the mission slug. This is the /monitor placement: each in-flight
# mission's resumption ticket goes into ITS worktree, not the main tree.
WORKTREES_DIR=".worktrees"
MISSIONS_JSON="[]"
MISSIONS_PRESENT=false
if [ -d "$WORKTREES_DIR" ]; then
    m_items=""
    for d in "$WORKTREES_DIR"/*/; do
        [ -d "$d" ] || continue
        slug=$(basename "$d")
        [ -f "${d}.workaholic/missions/active/${slug}/mission.md" ] || continue
        m_items="${m_items},{\"slug\":\"${slug}\",\"worktree_path\":\"${WORKTREES_DIR}/${slug}\"}"
    done
    if [ -n "$m_items" ]; then
        MISSIONS_JSON="[${m_items#,}]"
        MISSIONS_PRESENT=true
    fi
fi

cat <<EOF
{
  "created_at": "${CREATED_AT}",
  "author": "${AUTHOR}",
  "filename_timestamp": "${FILENAME_TS}",
  "user_slug": "${USER_SLUG}",
  "slug": "${SLUG}",
  "ticket_path": "${TICKET_PATH}",
  "trips_present": ${TRIPS_PRESENT},
  "trips": ${TRIPS_JSON},
  "missions_present": ${MISSIONS_PRESENT},
  "missions": ${MISSIONS_JSON}
}
EOF
