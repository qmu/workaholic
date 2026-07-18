#!/bin/sh -eu
# Complete archive workflow: move ticket, commit via commit skill, update frontmatter

set -eu

TICKET="${1:-}"
COMMIT_MSG="${2:-}"
REPO_URL="${3:-}"
WHY="${4:-}"
CHANGES="${5:-None}"
CONCERNS="${6:-}"
INSIGHTS="${7:-}"
VERIFY="${8:-None}"
shift 8 2>/dev/null || true

if [ -z "$TICKET" ] || [ -z "$COMMIT_MSG" ] || [ -z "$REPO_URL" ]; then
    echo "Usage: archive.sh <ticket-path> <commit-message> <repo-url> [why] [changes] [concerns] [insights] [verify] [files...]"
    exit 1
fi

if [ ! -f "$TICKET" ]; then
    echo "Error: Ticket not found: $TICKET"
    exit 1
fi

BRANCH=$(git branch --show-current)

if [ -z "$BRANCH" ]; then
    echo "Error: Cannot archive ticket: not on a named branch."
    exit 1
fi

TICKET_DIR=$(dirname "$TICKET")
# Strip /todo, /icebox, or their per-user form /todo/<user>, /icebox/<user> to
# find the tickets root. The per-user patterns run first so a trailing user
# segment is removed before the bare-directory patterns apply.
TICKETS_ROOT=$(echo "$TICKET_DIR" | sed 's|/todo/[^/]*$||; s|/icebox/[^/]*$||; s|/todo$||; s|/icebox$||')
# Sanitize branch name: replace / with - for flat archive directory naming
# e.g. trip/my-feature -> trip-my-feature (consistent with drive-* convention)
SAFE_BRANCH=$(echo "$BRANCH" | tr '/' '-')
ARCHIVE_DIR="${TICKETS_ROOT}/archive/${SAFE_BRANCH}"
TICKET_FILENAME=$(basename "$TICKET")

CATEGORY="Changed"
case "$COMMIT_MSG" in
    Add*|Create*|Implement*|Introduce*) CATEGORY="Added" ;;
    Remove*|Delete*) CATEGORY="Removed" ;;
esac

echo "==> Archiving ticket..."
mkdir -p "$ARCHIVE_DIR"
mv "$TICKET" "$ARCHIVE_DIR/"
ARCHIVED_TICKET="${ARCHIVE_DIR}/${TICKET_FILENAME}"
echo "    ${ARCHIVED_TICKET}"

SCRIPT_DIR=$(dirname "$0")

# Report one mission mutator's outcome without ever blocking the archive. The boundary,
# stated here so the next reader does not re-collapse it: archiving never FAILS on a
# mission problem (a finished ticket must not be stranded outside the archive by an
# unrelated mission-file issue), and archiving never HIDES one either. Routing the outcome
# to /dev/null (the old shape) conflated those two decisions and let a mission that was
# never rolled pass under "Archive complete!". Three volumes, so a normal archive stays
# readable while the interesting cases stand out:
#   failure (mutator exits non-zero)   -> loud: name the mission, the mutator, the reason
#   clean no-op (exit 0, changed none) -> the `reason` the mutator already returns in JSON
#                                         (this is the case that bit us: exit 0, did nothing)
#   success (exit 0, did the work)     -> one terse line
report_mission_roll() {
    _rmr_slug="$1"
    _rmr_what="$2"
    _rmr_rc="$3"
    _rmr_out="$4"
    _rmr_reason=$(printf '%s' "$_rmr_out" | sed -n 's/.*"reason"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    if [ "$_rmr_rc" -ne 0 ]; then
        echo "    ! mission ${_rmr_slug}: ${_rmr_what} NOT rolled (${_rmr_reason:-exit ${_rmr_rc}}); archive proceeds"
    elif printf '%s' "$_rmr_out" | grep -Eq '"(ticked|appended)"[[:space:]]*:[[:space:]]*true'; then
        echo "    mission ${_rmr_slug}: ${_rmr_what} rolled"
    else
        echo "    ~ mission ${_rmr_slug}: ${_rmr_what} changed nothing (${_rmr_reason:-no reason given})"
    fi
}

# Roll every related mission: a ticket carrying `mission: [a, b]` appends a "ticket
# archived" changelog line and ticks its acceptance item on EACH mission it names, via
# the mission skill's shared, idempotent mutators. The relation is read by the mission
# skill's single reader, so the field's shape lives in one place.
#
# Looping is safe without dedup: append-changelog.sh keys on the (event, artifact) pair
# and tick-acceptance.sh on the artifact basename, so both no-op on a repeat and
# tick-acceptance simply finds nothing on a mission whose Acceptance does not list this
# ticket. Non-blocking but NOT silent (see report_mission_roll above) — each roll's
# outcome is captured and reported instead of discarded. The mutators git-stage the
# mission file, so it rides along in the archive commit's `git add -A` below.
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts/"
# Resolution follows the TICKET, not the process cwd: the mission the archived ticket
# names lives in the ticket's own .workaholic tree, so its root is derived from the
# ticket's path and each slug is resolved to an ABSOLUTE mission.md under it before the
# mutators run. Passing a bare slug would let the mutators re-resolve against the cwd and,
# with a same-slug mission in a sibling worktree, roll the wrong tree's mission.
#
# The reader is read with its exit code captured, not masked: a ticket that names NO
# mission is the common case and stays silent, but a relation that could NOT be read
# (read-relation.sh exits non-zero) is a distinct event and is reported rather than
# collapsed into "no mission". Guarded on a non-empty relation: an un-missioned ticket
# runs NO mission script at all (no changelog, no tick, no living migration), so archiving
# it leaves every mission — even a legacy flat dir — byte-for-byte untouched.
MISSION_SLUGS=$(sh "${MISSION_SCRIPTS}/read-relation.sh" "$ARCHIVED_TICKET") && REL_RC=0 || REL_RC=$?
if [ "$REL_RC" -ne 0 ]; then
    echo "    ! could not read the ticket's mission relation (read-relation.sh exit ${REL_RC}); archive proceeds, no mission rolled"
elif [ -n "$MISSION_SLUGS" ]; then
    . "${MISSION_SCRIPTS}/lib/resolve.sh"
    MISSION_ROOT=$(missions_root_from_artifact "$ARCHIVED_TICKET")
    missions_migrate_layout "$MISSION_ROOT"
    # A here-doc, not `printf | while`: the loop runs in THIS shell rather than a pipe
    # subshell, so its reporting reaches archive.sh's own stdout (the same reason
    # apply-deferred-concern-verdicts.sh keeps its counters in-shell). Reporting is a
    # per-mission echo with no accumulated state, but the here-doc keeps it robust if a
    # future edit ever does accumulate across missions.
    while IFS= read -r MISSION_SLUG; do
        [ -n "$MISSION_SLUG" ] || continue
        MISSION_FILE=$(mission_resolve "$MISSION_ROOT" "$MISSION_SLUG")
        CL_OUT=$(sh "${MISSION_SCRIPTS}/append-changelog.sh" "$MISSION_FILE" "ticket archived" "$TICKET_FILENAME" 2>&1) && CL_RC=0 || CL_RC=$?
        report_mission_roll "$MISSION_SLUG" changelog "$CL_RC" "$CL_OUT"
        TK_OUT=$(sh "${MISSION_SCRIPTS}/tick-acceptance.sh" "$MISSION_FILE" "$TICKET_FILENAME" 2>&1) && TK_RC=0 || TK_RC=$?
        report_mission_roll "$MISSION_SLUG" acceptance "$TK_RC" "$TK_OUT"
    done <<EOF
$MISSION_SLUGS
EOF
fi

# Refresh the .workaholic OKF bundle indexes so the archive commit ships with a fresh
# hierarchy. Non-blocking but not silent, same boundary as the mission roll: an index
# refresh that fails must not strand the archive, and must not vanish either (discarding
# both its output and its exit code did both). Silent on success — it runs on every
# archive, so a success line each time would be pure noise.
IDX_OUT=$(sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" 2>&1) && IDX_RC=0 || IDX_RC=$?
if [ "$IDX_RC" -ne 0 ]; then
    echo "    ! OKF index refresh failed (exit ${IDX_RC}); archive proceeds. refresh-index.sh said: ${IDX_OUT}"
fi

# Stage all changes including the archived ticket
echo "==> Staging changes..."
git add -A

# Delegate to commit skill (with --skip-staging since we already staged)
SCRIPT_DIR=$(dirname "$0")
COMMIT_SCRIPT="${SCRIPT_DIR}/../../commit/scripts//commit.sh"

# Pass the same computed CATEGORY both into the commit (as a git trailer) and into
# the ticket frontmatter below, so the two surfaces can never disagree.
sh "$COMMIT_SCRIPT" --skip-staging --category "$CATEGORY" "$COMMIT_MSG" "$WHY" "$CHANGES" "$CONCERNS" "$INSIGHTS" "$VERIFY"

# NOTE: `commit_hash` is deliberately NOT stamped here. A commit cannot contain its own
# hash: writing it and amending changes the hash, so the recorded value named a pre-amend
# commit that is orphaned and never pushed — every link built from it 404s. Re-stamping
# after the amend just regresses forever (no fixed point exists). The hash is derived
# instead, from the commit that ADDED the archived ticket — see
# `report/scripts/ticket-commits.sh`, which is the single source of truth for it.
echo "==> Updating ticket frontmatter..."
UPDATE_SCRIPT="${SCRIPT_DIR}/update.sh"
sh "$UPDATE_SCRIPT" "$ARCHIVED_TICKET" "category" "$CATEGORY"

git add "$ARCHIVED_TICKET"
git commit --amend --no-edit
echo "==> Updated ticket with category"

# Read the hash only AFTER the final amend, so what we print actually exists.
COMMIT_HASH=$(git rev-parse --short HEAD)

echo ""
echo "Archive complete!"
echo "  Commit: ${COMMIT_HASH}"
echo "  Ticket: ${ARCHIVED_TICKET}"
