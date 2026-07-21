#!/bin/sh -eu
# Summarize the ACTIVE missions that are the current user's business (read-only).
#
# ROLE NOTE (2026-07-22): the `/mission summary` command mode this powered is
# retired — the bare /mission view now renders the developer-centric partition
# from list.sh's `relation` field. This script stays as the canonical statement
# of the shared assignee gate ("not somebody else's") that the monitor skill's
# Scope section and the mission lens reference, and as the business-set reader
# for programmatic callers.
#
# That means "not somebody else's", NOT "matches my email exactly". Two readings of
# "assigned to me" were possible and this is the one that matches what the summary is
# for: an UNASSIGNED mission is unclaimed work, which is closer to the developer's
# business than a mission explicitly assigned to a colleague. So:
#
#   - assignee == my `git config user.email`  -> reported (mine, listed FIRST)
#   - assignee absent or empty                -> reported as unassigned (claimable)
#   - assignee == someone else                -> excluded (that gate works as intended)
#
# Previously this required an exact email match. `fm_field` returns "" for an absent
# field, and "" matches no email that could ever exist, so an unassigned mission was
# skipped for EVERYBODY -- not just for the developer running the command. `list.sh`
# still reported it, which is what made the gap silent rather than loud. It was not one
# stale file: missions keep arriving unassigned because create.sh's self-assignment
# default is not the only way a mission.md comes into existence.
#
# Absent and empty behave identically -- `fm_field` already collapses them and the
# schema draws no distinction, so neither does this.
#
# Only `active` missions are reported. Progress is computed on demand via progress.sh
# and the next step via next-acceptance.sh (never a stored number). Creates nothing.
#
# Usage: summary.sh
# Output: JSON array [{slug, title, checked, total, next, assignee, path}];
#         the caller's own missions first, then unassigned ones, each sorted by slug.
#         `assignee` is "" for an unassigned mission -- the payload carries the fact so
#         both consumers (commands/mission.md and hooks/mission-lens.sh) read it from
#         one place instead of each re-deriving it from frontmatter.
#         [] when no active mission is the current user's business.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT=".workaholic/missions"

EMAIL=$(git config user.email 2>/dev/null || true)

if [ ! -d "$ROOT" ] || [ -z "$EMAIL" ]; then
    echo '[]'
    exit 0
fi

# Heal any legacy flat layout first so active missions surface under active/. summary.sh
# enumerates this repo's active missions from the cwd-relative tree, so it migrates that
# same tree.
. "${SCRIPT_DIR}/lib/resolve.sh"
missions_migrate_layout ".workaholic"

# JSON-escape a value (backslash and double-quote only; titles are plain text).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read a frontmatter field's value ("" when absent).
fm_field() {
    grep -m1 "^$2:" "$1" 2>/dev/null | sed -e "s/^$2:[ \t]*//" || true
}

DIRS=$(find "$ROOT/active" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort || true)

OUT="["
FIRST=1

# Two passes rather than one, so a developer with real assigned work sees it first and
# unassigned missions never crowd it out. Within each pass $DIRS is already slug-sorted.
for pass in mine unassigned; do
    for d in $DIRS; do
        f="$d/mission.md"
        [ -f "$f" ] || continue
        [ "$(fm_field "$f" status)" = "active" ] || continue

        assignee=$(fm_field "$f" assignee)
        case "$pass" in
            mine)
                # $EMAIL is non-empty (guarded above), so an unassigned mission can
                # never fall through this branch by matching "".
                [ "$assignee" = "$EMAIL" ] || continue
                ;;
            unassigned)
                # Absent and empty are the same thing here, deliberately.
                [ -z "$assignee" ] || continue
                ;;
        esac

        slug=$(basename "$d")
        title=$(json_escape "$(fm_field "$f" title)")
        prog=$(sh "${SCRIPT_DIR}/progress.sh" "$f")
        checked=$(printf '%s' "$prog" | sed -e 's/.*"checked": *//' -e 's/[,}].*//')
        total=$(printf '%s' "$prog" | sed -e 's/.*"total": *//' -e 's/[,}].*//')
        next=$(json_escape "$(sh "${SCRIPT_DIR}/next-acceptance.sh" "$f")")
        [ "$FIRST" -eq 1 ] || OUT="${OUT},"
        FIRST=0
        OUT="${OUT}{\"slug\":\"${slug}\",\"title\":\"${title}\",\"checked\":${checked},\"total\":${total},\"next\":\"${next}\",\"assignee\":\"$(json_escape "$assignee")\",\"path\":\"${f}\"}"
    done
done
OUT="${OUT}]"
printf '%s\n' "$OUT"
