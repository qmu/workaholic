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
# `--successor-title` IS REFUSED (2026-08-04, the ticket floor -- mission/SKILL.md,
# *Granularity -> The ticket floor*). It minted a successor from a title, and a minted
# successor arrives with ZERO tickets, violating the floor by construction: that is
# exactly how the live violation of that date reached main. The refusal names the route
# rather than only the rule, because an author who is told "no" and not "write this
# instead" simply retries the same thing (implementation/observability).
#
# WHAT THE SUCCESSOR INHERITS, and why:
#   - The UNCHECKED ## Acceptance items, verbatim, with their (#<filename>) ticket
#     markers intact. Checked items stay with the predecessor -- they were achieved
#     THERE, and re-listing them would make the successor's computed progress claim
#     work it did not do. No number is ever carried across; the successor's progress
#     falls out of its own list.
#   - NOTHING ELSE. The successor is an existing mission with its own ## Goal, its own
#     gate_* fields and its own items, so a carry APPENDS the remainder and touches no
#     other part of the file. The mint route used to import Goal and gate_* as well --
#     correct while it owned a freshly scaffolded file, and meaningless now that the
#     only successor is one that already says what it is for. A genuine re-framing is a
#     NEW mission created through the normal path, not a carry.
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
# silently SILENCES the mission lens inside that very worktree (the lens reads a worktree
# whose basename names no active mission as a /drive worktree and says nothing at all).
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
#   --successor-title is still PARSED so it can be refused by name rather than falling
#   through as an unrecognised word into the positional date slot.
#   date defaults to today (YYYY-MM-DD); pass it explicitly for deterministic tests.
# Output: JSON {closed, slug, status, path[, successor, successor_path, reason]}

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
            echo '{"closed": false, "reason": "carried_needs_successor", "alternative": "name an existing active mission with --successor <slug>"}' >&2
            exit 1
        fi
        if [ -n "$SUCCESSOR_TITLE" ] && [ -n "$SUCCESSOR_SLUG" ]; then
            echo '{"closed": false, "reason": "carried_needs_one_successor"}' >&2
            exit 1
        fi
        # THE TICKET FLOOR REFUSES `--successor-title` (mission/SKILL.md, *Granularity ->
        # The ticket floor*; the rejected alternatives are in reference/schema.md). A
        # minted successor arrives with zero tickets and violates the floor by
        # construction. The refusal was SEQUENCED behind one fix and that fix has landed:
        # the unmet-acceptance inheritance used to live entirely inside the mint branch,
        # so refusing the title first would have left no carry route that transfers the
        # remainder -- trading a record defect for a data-loss one. Both routes inherited
        # through lib/acceptance.sh as of 2026-08-04, and only the append route remains.
        #
        # The cost is real and accepted: a "this direction continues but nothing suitable
        # exists yet" carry has no one-step path. Creating the successor first IS the
        # interrogation that produces its tickets, which is what the floor is asking for.
        if [ -n "$SUCCESSOR_TITLE" ]; then
            echo '{"closed": false, "reason": "successor_title_refused", "alternative": "create the successor through /mission \"<title>\" -- its interrogation emits the ticket set -- then carry into it with --successor <slug>"}' >&2
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

# --- carried: resolve the successor BEFORE archiving the predecessor -------------
# Order matters. The predecessor is still in active/ here, so its Acceptance list is
# read from a stable path; and if the successor cannot be resolved we exit without
# having half-closed anything.
#
# ONE ROUTE. The mint branch that stood here until 2026-08-04 -- slug.sh, a create.sh
# call and a ~75-line awk rebuild importing Goal, gate_* and the unmet items into a
# fresh scaffold -- went with the `--successor-title` refusal above. It was unreachable
# by construction once the flag is refused at argument validation, and unreachable code
# no test can exercise is a maintenance surface, not documentation. What it knew is
# recorded where a reader looks for it: the header, reference/schema.md's carry
# decision, and lib/acceptance.sh's extraction, which the surviving route still calls.
SUCCESSOR=""
SUCCESSOR_PATH=""
if [ "$TARGET" = "carried" ]; then
    SUCCESSOR_PATH=$(mission_resolve "$ROOT" "$SUCCESSOR_SLUG")
    [ -f "$SUCCESSOR_PATH" ] || {
        printf '{"closed": false, "reason": "successor_not_found", "successor": "%s"}\n' "$SUCCESSOR_SLUG" >&2
        exit 1
    }
    SUCCESSOR="$SUCCESSOR_SLUG"
        # CARRY INTO AN EXISTING MISSION. Until 2026-08-04 this branch did nothing at
        # all -- it resolved a path above and fell through, so every unmet item was
        # dropped while the operation reported success. The successor already has its
        # own Goal, its own Acceptance list, possibly its own tickets and progress, so
        # this is an APPEND: no Goal import, no gate_* import, and the successor's own
        # items are untouched.
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
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

if [ "$TARGET" = "carried" ]; then
    printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s", "successor": "%s", "successor_path": "%s"}\n' \
        "$SLUG" "$TARGET" "$FILE" "$SUCCESSOR" "$SUCCESSOR_PATH"
else
    printf '{"closed": true, "slug": "%s", "status": "%s", "path": "%s"}\n' "$SLUG" "$TARGET" "$FILE"
fi
