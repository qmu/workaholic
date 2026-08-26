#!/bin/sh
# Shared claim-protocol reader -- the SINGLE implementation of "which PR-units are
# in flight", sourced by both consumers so the reader and the writer cannot drift.
#
#   list-claims.sh  renders this scan as JSON (the human/agent-facing reader).
#   claim.sh        verifies a unit is unclaimed through this SAME scan before it
#                   creates anything (a writer that carried its own scan would be
#                   free to disagree with the reader, which is exactly the state a
#                   coordination protocol must not have).
#
# THE MODEL (docs/loop-engineering-workflow.md G3): the repository is the
# coordination medium. A claim is a commit carrying a `Unit: <unit-id>` trailer under the
# fixed subject `Claim a PR-unit`, on a fresh work-* branch, stamping `claim: <branch>`
# into the claimed artifacts' frontmatter, pushed immediately.
#
# THE UNIT ID RIDES A TRAILER, NOT THE SUBJECT, and that is a correctness requirement
# rather than a style choice. It used to be the subject -- `Claim <unit-id>` -- which
# meant the id had to fit inside the 50-character subject rule commit.sh enforces. A
# mission's unit id is its slug, and four of the five active missions had slugs long
# enough to blow the cap (64-77 characters with the prefix), so `commit.sh` refused the
# claim commit and those missions were UNCLAIMABLE -- 80% of the roadmap, reported to the
# runner only as `commit_failed` (measured 2026-08-01). A trailer has no length limit and
# `git log --format='%(trailers:key=Unit,valueonly)'` reads it back exactly.
#
# The legacy subject form is still recognised, because claims pushed before this change
# are in flight on real branches and a reader that stopped seeing them would report those
# units as free -- the double-pick the protocol exists to prevent. So the set of claims in flight is exactly the set
# of remote branches carrying commits not yet on the base -- no lock file, no server,
# nothing to leak when a runner dies. A merge empties a claim by definition; deleting
# the branch releases it explicitly.
#
# THAT MODEL REQUIRES COMPLETE HISTORY, AND SAYS SO NOW.
# "commits not yet on the base" is `git rev-list --count base..ref`, which is only
# meaningful when the merge base is inside the clone. In a SHALLOW clone it is not: the
# range cannot be reduced, so git counts the whole visible window and a branch whose
# commits all reached the base still reports a large positive `ahead`. The scan then
# finds the claim commit in its history and reports a PR-unit that merged days ago.
#
# Measured 2026-08-04 on the hourly unattended runner, in the cloud container it always
# runs in (`git rev-parse --is-shallow-repository` was `true` on the fresh clone). For
# `origin/claude/sharp-rubin-xiorxm`, merged as PR #109 on 2026-07-30:
# `rev-list --count` returned 154 while shallow and 0 after `--unshallow`, and the unit
# was offered as `resumable` -- past BOTH safety gates, since the identity matched and
# the heartbeat had lapsed five days earlier. ~180 merged-but-undeleted remote branches
# here are candidates, and which ones surface depends on the container's clone depth, so
# the symptom is intermittent across ticks.
#
# TWO ANSWERS, DELIBERATELY DIFFERENT, because the condition has two very different
# repairs available:
#   1. REPAIR when possible -- `claims_fetch` deepens a shallow clone (`--unshallow`)
#      before anything reads ancestry. This restores the reader's actual question rather
#      than working around it, and costs one fetch per container lifetime, not per scan.
#   2. DEGRADE LOUDLY when not -- with an unreachable origin the clone stays shallow, so
#      `claims_shallow` reports `true` to both consumers (which forbid `ok` on it exactly
#      as they do on `current: false`) and any branch whose merge base is unreachable is
#      reported `resumable: false` with reason `shallow_history`. An unanswerable question
#      must not render as `heartbeat_lapsed`.
# Doing only (2) would leave a runner that starts shallow permanently unable to see its
# own genuinely resumable units, which is the recovery path the protocol depends on.
#
# The claim is still LISTED when history is truncated, rather than dropped. That follows
# the same asymmetry as the offline case below: over-reporting a claim makes a runner
# wait, while under-reporting one double-picks work.
#
# Usage (from a drive script, with SCRIPT_DIR its own scripts/ dir):
#   . "<scripts-dir>/lib/claims.sh"
#   claims_fetch            # echoes true/false -- NEVER fails (see the asymmetry below)
#   claims_base             # echoes the base ref the unmerged set is measured against
#   claims_scan "<base>"    # echoes one TSV row per claim
#
# `claims_scan` emits, tab-separated, one row per claim:
#   unit <TAB> branch <TAB> last_commit_at <TAB> stale <TAB> author <TAB>
#   resumable <TAB> resume_reason <TAB> artifact,artifact,...
# where `branch` is the SHORT name (no `origin/` prefix -- the name the stamp carries),
# `stale` is true|false against WORKAHOLIC_CLAIM_STALE_HOURS (default 24), and the
# artifact list is comma-separated repo-relative paths (empty when a claim commit
# stamped nothing that survives at the tip). The artifact list stays LAST because it
# is the only variable-length field; every consumer reads it as the tail.
#
# RESUMABILITY: A CLAIM NOBODY FINISHES USED TO BE UNREACHABLE FOREVER.
# The design record says in-flight state lives on the claim branch and "the next tick
# re-claims and resumes from what is pushed" (docs/loop-engineering-workflow.md I5).
# The implementation did the opposite, measured 2026-08-01: plan-units.sh dropped every
# claimed unit as `claimed`, and claim.sh refused the same unit as `already_claimed`, so
# NO survey ever offered it again -- not the same runner's next tick, not another runner,
# not a developer typing /drive. That is survivable for a local runner whose worktree is
# still on disk, and fatal for a cloud runner whose worktree dies with its sandbox: the
# pushed branch is the sole surviving copy and nothing routed anyone to it.
#
# The verdict is computed HERE, in the one scan all three consumers read, for the same
# reason the claim check is: a surveyor and a writer that each decided resumability for
# themselves would be free to disagree, and this protocol's one intolerable state is the
# reader and the writer disagreeing about what is in flight.
#
# THREE conditions, and the ORDER matters -- identity is checked first because a foreign
# claim is never resumable at ANY age, and the queue check comes last because it is the
# only one that costs git calls:
#
#   1. SAME IDENTITY. The claim commit's author email must equal this runner's
#      `git config user.email`. The governing principle (developer, 2026-08-01) is that
#      a *pushed claim is the loop's work* -- merging to main means the runner
#      implemented it, and work you mean to keep in your own hands should never have
#      been pushed as a claim. That is what makes same-identity resumption safe rather
#      than reckless: it never licenses taking over a colleague's claim. An unresolvable
#      identity resumes nothing, the same conservative reading plan-units.sh applies to
#      mission ownership.
#   2. NOT ACTIVE. The branch tip must be older than
#      WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES (default 30). THE BRANCH TIP *IS* THE
#      HEARTBEAT: heartbeat.sh refreshes it with an empty commit at a bounded interval,
#      and any ordinary work commit refreshes it too -- which is correct, since a run
#      that is committing is a run that is alive. Deciding liveness this way needs no
#      lock file and no server (the protocol forbids both), pollutes no PR diff (an
#      empty commit changes no file), and leaks nothing when a runner dies: the signal
#      lives on the very branch that a merge or a release already cleans up.
#   3. SOMETHING LEFT TO DRIVE. At least one of the unit's tickets must still be
#      undriven ON THAT BRANCH -- under `.workaholic/tickets/todo/` at the tip.
#      Without this, resumability could not tell a run that DIED from a unit that
#      FINISHED: a `review` unit stops at its PR by design and its branch correctly
#      stays unmerged, so its tip stops advancing and its heartbeat lapses exactly like
#      an abandoned one. Measured 2026-08-01, hours after resumption shipped: the hourly
#      runner re-took `batch-20260731185901` at 21:57, 22:57 and 00:58, and only the
#      first pass did any work -- the other two added an empty `Resume` commit to a
#      branch a human was reviewing and stopped. It does not terminate; a review PR can
#      sit for days. The unit-outcome vocabulary already drew this line for `handoff`
#      versus "a review unit at a PR"; the resumability verdict simply had not learned
#      it.
#
#      AND A DRAINED QUEUE IS NOT ONE STATE (2026-08-19). The gate above answers "did the
#      run die, or did the unit finish?" -- but "finished" itself covers a unit that
#      REPORTED (story at the tip, pull request open, a human is what it waits for) and a
#      run that died AFTER archiving its last ticket and BEFORE opening anything, whose
#      work is pushed and which nobody has been told about. Both answered
#      `queue_drained`, so both were untouchable AND both had their tickets excluded
#      `claimed_reported` at every later survey -- no fresh claim reached them either.
#      The distinguishing signal is the one condition 3's own fork already reads: the
#      story file. Present => `queue_drained` (unchanged, this is what the 2026-08-01
#      gate protects); absent => `report_incomplete`, resumable, entering at §5 with an
#      empty queue. This NARROWS the gate; it does not reverse it.
#
#      How "left to drive" is read differs by unit kind, because a claim stamps
#      different things: a BATCH claims its ticket files, so the test is whether any of
#      them is still under todo/ at the tip (archive.sh renames a driven ticket, and the
#      reader already follows that rename). A MISSION claims only its `mission.md`,
#      which never lives under todo/, so the test is whether any ticket at the tip still
#      NAMES the mission -- the same question `queue-size.sh` asks of the working tree.
#      Reading it from the branch keeps the whole verdict offline-capable.
#
# The 24-hour `stale` flag keeps its separate meaning -- REPORTED, never acted on. It is
# not the resumption trigger: an hourly routine that recovers its own dropped unit only
# after a day is not a recovery path, which is why the heartbeat threshold is in minutes.
#
# `resume_reason` always answers "why is it in this state", and is NEVER empty (see the
# no-empty-field rule below): `heartbeat_lapsed`, `parked_with_pr` or `report_incomplete`
# when resumable, else `claim_active`, `foreign_identity`, `identity_unresolved`,
# `shallow_history`, `superseded`, or `queue_drained`.
# `parked_with_pr` splits the RESUMABLE case in two: a unit that reached its PR (its story
# file is committed at the branch tip) and merely has follow-up work, versus a run that
# died mid-drive. Both MAY be taken over; only the latter is a MANDATORY takeover, because
# forcing the parked one ahead of fresh work is what made an attended run spend its first
# forty minutes reopening a pull request the developer considered finished.
# `shallow_history` is the one that blames the INPUT rather than the unit: the clone
# cannot see far enough to say whether the branch is merged, so no verdict is offered.
# `queue_drained` gets its
# own word rather than folding into `claim_active` because the two call for opposite
# operator responses: `claim_active` means wait for the run, `queue_drained` means the
# work is done and a human -- not a runner -- is what it is waiting for. It is reported rather than merely implied
# so an operator can read WHY a unit is untouchable straight out of list-claims.sh.
# `report_incomplete` is the DRAINED case where no human is waiting, because none was ever
# told: the queue is empty and there is no story at the tip, so the run died between §4
# and §5 and its work sits pushed and undelivered. It is resumable and MANDATORY like
# `heartbeat_lapsed` -- a dead run's remains, not a unit waiting on a person -- and it
# narrows the 2026-08-01 drained gate rather than reversing it: a unit that DID report
# still answers `queue_drained` and is still untouchable.
# `superseded` is the claim whose CONTENT already reached the base by another route, so
# there is nothing in it to drive and nothing for a human to merge (`claims_superseded`).
# It is reported and never acted on, exactly like `stale`, and it must not forbid `ok`.
#
# Paths are assumed free of tabs, commas, quotes and backslashes -- true of every
# .workaholic/ artifact by construction (the ticket/mission filename rules), and the
# same assumption posix-lint.sh and the worktree scripts already make. That is what
# lets both consumers use flat TSV and unescaped JSON.

# Fetch origin, tolerating an unreachable one. Echoes `true` when the fetch actually
# ran, `false` otherwise -- and NEVER returns non-zero.
#
# THE ASYMMETRY IS DELIBERATE. An unreachable origin only DEGRADES the reader (it
# reports `fetched: false` and answers from the last-known remote-tracking refs) but
# must FAIL the writer loudly (claim.sh), because a claim that was not pushed is not
# a claim. False "unclaimed" is the dangerous error: it double-picks work. A stale
# reader over-reports claims, which merely makes a runner wait.
#
# THE MERGED LOOKUP BELOW RUNS THE SAME ASYMMETRY, and this is the sentence to read before
# changing it (2026-08-26): a wrong `merged` RELEASES work that is still in flight, a wrong
# `in flight` only delays a claim — so a lookup we could not make leaves the row precisely
# the verdict it would have had without it, and is reported by name instead.

# WHETHER THE LAST FETCH ACTUALLY RAN, for the one consumer inside this library that has to
# know: the merged-claim lookup below, which is a NETWORK read and must not be attempted on a
# run that has just proved it has no network. `claims_fetch` echoes the same answer to its
# caller; this is the copy `claims_scan` can see, because command substitution puts the scan
# in a subshell of its own and nothing it sets could travel back.
CLAIMS_FETCH_OK=false

# Where this library itself lives — what locates the sibling `claim-merged.sh` the merged
# lookup runs.
#
# THE CALLER SETS IT, and the `$0` walk below is only a fallback. A sourced file cannot ask
# where it is: `$0` is the CALLER's script, and the caller may sit in a worktree, a publish
# tree or the installed plugin cache. Every sourcer already computes its own script directory
# in order to source this file at all, so passing it costs one line and is the only form that
# is right by construction rather than by coincidence.
CLAIMS_LIB_DIR="${CLAIMS_LIB_DIR:-}"
if [ -z "$CLAIMS_LIB_DIR" ]; then
    for _cl_cand in "$(dirname -- "$0")/lib" "$(dirname -- "$0")"; do
        if [ -f "${_cl_cand}/claims.sh" ]; then
            CLAIMS_LIB_DIR=$(CDPATH= cd -- "$_cl_cand" && pwd)
            break
        fi
    done
    unset _cl_cand
fi

claims_fetch() {
    if ! git config --get remote.origin.url >/dev/null 2>&1; then
        CLAIMS_FETCH_OK=false
        printf 'false'
        return 0
    fi
    # REPAIR TRUNCATED HISTORY BEFORE ANYTHING READS ANCESTRY (see the header). A plain
    # `git fetch --prune` never deepens, so without this the scan's merged/unmerged test
    # stays unanswerable for the whole life of the container. Guarded on shallowness
    # because `--unshallow` errors on a complete repository, and best-effort because an
    # unreachable origin must degrade this reader, never fail it.
    if [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ]; then
        git fetch --unshallow --prune --quiet origin >/dev/null 2>&1 || true
    fi
    if git fetch --prune --quiet origin >/dev/null 2>&1; then
        CLAIMS_FETCH_OK=true
        printf 'true'
    else
        CLAIMS_FETCH_OK=false
        printf 'false'
    fi
}

# Is this clone's history truncated? Echoes true|false, never fails.
#
# Reported OUT to both consumers rather than folded into the TSV row, deliberately: it is
# a property of the whole scan, not of one claim, and the row's field count is load-bearing
# (see the no-empty-field note below -- adding a column is exactly how a reader starts
# shifting fields). `list-claims.sh` and `plan-units.sh` each call this alongside
# `claims_fetch`.
claims_shallow() {
    if [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ]; then
        printf 'true'
    else
        printf 'false'
    fi
}

# Can "is this branch merged into the base" actually be answered? True iff a merge base
# is visible in this clone. In a complete clone this is always true for any two refs with
# shared history; in a shallow one it is exactly the question the graft boundary makes
# unanswerable. $1 = base ref, $2 = branch ref.
claims_ancestry_ok() {
    [ -n "$(git merge-base "$1" "$2" 2>/dev/null || true)" ]
}

# The ref the "unmerged" set is measured against. origin/main is the truth; the
# remaining candidates keep the scan working in a fixture or a master-named repo.
# Echoes an empty string when nothing resolves (a repo with no base has no claims).
claims_base() {
    for _cb in origin/main origin/master main master; do
        if git rev-parse --verify --quiet "${_cb}^{commit}" >/dev/null 2>&1; then
            printf '%s' "$_cb"
            return 0
        fi
    done
    printf ''
}

# Read one frontmatter key out of a blob at <ref>:<path>. Same frontmatter shape as
# every other reader in the plugin (first match inside the leading --- block wins).
claims_blob_field() {
    git show "${1}:${2}" 2>/dev/null | awk -v key="$3" '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        index($0, key ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
    ' 2>/dev/null || true
}

# Map a path the claim commit touched to where that file lives NOW at the branch tip.
# $1 = the newline/tab rename map (old<TAB>new rows), $2 = the original path.
# Echoes $2 unchanged when it was never renamed (including when it was deleted --
# `git show <ref>:<gone>` then fails and the caller drops the artifact, which is the
# intended reading: a deleted artifact is not claimed).
claims_current_path() {
    printf '%s\n' "$1" | awk -F'\t' -v p="$2" '
        $1 == p { print $2; found = 1; exit }
        END { if (!found) print p }
    '
}

# THE RENAME MAP IS A HEURISTIC, AND THE RESOLUTION MUST NOT BE.
# `git diff --find-renames` pairs a delete with an add only when they are at least 50%
# similar, and it abandons inexact detection wholesale once a range exceeds
# `diff.renameLimit`. An archived ticket is not merely moved: it also gains its appended
# Final Report, so a short ticket carrying a long report lands UNDER that
# threshold and the move is reported as a plain add + delete. The rename map then has no
# row, `claims_current_path` hands back the todo/ path, `git show <tip>:<that>` fails, and
# THE ARTIFACT SILENTLY LEAVES THE CLAIM.
#
# One lost artifact produced both halves of the failure measured on 2026-08-04:
#   * plan-units.sh subtracted nothing, so a ticket already driven on a pushed branch was
#     offered again as fresh backlog -- and with no `excluded[]` row, because the survey
#     only reports items it SAW and dropped;
#   * claims_has_work fell through to its "no artifacts means unknown, so assume work
#     remains" branch, flipping a drained unit to `resumable` and inviting a takeover of a
#     branch whose PR was waiting on a human.
#
# So the tip-side path is resolved a second way when the first fails, and the second way is
# EXACT rather than statistical: `archive.sh` preserves the FILENAME (`todo/<user>/X.md` ->
# `archive/<branch>/X.md`), and a ticket filename is unique in the tree by construction (the
# `YYYYMMDDHHMMSS-slug.md` rule). So a lookup by basename under `.workaholic/tickets/` finds
# it regardless of how much its content changed, and regardless of how large the range is.
#
# It is applied ONLY to ticket paths, and only when the basename resolves to exactly one
# file. `mission.md` is the counter-example that fixes the scope: its basename is shared by
# every mission, so a general basename fallback would resolve one mission's claim onto
# another's file. Ambiguity therefore falls back to the mapped path, which drops the
# artifact -- the same conservative answer as before, never a guess.
#
# $1 = branch ref, $2 = the path the rename map produced, $3 = the claim-side path.
claims_resolve_at_tip() {
    if git cat-file -e "${1}:${2}" 2>/dev/null; then
        printf '%s' "$2"
        return 0
    fi
    case "$3" in
        .workaholic/tickets/*) ;;
        *) printf '%s' "$2"; return 0 ;;
    esac
    _crt_base="${3##*/}"
    _crt_hits=$(git ls-tree -r --name-only "$1" -- .workaholic/tickets 2>/dev/null \
        | awk -v b="$_crt_base" '{ n = length($0); m = length(b); if (n > m && substr($0, n - m) == "/" b) print }' || true)
    _crt_n=$(printf '%s' "$_crt_hits" | grep -c . || true)
    if [ "$_crt_n" = "1" ]; then
        printf '%s' "$_crt_hits"
    else
        printf '%s' "$2"
    fi
}

# Has this unit anything left to drive ON ITS OWN BRANCH? $1 = the branch ref,
# $2 = the comma-separated TIP-side artifact paths. Echoes true|false.
#
# This is condition 3 of the resumability verdict (see the header) and the answer to
# "did the run die, or did the unit finish?". Both unit kinds are handled, because a
# claim stamps different things for each:
#
#   BATCH  -- the artifacts ARE the tickets. Any one still under `.workaholic/tickets/
#             todo/` at the tip is undriven work, because archive.sh drives a ticket by
#             renaming it out of todo/ into archive/<branch>/.
#   MISSION -- the only artifact is `mission.md`, which never sits under todo/. So the
#             tickets are found the other way round: any ticket at the tip whose
#             `mission:` names this slug. Read at the branch tip, not the working tree,
#             so the answer is about the unit's own branch and stays offline-capable.
#
# A claim with no surviving artifacts at all answers `true` -- unknown is not the same
# as finished, and the conservative reading for a signal that GATES a takeover is to let
# the other two conditions decide rather than to silently declare the unit done.
claims_has_work() {
    _chw_ref="$1"
    _chw_arts="${2:-}"
    [ -n "$_chw_arts" ] || { printf 'true'; return 0; }

    _chw_mission=""
    _chw_old_ifs="$IFS"
    IFS=','
    for _chw_p in $_chw_arts; do
        case "$_chw_p" in
            .workaholic/tickets/todo/*)
                IFS="$_chw_old_ifs"
                printf 'true'
                return 0
                ;;
            */missions/*/mission.md)
                # Strip to the directory name: .../missions/<area>/<slug>/mission.md
                _chw_mission="${_chw_p%/mission.md}"
                _chw_mission="${_chw_mission##*/}"
                ;;
        esac
    done
    IFS="$_chw_old_ifs"

    [ -n "$_chw_mission" ] || { printf 'false'; return 0; }

    for _chw_t in $(git ls-tree -r --name-only "$_chw_ref" -- .workaholic/tickets/todo 2>/dev/null || true); do
        case "$(claims_blob_field "$_chw_ref" "$_chw_t" mission)" in
            "") continue ;;
            *"$_chw_mission"*) printf 'true'; return 0 ;;
        esac
    done
    printf 'false'
}

# Did this unit already REPORT -- i.e. reach the story+PR seam? $1 = branch ref,
# $2 = the short branch name. Echoes true|false.
#
# `/story` commits `.workaholic/stories/<branch>.md` as part of opening the pull request,
# so that file at the branch tip is durable, offline evidence that the unit got as far as a
# PR. That matters because "parked at its PR, waiting for a human" and "died mid-drive" are
# the same shape to every other signal: a `review` unit stops at its PR by design, its
# branch stays unmerged, its tip stops advancing, and its heartbeat lapses exactly like an
# abandoned run's. When such a unit still has follow-up tickets in todo/ on its branch it is
# genuinely resumable -- but reopening it reads to the operator as redoing finished work,
# which is what happened on an attended run (the developer interrupted twice to ask "there
# is already a PR -- what are you doing?").
#
# The STORY FILE is the signal rather than a `gh pr view` call, deliberately: the whole
# resumability verdict is offline-capable by construction, and one network call per claim
# would make the reader fail differently depending on connectivity -- the property this
# library spends its longest comment defending.
claims_has_story() {
    git cat-file -e "${1}:.workaholic/stories/${2}.md" 2>/dev/null && printf 'true' || printf 'false'
}

# Has this claim's work already reached the BASE by another route? $1 = base ref,
# $2 = the comma-separated CLAIM-SIDE artifact paths. Echoes true|false.
#
# "In flight" is `git rev-list --count base..ref` -- the right question for a branch whose
# work is genuinely outstanding, and the wrong one for a branch whose CONTENT reached the
# base some other way: a unit recovered by hand onto a fresh claim branch, a change
# re-applied, a revert-and-redo. Such a branch is unmerged forever, so it is claimed
# forever, and every consumer reads it as work.
#
# The cost was theoretical while `queue_drained` made every drained claim untouchable, and
# it stopped being theoretical the moment `report_incomplete` made a drained, unreported
# claim a MANDATORY takeover. Measured 2026-08-26, on the first run to hold that tier: it
# resumed `batch-20260819063000` exactly as designed, and the unit had been recovered by
# hand onto `work-20260821-221006` five days earlier -- both tickets already archived on
# the base, the behaviour shipped and refined since, and `git merge-tree` reporting ten
# conflicts of which three were `modify/delete` against a directory the base had deleted in
# a rename. The run spent a full story-and-pull-request cycle to produce a pull request
# whose only correct outcome was to be closed.
#
# THE SIGNAL IS "THE UNIT'S TICKETS ARE ARCHIVED ON THE BASE", NOT "THE DIFF IS CONTAINED".
# Containment is the more general test and it is WRONG for this case: the measured recovery
# landed REFINED rather than verbatim (the digest suffix became unconditional and the slug
# bound moved), so a containment test would have answered `false` on the very branch that
# provoked the rule. Archived-on-the-base asks the question the unit is actually about --
# was this work driven and delivered? -- and answers it with one `git ls-tree` against the
# base, offline, at the same cost as the resolution `claims_resolve_at_tip` already makes.
# Filenames are unique in the tree by construction (the `YYYYMMDDHHMMSS-slug.md` rule), and
# the branch directory under `archive/` is deliberately NOT compared: a ticket archived
# under ANY branch is delivered, and which branch delivered it is exactly what this test
# must not care about.
#
# IT ANSWERS FOR BATCH UNITS AND LEAVES MISSION UNITS ON TODAY'S READING, deliberately and
# in the open. A batch claim stamps its ticket files, so "are they archived?" is a direct
# question about the unit's own artifacts. A mission claim stamps only `mission.md`, which
# driving never archives -- the equivalent would have to walk every ticket on the base and
# read its `mission:` relation, which is a second parser of a many-valued relation for a
# shape nothing has measured. A unit carrying any non-ticket artifact answers `false`, so a
# mission claim keeps precisely the verdict it has today.
#
# REPORTED, NEVER ACTED ON. Nothing here deletes a branch, closes a pull request or breaks
# a claim -- `stale` has been reported-never-acted-on since the protocol shipped and this is
# the same kind of fact. It is `resumable: false` because there is nothing to drive, and for
# the same reason it must NOT forbid `ok` (drive/SKILL.md §7): a claim holding no work is
# the opposite of outstanding work.
claims_superseded() {
    _csp_base="$1"
    _csp_arts="${2:-}"
    [ -n "$_csp_arts" ] || { printf 'false'; return 0; }

    # One listing per claim, reused for every artifact -- the archive is the largest path
    # in the tree and this is the scan's most expensive gate, which is why it sits last
    # among the conditions that can still change the verdict.
    _csp_listed=""
    _csp_have_list=false
    _csp_total=0
    _csp_archived=0

    _csp_old_ifs="$IFS"
    IFS=','
    for _csp_p in $_csp_arts; do
        case "$_csp_p" in
            .workaholic/tickets/*) ;;
            # A mission unit (or anything else a claim may come to stamp) is out of scope:
            # answer `false` rather than guessing, so its verdict is untouched.
            *)
                IFS="$_csp_old_ifs"
                printf 'false'
                return 0
                ;;
        esac
        if [ "$_csp_have_list" = "false" ]; then
            _csp_listed=$(git ls-tree -r --name-only "$_csp_base" -- .workaholic/tickets/archive 2>/dev/null || true)
            _csp_have_list=true
        fi
        _csp_total=$((_csp_total + 1))
        _csp_bn="${_csp_p##*/}"
        if printf '%s\n' "$_csp_listed" | awk -v b="$_csp_bn" '
            { n = length($0); m = length(b); if (n > m && substr($0, n - m) == "/" b) { found = 1; exit } }
            END { exit found ? 0 : 1 }
        '; then
            _csp_archived=$((_csp_archived + 1))
        fi
    done
    IFS="$_csp_old_ifs"

    # EVERY ticket, not any: a unit half of whose tickets landed elsewhere still has work,
    # and calling it superseded would hide that half.
    if [ "$_csp_total" -gt 0 ] && [ "$_csp_total" -eq "$_csp_archived" ]; then
        printf 'true'
    else
        printf 'false'
    fi
}

# Has this claim branch's work reached the base through a MERGED pull request? $1 = branch
# name. Echoes `merged`, `not_merged` or `unanswerable`, and never fails.
#
# THIS IS THE CLAIM PROTOCOL'S ONE NETWORK READ, and every rule around it exists to keep
# that from costing the reader its offline contract (`list-claims.sh`: *the reader degrades
# offline*). `claims_superseded` above answers the same question from the tree and cannot
# answer it for a mission claim; this can, because a pull request has a head branch whatever
# the unit's grain.
#
# THE ASYMMETRY IS THE WHOLE DESIGN, and it runs the same way as `claims_fetch`'s: a wrong
# `merged` RELEASES work that is still in flight, and the release is what double-picks a
# colleague's unit. A wrong `in flight` only makes a runner wait. So an answer we could not
# read is NEVER promoted to `merged` — it leaves the row exactly the verdict it would have
# had before this lookup existed.
#
# IT IS SKIPPED, BY NAME, WHENEVER IT CANNOT SUCCEED. A run whose fetch just failed has
# proved it has no network, so spending a call per claim to be told so again is pure latency
# on the path a degraded runner is already on; `WORKAHOLIC_CLAIM_MERGED_LOOKUP=0` is the
# explicit opt-out for a caller that wants the scan purely local. Both are reported as
# reasons rather than silently answering `not_merged`.
#
# AT MOST ONE CALL PER CLAIM. It is invoked from exactly one place in the verdict chain, and
# the chain short-circuits before it whenever a cheaper gate already decided.
claims_merged_state() {
    _cms_branch="${1:-}"
    [ -n "$_cms_branch" ] || { printf 'unanswerable'; return 0; }

    _cms_enabled="${WORKAHOLIC_CLAIM_MERGED_LOOKUP:-1}"
    if [ "$_cms_enabled" = "0" ]; then
        claims_note_unanswered "$_cms_branch" disabled
        printf 'unanswerable'
        return 0
    fi
    if [ "${CLAIMS_FETCH_OK:-false}" != "true" ]; then
        claims_note_unanswered "$_cms_branch" offline
        printf 'unanswerable'
        return 0
    fi

    _cms_reader="${CLAIMS_LIB_DIR}/../claim-merged.sh"
    if [ ! -f "$_cms_reader" ]; then
        claims_note_unanswered "$_cms_branch" no_reader_script
        printf 'unanswerable'
        return 0
    fi

    _cms_out=$(sh "$_cms_reader" "$_cms_branch" 2>/dev/null || true)
    _cms_state=$(printf '%s' "$_cms_out" | sed -n 's/.*"state": "\([^"]*\)".*/\1/p')
    case "$_cms_state" in
        merged|not_merged)
            printf '%s' "$_cms_state"
            ;;
        *)
            _cms_reason=$(printf '%s' "$_cms_out" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
            claims_note_unanswered "$_cms_branch" "${_cms_reason:-unreadable}"
            printf 'unanswerable'
            ;;
    esac
}

# Record one claim the merged lookup could not answer for, so the scan can REPORT what it
# could not read rather than leaving it indistinguishable from what it read as live.
#
# IT GOES TO A FILE THE CALLER NAMES, not to a variable and not to an extra TSV column.
# `claims_scan` runs inside a command substitution, so a variable it sets dies with the
# subshell; and the row's field count is load-bearing — the header's longest warning is
# about exactly what happens when a column is added. A caller that wants the set creates a
# file, exports `CLAIMS_UNANSWERED_FILE`, and reads it afterwards; a caller that does not
# care sets nothing and this is a no-op.
claims_note_unanswered() {
    [ -n "${CLAIMS_UNANSWERED_FILE:-}" ] || return 0
    printf '%s\t%s\n' "$1" "$2" >> "$CLAIMS_UNANSWERED_FILE" 2>/dev/null || true
}

# Scan the remote branches for claims. $1 = base ref (from claims_base).
claims_scan() {
    _cs_base="${1:-}"
    [ -n "$_cs_base" ] || return 0

    _cs_hours="${WORKAHOLIC_CLAIM_STALE_HOURS:-24}"
    case "$_cs_hours" in
        '' | *[!0-9]*) _cs_hours=24 ;;
    esac
    _cs_now=$(date +%s)
    _cs_threshold=$((_cs_hours * 3600))

    # The liveness window, in MINUTES and deliberately short (see the header). A
    # malformed value falls back to the default rather than failing the scan: the
    # reader must keep answering, and a bad env var is not a reason to report no
    # claims at all.
    _cs_hb="${WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES:-30}"
    case "$_cs_hb" in
        '' | *[!0-9]*) _cs_hb=30 ;;
    esac
    _cs_hb_threshold=$((_cs_hb * 60))

    # Resolved once: whose runner this is. Empty means unresolvable, and every claim
    # is then somebody else's.
    _cs_me=$(git config user.email 2>/dev/null || true)

    for _cs_ref in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin 2>/dev/null | sort); do
        [ "$_cs_ref" = "origin/HEAD" ] && continue
        [ "$_cs_ref" = "$_cs_base" ] && continue

        # Unmerged? A branch whose commits all reached the base is released by
        # definition -- merging IS the release, so no separate signal is needed.
        _cs_ahead=$(git rev-list --count "${_cs_base}..${_cs_ref}" 2>/dev/null || echo 0)
        [ "$_cs_ahead" -gt 0 ] || continue

        # Fast filter: the newest claim commit in the unmerged range. A branch with
        # unmerged commits but no claim commit is ordinary in-flight work (someone's
        # hand-made branch), not a claim, and is not reported.
        #
        # TWO ACCEPTED FORMS. The current one is the fixed subject `Claim a PR-unit` with
        # the id in a `Unit:` trailer; the legacy one is `Claim <unit-id>` as the whole
        # subject. Both are read, and the trailer wins when both are present. Dropping the
        # legacy form would make every claim pushed before this change invisible, and an
        # invisible claim reads as free work.
        _cs_row=$(git log --format='%H%x09%s%x09%(trailers:key=Unit,valueonly,separator=%x20)' "${_cs_base}..${_cs_ref}" 2>/dev/null \
            | awk -F'\t' '
                $2 == "Claim a PR-unit" && $3 != "" { print $1 "\t" $3; exit }
                $2 ~ /^Claim [^ ]+$/ { print $1 "\t" substr($2, 7); exit }
              ' || true)
        [ -n "$_cs_row" ] || continue
        _cs_sha=$(printf '%s' "$_cs_row" | cut -f1)
        _cs_unit=$(printf '%s' "$_cs_row" | cut -f2)
        [ -n "$_cs_unit" ] || continue

        _cs_branch="${_cs_ref#origin/}"

        # The claimed artifacts are the files the claim commit touched that STILL
        # carry `claim: <branch>` at the tip -- so a later commit that removes a
        # stamp drops that artifact from the claim without any bookkeeping.
        #
        # THE STAMP IS READ AT THE FILE'S CURRENT PATH, NOT THE CLAIMED ONE. `archive.sh`
        # RENAMES a driven ticket (todo/<user>/X.md -> archive/<branch>/X.md) carrying its
        # stamp along, and looking the old path up at the tip finds nothing -- so every
        # batch unit silently lost its whole artifact list the moment its first ticket was
        # archived, and the survey then offered tickets that were already in flight. That
        # is the double-pick the protocol exists to prevent; it was observed live on
        # 2026-07-30. One tree-to-tree diff per claim gives the net old->new mapping
        # (chained renames collapse to a single row, so no walk is needed).
        _cs_renames=$(git diff --find-renames --name-status "$_cs_sha" "$_cs_ref" 2>/dev/null \
            | awk -F'\t' '$1 ~ /^R/ { print $2 "\t" $3 }' || true)

        # WHAT IS REPORTED IS THE BASE-SIDE PATH -- the one the claim commit stamped, which
        # is where the artifact still sits on the base. That is the coordinate space both
        # consumers work in: plan-units.sh compares against list-todo.sh's view of the
        # working tree, and claim.sh against paths it resolved in the main tree. Reporting
        # the archived path instead would be the useless half of the pair.
        # Both coordinate spaces are kept: `_cs_artifacts` is what the row REPORTS (the
        # base-side paths both consumers compare in), while `_cs_artifacts_tip` is where
        # those files actually live at the tip -- which is the only space in which
        # "is this ticket still undriven?" can be asked, since driving a ticket is
        # precisely a rename out of todo/.
        _cs_artifacts=""
        _cs_artifacts_tip=""
        for _cs_file in $(git diff-tree --no-commit-id --name-only -r "$_cs_sha" 2>/dev/null || true); do
            _cs_at_tip=$(claims_current_path "$_cs_renames" "$_cs_file")
            # The rename map first, then the exact by-filename resolution when it missed
            # (see claims_resolve_at_tip -- a below-threshold or skipped rename is not a
            # deleted artifact, and must not read as one).
            _cs_at_tip=$(claims_resolve_at_tip "$_cs_ref" "$_cs_at_tip" "$_cs_file")
            [ "$(claims_blob_field "$_cs_ref" "$_cs_at_tip" claim)" = "$_cs_branch" ] || continue
            if [ -z "$_cs_artifacts" ]; then
                _cs_artifacts="$_cs_file"
                _cs_artifacts_tip="$_cs_at_tip"
            else
                _cs_artifacts="${_cs_artifacts},${_cs_file}"
                _cs_artifacts_tip="${_cs_artifacts_tip},${_cs_at_tip}"
            fi
        done

        _cs_at=$(git log -1 --format='%cI' "$_cs_ref" 2>/dev/null || true)
        _cs_ct=$(git log -1 --format='%ct' "$_cs_ref" 2>/dev/null || echo "$_cs_now")

        # STALENESS IS REPORTED, NEVER AUTO-BROKEN. A tip older than the threshold
        # says "look at this", not "take it": a runner that reclaims on its own
        # verdict is a runner that can silently duplicate a colleague's in-flight
        # work over a long lunch. Reclaiming is a human/dispatcher decision.
        if [ $((_cs_now - _cs_ct)) -ge "$_cs_threshold" ]; then
            _cs_stale=true
        else
            _cs_stale=false
        fi

        # WHO holds this claim: the author of the claim commit itself, not of the tip.
        # A resumed unit gains a `Resume` commit by whoever took it over, but takeover
        # is same-identity by construction, so the claim commit stays the honest answer
        # to "whose loop is this" even after several hand-offs.
        #
        # NO FIELD OF THIS ROW MAY BE EMPTY EXCEPT THE LAST. A tab is an IFS *whitespace*
        # character, so `read` with IFS=<tab> collapses a run of tabs into one delimiter
        # -- an empty middle field silently vanishes and every field after it shifts left.
        # That is not theoretical: it is what an empty `resume_reason` did on first
        # implementation, handing plan-units.sh the artifact list in the reason slot and
        # an empty artifact list, which would have let the survey offer a ticket a claim
        # already held. The artifact list is last precisely because a trailing empty field
        # is the one case `read` handles correctly.
        _cs_author=$(git log -1 --format='%ae' "$_cs_sha" 2>/dev/null || true)
        [ -n "$_cs_author" ] || _cs_author="unknown"
        [ -n "$_cs_at" ] || _cs_at="unknown"

        # WHETHER THIS UNIT REACHED ITS PULL REQUEST, on every row rather than on the
        # one branch that happened to need it (2026-08-23). `claims_has_story` was
        # consulted only where the resumable verdict forked, so `queue_drained` — the
        # commonest state of a finished-but-unmerged unit — short-circuited before it and
        # a reader could not tell a unit parked at a pull request from one that never
        # opened any. The maintenance tick's stalled-unit step needs exactly that
        # distinction, and deriving it a second time would give the claim protocol two
        # answers to one question. It is the same offline signal (`/story` commits
        # `.workaholic/stories/<branch>.md` when it opens the pull request), so hoisting it
        # costs one `git ls-tree` per claim and no network call.
        #
        # IT IS READ BEFORE THE VERDICT, NOT AFTER IT (2026-08-19). The verdict now forks
        # on it twice -- drained/reported below, and parked/dead after that -- so it is
        # an INPUT to the verdict rather than a fact reported beside it. One call still
        # answers both forks, and the row's value is unchanged.
        _cs_reported=$(claims_has_story "$_cs_ref" "$_cs_branch")

        # The resumability verdict (see the header). Identity first: a foreign claim is
        # untouchable at any age, so its liveness never even needs measuring. The queue
        # check runs last because it is the only one that costs git calls.
        if [ -z "$_cs_me" ]; then
            _cs_resumable=false
            _cs_reason=identity_unresolved
        elif [ "$_cs_author" != "$_cs_me" ]; then
            _cs_resumable=false
            _cs_reason=foreign_identity
        elif ! claims_ancestry_ok "$_cs_base" "$_cs_ref"; then
            # Truncated history: this branch may already be merged and simply unprovable
            # here (see the header). Every gate below would pass on a merged unit -- the
            # identity matches because this runner claimed it, and the heartbeat lapsed
            # precisely because the work finished -- so the verdict is suppressed at the
            # one point where the input, not the unit, is the problem.
            _cs_resumable=false
            _cs_reason=shallow_history
        elif [ $((_cs_now - _cs_ct)) -lt "$_cs_hb_threshold" ]; then
            _cs_resumable=false
            _cs_reason=claim_active
        elif [ "$(claims_superseded "$_cs_base" "$_cs_artifacts")" = "true" ]; then
            # The unit's work is already on the base by another route (see
            # claims_superseded). It sits AFTER `claim_active` on purpose: liveness is what
            # gates a takeover, so a run that is still committing keeps the reading that
            # protects it, and only a lapsed claim is relabelled. It sits BEFORE the drained
            # fork because both of that fork's answers would be wrong here -- `queue_drained`
            # says a human is waiting at a pull request that need not exist, and
            # `report_incomplete` would offer a mandatory takeover of a branch that cannot
            # land.
            _cs_resumable=false
            _cs_reason=superseded
        elif [ "$(claims_has_work "$_cs_ref" "$_cs_artifacts_tip")" = "false" ]; then
            # A DRAINED QUEUE IS TWO DIFFERENT STATES, TOLD APART BY THE SAME STORY SIGNAL
            # the parked/dead fork below already reads (2026-08-19). With a story at the
            # tip the unit REPORTED -- its pull request is open and a human, not a runner,
            # is what it waits for; that is the 2026-08-01 gate and it is unchanged. With
            # NO story the run died BETWEEN §4 and §5: every ticket archived and pushed,
            # nothing opened, nobody told. That is a dead run's remains, and it was
            # equally untouchable -- resumption refused it, and its tickets were excluded
            # `claimed_reported` at every later survey, so no fresh claim reached them
            # either. Measured 2026-08-19: unit `batch-20260819063000` sat undelivered
            # while four consecutive `[Implement]` ticks surveyed a clean checkout, found
            # nothing, and drove nothing. The takeover re-drives no ticket (the queue is
            # empty) and re-enters the Unified Run at §5, writing the story and opening
            # the pull request the dead run never did.
            if [ "$_cs_reported" = "true" ]; then
                _cs_resumable=false
                _cs_reason=queue_drained
            else
                _cs_resumable=true
                _cs_reason=report_incomplete
            fi
        elif [ "$_cs_reported" = "true" ]; then
            # Resumable, but PARKED rather than dead: it reported and opened a PR, and the
            # follow-up tickets on its branch are why it still has work. Taking it over is
            # legitimate; being FORCED to take it over ahead of fresh work is not, so the
            # reason is distinct and /drive treats it as reportable rather than mandatory.
            _cs_resumable=true
            _cs_reason=parked_with_pr
        else
            _cs_resumable=true
            _cs_reason=heartbeat_lapsed
        fi

        # `reported` sits BEFORE the artifact list, never after it: the artifact list is
        # last because a trailing empty field is the one case `read` handles correctly
        # (see the note above), so a new column appended after it would land inside it.
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$_cs_unit" "$_cs_branch" "$_cs_at" "$_cs_stale" \
            "$_cs_author" "$_cs_resumable" "$_cs_reason" "$_cs_reported" "$_cs_artifacts"
    done
}
