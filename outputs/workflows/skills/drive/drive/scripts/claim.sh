#!/bin/sh -eu
# The claim WRITER: take a PR-unit before driving it, by pushing the claim.
#
#   claim.sh mission <slug>            -- claim one approved mission (unit id = the slug)
#   claim.sh batch <ticket-file>...    -- claim one batch of backlog tickets
#                                         (unit id = batch-<YYYYMMDDHHMMSS>, minted here)
#   claim.sh resume <unit-id>          -- TAKE OVER an existing claim whose run stopped,
#                                         continuing from its pushed branch tip. It ADOPTS
#                                         this machine's existing .worktrees/<unit>/ when
#                                         that worktree is on the claim's branch at the
#                                         tip the resumability decision observed, and only
#                                         creates one otherwise. Same-machine resume is the
#                                         common case and used to fail outright there
#                                         (`worktree_creation_failed`), which forced runs to
#                                         hand-roll the takeover. It reports
#                                         `adopted_worktree` so the caller can see which
#                                         path ran, and `resume_reason` so an operator can
#                                         see WHY the unit was offered -- notably
#                                         `parked_with_pr`, a unit that reported and opened
#                                         its PR rather than one that died mid-drive, and
#                                         `report_incomplete`, a unit whose queue is
#                                         drained and which never opened one at all, so it
#                                         re-enters the Unified Run at §5 with nothing left
#                                         to drive.
#
# One unit <-> one branch <-> one worktree <-> one PR. The sequence is fixed:
#   1. fetch origin (a claim that cannot be pushed is not a claim -- see below);
#   2. verify the unit is unclaimed THROUGH THE READER (lib/claims.sh, the same scan
#      list-claims.sh renders, so writer and reader can never disagree);
#   3. create the unit's worktree + branch via the sanctioned creator;
#   4. stamp `claim: <branch>` into the claimed artifacts IN THE WORKTREE CHECKOUT;
#   5. commit the claim (fixed subject, `Unit: <unit-id>` trailer) and push -u at once.
#
# Output: {"claimed": true, "unit": "...", "branch": "work-...", "worktree_path": "...",
#          "artifacts": [...], "announced": bool, "announce_reason": "..."}
#     or: {"claimed": false, "reason": "...", ...} on stderr with a non-zero exit.
# Refusal reasons: already_claimed (names the holding branch and unit), no_origin,
# origin_unreachable, mission_missing, artifact_missing, no_frontmatter, push_failed.
#
# NEVER PROMPTS. It is the coordination step of an unattended runner.
#
# CLAIMING ANNOUNCES (see step 7). The claim is the first published, irreversible-in-
# practice commitment a run makes, and until this seam existed nothing told a PERSON:
# the first human-visible artifact was the pull request, opened only after every
# ticket in the unit had been driven. For an unattended fleet that silent window is
# the difference between "the routine is working" and "the routine is dead", and an
# operator could not tell which. The announcement lives HERE rather than in
# commands/drive.md because this is where the fact becomes true, so every caller of
# claim.sh -- including `resume` below -- announces through one seam.
#
# THE STAMP RIDES THE WORKTREE, NEVER THE MAIN TREE. The runner's main checkout must
# stay clean between ticks (the /specificate batch commits on main and depends on that),
# and the claim is branch-only by design: main never shows a claim, so no merge ever
# has to un-stamp one.
#
# AN UNREACHABLE ORIGIN FAILS LOUDLY HERE. The reader degrades offline; the writer
# must not. A claim nobody else can see is not a claim, and proceeding to drive on
# one is exactly the double-pick the protocol exists to prevent.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"

fail() {
    printf '{"claimed": false, "reason": "%s"%s}\n' "$1" "${2:-}" >&2
    exit 1
}

usage() {
    echo 'Usage: claim.sh mission <slug> | claim.sh batch <ticket-file>... | claim.sh resume <unit-id>' >&2
}

kind="${1:-}"
case "$kind" in
    mission | batch | resume) shift ;;
    *)
        usage
        exit 1
        ;;
esac

if [ "$#" -eq 0 ]; then
    usage
    exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo '{"claimed": false, "reason": "not inside a git repository"}' >&2
    exit 1
fi
repo_root="$(git rev-parse --show-toplevel)"

# --- 1. Origin is mandatory for the writer ---------------------------------
git config --get remote.origin.url >/dev/null 2>&1 \
    || fail "no_origin" ', "detail": "a claim is a pushed branch; this repository has no origin remote"'
[ "$(claims_fetch)" = "true" ] \
    || fail "origin_unreachable" ', "detail": "refusing to claim a unit without a reachable origin -- an unpushed claim is not a claim"'
# The writer refuses without a reachable origin, so reaching this line means the fetch ran.
# The flag has to be set HERE because `claims_fetch` above runs in a command substitution and
# the value it sets dies with that subshell (see lib/claims.sh); without it the merged lookup
# is skipped as `offline` and `resume` cannot see a `superseded` claim at all.
CLAIMS_FETCH_OK=true

base=$(claims_base)

# --- 1b. RESUME: take over a claim whose run stopped -----------------------
# A whole separate path, because resuming inverts nearly every step of a fresh claim:
# the unit is already claimed (that is the precondition, not the refusal), the
# artifacts are already stamped, and the worktree must start at the PUBLISHED BRANCH
# TIP rather than the base -- the earlier run's commits are the work being continued,
# and cutting from the base would silently re-drive tickets that branch already
# archived.
#
# THE RACE IS RESOLVED BY GIT, NOT BY A CLOCK READ LOCALLY. Two runners can both see a
# unit as resumable in the same instant; both create a worktree at tip T and both push
# a takeover commit. The first push wins and the second is rejected non-fast-forward --
# exactly how `branch_collision` already resolves two fresh claims. The loser tears its
# worktree down and reports a retryable reason, having taken nothing. Nothing anywhere
# decides the winner by comparing timestamps, which is what makes this safe under clock
# skew between a local runner and a cloud one.
if [ "$kind" = "resume" ]; then
    unit="$1"
    resume_row=$(claims_scan "$base" | awk -F'\t' -v u="$unit" '$1 == u { print; exit }')
    [ -n "$resume_row" ] \
        || fail "not_claimed" ', "unit": "'"${unit}"'", "detail": "no claim in flight for that unit -- claim it fresh instead"'

    r_branch=$(printf '%s' "$resume_row" | cut -f2)
    r_at=$(printf '%s' "$resume_row" | cut -f3)
    r_author=$(printf '%s' "$resume_row" | cut -f5)
    r_resumable=$(printf '%s' "$resume_row" | cut -f6)
    r_reason=$(printf '%s' "$resume_row" | cut -f7)
    # FIELD 9, NOT 8. The artifact list is the row's LAST field, and `reported` was
    # inserted before it (2026-08-23) -- so this read was silently returning `true`/`false`
    # as the unit's whole artifact list. It is the tail by construction (see lib/claims.sh's
    # no-empty-field rule), which is what makes a fixed index safe at all.
    r_arts=$(printf '%s' "$resume_row" | cut -f9)

    # The verdict is the SHARED scan's, never re-derived here. A writer that decided
    # resumability for itself could take over a unit the reader still reports as
    # active -- the concurrent-write corruption this whole feature must not create.
    if [ "$r_resumable" != "true" ]; then
        case "$r_reason" in
            claim_active)
                fail "claim_active" ', "unit": "'"${unit}"'", "branch": "'"${r_branch}"'", "last_commit_at": "'"${r_at}"'", "detail": "a run is still working this unit (its branch tip is within the heartbeat window) -- resuming would double-drive it"'
                ;;
            foreign_identity)
                fail "foreign_identity" ', "unit": "'"${unit}"'", "branch": "'"${r_branch}"'", "author": "'"${r_author}"'", "detail": "another identity holds this claim; it is never resumable here, at any age"'
                ;;
            queue_drained)
                fail "queue_drained" ', "unit": "'"${unit}"'", "branch": "'"${r_branch}"'", "detail": "this unit has nothing left to drive AND it reported -- its story is committed and its PR is open, so it is waiting on a human, not on a runner; resuming it would only add an empty takeover commit to a branch under review. A drained unit that never reported is a different state and IS resumable (report_incomplete)"'
                ;;
            # A CLAIM WHOSE WORK IS ALREADY ON THE BASE (2026-08-26). Named on its own rather
            # than left to the default, because the operator reading this refusal needs to
            # learn that the pull request MERGED -- a generic denial sends them looking for a
            # live run that does not exist. Measured: a mission unit was offered as resumable
            # five days after its own pull request merged, and taking that offer costs a full
            # story-and-pull-request cycle whose only correct outcome is to be closed.
            superseded)
                fail "superseded" ', "unit": "'"${unit}"'", "branch": "'"${r_branch}"'", "detail": "this unit'"'"'s work already reached the base -- a merged pull request has this branch as its head, or every one of its tickets is archived on the base. There is nothing left to drive and nothing for a human to merge; nothing here deletes the branch or closes the pull request, so an operator closes it out"'
                ;;
            shallow_history)
                fail "shallow_history" ', "unit": "'"${unit}"'", "branch": "'"${r_branch}"'", "detail": "this clone'"'"'s history is truncated, so whether the branch already merged is unanswerable here -- the verdict is suppressed rather than guessed. Deepen the clone (a reachable origin does it automatically) and ask again"'
                ;;
            # THE DEFAULT NO LONGER ASSERTS A CAUSE. It named `identity_unresolved` for every
            # unrecognised reason, so a verdict added to the scan without a case here was
            # reported as a missing git identity -- which is what `superseded` and
            # `shallow_history` were both doing until this change.
            identity_unresolved)
                fail "identity_unresolved" ', "unit": "'"${unit}"'", "branch": "'"${r_branch}"'", "detail": "this checkout has no git config user.email, so it cannot establish the claim is its own"'
                ;;
            *)
                fail "not_resumable" ', "unit": "'"${unit}"'", "branch": "'"${r_branch}"'", "resume_reason": "'"${r_reason}"'", "detail": "the shared scan reports this claim as not resumable; the reason it gave is carried above verbatim"'
                ;;
        esac
    fi

    # PIN THE TIP THE DECISION WAS MADE ON. The scan just fetched, so this is the tip
    # that was judged resumable. The worktree creator fetches again, which is what
    # would otherwise leave the race half-open: a runner that lost by a second would
    # check out the WINNER'S new tip, and its takeover would then push as a clean
    # fast-forward -- two runners driving one unit, each believing it won. Comparing
    # the created HEAD against this sha below closes that window deterministically,
    # and the non-fast-forward push rejection remains as the second layer.
    r_observed_tip=$(git rev-parse --verify --quiet "refs/remotes/origin/${r_branch}^{commit}" 2>/dev/null || true)

    # ADOPT THE WORKTREE THIS MACHINE ALREADY HAS, rather than failing through the creator.
    # Resumption's narrow, safe case is "your own claim, on your own machine" -- and that is
    # exactly the case where `.worktrees/<unit>/` still exists, so the creator refused with
    # `worktree already exists` and resume returned `worktree_creation_failed` EVERY time.
    # The observed cost was a run hand-rolling the takeover (the empty commit, the push, the
    # notifier) by replicating this script's internals, which is the failure the sanctioned
    # scripts exist to prevent.
    #
    # Adoption is gated on the SAME pin the race check uses: the existing worktree must be on
    # the claim's branch and its HEAD must equal the tip the resumability decision observed.
    # A worktree sitting on some other commit is not the thing that was judged resumable, so
    # it falls through to the creator and fails loudly rather than being driven silently.
    r_adopted=false
    r_existing="${repo_root}/.worktrees/${unit}"
    if [ -n "$r_observed_tip" ] && [ -d "$r_existing" ] \
        && [ "$(git -C "$r_existing" rev-parse --abbrev-ref HEAD 2>/dev/null || true)" = "$r_branch" ] \
        && [ "$(git -C "$r_existing" rev-parse HEAD 2>/dev/null || true)" = "$r_observed_tip" ]; then
        r_adopted=true
        worktree_path="$r_existing"
        branch="$r_branch"
    elif create_out=$(sh "${SCRIPT_DIR}/../../branching/scripts//create-mission-worktree.sh" --branch "$r_branch" "$unit"); then
        worktree_path=$(printf '%s' "$create_out" | sed -n 's/.*"worktree_path":[ ]*"\([^"]*\)".*/\1/p')
        branch=$(printf '%s' "$create_out" | sed -n 's/.*"branch":[ ]*"\([^"]*\)".*/\1/p')
    else
        fail "worktree_creation_failed" ', "unit": "'"${unit}"'", "branch": "'"${r_branch}"'", "detail": "see the creator'"'"'s error above"'
    fi
    if [ -z "$worktree_path" ] || [ -z "$branch" ]; then
        fail "worktree_creation_failed" ', "detail": "could not read worktree_path/branch from the creator"'
    fi

    # AN ABORT MAY ONLY DESTROY WHAT THIS INVOCATION CREATED. Tearing down an ADOPTED
    # worktree would delete local state this run did not make -- including a developer's
    # uncommitted work in it -- to report a race it merely lost.
    abort_resume() {
        if [ "$r_adopted" != "true" ]; then
            ( cd "$repo_root" && sh "${SCRIPT_DIR}/../../branching/scripts//cleanup-mission-worktree.sh" "$unit" ) >/dev/null 2>&1 || true
        fi
        fail "$1" "${2:-}"
    }

    # The pinned tip, checked (see above). A mismatch means the branch moved between
    # the decision and the checkout -- another runner's takeover, or the original run
    # waking up and committing. Either way this runner did not win, and it takes nothing.
    r_actual_tip=$(git -C "$worktree_path" rev-parse HEAD 2>/dev/null || true)
    if [ -n "$r_observed_tip" ] && [ "$r_actual_tip" != "$r_observed_tip" ]; then
        abort_resume "resume_race_lost" ', "unit": "'"${unit}"'", "branch": "'"${branch}"'", "observed_tip": "'"${r_observed_tip}"'", "actual_tip": "'"${r_actual_tip}"'", "detail": "the claim branch moved between the resumability decision and the checkout; nothing was resumed -- retry"'
    fi

    # PUBLISH THE TAKEOVER, through the same commit seam as everything else -- an EMPTY
    # commit, because the takeover is a fact about who is driving rather than a change
    # to any file, and it must not show up in the PR diff. Its push is also the race's
    # arbiter, which is why it happens before a single line of work.
    ( cd "$worktree_path" && sh "${SCRIPT_DIR}/../../commit/scripts//commit.sh" --allow-empty \
        --trailer "Unit: ${unit}" \
        "Resume a PR-unit" \
        "An earlier run claimed this unit and stopped before delivering it -- mid-drive, or with its queue drained and no pull request opened; its branch tip fell outside the heartbeat window, so the unit was offered as resumable and this runner took it over" \
        "None -- coordination only; the takeover changes no file and never reaches the PR diff" \
        "None" "None" \
        "list-claims.sh reports this unit as claim_active again once the takeover is pushed" ) >&2 \
        || abort_resume "commit_failed" ', "branch": "'"${branch}"'"'

    if git -C "$worktree_path" push --quiet origin "$branch" >&2; then
        :
    else
        # Rejected: someone else's takeover landed on this branch first. Nothing was
        # taken -- retry on the next tick, when the scan reports the unit active again.
        abort_resume "resume_race_lost" ', "unit": "'"${unit}"'", "branch": "'"${branch}"'", "detail": "another runner published its takeover of this unit first; nothing was resumed -- retry"'
    fi

    r_notify="${WORKAHOLIC_NOTIFIER:-${SCRIPT_DIR}/../../specificate/scripts//notify-slack.sh}"
    r_out=$(sh "$r_notify" "Resumed ${unit} on ${branch} — an earlier run left it unfinished; driving it now" 2>/dev/null) || r_out=''
    case "$r_out" in
        *'"notified": true'*) r_announced=true ;;
        *) r_announced=false ;;
    esac
    r_announce_reason=$(printf '%s' "$r_out" | sed -n 's/.*"reason": *"\([^"]*\)".*/\1/p')
    [ -n "$r_out" ] || r_announce_reason="notifier_failed"

    printf '{"claimed": true, "resumed": true, "unit": "%s", "branch": "%s", "worktree_path": "%s", "adopted_worktree": %s, "resume_reason": "%s", "announced": %s, "announce_reason": "%s", "artifacts": [' \
        "$unit" "$branch" "$worktree_path" "$r_adopted" "$r_reason" "$r_announced" "$r_announce_reason"
    sep=""
    old_ifs="$IFS"
    IFS=','
    for rel in $r_arts; do
        printf '%s"%s"' "$sep" "$rel"
        sep=", "
    done
    IFS="$old_ifs"
    printf ']}\n'
    exit 0
fi

# --- 2. Resolve the unit and the artifacts it claims -----------------------
# `unit` is the id that rides the commit subject; `artifact_rels` are repo-relative
# paths (the shape the reader reports), resolved in the MAIN tree here and re-rooted
# into the worktree at stamp time.
artifact_rels=""
case "$kind" in
    mission)
        unit="$1"
        . "${SCRIPT_DIR}/../../mission/scripts//lib/resolve.sh"
        mission_file=$(mission_resolve "${repo_root}/.workaholic" "$unit")
        # A MISSING mission.md IS AN ERROR NOW (decision J1/J3). It used to be normal:
        # a mission could live on an unmerged branch in its own worktree, so absence
        # from the main tree said nothing. Missions are published to main, so absence
        # means one of two real problems -- no such mission, or this checkout is behind
        # origin/main (the freshness step in commands/drive.md exists to rule the second
        # one out before claiming). Both are worth reporting; swallowing them would
        # claim a unit whose plan the runner has never read.
        [ -f "$mission_file" ] || fail "mission_missing" ', "unit": "'"${unit}"'", "resolved": "'"${mission_file}"'", "detail": "no mission.md at that path in this checkout -- either the slug is wrong or this checkout is behind the base; run branching/scripts/sync-main.sh"'
        case "$mission_file" in
            "${repo_root}/"*) artifact_rels="${mission_file#"${repo_root}/"}" ;;
        esac
        ;;
    batch)
        unit="batch-$(date +%Y%m%d%H%M%S)"
        for arg in "$@"; do
            [ -f "$arg" ] || fail "artifact_missing" ', "artifact": "'"${arg}"'"'
            abs=$(cd -- "$(dirname -- "$arg")" && pwd)/$(basename -- "$arg")
            case "$abs" in
                "${repo_root}/"*) : ;;
                *) fail "artifact_outside_repo" ', "artifact": "'"${arg}"'"' ;;
            esac
            artifact_rels="${artifact_rels}${abs#"${repo_root}/"}
"
        done
        ;;
esac
artifact_rels=$(printf '%s' "$artifact_rels" | grep -v '^$' || true)

# --- 3. Refuse a unit (or an artifact) already in flight -------------------
# Both checks matter: the unit id catches a second runner claiming the same mission,
# and the artifact overlap catches a batch that scoops up a ticket another branch
# already took under a different batch id.
#
# A `superseded` CLAIM IS NOT IN FLIGHT, AND SKIPPING IT IS THE OTHER HALF OF THE
# 2026-08-26 CHANGE (2026-08-27). `plan-units.sh` already resurveys the mission and
# tickets behind such a claim -- its `resurveyed[]` field names them, and `workaholic:drive`
# §1 says in as many words *a fresh claim drives them, because the old branch cannot land*.
# This loop read the verdict (`_held_reason` is right here) and ignored it, so the survey
# offered a unit that BOTH claim paths refused: a fresh claim answered `already_claimed`
# and `claim.sh resume` answered `superseded`, by design. Measured 2026-08-27 on this
# repository: mission `make-workaholify-converge-the-account-s-routines` was offered and
# named in `resurveyed[]` while its only holder, `work-20260819-113836`, had read
# `superseded` since the day before -- reachable by no path at all, and forbidding `ok` on
# every later tick. That is the shape `report_incomplete` was added to remove in
# 2026-08-19, one layer up.
#
# IT FREES THE WORK, NOT THE BRANCH. `superseded` stays *reported, never acted on*: nothing
# here deletes the old branch, closes its pull request or releases its claim, and the new
# claim is an ordinary `work-*` branch beside it. The bound is the one `resurveyed[]`
# already relies on and is derived in exactly one place (`lib/claims.sh`), so the survey's
# offer and this refusal cannot disagree again: every one of the unit's tickets is archived
# on the base, or a merged pull request has that branch as its head. Every other refusal is
# untouched -- a live claim, a colleague's, a `queue_drained` one and a `report_incomplete`
# one all refuse exactly as before, because only a claim already PROVED to hold nothing is
# claimable over.
rows=$(claims_scan "$base")
if [ -n "$rows" ]; then
    while IFS='	' read -r held_unit held_branch _held_at _held_stale _held_author _held_resumable _held_reason _held_reported held_arts; do
        [ -n "$held_unit" ] || continue
        if [ "$_held_reason" = "superseded" ]; then
            continue
        fi
        if [ "$held_unit" = "$unit" ]; then
            fail "already_claimed" ', "unit": "'"${unit}"'", "holder_branch": "'"${held_branch}"'", "holder_unit": "'"${held_unit}"'"'
        fi
        for rel in $artifact_rels; do
            old_ifs="$IFS"
            IFS=','
            for held in $held_arts; do
                if [ "$held" = "$rel" ]; then
                    IFS="$old_ifs"
                    fail "already_claimed" ', "artifact": "'"${rel}"'", "holder_branch": "'"${held_branch}"'", "holder_unit": "'"${held_unit}"'"'
                fi
            done
            IFS="$old_ifs"
        done
    done <<EOF
$rows
EOF
fi

# --- 4. Create the unit's worktree + branch --------------------------------
# The sanctioned creator: it cuts from the FETCHED origin/main, mints the canonical
# work-* branch name, and reports the worktree's real HEAD. The worktree directory is
# the unit id, so `.worktrees/<unit>` stays keyed 1:1 to the unit for both a mission
# (dir = slug) and a batch (dir = batch id).
if create_out=$(sh "${SCRIPT_DIR}/../../branching/scripts//create-mission-worktree.sh" "$unit"); then
    :
else
    fail "worktree_creation_failed" ', "unit": "'"${unit}"'", "detail": "see the creator'"'"'s error above"'
fi
worktree_path=$(printf '%s' "$create_out" | sed -n 's/.*"worktree_path":[ ]*"\([^"]*\)".*/\1/p')
branch=$(printf '%s' "$create_out" | sed -n 's/.*"branch":[ ]*"\([^"]*\)".*/\1/p')
if [ -z "$worktree_path" ] || [ -z "$branch" ]; then
    fail "worktree_creation_failed" ', "detail": "could not read worktree_path/branch from the creator"'
fi

# Undo a partial claim: the worktree and its branch exist only to hold a claim that
# was never published, so removing them leaves no debris and no false "unclaimed".
# Undo a partial claim COMPLETELY -- including the stamp this script wrote.
#
# The cleaner refuses a dirty worktree, correctly: it must never discard work it did not
# write. But claim.sh stamps `claim: <branch>` into the artifacts BEFORE committing, so on
# any post-stamp failure the worktree is dirty with exactly this script's own edit, the
# cleaner refuses, and the claim strands a worktree and a local branch. The next attempt
# then fails as `worktree_creation_failed` and buries the original cause -- observed
# 2026-08-01. So the stamps are reverted by targeted path first, which is safe precisely
# because this script knows which paths it touched and wrote them seconds ago; anything
# else in the worktree still stops the cleaner, as it should.
abort_claim() {
    if [ -n "${worktree_path:-}" ] && [ -d "$worktree_path" ]; then
        for _ac_rel in ${artifact_rels:-}; do
            git -C "$worktree_path" checkout -- "$_ac_rel" >/dev/null 2>&1 || true
        done
    fi
    ( cd "$repo_root" && sh "${SCRIPT_DIR}/../../branching/scripts//cleanup-mission-worktree.sh" "$unit" ) >/dev/null 2>&1 || true
    fail "$1" "${2:-}"
}

# --- 5. Stamp the claim in the WORKTREE checkout ---------------------------
# For a mission, resolve again against the WORKTREE's own .workaholic -- verified as
# still load-bearing, for a reason unrelated to the retired stranded-artifact one.
# The stamp belongs to the worktree checkout, and that checkout was cut from the
# FETCHED origin/<base>, which the main tree need not match: a mission created or
# archived on the base since this checkout last advanced resolves to a different path
# there. Resolving against the checkout being written is therefore the correct
# reading, not a duplicate of step 2 -- and the resolver takes an explicit root
# precisely so this is not a cwd guess. Absence here is a genuine failure, which
# abort_claim already reports.
if [ "$kind" = "mission" ]; then
    artifact_rels=""
    wt_mission=$(mission_resolve "${worktree_path}/.workaholic" "$unit")
    [ -f "$wt_mission" ] || abort_claim "artifact_missing" ', "artifact": "'"${wt_mission}"'"'
    artifact_rels="${wt_mission#"${worktree_path}/"}"
fi

stamp_claim() {
    _sc_file="$1"
    _sc_branch="$2"
    _sc_tmp="${_sc_file}.claim.$$"
    awk -v br="$_sc_branch" '
        NR == 1 && $0 == "---" { in_fm = 1; print; next }
        in_fm && /^---[ \t]*$/ { if (!done) { print "claim: " br; done = 1 } in_fm = 0; print; next }
        in_fm && /^claim:[ \t]*/ { print "claim: " br; done = 1; next }
        { print }
        END { exit(done ? 0 : 1) }
    ' "$_sc_file" > "$_sc_tmp" 2>/dev/null && mv "$_sc_tmp" "$_sc_file" && return 0
    rm -f "$_sc_tmp" 2>/dev/null || true
    return 1
}

for rel in $artifact_rels; do
    target="${worktree_path}/${rel}"
    [ -f "$target" ] || abort_claim "artifact_missing" ', "artifact": "'"${rel}"'", "detail": "not present in the claim worktree"'
    stamp_claim "$target" "$branch" \
        || abort_claim "no_frontmatter" ', "artifact": "'"${rel}"'", "detail": "a claimed artifact must carry YAML frontmatter to stamp"'
done

# --- 6. Commit and push -- immediately, in that order ----------------------
# THE UNIT ID RIDES A TRAILER (see lib/claims.sh). It was the subject until 2026-08-01,
# which capped it at the 50-character subject rule and made every mission with a slug
# longer than 44 characters permanently unclaimable -- four of five active missions, each
# refused as an unexplained `commit_failed`. The subject is now fixed and short; the id
# goes where length does not matter and a script can read it back exactly.
set -- --trailer "Unit: ${unit}" "Claim a PR-unit" \
    "The runner takes PR-unit ${unit} before driving it; the claim is published so every other runner's reader sees the unit in flight and never double-picks it" \
    "None -- coordination only; the stamp is branch-local and never reaches main" \
    "None" "None" \
    "list-claims.sh reports this unit as claimed on ${branch} from any clone"
for rel in $artifact_rels; do
    set -- "$@" "$rel"
done
# Capture the commit seam's own output so a refusal can NAME its cause. A bare
# `commit_failed` sent a live run looking at the commit machinery when the real answer was
# a rejected subject, printed plainly by check-subject.sh and then thrown away.
commit_log=$(mktemp "${TMPDIR:-/tmp}/workaholic-claim-commit.XXXXXX")
if ( cd "$worktree_path" && sh "${SCRIPT_DIR}/../../commit/scripts//commit.sh" "$@" ) >"$commit_log" 2>&1; then
    cat "$commit_log" >&2
    rm -f "$commit_log"
else
    cat "$commit_log" >&2
    commit_detail=$(sed -n 's/^Error: //p' "$commit_log" | head -1 | tr -d '"\\' | cut -c1-200)
    rm -f "$commit_log"
    [ -n "$commit_detail" ] || commit_detail="see the commit output above"
    abort_claim "commit_failed" ', "branch": "'"${branch}"'", "detail": "'"${commit_detail}"'"'
fi

if git -C "$worktree_path" push -u --quiet origin "$branch" >&2; then
    :
else
    # Classify the failure before reporting it. The branch name is minted from the
    # clock to the second (create-mission-worktree.sh), so two runners claiming
    # different units in the SAME second mint the SAME name -- and neither can see
    # the other's remote ref yet, so the collision surfaces only here, as a rejected
    # push. That rejection is the protocol working: without it, the loser's claim
    # commit would land on the winner's branch and one unit would silently vanish
    # from the reader (a branch reports only its newest `Claim` subject). Name it
    # `branch_collision` so a runner retries on the next tick instead of reading it
    # as a broken remote -- the very next second mints a different name.
    git fetch --quiet origin >/dev/null 2>&1 || true
    if git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
        abort_claim "branch_collision" ', "branch": "'"${branch}"'", "detail": "another runner minted this work-* branch name in the same second; nothing was claimed -- retry"'
    fi
    abort_claim "push_failed" ', "branch": "'"${branch}"'", "detail": "the claim was not published; nothing was claimed"'
fi

# --- 7. Announce the claim -- AFTER the push, and NEVER load-bearing -------
# Deliberately placed below every `abort_claim` call site and outside that error
# path entirely. claim.sh treats each post-worktree failure as a reason to tear the
# worktree down, so folding the notice into that path would make a Slack outage
# start DISCARDING claims. A claim that succeeded and an announcement that did not
# are two different facts, and only the first one gates the run -- so this cannot
# change the exit status, the worktree, or the `claimed: true` contract. It reports
# its own outcome instead, so a run report can say plainly that the claim landed and
# the notice did not.
announce_claim() {
    _ac_count=$(printf '%s' "$artifact_rels" | grep -c . || true)
    [ -n "$_ac_count" ] || _ac_count=0
    _ac_text="Claimed ${unit} on ${branch} (${_ac_count} artifact(s)) — driving now"
    # The notifier is reached AS A SCRIPT (the same one /drive's route step uses), never
    # as an inline curl: one notifier, one place where the token is handled. The override
    # is the house test seam (cf. WORKAHOLIC_SLACK_API_URL in notify-slack.sh) -- the
    # hermetic suite must be able to make the notifier FAIL, which is the whole point of
    # the never-load-bearing contract and is not reachable through a URL override.
    _ac_script="${WORKAHOLIC_NOTIFIER:-${SCRIPT_DIR}/../../specificate/scripts//notify-slack.sh}"
    if _ac_out=$(sh "$_ac_script" "$_ac_text" 2>/dev/null); then
        case "$_ac_out" in
            *'"notified": true'*) printf 'true\t' ;;
            *) printf 'false\t' ;;
        esac
        printf '%s' "$_ac_out" | sed -n 's/.*"reason": *"\([^"]*\)".*/\1/p'
        printf '\n'
    else
        # A notifier that exits non-zero, or is missing outright, is still just a
        # notice that did not happen.
        printf 'false\tnotifier_failed\n'
    fi
}
announced_row=$(announce_claim 2>/dev/null || printf 'false\tnotifier_failed\n')
announced=$(printf '%s' "$announced_row" | cut -f1)
announce_reason=$(printf '%s' "$announced_row" | cut -f2)
case "$announced" in
    true | false) ;;
    *) announced=false; announce_reason="notifier_failed" ;;
esac

printf '{"claimed": true, "unit": "%s", "branch": "%s", "worktree_path": "%s", "announced": %s, "announce_reason": "%s", "artifacts": [' \
    "$unit" "$branch" "$worktree_path" "$announced" "$announce_reason"
sep=""
for rel in $artifact_rels; do
    printf '%s"%s"' "$sep" "$rel"
    sep=", "
done
printf ']}\n'
