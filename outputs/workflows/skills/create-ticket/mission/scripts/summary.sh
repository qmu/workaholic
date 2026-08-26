#!/bin/sh -eu
# Summarize the ACTIVE missions that are the current user's business (read-only).
#
# ROLE NOTE (2026-07-22): the `/mission summary` command mode this powered is
# retired — the bare /mission view now renders the developer-centric partition
# from list.sh's `relation` field. This script stays as the canonical statement
# of the shared assignee gate ("not somebody else's") that /drive's survey
# answers to, and as the business-set reader for programmatic callers.
#
# That means "not somebody else's", NOT "matches my email exactly". Two readings of
# "assigned to me" were possible and this is the one that matches what the summary is
# for: an UNASSIGNED mission is unclaimed work, which is closer to the developer's
# business than a mission explicitly owned by a colleague. So:
#
#   - I am among the mission's owners       -> reported (mine, listed FIRST)
#   - the mission has no owners             -> reported as unassigned (claimable)
#   - owned only by someone else            -> excluded (that gate works as intended)
#
# OWNERSHIP IS DERIVED, not read from the mission's own frontmatter (2026-07-24): a
# mission's owners come from its own plural `assignees`, with a legacy
# fallback to the mission's own `assignee` — resolved through gather/owners.sh, the
# single oracle. A mission may be co-owned, so it can have several owners; "mine"
# means the caller is one of them. An unowned mission (no assignees and no
# legacy assignee) is unclaimed work, surfaced to everyone as claimable.
#
# Only IN-FLIGHT missions are reported — the active area's working set, which since
# the draft gate's retirement (2026-07-31, docs/loop-engineering-workflow.md K1) is
# the single status `active`. The retired `draft`/`approved` spellings are tolerated
# for a mission the living migration has not rewritten yet; the ended states live in
# archive/ and never appear here.
# Progress is computed on demand via progress.sh
# and the next step via next-acceptance.sh (never a stored number). Creates nothing.
#
# Usage: summary.sh
# Output: JSON array [{slug, title, checked, total, next, assignee, path}];
#         the caller's own missions first, then unassigned ones, each sorted by slug.
#         `assignee` is "" for an unassigned mission -- the payload carries the fact so
#         its consumers (commands/mission.md and moderate's closable-missions step)
#         read it from one place instead of each re-deriving it from frontmatter.
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
        # In-flight = the one open state (the retired `draft`/`approved` spellings
        # tolerated pre-migration). Everything else has ended and lives in archive/.
        case "$(fm_field "$f" status)" in
            active|draft|approved) : ;;
            *) continue ;;
        esac

        # Owners (the mission's own assignees, legacy singular fallback) via the
        # single oracle. `assignee` in the output is the first owner, aliased for callers.
        owners=$(sh "${SCRIPT_DIR}/../../gather/scripts//owners.sh" "$f" 2>/dev/null || true)
        assignee=$(printf '%s\n' "$owners" | sed -n '1p')
        case "$pass" in
            mine)
                # $EMAIL is non-empty (guarded above). Caller must be AMONG the owners.
                printf '%s\n' "$owners" | grep -Fxq "$EMAIL" || continue
                ;;
            unassigned)
                # No owners at all — unclaimed work, surfaced to everyone.
                [ -z "$owners" ] || continue
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
