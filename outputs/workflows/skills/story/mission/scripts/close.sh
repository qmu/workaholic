#!/bin/sh -eu
# End a mission: flip its `status` frontmatter to achieved, abandoned or carried,
# record the transition as an append-only ## Changelog line (via append-changelog.sh,
# the single changelog writer -- the history survives the close), and move the
# mission dir from active/ into archive/. This is the ONLY sanctioned way to end
# a mission -- never hand-edit `status:` or `mv` a mission dir.
#
# It closes the ONE in-flight state (2026-07-31 --
# docs/loop-engineering-workflow.md K1): a mission that ran and a proposal nobody
# ever picked up both end here, because since the draft gate's retirement they are
# the same state. An unwanted proposal is closed `abandoned` (or carried into a
# successor); there is no separate "reject a proposal" operation, because ending a
# mission is one concept and it already has a word. The retired `draft`/`approved`
# spellings still close normally -- close.sh keys on the AREA, not the word.
#
# THE THREE OUTCOMES. `achieved` and `abandoned` were the whole set, which left no
# honest answer for the common verdict "most of this landed, the rest is still worth
# doing": `achieved` lies to a progress model whose entire claim is that progress is
# COMPUTED from unchecked ## Acceptance items and never hand-set, and `abandoned` is
# false as well. `carried` is that third outcome -- the mission is done AS FRAMED, and
# its remainder becomes a successor mission that inherits what was not finished.
#
#   carried REQUIRES an EXISTING successor (--successor <slug>). Without one it is
#   rejected like any other invalid input: a carry with nowhere to carry to is just an
#   abandon that avoids saying so.
#
# `--successor-title` IS REFUSED -- THE TICKET FLOOR (mission/SKILL.md, *Granularity ->
# The ticket floor*; decided by 20260804173624, enforced by 20260804173625). It used to
# MINT a successor from the predecessor's unmet items, which produced a mission with zero
# tickets every single time -- a violation by construction, and the one that reached
# `main` on 2026-08-04. The route is not gated, it is GONE: this script is bookkeeping,
# and emitting a ticket set needs a planning input the unmet acceptance items do not
# contain. The sanctioned route is to create the successor through the ordinary mission
# path -- that interrogation is what produces its ticket set -- and then carry into it.
# The rejected alternatives and the accepted cost are in reference/schema.md, *The ticket
# floor*; the refusal here names the alternative rather than only the rule.
#
# WHAT THE SUCCESSOR INHERITS, and why:
#   - The UNCHECKED ## Acceptance items, verbatim, with their (#<filename>) ticket
#     markers intact, APPENDED to the successor's own list. Checked items stay with the
#     predecessor -- they were achieved THERE, and re-listing them would make the
#     successor's computed progress claim work it did not do. No number is ever carried
#     across; the successor's progress falls out of its own merged list.
#   - NOTHING ELSE. The successor already has its own Goal, its own gate_* fields and
#     possibly its own progress, so a carry appends the remainder and touches nothing
#     else. The retired mint route imported Goal and gate_* because it owned the whole
#     file; with that route gone, "a carry imports the predecessor's framing" is no
#     longer true of any path. A genuine re-framing was always a NEW mission rather than
#     a carry, which is what keeps this script independent of the interrogation flow.
#
# LINEAGE IS RECORDED IN BOTH DIRECTIONS (design/history-structures): the predecessor
# gets a changelog line naming the successor, and the successor records `carried_from`.
# Without both, the archive shows a mission that stopped and a mission that started with
# nothing joining them.
#
# THE WORKTREE IS NOT TOUCHED HERE, and NOTHING tears one down after this script either.
# A worktree is claim-born and ship-torn (docs/loop-engineering-workflow.md I6): claim.sh
# creates it, and ship or release-claim.sh removes it. One still standing at close time is
# an in-flight or stale CLAIM, which list-claims.sh surfaces and a human decides about --
# so closing a mission never doubles as a destructive action. A carry likewise does NOT
# hand a worktree to the successor. The successor has a new slug, and .worktrees/<slug> is
# keyed 1:1 to the unit slug by slug.sh; a successor living in the predecessor's directory
# would break that keying — every consumer that maps a worktree basename to its mission
# (claim teardown, the surveys) would read the wrong unit or none at all.
# The successor gets its own worktree when it is CLAIMED; in-flight state and the port are
# not carried.
#
# Idempotent: closing an already-archived mission with the same status is a
# no-op ({closed: false, reason: "already_closed"}); the changelog append is
# idempotent on its (event, artifact) pair. Re-closing with the OTHER status
# (achieved -> abandoned or back) flips the status and appends its own line,
# preserving the full transition history. A re-run of the same carry is likewise a
# no-op -- the successor already exists and is not rebuilt.
#
# Usage: close.sh <mission-slug-or-file> <achieved|abandoned|carried> [date]
#          [--successor <slug>]
#   date defaults to today (YYYY-MM-DD); pass it explicitly for deterministic tests.
#   --successor-title is still PARSED so it can be refused by name; passing it is an
#   error, never a fallthrough into the positional date.
# Output: JSON {closed, slug, status, path[, successor, successor_path, reason,
#          alternative]}

set -eu

ARG="${1:-}"
TARGET="${2:-}"
shift 2 2>/dev/null || true

# Positional date stays supported (close.sh <slug> <status> [date]); the successor
# flags may follow it in any order.
DATE=""
SUCCESSOR_TITLE=""
SUCCESSOR_SLUG=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --successor-title) SUCCESSOR_TITLE="${2:-}"; shift 2 || true ;;
        --successor) SUCCESSOR_SLUG="${2:-}"; shift 2 || true ;;
        *) [ -n "$DATE" ] || DATE="$1"; shift ;;
    esac
done

if [ -z "$ARG" ] || [ -z "$TARGET" ]; then
    echo '{"closed": false, "reason": "missing_args"}' >&2
    exit 1
fi
case "$TARGET" in
    achieved|abandoned) : ;;
    carried)
        # A carry with nowhere to carry to is an abandon wearing a nicer name.
        if [ -z "$SUCCESSOR_TITLE" ] && [ -z "$SUCCESSOR_SLUG" ]; then
            printf '{"closed": false, "reason": "carried_needs_successor", "alternative": "%s"}\n' \
                "carry into an existing active mission with --successor <slug>; a carry with no successor is an abandon -- close it \`abandoned\` and record the direction as a feedback record" >&2
            exit 1
        fi
        if [ -n "$SUCCESSOR_TITLE" ] && [ -n "$SUCCESSOR_SLUG" ]; then
            echo '{"closed": false, "reason": "carried_needs_one_successor"}' >&2
            exit 1
        fi
        # THE TICKET FLOOR REFUSES `--successor-title` (mission/SKILL.md, *Granularity ->
        # The ticket floor*). A minted successor arrives with zero tickets, so this route
        # violated the floor by construction on every use -- it is how the live violation
        # of 2026-08-04 reached `main`. The refusal was sequenced behind one fix, now
        # landed: the unmet-acceptance inheritance used to live entirely inside the mint
        # branch, so refusing the title while that held would have left no carry route
        # that transfers the remainder -- trading a record defect for a data-loss one.
        # `--successor <slug>` inherits through lib/acceptance.sh since 2026-08-04
        # (ticket 20260804184949), so the refusal costs no carry its payload.
        #
        # The refusal NAMES THE ALTERNATIVE, because a refusal that states only the rule
        # leaves the author retrying the same thing (implementation/observability).
        if [ -n "$SUCCESSOR_TITLE" ]; then
            printf '{"closed": false, "reason": "carried_successor_must_exist", "successor_title": "%s", "alternative": "%s"}\n' \
                "$SUCCESSOR_TITLE" \
                "create the successor through the ordinary mission path first -- its interrogation emits the ticket set the floor requires -- then close with --successor <slug>" >&2
            exit 1
        fi
        ;;
    *) printf '{"closed": false, "reason": "invalid_status", "status": "%s"}\n' "$TARGET" >&2; exit 1 ;;
esac

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
. "${SCRIPT_DIR}/lib/acceptance.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"closed": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

MISSION_DIR=$(dirname "$FILE")
SLUG=$(basename "$MISSION_DIR")
AREA=$(basename "$(dirname "$MISSION_DIR")")
CURRENT=$(grep -m1 '^status:' "$FILE" 2>/dev/null | sed -e 's/^status:[ \t]*//' -e 's/[ \t]*$//' || true)

if [ "$AREA" = "archive" ] && [ "$CURRENT" = "$TARGET" ]; then
    printf '{"closed": false, "reason": "already_closed", "slug": "%s", "status": "%s", "path": "%s"}\n' "$SLUG" "$TARGET" "$FILE"
    exit 0
fi

# --- carried: move the remainder BEFORE archiving the predecessor ----------------
# Order matters. The predecessor is still in active/ here, so its Acceptance list is
# read from a stable path; and if the successor cannot be resolved we exit without
# having half-closed anything.
#
# ONE ROUTE. Minting a successor from a title was the other one until the ticket floor
# refused it above, so `carried` now always names a mission that already exists -- and
# already passed the floor when its own creation published its ticket set.
SUCCESSOR=""
SUCCESSOR_PATH=""
if [ "$TARGET" = "carried" ]; then
    SUCCESSOR_PATH=$(mission_resolve "$ROOT" "$SUCCESSOR_SLUG")
    [ -f "$SUCCESSOR_PATH" ] || {
        printf '{"closed": false, "reason": "successor_not_found", "successor": "%s", "alternative": "%s"}\n' \
            "$SUCCESSOR_SLUG" \
            "create that mission through the ordinary mission path first -- its interrogation emits the ticket set the floor requires -- then re-run this close" >&2
        exit 1
    }
    SUCCESSOR="$SUCCESSOR_SLUG"
    # CARRY INTO AN EXISTING MISSION. Until 2026-08-04 this branch did nothing at
    # all -- it resolved a path above and fell through, so every unmet item was
    # dropped while the operation reported success. The successor already has its
    # own Goal, its own Acceptance list, possibly its own tickets and progress, so
    # this is an APPEND, never the mint route's rebuild: no Goal import, no gate_*
    # import, and the successor's own items are untouched.
    UNMET_F="${SUCCESSOR_PATH}.$$.unmet"
    mission_unchecked_items "$FILE" > "$UNMET_F"
    if [ -s "$UNMET_F" ]; then
        TMP_S="${SUCCESSOR_PATH}.$$.tmp"
        # IDEMPOTENT BY ITEM TEXT. A re-run of the same carry must not duplicate
        # what it already transferred, and the item line (marker included) is the
        # stable identity -- the same key `link-acceptance.sh` and `tick-acceptance.sh`
        # address items by. An item the successor already carries is skipped whether
        # this carry put it there or the successor wrote it itself; either way the
        # board must not gain a second copy.
        awk -v pred="$SLUG" -v unmetfile="$UNMET_F" '
            function load_existing(   line) {
                while ((getline line < FILENAME_SAVE) > 0) {
                    if (line ~ /^## Acceptance$/) { in_a = 1; continue }
                    if (in_a && line ~ /^## /) { in_a = 0; continue }
                    if (in_a && line ~ /^- \[/) have[line] = 1
                }
                close(FILENAME_SAVE)
            }
            BEGIN { FILENAME_SAVE = ARGV[1]; load_existing() }
            # carried_from is many-valued: a mission can absorb more than one
            # predecessor. A bare scalar still reads as one, matching the `mission:`
            # relation convention, so nothing predating this is orphaned.
            NR == 1 && $0 == "---" { in_fm = 1; print; next }
            in_fm && /^carried_from:/ {
                seen_cf = 1
                val = $0; sub(/^carried_from:[ \t]*/, "", val)
                gsub(/^\[|\][ \t]*$/, "", val)
                if (val == "") { print "carried_from: " pred }
                else if (index(", " val ", ", ", " pred ", ") || val == pred) { print }
                else { print "carried_from: [" val ", " pred "]" }
                next
            }
            in_fm && /^---[ \t]*$/ {
                in_fm = 0
                if (!seen_cf) print "carried_from: " pred
                print; next
            }
            in_fm { print; next }
            # Append at the END OF THE ITEM LIST, not the end of the section: the
            # blank line that separates Acceptance from the next heading is held
            # back and re-emitted after the inherited items, so the section keeps
            # the shape it had. Without this the appended items land after the
            # separator and the next heading butts against the last item.
            function flush_items(   u) {
                while ((getline u < unmetfile) > 0) if (!(u in have)) print u
                close(unmetfile)
            }
            function flush_pending(   i) {
                for (i = 1; i <= np; i++) print pend[i]
                np = 0
            }
            /^## Acceptance$/ { print; in_acc = 1; np = 0; next }
            in_acc && /^## / { flush_items(); flush_pending(); in_acc = 0; print; next }
            in_acc && /^[ \t]*$/ { pend[++np] = $0; next }
            in_acc { flush_pending(); print; next }
            { print }
            END { if (in_acc) { flush_items(); flush_pending() } }
        ' "$SUCCESSOR_PATH" > "$TMP_S"
        mv "$TMP_S" "$SUCCESSOR_PATH"
        git add "$SUCCESSOR_PATH" 2>/dev/null || true
    fi
    rm -f "$UNMET_F"
    # The successor's own history records what it absorbed. append-changelog.sh is
    # idempotent on the (event, artifact) pair, so a re-run adds no second line.
    sh "${SCRIPT_DIR}/append-changelog.sh" "$SUCCESSOR_PATH" \
        "remainder carried from ${SLUG}" "mission.md" ${DATE:+"$DATE"} >/dev/null 2>&1 || true
fi

# Flip the status field inside the frontmatter block only (a `status:` in the
# body -- e.g. inside a code fence -- is never touched).
if [ "$CURRENT" != "$TARGET" ]; then
    TMP="${FILE}.$$.tmp"
    awk -v new="$TARGET" '
        NR == 1 && $0 == "---" { in_fm = 1; print; next }
        in_fm && /^---[ \t]*$/ { in_fm = 0; print; next }
        in_fm && /^status:/ { print "status: " new; next }
        { print }
    ' "$FILE" > "$TMP"
    mv "$TMP" "$FILE"
fi

# Record the transition in the append-only changelog (idempotent on the
# (event, artifact) pair; the artifact is the mission file itself). For a carry the
# event names the successor, so the predecessor's own history says where its remainder
# went -- half of the two-way lineage, and the reason this is not optional
# (design/history-structures). Written via append-changelog.sh, the single changelog
# writer; never hand-edited.
EVENT="mission ${TARGET}"
[ "$TARGET" != "carried" ] || EVENT="mission carried into ${SUCCESSOR}"
if [ -n "$DATE" ]; then
    sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "$EVENT" "mission.md" "$DATE" >/dev/null
else
    sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "$EVENT" "mission.md" >/dev/null
fi

# Move the mission into the archive/ area (unless already there). git mv keeps
# history; plain mv + git add covers an untracked mission.
if [ "$AREA" != "archive" ]; then
    MROOT=$(dirname "$MISSION_DIR")
    [ "$AREA" = "active" ] && MROOT=$(dirname "$MROOT")
    DEST="${MROOT}/archive/${SLUG}"
    mkdir -p "${MROOT}/archive"
    # A same-slug dir already in archive/ is a conflicted state a human must
    # resolve -- keep the mission where it is rather than nesting dirs.
    if [ -e "$DEST" ]; then
        printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s", "reason": "archive_slug_conflict"}\n' "$SLUG" "$TARGET" "$FILE"
        exit 0
    fi
    :
    if git mv "$MISSION_DIR" "$DEST" >/dev/null 2>&1; then
        :
    else
        mv "$MISSION_DIR" "$DEST"
        git add -A "$MROOT" >/dev/null 2>&1 || true
    fi
    FILE="${DEST}/mission.md"
fi

# Refresh the OKF bundle indexes so the close commit ships a fresh hierarchy
# (best-effort: an index problem must not block the close).
sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

if [ "$TARGET" = "carried" ]; then
    printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s", "successor": "%s", "successor_path": "%s"}\n' \
        "$SLUG" "$TARGET" "$FILE" "$SUCCESSOR" "$SUCCESSOR_PATH"
else
    printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s"}\n' "$SLUG" "$TARGET" "$FILE"
fi
