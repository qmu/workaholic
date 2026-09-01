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

# A LEGACY PATH THE TODO-LAYOUT MIGRATION HAS ALREADY FLATTENED still archives
# (2026-08-14, issue #454). This seam now converges `todo/<user-slug>/X.md` to
# `todo/X.md` on every archive (see the migration below), and a unit's queue is listed
# ONCE and driven ticket by ticket — so the first archive of a legacy queue flattens
# every remaining ticket, and each later call arrives holding a path that was correct
# when it was read. Failing those with `Ticket not found` would strand a half-driven
# unit needing the hand-written `git mv` the drive workflow forbids, which is the same
# recovery the subject gate below exists to prevent. The fallback is purely lexical —
# drop the one `<segment>/` between `todo/` and the filename — and it is tried ONLY
# when the named path is absent, so a field-owned ticket is never second-guessed and a
# ticket that genuinely does not exist still fails here.
if [ ! -f "$TICKET" ]; then
    _flat=''
    case "$TICKET" in
        */todo/*/*.md) _flat="$(dirname "$(dirname "$TICKET")")/$(basename "$TICKET")" ;;
    esac
    if [ -n "$_flat" ] && [ -f "$_flat" ]; then
        echo "==> The todo-layout migration flattened this ticket; archiving it from ${_flat}"
        TICKET="$_flat"
    else
        echo "Error: Ticket not found: $TICKET"
        exit 1
    fi
fi

BRANCH=$(git branch --show-current)

if [ -z "$BRANCH" ]; then
    echo "Error: Cannot archive ticket: not on a named branch."
    exit 1
fi

# SUBJECT GATE BEFORE ANYTHING MOVES (2026-08-12). `commit.sh` runs this same rule
# before it stages, but it only runs at the END of this script — after the ticket has
# already been moved into `archive/<branch>/`. So an off-policy subject used to leave the
# tree HALF-ARCHIVED: the rename staged, no commit, and the obvious retry impossible,
# because the path the caller was told to pass no longer holds a file:
#
#   ==> Archiving ticket...
#   Error: rejected off-policy subject (subject is 60 characters (limit 50)).
#   $ <identical re-run>
#   Error: Ticket not found: .workaholic/tickets/todo/<name>.md
#
# Measured while driving ticket 20260812155908 on branch work-20260812-183726; recovery
# took a hand-written `git mv` back into `todo/`, in the one seam the drive workflow says
# must never be done by hand ("NEVER manually archive"). Under `/implement` nobody is
# reading the transcript, and every honest outcome in the failure contract assumes the
# tree is left in a state a later run can read — a staged-but-uncommitted rename is not.
#
# The subject is knowable before anything moves, so it is checked here. This is a CALL to
# the one canonical validator, never a second copy of the rule, and `commit.sh` keeps its
# own check: the layers share one source and cannot drift. The subject is never
# auto-shortened to fit — that would put a machine-invented sentence into permanent
# history; the caller passes a shorter one.
#
# Audited with it (the same shape elsewhere in this seam): every other refusal in
# `commit.sh` is either already checked above (a named branch) or unreachable from here
# (`--skip-staging` is passed with no file list, so the "named path cannot be staged"
# refusal cannot fire). The subject gate was the only one that could.
SCRIPT_DIR=$(dirname "$0")
if ! SUBJECT_REASON=$(sh "${SCRIPT_DIR}/../../commit/scripts//check-subject.sh" "$COMMIT_MSG"); then
    echo "Error: rejected off-policy subject (${SUBJECT_REASON})."
    echo "  Subject: \"${COMMIT_MSG}\""
    echo ""
    echo "Subject policy (plugins/workaholic/skills/commit/SKILL.md):"
    echo "  - present-tense, 50 characters or fewer"
    echo "  - no Conventional-Commit prefix (feat:/fix:/docs: ...)"
    echo "  - no leading [bracket] tag"
    echo ""
    echo "Nothing was moved and nothing was staged. Re-run with a conforming subject."
    exit 1
fi

# CLAIM RE-CHECK BEFORE ANYTHING MOVES (2026-08-30, mission
# `stop-two-runs-from-claiming-and-driving-one-unit`). The claim protocol closes the window
# between two SURVEYS and not the one between a survey and the first WRITE: a runner can hold
# a claim, begin driving, and only later meet a state its claim no longer covers -- a race, a
# release, a retirement, or another runner's fresh claim over a branch proved superseded.
#
# THIS SEAM, FOR THE SUBJECT GATE'S OWN REASON. `archive.sh` is where a driving run first
# writes something the base will see: it moves the ticket, commits, and pushes the claim
# branch. The subject gate directly above already runs BEFORE the move precisely so a refusal
# leaves the tree byte-identical, and this joins it there on the same reasoning and in the
# same place -- ahead of the todo-layout migration below, which stages what it converges.
#
# IT IS DEFENCE IN DEPTH, NOT THE REPAIR. What stops a race is the claim contending for one
# ref per unit; this bounds the damage when a claim changes hands for any reason at all.
#
# THE BIAS IS TOWARDS PROCEEDING, and it is the opposite of the claim act's on purpose: a
# wrong refusal strands finished work outside the archive, needing the hand-written `git mv`
# this seam exists to prevent. So it refuses only on POSITIVE evidence -- `other` (a different
# live branch now holds this unit) or `ambiguous` (two live claims, which is the race itself)
# -- and an unreadable scan, an unreachable origin or a branch with no claim row all answer
# `unknown` and proceed. `claim-holder.sh` composes `lib/claims.sh` and adds no verdict word;
# the reading is re-derived here, at the moment of the write, rather than handed in.
HOLDER_SCRIPT="$(dirname "$0")/claim-holder.sh"
if [ -f "$HOLDER_SCRIPT" ]; then
    HOLDER_OUT=$(sh "$HOLDER_SCRIPT" "$BRANCH" 2>/dev/null || true)
    HOLDER=$(printf '%s' "$HOLDER_OUT" | sed -n 's/.*"holder": "\([a-z_]*\)".*/\1/p')
    case "$HOLDER" in
        other)
            HOLDER_BRANCH=$(printf '%s' "$HOLDER_OUT" | sed -n 's/.*"holder_branch": "\([^"]*\)".*/\1/p')
            HOLDER_UNIT=$(printf '%s' "$HOLDER_OUT" | sed -n 's/.*"unit": "\([^"]*\)".*/\1/p')
            echo "Error: claim_taken_over — this branch no longer holds unit ${HOLDER_UNIT}."
            echo "  This branch: ${BRANCH}"
            echo "  Holder now:  ${HOLDER_BRANCH}"
            echo ""
            echo "Nothing was moved, staged or committed. Survey again before driving this unit."
            exit 1
            ;;
        ambiguous)
            HOLDER_BRANCHES=$(printf '%s' "$HOLDER_OUT" | sed -n 's/.*"branches": "\([^"]*\)".*/\1/p')
            HOLDER_UNIT=$(printf '%s' "$HOLDER_OUT" | sed -n 's/.*"unit": "\([^"]*\)".*/\1/p')
            echo "Error: ambiguous_claim — two or more live claims hold unit ${HOLDER_UNIT}."
            echo "  Branches: ${HOLDER_BRANCHES}"
            echo ""
            echo "Nothing was moved, staged or committed. A human decides which branch is the unit."
            exit 1
            ;;
    esac
fi

TICKET_DIR=$(dirname "$TICKET")
# Strip /todo, /icebox, or a legacy per-user form /todo/<user>, /icebox/<user> to
# find the tickets root. The per-user patterns run first so a trailing user
# segment is removed before the bare-directory patterns apply.
TICKETS_ROOT=$(echo "$TICKET_DIR" | sed 's|/todo/[^/]*$||; s|/icebox/[^/]*$||; s|/todo$||; s|/icebox$||')
# Sanitize branch name: replace / with - for flat archive directory naming
# e.g. trip/my-feature -> trip-my-feature (consistent with drive-* convention)
SAFE_BRANCH=$(echo "$BRANCH" | tr '/' '-')
ARCHIVE_DIR="${TICKETS_ROOT}/archive/${SAFE_BRANCH}"
TICKET_FILENAME=$(basename "$TICKET")

# The category is derived from the commit verb and emitted ONLY as the commit's
# `Category:` git trailer (via commit.sh --category), which is what /story's
# collect-commits.sh and the release-note grouping read. It is NOT stamped into the
# ticket frontmatter any more — the `category` ticket field was retired with
# type/layer/effort/commit_hash (2026-08-07); archived tickets that already carry it
# are history and are left as they are.
CATEGORY="Changed"
case "$COMMIT_MSG" in
    Add*|Create*|Implement*|Introduce*) CATEGORY="Added" ;;
    Remove*|Delete*) CATEGORY="Removed" ;;
esac

# Converge the todo layout before anything moves: `todo/<user-slug>/X.md` to the flat
# root, stamping `assignees` from the directory (2026-08-14, issue #454). The
# migration's own header has always named this seam — "create-ticket's publish step,
# promote-icebox.sh, and drive's archive.sh" — and archive.sh was the one that did not
# call it, so a queue that predates P2 never converged through ORDINARY USE: measured
# overnight 2026-08-13→14, tickets moved straight from `todo/<another-user-slug>/` into
# `archive/` without ever being stamped, which is what makes the ownership tolerance in
# `gather/scripts/owners.sh` permanent rather than transitional.
#
# BEFORE THE MOVE, NOT AFTER, and that ordering is the whole design. Running it after
# would leave the ticket being archived as the one ticket the seam never stamps —
# precisely the file whose ownership was lost in the measurement above. Running it
# before stamps it like any other and lets it ride into the archive already converged.
#
# It is also OUTSIDE the mission branch below: that branch is why the migration ran for
# some archives and not others, and an un-missioned ticket has to converge its queue too.
# And it is before `git add -A`, so every move rides the archive commit already being
# made rather than sitting unstaged for whoever commits next.
#
# Scoped to the ARCHIVED TICKET'S OWN TREE via `$TICKETS_ROOT` (derived from the ticket's
# path above), the same rule `missions_root_from_artifact` applies to the mission roll:
# archive.sh runs inside a claim worktree, so defaulting to the process cwd would
# converge a different tree than the one being committed.
#
# Same failure boundary as the mission roll and the index refresh: non-blocking — a
# migration problem must never strand an archive — but NOT silent, and silent on success,
# since it runs on every archive and a success line each time would be noise.
MIG_OUT=$(sh "${SCRIPT_DIR}/../../gather/scripts//migrate-todo-owners.sh" "$TICKETS_ROOT" 2>&1) && MIG_RC=0 || MIG_RC=$?
if [ "$MIG_RC" -ne 0 ]; then
    echo "    ! todo-layout migration failed (exit ${MIG_RC}); archive proceeds. migrate-todo-owners.sh said: ${MIG_OUT}"
fi

# THE MIGRATION MAY HAVE MOVED THE TICKET THIS CALL NAMES, so the legacy path a caller
# holds is re-resolved to the flat one rather than failing as `Ticket not found`. This is
# not a convenience: a unit's queue is listed ONCE and driven ticket by ticket, so
# without it the first archive of a legacy queue would flatten every remaining ticket and
# each later call would die on a path that was correct when it was read — the same
# half-archived, hand-`git mv` recovery the subject gate above exists to prevent. A
# ticket that simply does not exist still fails, at the pre-flight check above.
if [ ! -f "$TICKET" ] && [ -f "${TICKETS_ROOT}/todo/${TICKET_FILENAME}" ]; then
    echo "    · the todo-layout migration flattened this ticket; archiving it from ${TICKETS_ROOT}/todo/${TICKET_FILENAME}"
    TICKET="${TICKETS_ROOT}/todo/${TICKET_FILENAME}"
fi

echo "==> Archiving ticket..."
mkdir -p "$ARCHIVE_DIR"
mv "$TICKET" "$ARCHIVE_DIR/"
ARCHIVED_TICKET="${ARCHIVE_DIR}/${TICKET_FILENAME}"

# Stamp the ticket's end state (2026-08-13, issue #436: state is a frontmatter
# field, the archive is a place). `done` is the outcome an archive represents —
# the ticket passed its gate and its work is in this commit. Absent means queued,
# so a ticket only ever gains this field at the moment it stops being queued.
# Idempotent: a ticket that already carries a `status:` is left alone, which keeps
# a re-archive (and a ticket a living migration already stamped) byte-identical.
if head -n 1 "$ARCHIVED_TICKET" 2>/dev/null | grep -q '^---$' && \
   ! grep -qE '^status:' "$ARCHIVED_TICKET" 2>/dev/null; then
    _st_tmp="${ARCHIVED_TICKET}.status.$$"
    if awk '
        NR == 1 { print; if ($0 != "---") { fin = 1 }; next }
        fin { print; next }
        !placed && /^---[ \t]*$/ { print "status: done"; placed = 1; fin = 1; print; next }
        !placed && /^created_at:[ \t]*/ { print; print "status: done"; placed = 1; next }
        { print }
    ' "$ARCHIVED_TICKET" > "$_st_tmp" 2>/dev/null; then
        mv "$_st_tmp" "$ARCHIVED_TICKET" 2>/dev/null || rm -f "$_st_tmp" 2>/dev/null || true
    else
        rm -f "$_st_tmp" 2>/dev/null || true
    fi
fi
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

        # CLOSE A MISSION THIS ARCHIVE JUST FINISHED (2026-08-23). This seam already knew
        # a mission had moved — it ticked the item this ticket satisfies, one line up —
        # and stopped one step short of noticing it was the last one. A fully-accepted
        # mission with an empty queue then sat `active` until a human ran
        # `/mission-close`, and the survey went on listing it.
        #
        # THE SINGLE-WRITER RULE DOES NOT MOVE. `close.sh` is still the only writer of an
        # end state, and this calls it rather than writing a status. Only `achieved` is
        # ever passed, never `abandoned` and never `carried`: those two assert something
        # about *intent* and a run that just merged its own work is a poor judge of which
        # applies. `achieved` is the one of the three that is **arithmetic**.
        #
        # THE MEASURED OBJECTION IS ANSWERED, NOT IGNORED. `plan-units.sh` records that of
        # four missions closed by hand on 2026-08-04, one turned out not to be achieved at
        # all. That is exactly what this proof refuses: it does not ask whether the work
        # was good, it asks whether every acceptance item is ticked, none is unlinked, and
        # nothing is queued. The 2026-08-04 mission would have failed it.
        #
        # EVERY PART COMES FROM AN EXISTING READER — no new parser, and in particular no
        # fresh grep for `mission: <slug>`, which would be a second reader of a
        # many-valued relation `read-relation.sh` already owns.
        PROG=$(sh "${MISSION_SCRIPTS}/progress.sh" "$MISSION_FILE" 2>/dev/null || true)
        QSZ=$(sh "${MISSION_SCRIPTS}/queue-size.sh" "$MISSION_SLUG" 2>/dev/null || true)
        M_CHECKED=$(printf '%s' "$PROG" | sed -n 's/.*"checked": *\([0-9][0-9]*\).*/\1/p')
        M_TOTAL=$(printf '%s' "$PROG" | sed -n 's/.*"total": *\([0-9][0-9]*\).*/\1/p')
        M_UNLINKED=$(printf '%s' "$PROG" | sed -n 's/.*"unlinked": *\([0-9][0-9]*\).*/\1/p')
        M_TODO=$(printf '%s' "$QSZ" | sed -n 's/.*"todo": *\([0-9][0-9]*\).*/\1/p')
        # A DECLARED HANDOFF REFUSES THE CLOSE, AND THE TICK STAYS (2026-08-31, ticket
        # `20260831140500`). The arithmetic above cannot see the one fact that makes its
        # sum a lie: a ticket that declared `verification_handoff` is archived as
        # implemented — the routing table says so and it is right, the code IS written —
        # so the acceptance item naming it ticks, and this gate then closed the mission
        # `achieved` while what that item asserts had been verified by nobody. Measured
        # on `bring-the-theme-master-onto-the-one-master-seam-so-the-deployed-app-can-write-it`,
        # whose deployed-round item was ticked by the archive of the very ticket saying
        # no unattended runner can reach a deployment.
        #
        # WHICH OF THE TWO REPAIRS THIS IS, since the ticket left the fork open and asked
        # for the choice to be stated: the item still TICKS and the close refuses. Not
        # ticking would say the item is not met, which is false — the code is written and
        # every acceptance item is a statement about work, not about who looked at it.
        # Refusing the close says the item is met as far as anything here can tell and a
        # person still has to look, which is exactly the true statement. It also keeps
        # `tick-acceptance.sh` idempotent and `progress.sh`'s arithmetic honest; the
        # alternative would have left a mission permanently reading N-1 of N with nothing
        # saying why.
        #
        # IT IS A CONSUMER, NOT A SECOND DERIVATION. `acceptance-handoffs.sh` resolves the
        # items' tickets and delegates the declaration itself to
        # `verification-handoff.sh`, the one reader.
        HOFF=$(sh "${MISSION_SCRIPTS}/acceptance-handoffs.sh" "$MISSION_FILE" 2>/dev/null || true)
        HOFF_ANY=$(printf '%s' "$HOFF" | sed -n 's/.*"handoff"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p')
        HOFF_TICKETS=$(printf '%s' "$HOFF" | sed -n 's/.*"tickets"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p')

        # An unreadable reader is NOT a proof: a missing number leaves the mission alone.
        if [ -n "$M_CHECKED" ] && [ -n "$M_TOTAL" ] && [ -n "$M_UNLINKED" ] && [ -n "$M_TODO" ] \
           && [ "$M_TOTAL" -gt 0 ] && [ "$M_CHECKED" -eq "$M_TOTAL" ] \
           && [ "$M_UNLINKED" -eq 0 ] && [ "$M_TODO" -eq 0 ] \
           && [ "$HOFF_ANY" = "true" ]; then
            # Reported where the close would have been reported, and by name, so the
            # reason is in the run's own output rather than only in a mission file
            # nobody reopens.
            echo "    ! mission ${MISSION_SLUG}: ${M_CHECKED}/${M_TOTAL} accepted and queue empty, but NOT closed — an acceptance item is answered only by a declared verification handoff (${HOFF_TICKETS:-unnamed}); a person must verify it and close the mission"
        elif [ -n "$M_CHECKED" ] && [ -n "$M_TOTAL" ] && [ -n "$M_UNLINKED" ] && [ -n "$M_TODO" ] \
           && [ "$M_TOTAL" -gt 0 ] && [ "$M_CHECKED" -eq "$M_TOTAL" ] \
           && [ "$M_UNLINKED" -eq 0 ] && [ "$M_TODO" -eq 0 ]; then
            CLOSE_OUT=$(sh "${MISSION_SCRIPTS}/close.sh" "$MISSION_FILE" achieved 2>&1) && CLOSE_RC=0 || CLOSE_RC=$?
            if [ "$CLOSE_RC" -ne 0 ]; then
                CLOSE_REASON=$(printf '%s' "$CLOSE_OUT" | sed -n 's/.*"reason"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                echo "    ! mission ${MISSION_SLUG}: proved finished but NOT closed (${CLOSE_REASON:-exit ${CLOSE_RC}}); archive proceeds"
            elif printf '%s' "$CLOSE_OUT" | grep -Eq '"closed"[[:space:]]*:[[:space:]]*true'; then
                echo "    mission ${MISSION_SLUG}: achieved — ${M_CHECKED}/${M_TOTAL} accepted, queue empty; closed"
            else
                # Idempotent, like the two mutators above: a mission already ended is a
                # no-op rather than an error.
                echo "    ~ mission ${MISSION_SLUG}: already ended; close changed nothing"
            fi

            # NAME THE MISSION'S OWN DRILL VERDICT BESIDE THE CLOSE — AND GATE NOTHING
            # (2026-08-29, mission `run-the-loop-s-own-proofs-on-every-turn`). The gate
            # above closes a mission on ARITHMETIC — every ticket archived, the acceptance
            # fully checked, the queue empty — and says nothing about whether the mechanism
            # that mission shipped still works. This reads that mechanism's drill and says
            # so, as evidence.
            #
            # THE CLOSE IS BYTE-IDENTICAL EITHER WAY. It runs AFTER the close (or its
            # refusal) is decided, and a failing drill neither blocks nor delays it. The
            # temptation is to hold a close whose drill is red; it is refused by name,
            # because this gate's proof is *is the acceptance complete*, not *is the work
            # good*, and a second condition would make an unattended close depend on a
            # reading designed to become false when re-run (`drive/reference/claims.md`,
            # *Proofs and judgements*: every value here is a judgement).
            #
            # THE READ IS BEST-EFFORT AND ITS DEGRADATION IS REPORTED, exactly as the base
            # health read already is: it costs one REST call, and a call that fails must
            # never turn a landed archive into a failure. `no_drill` (the mission ships
            # none) and `drill_unreadable:<reason>` are each named by their own word rather
            # than reading as green.
            DRILL_REG="${SCRIPT_DIR}/drill-register.sh"
            DRILL_READ="${SCRIPT_DIR}/read-drill-verdicts.sh"
            if [ -f "$DRILL_REG" ] && [ -f "$DRILL_READ" ]; then
                DR_OUT=$(sh "$DRILL_REG" mission "$MISSION_SLUG" 2>/dev/null || true)
                DR_NAMES=$(printf '%s' "$DR_OUT" | tr '{' '\n' | sed -n 's/.*"drill": "\([a-z0-9-]*\)".*/\1/p')
                if [ -z "$DR_NAMES" ]; then
                    echo "    mission ${MISSION_SLUG}: drill verdict — no_drill (this mission shipped none)"
                else
                    DR_TIP=$(git rev-parse --verify "${WORKAHOLIC_BASE_REF:-origin/main}^{commit}" 2>/dev/null || true)
                    if [ -z "$DR_TIP" ]; then
                        echo "    mission ${MISSION_SLUG}: drill verdict — drill_unreadable:no_base_ref"
                    else
                        for DR_NAME in $DR_NAMES; do
                            DR_V=$(sh "$DRILL_READ" "$DR_TIP" --drill "$DR_NAME" 2>/dev/null || true)
                            DR_VERDICT=$(printf '%s' "$DR_V" | sed -n 's/.*"verdict": "\([a-z_]*\)".*/\1/p')
                            DR_WHY=$(printf '%s' "$DR_V" | sed -n 's/.*"reason": "\([a-z_:]*\)".*/\1/p')
                            case "$DR_VERDICT" in
                                failing)
                                    echo "    ! mission ${MISSION_SLUG}: drill ${DR_NAME} is FAILING on the base at ${DR_TIP}; the close is unchanged" ;;
                                no_failing_drill)
                                    echo "    mission ${MISSION_SLUG}: drill ${DR_NAME} — not failing on the base at ${DR_TIP}" ;;
                                no_drill)
                                    echo "    mission ${MISSION_SLUG}: drill verdict — no_drill (${DR_NAME} is not in the register)" ;;
                                *)
                                    echo "    mission ${MISSION_SLUG}: drill ${DR_NAME} — drill_unreadable:${DR_WHY:-unreadable}" ;;
                            esac
                        done
                    fi
                fi
            fi
        fi
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

# Delegate to commit skill (with --skip-staging since we already staged). SCRIPT_DIR is
# already set above, where the subject gate uses it.
COMMIT_SCRIPT="${SCRIPT_DIR}/../../commit/scripts//commit.sh"

sh "$COMMIT_SCRIPT" --skip-staging --category "$CATEGORY" "$COMMIT_MSG" "$WHY" "$CHANGES" "$CONCERNS" "$INSIGHTS" "$VERIFY"

# NOTE: nothing is written back into the ticket after the commit. `commit_hash` is
# deliberately NOT stamped — a commit cannot contain its own hash: writing it and
# amending changes the hash, so the recorded value named a pre-amend commit that is
# orphaned and never pushed. The hash is derived instead, from the commit that ADDED
# the archived ticket — see `story/scripts/ticket-commits.sh`, the single source of
# truth for it. And `category` lives only in the commit's `Category:` trailer (above),
# since the ticket field was retired — which is also what removed the stamp-then-amend
# dance this script used to end with.
COMMIT_HASH=$(git rev-parse --short HEAD)

# Push the archive commit immediately, following the same non-blocking convention
# heartbeat.sh already uses for the branch tip: the commit is already made locally and
# must not be lost or treated as an error if the push fails. A failed push is reported
# loudly (not silently swallowed) but never fails the archive -- the next heartbeat or
# commit will carry it forward regardless.
if git push --quiet origin "$BRANCH" >/dev/null 2>&1; then
    PUSH_STATUS="pushed"
else
    PUSH_STATUS="! could not push claim branch ${BRANCH}"
fi

echo ""
echo "Archive complete!"
echo "  Commit: ${COMMIT_HASH}"
echo "  Ticket: ${ARCHIVED_TICKET}"
echo "  Push: ${PUSH_STATUS}"
