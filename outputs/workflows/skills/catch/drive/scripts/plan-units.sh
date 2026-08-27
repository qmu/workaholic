#!/bin/sh -eu
# The SURVEY half of the unified drive's partitioning: report everything that is
# claimable right now, with the in-flight claims already subtracted.
#
# Usage: plan-units.sh
# Output: JSON
#   {"fetched": bool, "shallow": bool, "base": "<ref>",
#    "surveyed_sha": "<sha of the checkout's HEAD>", "base_sha": "<sha of <base>>",
#    "current": bool,
#    "user_slug": "<the runner's own slug, "" when it has no git identity>",
#    "backlog_error": "<reason, "" when the queue was read>",
#    "backlog_size": <how many tickets the queue actually holds, owned or not>,
#    "owner_unresolved": bool,
#    "claimed": [{"unit", "branch", "stale", "resumable", "resume_reason"}],
#    "resumable": [{"unit", "branch", "author", "last_commit_at", "stale",
#                   "resume_reason", "artifacts"}],
#    "missions": [{"slug", "title", "merge_policy", "checked", "total", "next", "path"}],
#    "backlog":  [{"path", "title", "merge_policy", "depends_on", "mission_closed"}],
#    "excluded": [{"kind": "mission"|"ticket", "id": "...", "reason": "..."}],
#    "backlog_all_excluded": {"excluded": true|false, "backlog_size": N,
#                             "reasons": [{"reason": "...", "count": N}, ...]}}
#
# IT STATES ITS OWN FRESHNESS, AND STILL DOES NOT FIX IT (decision J3). Claims come
# from git refs, but the ARTIFACTS come from the working tree this runs in -- so a
# checkout behind <base> surveys a stale queue and reports it confidently. That
# defect is closed by the CALLER (commands/drive.md runs branching/sync-main.sh
# before surveying), not here: a script named "plan units" that mutated the checkout
# would surprise every other caller, and this one is deliberately callable where
# reading must be side-effect-free (including inside a claim worktree).
#
# What it owes the caller instead is the FACT: `surveyed_sha` is what the working
# tree actually holds, `base_sha` is where <base> points, and `current` is whether
# the survey is KNOWN current -- the shas agree AND the fetch succeeded, since an
# offline runner matching its own last-known ref has established nothing about the
# base. `current: false` means this survey could not see everything on the base, and
# the run's terminal token may not be `ok` on the strength of it. There is
# no `excluded` reason for staleness because a stale checkout does not drop a NAMED
# item -- it never learns the item exists, which is exactly why the condition has to
# be reported as a property of the survey rather than of an artifact.
#
# THE SPLIT IS THE POINT (docs/loop-engineering-workflow.md G2). Partitioning the
# work into PR-units is two different jobs, and only one of them is mechanical:
#
#   * WHAT IS AVAILABLE is derivable -- the active missions, this developer's todo
#     queue, minus whatever a claim already holds. That is this script, and it is
#     deterministic so two runners on two machines survey the same world.
#   * WHAT DESERVES ONE MERGE is judgment -- which backlog tickets are related
#     enough to share a PR. That stays with the executor (drive/SKILL.md, *Unified
#     Run* §2), which is why no grouping heuristic lives here. A script that
#     guessed at relatedness would make the conservative "when unsure, one ticket
#     per unit" bar unreachable, because nothing downstream could tell a confident
#     grouping from a coincidental one.
#
# CLAIMS ARE READ THROUGH THE SHARED SCAN (lib/claims.sh) -- the same
# implementation list-claims.sh renders and claim.sh verifies against. A surveyor
# with its own scan could offer a unit the writer would then refuse, so all three
# read one scan. Both subtractions matter: the UNIT id keeps a claimed mission out
# of the offer, and the ARTIFACT paths keep an already-batched ticket out of it.
#
# NOTHING IS EXCLUDED SILENTLY. Every mission and ticket the survey drops is reported
# in `excluded` with its reason (`claimed_active`, `claimed_reported`,
# `claimed_by_other`, `claimed_resumable`, `claimed_superseded`, `owned_by_other`,
# `no_plan`, `no_tickets`,
# `queue_drained`, `mission_member`; `not_approved` was retired with the draft gate --
# K1), because a
# queue item that vanishes from an unattended run's offer with no trace is
# indistinguishable from one that was never there (`workaholic:implementation` /
# observability).
#
# THE SAME RULE APPLIES TO A REPAIR, WHICH IS WHY ONE REASON HAS NO `excluded` ENTRY.
# `mission_member` is not a fact about a ticket, it is a PREMISE -- "this arrives inside
# its mission's unit instead" -- and the premise expires when the last mission the ticket
# names closes, because only `missions/active/` yields units. A ticket in that state is
# now OFFERED rather than dropped, so it appears in `backlog` with a non-empty
# `mission_closed` naming the closed missions it carries. It is deliberately NOT an
# `excluded` reason: `excluded[]` means "the survey saw this and dropped it", and a
# repaired ticket is the opposite of dropped. Reading it as an annotation keeps both
# halves honest -- the offer says what it offers, and the row says why it once did not.
#
# A CLAIM IS NOT A DEAD END. The single `claimed` reason split into three, because it
# was hiding the difference between work in progress and work abandoned mid-flight: a
# unit whose runner died was excluded forever, and the design record's promise that
# "the next tick re-claims and resumes" was false in code (see lib/claims.sh). Now
# `claimed_active` means a run is on it, `claimed_reported` means the unit FINISHED and
# its PR is waiting on a human, `claimed_by_other` means it is not this runner's at any
# age, and `claimed_resumable` means the unit ALSO appears in `resumable[]` and can be
# taken over. The four names are read straight out of cron logs, so each one has to
# imply its own next action -- and `claimed_reported` exists because folding it into
# `claimed_active` said "a run is on it" about a unit no run will ever touch again.
#
# `claimed_superseded` IS THE FIFTH, AND IT NAMES A CLAIM WITH NOTHING IN IT (2026-08-26).
# The unit's tickets are already archived on the base, delivered by another route -- a
# hand recovery, a re-application, a revert-and-redo. Its own next action is neither
# `wait`, `review`, `never` nor `resume` but *close it out*, and it must NOT forbid `ok`:
# a claim holding no work is the opposite of outstanding work. It follows the same rule
# every other reason here does -- the verdict is the shared scan's (`claims_superseded`),
# never re-derived, and nothing acts on it.
#
# `claimed_reported` NOW MEANS WHAT IT SAYS (2026-08-19). It used to be emitted for every
# `queue_drained` unit, including one that died between §4 and §5 -- drained, pushed, and
# with no pull request anywhere -- so it asserted a report that never happened and the
# work was reachable by nobody: not by resumption (refused), not by a fresh claim (its
# tickets were excluded here). Such a unit now reads `report_incomplete` in the shared
# scan, which is `resumable: true`, so it lands in `claimed_resumable` and in the offer.
# No branch here changed: the classification below already keys on `resumable` first.
#
# `resumable[]` is a THIRD offer alongside `missions`/`backlog`, not a fourth kind of
# exclusion: those two are claimed fresh from the base, a resumable unit is taken over
# at its pushed branch tip. A resumable unit left untaken is claimable work outstanding
# and therefore forbids `ok` (drive/SKILL.md §7), exactly as an unclaimed ticket does.
#
# `no_plan`, `no_tickets` and `queue_drained` are DELIBERATELY DISTINCT, because each
# calls for a different developer action: `no_plan` means write the acceptance criteria,
# `no_tickets` means emit the ticket set (`/mission <instruction>` replans it), and
# `queue_drained` means every ticket was driven -- decide the close. The
# reason vocabulary is read straight out of cron logs, so collapsing them would make
# the log less actionable.
#
# AN UNREADABLE QUEUE IS NOT AN EMPTY ONE, AND AN UNIDENTIFIED RUNNER NO LONGER
# PRODUCES ONE (P2, 2026-08-06). Until then the backlog was scoped by PATH --
# `todo/<user-slug>/` -- so with no `git config user.email` there was no directory
# to name and the survey never learned any ticket existed; `backlog_error:
# identity_unresolved` was the honest report of a queue that could not be located,
# and it terminated the run. Ownership is a FIELD now, so the queue is read whatever
# the runner's identity, and the two facts separate cleanly:
#
#   `backlog_error`     the queue could not be READ at all (`unreadable`). Still a
#                       top-level key rather than an `excluded[]` entry, for the same
#                       reason `current` is: `excluded[]` names artifacts the survey
#                       SAW and dropped, and this is not having learned any exists.
#   `backlog_size`      how many tickets the queue holds, before any filtering. This
#                       is what makes "nothing for me" and "nothing at all"
#                       distinguishable from outside.
#   `backlog_all_excluded`
#                       a DERIVED reading over the two above and `excluded[]`: the queue
#                       holds tickets (`backlog_size > 0`), the survey offers NONE of
#                       them (`backlog[]` empty), and something was excluded. It carries
#                       a count PER EXCLUSION REASON, because `owned_by_other` is one
#                       reason among several (`claimed_active`, `claimed_reported`,
#                       `claimed_superseded`, `mission_member`, `owner_unresolved`, ...)
#                       and the answers differ: a queue emptied by claims is the protocol
#                       working, a queue emptied by ownership is work nothing can drive.
#                       Measured 2026-08-26 on this repository, `backlog_size: 10` with
#                       `backlog: []` and `owned_by_other` x7 — a shape that rendered in
#                       the run report exactly like a repository with an empty queue, and
#                       reported `ok` every hour for five days while ten units sat
#                       undrivable.
#
#                       It is a TOP-LEVEL key, not an `excluded[]` entry, for the reason
#                       `resurveyed[]` is: `excluded[]` names what the survey saw and
#                       DROPPED, and this reading drops nothing of its own — it reads
#                       what the other fields already say. It costs no new scan, no
#                       stored state and no field on any artifact.
#
#                       IT MOVES NO TOKEN. Whether this reading forbids `ok` belongs to
#                       the mission that owns §7's token table
#                       (`refuse-ok-under-a-placeholder-identity`); two missions editing
#                       one table is how a table stops meaning one thing. Reporting the
#                       fact is useful on its own and is what lands here.
#   `owner_unresolved`  the queue WAS read, and this runner has no identity to judge
#                       ownership against. Unowned tickets are still offered (they
#                       are claimable by anyone); every owned one is excluded as
#                       `owner_unresolved`. It forbids `ok` -- there is claimable
#                       work this runner could not judge -- but it does NOT terminate
#                       the run, because the survey is honest and the unowned half is
#                       genuinely actionable. Claiming still needs an identity and
#                       still fails loudly if there is none, which is the claim
#                       protocol's business and is deliberately unchanged.
#
# EVERY ARTIFACT IS FILTERED BY THE SAME OWNERSHIP RULE, through the one oracle every
# other consumer reads (gather/scripts/owns.sh over gather/scripts/owners.sh --
# plural `assignees`, legacy fallback to the singular `assignee`, compared by slug).
# The gate is the roadmap's ("not somebody else's"), and applies to a ticket identically:
# an artifact is offerable when the runner's identity is AMONG its owners, or it has
# no owners at all (team-owned = claimable); one owned solely by others is dropped as
# `owned_by_other`. Without this the executor was the single ownership consumer
# answering differently from the roadmap the developer is shown -- and an unattended
# runner would claim a colleague's mission and, under `merge_policy: auto`, drive it
# to `main`.
#
# Pure read: it fetches (through the shared reader) and inspects, and writes nothing.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"error": "not inside a git repository"}' >&2
    exit 1
fi

MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts/"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

# JSON-escape a value (backslash and double-quote only; titles are plain text --
# the same assumption list.sh makes about .workaholic/ artifacts).
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Read one frontmatter key from a file ("" when absent). First match inside the
# leading --- block wins, like every other frontmatter reader in the plugin.
fm_field() {
    awk -v key="$2" '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        index($0, key ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$1" 2>/dev/null || true
}

# The document title: the first H1, falling back to the filename stem.
doc_title() {
    _dt=$(awk '/^# / { sub(/^# [ \t]*/, ""); print; exit }' "$1" 2>/dev/null || true)
    [ -n "$_dt" ] || _dt=$(basename "$1" .md)
    printf '%s' "$_dt"
}

# --- the claims in flight -----------------------------------------------------
FETCHED=$(claims_fetch)
# The merged lookup reads this in the parent shell: `claims_fetch` runs in a command
# substitution, so the flag it sets there dies with that subshell (see lib/claims.sh).
CLAIMS_FETCH_OK="$FETCHED"
# Read AFTER the fetch, which deepens when it can: this must describe the history the
# scan below actually saw, not the one the container was cloned with.
SHALLOW=$(claims_shallow)
BASE=$(claims_base)
ROWS=$(claims_scan "$BASE")

# --- freshness, reported never repaired (see the header) -----------------------
# `claims_fetch` above updated the remote-tracking refs, so BASE reflects the remote
# when it succeeded. Comparing the two shas is most of the check --
#
# -- but `current` requires FETCHED too, and that conjunction is the honest part.
# Offline, BASE is only the last-known ref, so "my HEAD equals origin/main" means
# "I match what I remember", not "I match the base". Reporting `current: true` there
# would let a runner that cannot reach the remote at all emit `ok`, which is the
# confident-stale-survey this field exists to make impossible.
SURVEYED_SHA=$(git rev-parse HEAD 2>/dev/null || printf '')
BASE_SHA=$(git rev-parse --verify --quiet "${BASE}^{commit}" 2>/dev/null || printf '')
if [ "$FETCHED" = "true" ] && [ -n "$SURVEYED_SHA" ] && [ "$SURVEYED_SHA" = "$BASE_SHA" ]; then
    CURRENT=true
else
    CURRENT=false
fi

CLAIMED_UNITS=""
CLAIMED_ARTIFACTS=""
CLAIMED_JSON=""
RESUMABLE=""
# Why each claimed unit/artifact is not freshly claimable, keyed by unit id AND by
# artifact path, so the exclusion vocabulary below can stay specific.
CLAIM_REASONS=""
# The branch each claimed unit/artifact sits on, for the resurveyed report line.
CLAIM_BRANCHES=""
if [ -n "$ROWS" ]; then
    sep=""
    r_sep=""
    while IFS='	' read -r c_unit c_branch c_at c_stale c_author c_resumable c_reason c_reported c_arts; do
        [ -n "$c_unit" ] || continue

        # A DEAD BRANCH BESIDE A LIVE ONE GOVERNS NOTHING (2026-08-27). Since a fresh claim
        # may be taken over a `superseded` one, a unit can be held by TWO branches -- and
        # every lookup below (`claim_reason_for`, `superseded_branch_for`) takes the FIRST
        # row it finds, which for this shape is the older, dead one. The survey then read the
        # unit as `claimed_superseded` and RESURVEYED it, offering as fresh backlog a mission
        # another run was driving at that moment: observed live on this repository, with the
        # same mission in `missions[]`, in `resumable[]` and in `resurveyed[]` at once.
        # The resolution is the shared one in lib/claims.sh, so the survey's offer and
        # `claim.sh`'s refusal cannot disagree about which branch a unit is.
        #
        # THE ROW IS STILL REPORTED. `superseded` has been reported-never-acted-on since it
        # shipped, so the claim stays visible in `claimed[]`; what it loses is its say over
        # the exclusion and the resurvey, which belong to the live branch.
        if [ "$c_reason" = "superseded" ] \
            && [ "$(claims_unit_resolution "$ROWS" "$c_unit")" != "superseded_only" ]; then
            CLAIMED_JSON="${CLAIMED_JSON}${sep}{\"unit\": \"${c_unit}\", \"branch\": \"${c_branch}\", \"stale\": ${c_stale}, \"resumable\": ${c_resumable}, \"resume_reason\": \"${c_reason}\", \"reported\": ${c_reported}}"
            sep=", "
            continue
        fi

        CLAIMED_UNITS="${CLAIMED_UNITS}${c_unit}
"
        # A bare `claimed` told a cron log nothing actionable. "Being driven right
        # now", "finished and waiting on a human", "a colleague's", and "yours,
        # dropped, and recoverable" call for four different responses -- wait, review,
        # never, resume -- so they get four names.
        if [ "$c_resumable" = "true" ]; then
            c_exc=claimed_resumable
        elif [ "$c_reason" = "foreign_identity" ] || [ "$c_reason" = "identity_unresolved" ]; then
            c_exc=claimed_by_other
        elif [ "$c_reason" = "queue_drained" ]; then
            c_exc=claimed_reported
        elif [ "$c_reason" = "superseded" ]; then
            c_exc=claimed_superseded
        else
            c_exc=claimed_active
        fi
        CLAIM_REASONS="${CLAIM_REASONS}${c_unit}	${c_exc}
"
        CLAIM_BRANCHES="${CLAIM_BRANCHES}${c_unit}	${c_branch}
"
        old_ifs="$IFS"
        IFS=','
        for art in $c_arts; do
            CLAIMED_ARTIFACTS="${CLAIMED_ARTIFACTS}${art}
"
            CLAIM_REASONS="${CLAIM_REASONS}${art}	${c_exc}
"
            CLAIM_BRANCHES="${CLAIM_BRANCHES}${art}	${c_branch}
"
        done
        IFS="$old_ifs"
        CLAIMED_JSON="${CLAIMED_JSON}${sep}{\"unit\": \"${c_unit}\", \"branch\": \"${c_branch}\", \"stale\": ${c_stale}, \"resumable\": ${c_resumable}, \"resume_reason\": \"${c_reason}\", \"reported\": ${c_reported}}"
        sep=", "
        # A RESUMABLE UNIT IS CLAIMABLE WORK, so it is offered rather than dropped --
        # in its own group, deliberately not merged into `missions`/`backlog`. Those
        # are fresh units a runner claims from the base; this one is taken over with
        # `claim.sh resume` and continues from the pushed branch tip, which is a
        # different action. Keeping them apart lets the caller route each correctly
        # without re-deriving the claim state it was just handed.
        if [ "$c_resumable" = "true" ]; then
            r_arts=""
            a_sep=""
            old_ifs="$IFS"
            IFS=','
            for art in $c_arts; do
                r_arts="${r_arts}${a_sep}\"$(json_escape "$art")\""
                a_sep=", "
            done
            IFS="$old_ifs"
            RESUMABLE="${RESUMABLE}${r_sep}{\"unit\": \"${c_unit}\", \"branch\": \"${c_branch}\", \"author\": \"$(json_escape "$c_author")\", \"last_commit_at\": \"${c_at}\", \"stale\": ${c_stale}, \"resume_reason\": \"${c_reason}\", \"artifacts\": [${r_arts}]}"
            r_sep=", "
        fi
    done <<EOF
$ROWS
EOF
fi

is_claimed_unit() {
    printf '%s' "$CLAIMED_UNITS" | grep -qx -- "$1" 2>/dev/null
}
is_claimed_artifact() {
    printf '%s' "$CLAIMED_ARTIFACTS" | grep -qx -- "$1" 2>/dev/null
}

# A CLAIM THAT HOLDS NOTHING MUST NOT HOLD ITS WORK EITHER (2026-08-26).
#
# `claimed_superseded` says the unit's work already reached the base — so the claim is a dead
# branch, and the queued tickets sitting behind it are ordinary backlog that nothing is
# driving. Excluding them was correct for every other claim reason and wrong for this one:
# measured, a mission was still `active` at 2/3 acceptance with queued tickets behind a claim
# whose pull request had merged five days earlier, and no survey would offer any of it.
#
# THIS FREES THE WORK; IT DOES NOT REVIVE THE BRANCH. The claim row stays `superseded` and
# `resumable: false`, nothing deletes it, and a run that takes the freed tickets claims them
# FRESH — a new branch, a new worktree, a new pull request. That is the only correct route: the
# old branch cannot land.
#
# AND IT IS NARROW BY CONSTRUCTION. Every other reason still excludes: `claimed_active` is being
# driven now, `claimed_by_other` is not this runner's, `claimed_reported` is waiting on a human,
# `claimed_resumable` is taken over rather than re-claimed. Only a claim proved empty is stepped
# over.
is_superseded() {
    [ "$(claim_reason_for "$1")" = "claimed_superseded" ]
}

# What the survey stepped over, reported so a unit that CAME BACK is never mistaken for one that
# was never claimed. `excluded[]` is the wrong home by its own definition — it names what the
# survey saw and DROPPED — so this is its own field, the same reasoning that put a repaired
# ticket's `mission_closed` on the offered row rather than in the exclusions.
RESURVEYED=""
rs_sep=""
note_resurveyed() {
    RESURVEYED="${RESURVEYED}${rs_sep}{\"kind\": \"${1}\", \"id\": \"$(json_escape "$2")\", \"claim\": \"$(json_escape "$3")\"}"
    rs_sep=", "
}
# The branch a unit's superseded claim sits on, for the report line above.
superseded_branch_for() {
    printf '%s' "$CLAIM_BRANCHES" | awk -F'\t' -v k="$1" '$1 == k { print $2; exit }'
}
# The specific reason a claimed unit/artifact is excluded. `claimed_active` is the
# fallback if a row is somehow missing: never offer, always report.
claim_reason_for() {
    _cr=$(printf '%s' "$CLAIM_REASONS" | awk -F'\t' -v k="$1" '$1 == k { print $2; exit }')
    [ -n "$_cr" ] || _cr=claimed_active
    printf '%s' "$_cr"
}

EXCLUDED=""
exc_sep=""
exclude() {
    EXCLUDED="${EXCLUDED}${exc_sep}{\"kind\": \"${1}\", \"id\": \"$(json_escape "$2")\", \"reason\": \"${3}\"}"
    exc_sep=", "
}

# --- claimable missions -------------------------------------------------------
# THE AREA IS THE AUTHORITY, NOT A STATUS WORD (2026-07-31 --
# docs/loop-engineering-workflow.md K1). A mission reaches missions/active/ on
# `main` only by merging its pull request, and that merge IS the approval: the
# project accepted it. So this offer does not read `status` at all -- the
# `not_approved` exclusion is gone, and with it the second gate that left six
# missions unclaimable on main while this survey reported `pending` every tick.
#
# The two REAL floors stay, because neither is a re-ask of the PR's question -- both
# are about whether there is anything to drive. A mission with an empty
# ## Acceptance authorizes work against no bar at all, so the offer applies that
# floor -- a planless mission is never handed to an unattended run.
#
# BUT ACCEPTANCE ITEMS ARE NOT A QUEUE, and the offer needs both floors. `/specificate`
# writes a provisional acceptance SKETCH, which satisfies an item count with zero
# tickets: on 2026-07-30 an approved mission with `merge_policy: auto`, `tickets: []`
# and an acceptance block reading "PROPOSED sketch -- not a plan" was offered here as
# claimable. So drivability is also checked against the ticket queue itself
# (`mission/scripts/queue-size.sh`, the single reader both floors call), and a mission
# with nothing left in todo/ is excluded `no_tickets`.
#
# Ownership is applied FIRST among the mission checks, because "not my work"
# is the cheapest true answer and the one an operator reading a cron log wants: a
# colleague's mission that is also claimed is `owned_by_other` to this runner either
# way, and no action of theirs follows from the claim.
MISSIONS=""
m_sep=""
# The runner's identity, resolved once and passed to every ownership question so the
# survey cannot answer two of them differently. Empty is reported as
# `owner_unresolved` rather than as "somebody else's": a runner that cannot say who
# it is must not claim work on anyone's behalf, but it must also not report that
# certainty it does not have. Unowned artifacts stay offerable, as everywhere else.
ME=$(git config user.email 2>/dev/null || true)
# Set by EITHER half — a mission and a ticket ask the same question, so one flag
# answers "was there anything this runner could not judge". Initialized here rather
# than beside the backlog it was first written for: the mission loop runs first, and
# a later re-initialization would silently discard its answer.
OWNER_UNRESOLVED=false
if [ -d ".workaholic/missions/active" ]; then
    for d in $(find .workaholic/missions/active -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort); do
        f="${d}/mission.md"
        [ -f "$f" ] || continue
        slug=$(basename "$d")
        # No status check: since K1 the AREA is the authority. A mission reaches
        # `missions/active/` on `main` only by merging its pull request, and that merge
        # IS the approval -- re-reading a status word here would re-ask the question the
        # review already answered.
        # Mine, or unclaimed. Someone else's is not this runner's to take.
        case "$(sh "${GATHER_SCRIPTS}/owns.sh" "$f" "$ME" 2>/dev/null || echo unowned)" in
            mine|unowned) : ;;
            unresolved)
                OWNER_UNRESOLVED=true
                exclude mission "$slug" "owner_unresolved"
                continue
                ;;
            *)
                exclude mission "$slug" "owned_by_other"
                continue
                ;;
        esac
        if is_claimed_unit "$slug"; then
            if is_superseded "$slug"; then
                note_resurveyed mission "$slug" "$(superseded_branch_for "$slug")"
            else
                exclude mission "$slug" "$(claim_reason_for "$slug")"
                continue
            fi
        elif is_claimed_artifact "$f"; then
            if is_superseded "$f"; then
                note_resurveyed mission "$slug" "$(superseded_branch_for "$f")"
            else
                exclude mission "$slug" "$(claim_reason_for "$f")"
                continue
            fi
        fi
        progress=$(sh "${MISSION_SCRIPTS}/progress.sh" "$f" 2>/dev/null || true)
        checked=$(printf '%s' "$progress" | sed -n 's/.*"checked": *\([0-9][0-9]*\).*/\1/p')
        total=$(printf '%s' "$progress" | sed -n 's/.*"total": *\([0-9][0-9]*\).*/\1/p')
        [ -n "$checked" ] || checked=0
        [ -n "$total" ] || total=0
        if [ "$total" -eq 0 ]; then
            exclude mission "$slug" "no_plan"
            continue
        fi
        # Nothing left to drive: the acceptance list may be full, but no ticket in
        # todo/ names this mission, so a claim would create a branch and a worktree
        # for an empty queue.
        #
        # AN EMPTY QUEUE IS TWO OPPOSITE STATES, AND ONE REASON WORD CANNOT CARRY BOTH.
        # `no_tickets` meant "the ticket set was never emitted -- replan it". A mission
        # whose every ticket was DRIVEN AND ARCHIVED lands in the same branch, and the
        # operator reading a cron log cannot tell "needs a plan" from "needs a close".
        # Measured on `main` 2026-08-04: four active missions, 15 archived tickets and
        # 4.66 recorded agent-hours between them, every one reported `no_tickets` -- for
        # four days, across every hourly tick. The archive is what distinguishes them,
        # and `queue-size.sh` already reports it, so this is a verdict on counts already
        # in hand rather than a second lookup (the ticket preferred extending that script
        # over adding a reader; it turned out to need no extension at all).
        #
        # NEITHER IS CLAIMABLE -- only the reported reason differs. A drained mission has
        # nothing to drive.
        #
        # THE CLOSE IS A HUMAN JUDGMENT FOR TWO OF THE THREE OUTCOMES (narrowed 2026-08-23).
        # `carried` and `abandoned` assert something about intent and stay the operator's:
        # of the four missions closed by hand on 2026-08-04, one turned out not to be
        # achieved at all, so an automated close on judgment would have recorded it wrongly.
        # `achieved` is the one that is arithmetic -- every acceptance item ticked, none
        # unlinked, nothing queued -- and `archive.sh` now closes exactly that case at the
        # gate, on a proof the 2026-08-04 mission would have failed. A mission reaching this
        # branch as `queue_drained` is therefore one whose acceptance is NOT complete, or one
        # finished by a path that archived no ticket.
        qs=$(sh "${MISSION_SCRIPTS}/queue-size.sh" "$slug" 2>/dev/null || true)
        queued=$(printf '%s' "$qs" | sed -n 's/.*"todo": *\([0-9][0-9]*\).*/\1/p')
        [ -n "$queued" ] || queued=0
        archived=$(printf '%s' "$qs" | sed -n 's/.*"archive": *\([0-9][0-9]*\).*/\1/p')
        [ -n "$archived" ] || archived=0
        if [ "$queued" -eq 0 ]; then
            if [ "$archived" -gt 0 ]; then
                exclude mission "$slug" "queue_drained"
            else
                exclude mission "$slug" "no_tickets"
            fi
            continue
        fi
        title=$(json_escape "$(fm_field "$f" title)")
        policy=$(json_escape "$(fm_field "$f" merge_policy)")
        next=$(json_escape "$(sh "${MISSION_SCRIPTS}/next-acceptance.sh" "$f" 2>/dev/null || true)")
        MISSIONS="${MISSIONS}${m_sep}{\"slug\": \"${slug}\", \"title\": \"${title}\", \"merge_policy\": \"${policy}\", \"checked\": ${checked}, \"total\": ${total}, \"next\": \"${next}\", \"path\": \"$(json_escape "$f")\"}"
        m_sep=", "
    done
fi

# --- the unclaimed backlog ----------------------------------------------------
# The WHOLE todo queue (list-todo.sh reads every ticket, whoever owns it), minus
# anything owned solely by someone else, minus anything a claim holds, minus
# anything a mission already owns: a missioned ticket is driven as part of its
# mission's unit, in that mission's worktree, so offering it here would split one
# plan across two PRs.
#
# The read's STATUS is captured rather than discarded (see the header). Since P2 the
# only way this read fails is the queue being genuinely unreadable — the
# identity-shaped failure is gone with the per-user directory, and `owner_unresolved`
# now carries what is left of it without pretending the queue was empty.
BACKLOG=""
b_sep=""
USER_SLUG=$(sh "${GATHER_SCRIPTS}/user-slug.sh" 2>/dev/null || true)
BACKLOG_ERROR=""
BACKLOG_SIZE=0
todo_status=0
TODO_LIST=$(sh "${SCRIPT_DIR}/list-todo.sh" 2>/dev/null) || todo_status=$?
case "$todo_status" in
    0) ;;
    *) BACKLOG_ERROR="unreadable" ;;
esac
for t in $TODO_LIST; do
    [ -f "$t" ] || continue
    BACKLOG_SIZE=$((BACKLOG_SIZE + 1))
    case "$(sh "${GATHER_SCRIPTS}/owns.sh" "$t" "$ME" 2>/dev/null || echo unowned)" in
        mine|unowned) : ;;
        unresolved)
            OWNER_UNRESOLVED=true
            exclude ticket "$t" "owner_unresolved"
            continue
            ;;
        *)
            exclude ticket "$t" "owned_by_other"
            continue
            ;;
    esac
    if is_claimed_artifact "$t"; then
        # A superseded claim holds no work, so its tickets are ordinary backlog (see
        # `is_superseded`). Every other claim reason still excludes.
        if is_superseded "$t"; then
            note_resurveyed ticket "$t" "$(superseded_branch_for "$t")"
        else
            exclude ticket "$t" "$(claim_reason_for "$t")"
            continue
        fi
    fi
    # A MISSION MEMBER ONLY WHILE A MISSION IT NAMES IS STILL ALIVE (2026-08-12,
    # qmu/workaholic#382). The exclusion rests on a premise -- "it will be offered inside
    # its mission's unit instead" -- and the mission loop above enumerates
    # `missions/active/` only, so the premise expires the moment the last mission a
    # ticket names is closed. Excluding on a merely NON-EMPTY relation therefore stranded
    # such a ticket: offered by neither path, sitting in todo/ while the queue read as
    # drained rather than as broken. Liveness is asked of the one reader that owns the
    # question (mission/scripts/read-active-relation.sh), never re-derived here.
    #
    # The relation is MANY-valued and the test is ANY, not ALL: a ticket naming one live
    # mission and one closed one is still a member, arrives through the live mission's
    # unit, and must not also be offered as backlog.
    relation=$(sh "${MISSION_SCRIPTS}/read-relation.sh" "$t" 2>/dev/null || true)
    active_relation=$(sh "${MISSION_SCRIPTS}/read-active-relation.sh" "$t" 2>/dev/null || true)
    if [ -n "$active_relation" ]; then
        exclude ticket "$t" "mission_member"
        continue
    fi
    # THE REPAIR IS ANNOTATED ON THE ROW, NOT REPORTED AS AN EXCLUSION. A repaired ticket
    # is OFFERED, and `excluded[]` names items the survey saw and DROPPED -- putting
    # `mission_closed` there would describe the opposite of what happened. So the offer
    # carries the closed slugs that would previously have suppressed it, and an operator
    # can see that a repair happened instead of inferring it from an absence. Empty for
    # the ordinary case of a ticket that names no mission at all.
    mission_closed=""
    if [ -n "$relation" ]; then
        mission_closed=$(printf '%s\n' "$relation" | tr '\n' ',' | sed -e 's/,*$//')
    fi
    title=$(json_escape "$(doc_title "$t")")
    policy=$(json_escape "$(fm_field "$t" merge_policy)")
    depends=$(json_escape "$(fm_field "$t" depends_on)")
    BACKLOG="${BACKLOG}${b_sep}{\"path\": \"$(json_escape "$t")\", \"title\": \"${title}\", \"merge_policy\": \"${policy}\", \"depends_on\": \"${depends}\", \"mission_closed\": \"$(json_escape "$mission_closed")\"}"
    b_sep=", "
done

# --- the derived reading: a queue that holds work and offers none of it ----------
# Derived from what the survey already computed -- no new scan, no stored state, no field
# on any artifact -- and reported so "the queue is empty" and "the queue is full and I can
# offer none of it" never render alike again. The per-reason counts are what make the
# reading actionable: a queue emptied by claims is the protocol working; one emptied by
# ownership is work nothing can drive. It moves no token (see the header).
ALL_EXCLUDED=false
EXCLUDED_REASONS=""
if [ "$BACKLOG_SIZE" -gt 0 ] && [ -z "$BACKLOG" ] && [ -n "$EXCLUDED" ]; then
    ALL_EXCLUDED=true
    er_sep=""
    # `printf '%s\n'` matters: the last comma-split fragment carries no trailing newline,
    # and `wc -l` counts newlines rather than lines — which undercounted every reason by
    # one. `grep -c` counts matching lines either way.
    reason_lines=$(printf '%s\n' "$EXCLUDED" | tr ',' '\n' | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
    for reason in $(printf '%s\n' "$reason_lines" | sort -u); do
        n=$(printf '%s\n' "$reason_lines" | grep -c "^${reason}\$" || true)
        [ -n "$n" ] || n=0
        EXCLUDED_REASONS="${EXCLUDED_REASONS}${er_sep}{\"reason\": \"${reason}\", \"count\": ${n}}"
        er_sep=", "
    done
fi
ALL_EXCLUDED_JSON="{\"excluded\": ${ALL_EXCLUDED}, \"backlog_size\": ${BACKLOG_SIZE}, \"reasons\": [${EXCLUDED_REASONS}]}"

printf '{"fetched": %s, "shallow": %s, "base": "%s", "surveyed_sha": "%s", "base_sha": "%s", "current": %s, "user_slug": "%s", "backlog_error": "%s", "backlog_size": %d, "owner_unresolved": %s, "claimed": [%s], "resumable": [%s], "resurveyed": [%s], "missions": [%s], "backlog": [%s], "excluded": [%s], "backlog_all_excluded": %s}\n' \
    "$FETCHED" "$SHALLOW" "$BASE" "$SURVEYED_SHA" "$BASE_SHA" "$CURRENT" "$(json_escape "$USER_SLUG")" "$BACKLOG_ERROR" \
    "$BACKLOG_SIZE" "$OWNER_UNRESOLVED" \
    "$CLAIMED_JSON" "$RESUMABLE" "$RESURVEYED" "$MISSIONS" "$BACKLOG" "$EXCLUDED" "$ALL_EXCLUDED_JSON"
