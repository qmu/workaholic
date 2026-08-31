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
#   resumable <TAB> resume_reason <TAB> reported <TAB> declared_handoff <TAB>
#   artifact,artifact,...
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
# `shallow_history`, `superseded`, `awaiting_verification`, `report_undelivered`, or
# `queue_drained`.
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
# `awaiting_verification` is the REPORTED unit whose remaining queued work was DECLARED
# unverifiable here at creation (`claims_declared_handoff`). It splits `parked_with_pr`, whose
# own wording -- *taking it over is legitimate* -- is false by declaration for such a unit: §6
# routed it to the handoff route because nothing unattended can finish it, so the next action is
# a PERSON satisfying the declared verification, never a takeover. `resumable: false`, excluded
# `claimed_awaiting_verification`, and it must NOT forbid `ok`: a unit waiting on a declared
# human verification is the gate working, exactly like a scan-held pull request. It RELEASES
# ITSELF -- the declaration is read from the still-queued work, so driving that ticket returns
# the unit to `parked_with_pr` or `queue_drained` with nothing stored anywhere.
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
# run that has just proved it has no network.
#
# THE CALLER ASSIGNS IT, right after its `fetched=$(claims_fetch)` line, and that is not a
# convenience — it is the only thing that works. `claims_fetch` is invoked in a command
# substitution, so the assignment it makes to this variable happens in a SUBSHELL and never
# reaches the parent; `claims_scan` then runs in a subshell of its own, which inherits the
# parent's value but cannot write one back. So the flag has to be set in the parent, between
# the two calls. It defaults to `false`, which is the safe direction: a caller that forgets
# skips the lookup and keeps every verdict local.
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
    # $3 = OPTIONAL precomputed `claims_remaining_tickets` output, so a caller that already
    # needs the set (the scan does, for the declared-handoff reading below) derives it once.
    if [ "$#" -ge 3 ]; then
        _chw_rem="$3"
    else
        _chw_rem=$(claims_remaining_tickets "$_chw_ref" "$_chw_arts")
    fi
    if [ -n "$_chw_rem" ]; then
        printf 'true'
    else
        printf 'false'
    fi
}

# THE UNIT'S STILL-QUEUED TICKETS AT THE TIP, one path per line (empty = nothing queued).
# $1 = branch ref, $2 = the comma-separated TIP-side artifact paths.
#
# This is the walk `claims_has_work` has always made, LIFTED OUT so the two readings built on
# it -- "is there anything left to drive?" and "was the remaining work declared unverifiable
# here?" -- cannot answer from two different ticket sets. Deriving the set a second way would
# give the protocol two answers to one question, which is the failure this whole library is
# written against.
#
# The grain split is the one the header describes and does not move: a BATCH claim stamps its
# ticket files, so its queued work is whichever artifacts are still under
# `.workaholic/tickets/todo/` at the tip (archive.sh drives a ticket by renaming it out); a
# MISSION claim stamps only `mission.md`, which never sits under todo/, so its queued work is
# every ticket at the tip whose `mission:` names the slug. `mission.md` itself is NOT queued
# work and is deliberately absent from this list -- a caller that needs the mission's own
# frontmatter (the handoff reading does) picks it out of the artifacts.
#
# An empty artifact list yields nothing, and the callers -- not this -- decide what that
# unknown means; `claims_has_work` reads it as `true` exactly as it always has.
claims_remaining_tickets() {
    _crt2_ref="$1"
    _crt2_arts="${2:-}"
    [ -n "$_crt2_arts" ] || return 0

    _crt2_mission=""
    _crt2_old_ifs="$IFS"
    IFS=','
    for _crt2_p in $_crt2_arts; do
        case "$_crt2_p" in
            .workaholic/tickets/todo/*)
                printf '%s\n' "$_crt2_p"
                ;;
            */missions/*/mission.md)
                # Strip to the directory name: .../missions/<area>/<slug>/mission.md
                _crt2_mission="${_crt2_p%/mission.md}"
                _crt2_mission="${_crt2_mission##*/}"
                ;;
        esac
    done
    IFS="$_crt2_old_ifs"

    [ -n "$_crt2_mission" ] || return 0

    claims_tickets_for_mission "$_crt2_ref" .workaholic/tickets/todo "$_crt2_mission"
}

# EVERY TICKET UNDER ONE PATH WHOSE `mission:` NAMES ONE SLUG, one path per line.
# $1 = ref, $2 = path prefix to list under, $3 = the mission slug.
#
# THE ONE PLACE THE `mission:` RELATION IS WALKED IN THIS LIBRARY, lifted out of
# `claims_remaining_tickets` (2026-08-30, mission `stop-two-runs-from-claiming-and-driving-one-unit`)
# because a second reading now needs the same walk over a DIFFERENT path: the queued half answers
# *is there anything left to drive?* and the archived half answers *did this unit's content reach
# the base?* (`claims_superseded`). Two walks would be two parsers of a many-valued relation, which
# is the objection `claims_superseded`'s own header recorded in 2026-08-26 and which this
# factoring answers rather than ignores — the relation is still read exactly once, through
# `claims_blob_field`, and neither caller re-implements the match.
#
# The match is the substring one `claims_remaining_tickets` has always used, unchanged: the
# relation is many-valued (`mission: [a, b]`), and a stricter parse here would be the second
# reader this factoring exists to prevent.
claims_tickets_for_mission() {
    _ctm_ref="$1"
    _ctm_path="$2"
    _ctm_slug="${3:-}"
    [ -n "$_ctm_slug" ] || return 0
    for _ctm_t in $(git ls-tree -r --name-only "$_ctm_ref" -- "$_ctm_path" 2>/dev/null || true); do
        case "$(claims_blob_field "$_ctm_ref" "$_ctm_t" mission)" in
            "") continue ;;
            *"$_ctm_slug"*) printf '%s\n' "$_ctm_t" ;;
        esac
    done
}

# WAS THE WORK STILL QUEUED BEHIND THIS CLAIM DECLARED UNVERIFIABLE HERE? $1 = branch ref,
# $2 = the comma-separated TIP-side artifact paths, $3 = OPTIONAL precomputed
# `claims_remaining_tickets` output. Echoes true|false, never fails.
#
# `verification_handoff:` is declared at CREATION and names a credential, device or account an
# unattended run does not have (`../verification-handoff.sh`). §6 reads it before merge policy
# and routes such a unit to the HANDOFF route: the pull request opens and stays open, the claim
# stays standing, and a person runs the verification. The route honoured it and THE ORACLE NEVER
# CONSULTED IT AGAIN -- so once `/story` committed the branch story the claim read
# `parked_with_pr`, `resumable: true`, and every later survey offered the takeover. Measured on
# PR #647 (2026-08-27): routed at 02:14 UTC, taken over again at 06:43 for nothing.
#
# NOTHING NEW IS DERIVED. The declaration is already read by exactly one script, and this hands
# it the blobs rather than parsing the field a second time -- a second parser of one field is
# what this repository forbids by name. The blobs are materialised from the BRANCH TIP into a
# throwaway directory, because the reader takes files and the tip is the only space in which
# "still queued behind this claim" is a question at all: the working tree belongs to whichever
# checkout happens to be running the scan.
#
# BOTH GRAINS, from `claims_remaining_tickets`'s one split. A mission's OWN
# `verification_handoff:` counts too -- any member declaring it carries the whole unit, which is
# the reader's own rule -- so `mission.md` is added from the artifact list even though it is
# never queued work.
#
# IT IS READ FROM THE REMAINING QUEUED WORK, NEVER THE ARCHIVED WORK, and that is what makes the
# reading SELF-RELEASING: once the declared ticket is driven the same reader answers `false`,
# with nothing stored anywhere and no cursor to reset.
#
# OFFLINE BY CONSTRUCTION -- `git ls-tree`/`git show` against an already-fetched ref and one
# local script, no network call -- so every verdict stays byte-identical on a run with no origin.
#
# A READ THAT CANNOT BE MADE ANSWERS `false` AND NEVER GUESSES. An absent reader script, an
# unreadable blob, an empty artifact list: none of them is a declaration, and inventing one would
# stop a merge on a typo exactly as `../verification-handoff.sh` refuses to.
#
# TWO READINGS, ONE MATERIALISATION (2026-08-27, mission
# `ask-for-the-one-act-a-declared-handoff-is-waiting-on`). The boolean was all the scan ever
# wanted, so the reader's `reason` -- the declared string, in the words the ticket wrote it in --
# was computed and thrown away, and the question a person must be asked names exactly that
# string. `claims_declared_reading` is the one derivation and echoes the reader's own JSON line;
# `claims_declared_handoff` and `claims_declared_reason` are both thin reads OF IT, so there is
# still one materialisation, one call to the one reader of the field, and no second parser.
claims_declared_handoff() {
    case "$(claims_declared_reading "$@")" in
        *'"handoff": true'*) printf 'true' ;;
        *) printf 'false' ;;
    esac
}

# THE DECLARED REASON, VERBATIM ("" when nothing is declared, or when the read could not be
# made). Same arguments as `claims_declared_handoff`.
#
# It is sliced out of the reader's own line between the two keys the reader always prints in
# that order, rather than by a JSON parser this library does not have and rather than by
# re-reading the frontmatter -- re-reading it would be the second parser of `verification_handoff:`
# that this whole shape exists to forbid. The value is JSON-escaped on the way out of the reader,
# so the two escapes it can carry are undone on the way back in.
claims_declared_reason() {
    _cdr_line=$(claims_declared_reading "$@")
    case "$_cdr_line" in
        *'"reason": "'*) ;;
        *) return 0 ;;
    esac
    _cdr_v=${_cdr_line#*'"reason": "'}
    _cdr_v=${_cdr_v%%'", "member"'*}
    printf '%s' "$_cdr_v" | sed -e 's/\\"/"/g' -e 's/\\\\/\\/g'
}

# The shared derivation: materialise the still-queued work (plus the mission's own `mission.md`)
# from the branch tip and hand it to the ONE reader of `verification_handoff:`. Echoes that
# reader's JSON line, or nothing at all when the read could not be made.
claims_declared_reading() {
    _cdh_ref="$1"
    _cdh_arts="${2:-}"
    [ -n "$_cdh_arts" ] || return 0

    _cdh_reader="${CLAIMS_LIB_DIR}/../verification-handoff.sh"
    [ -f "$_cdh_reader" ] || return 0

    if [ "$#" -ge 3 ]; then
        _cdh_rem="$3"
    else
        _cdh_rem=$(claims_remaining_tickets "$_cdh_ref" "$_cdh_arts")
    fi

    # The mission's own declaration, from the artifact list: any member carries the unit.
    _cdh_own=""
    _cdh_old_ifs="$IFS"
    IFS=','
    for _cdh_p in $_cdh_arts; do
        case "$_cdh_p" in
            */missions/*/mission.md) _cdh_own="${_cdh_own}${_cdh_p}
" ;;
        esac
    done
    IFS="$_cdh_old_ifs"

    _cdh_paths=$(printf '%s%s' "$_cdh_own" "$_cdh_rem")
    [ -n "$_cdh_paths" ] || return 0

    _cdh_dir=$(mktemp -d 2>/dev/null || printf '')
    [ -n "$_cdh_dir" ] || return 0

    _cdh_n=0
    _cdh_files=""
    for _cdh_f in $_cdh_paths; do
        _cdh_n=$((_cdh_n + 1))
        if git show "${_cdh_ref}:${_cdh_f}" > "${_cdh_dir}/${_cdh_n}.md" 2>/dev/null; then
            _cdh_files="${_cdh_files} ${_cdh_dir}/${_cdh_n}.md"
        fi
    done

    _cdh_out=""
    if [ -n "$_cdh_files" ]; then
        # shellcheck disable=SC2086 -- the paths are mktemp's own and carry no whitespace.
        _cdh_out=$(sh "$_cdh_reader" tickets $_cdh_files 2>/dev/null || true)
    fi
    rm -rf "$_cdh_dir" 2>/dev/null || true
    printf '%s' "$_cdh_out"
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

# Why is this reported unit's pull request still open? $1 = branch ref, $2 = short branch name.
# Echoes the outcome line `record-merge-outcome.sh` wrote into the branch story, or empty.
#
# `claimed_reported` COVERED TWO STATES WITH OPPOSITE NEXT ACTIONS (2026-08-27, mission
# `close-the-units-the-loop-already-finished`). A unit whose pull request a `hard`/`confirm`
# scan finding holds is waiting on a PERSON — the gate did its job and the override is a human
# ruling. A unit whose merge the TRANSPORT refused is the loop's own undelivered work, which
# nothing will pick up: it is drained, its claim is excluded, no later survey offers it, and
# nobody was told. Measured 2026-08-27: four such pull requests green and unmerged with `ok`
# reported over all of them. This is the shape the 2026-08-19 `report_incomplete` split already
# fixed one layer up, and that split's own header states the rule it rests on — a reason must
# imply its own next action, and folding two next actions into one word is what makes the
# invisible half invisible.
#
# IT IS READ OFF THE BRANCH, NOT RE-DERIVED AND NOT RE-FETCHED. The scan cannot be re-run here:
# `scan-branch-safety.sh` diffs `<base>..HEAD` of the CURRENT checkout, and the oracle stands in
# the main tree, so answering "would the scan have held this branch?" would mean checking the
# branch out inside a pure read. And a fresh lookup is worse than the run's own answer, for the
# reason `claim-merged.sh`'s three-valued contract exists: a wrong verdict here releases work
# still in flight. So the run that made the merge attempt records what happened, in the branch
# story it already committed, and this reads that blob — offline, no network call, no second
# derivation of anything.
#
# AN ABSENT SECTION IS NOT A REFUSAL. Every unit whose story predates this section, and every
# unit whose run died before it could record, answers empty — and empty keeps `queue_drained`,
# exactly the verdict it had before. The asymmetry is the same one the rest of this library
# runs on: over-reporting a claim as a human's business makes a runner wait, under-reporting it
# hides work nobody will deliver, so the NEW reason is claimed only on positive evidence.
claims_merge_outcome() {
    git cat-file blob "${1}:.workaholic/stories/${2}.md" 2>/dev/null \
        | sed -n '/^## Merge Outcome$/{n;n;p;}' 2>/dev/null || true
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
# IT ANSWERS FROM THE TREE AT BOTH GRAINS (2026-08-30, mission
# `stop-two-runs-from-claiming-and-driving-one-unit`). A batch claim stamps its ticket files,
# so "are they archived?" is a direct question about the unit's own artifacts. A mission claim
# stamps only `mission.md`, which driving never archives, so its tickets are found the other
# way round -- off the claim's own TIP, through `claims_mission_landed` -- and then put to the
# SAME archived-on-the-base test.
#
# THIS REVERSES A SCOPE RULE RATHER THAN IGNORING IT, and the reason it was written is
# answered rather than dropped. Until this change the header read: *the equivalent would have
# to walk every ticket on the base and read its `mission:` relation, which is a second parser
# of a many-valued relation for a shape nothing has measured.* Both halves have moved. The
# shape was measured on 2026-08-30 -- two runs claimed one mission four seconds apart, the
# loser's four tickets all landed on the base under the twin's branch directory, and the
# loser still read `report_undelivered`, so `retire-claim.sh` refused it and CI's retirement
# turn found no candidate. And the relation is still NOT parsed twice: `claims_mission_landed`
# composes `claims_tickets_for_mission`, the one walk `claims_remaining_tickets` already made.
#
# REPORTED, NEVER ACTED ON. Nothing here deletes a branch, closes a pull request or breaks
# a claim -- `stale` has been reported-never-acted-on since the protocol shipped and this is
# the same kind of fact. It is `resumable: false` because there is nothing to drive, and for
# the same reason it must NOT forbid `ok` (drive/SKILL.md §7): a claim holding no work is
# the opposite of outstanding work.
# Every archived ticket path on the base, one per line. $1 = base ref.
#
# One listing, reused: the archive is the largest path in the tree, which is why
# `claims_superseded` has always taken it once per claim rather than once per artifact.
claims_archived_on_base() {
    git ls-tree -r --name-only "$1" -- .workaholic/tickets/archive 2>/dev/null || true
}

# Is $2 (a ticket FILENAME) present in $1 (a listing from `claims_archived_on_base`)?
# Echoes true|false.
#
# MATCHED BY FILENAME UNDER ANY BRANCH DIRECTORY, deliberately: a ticket archived under ANY
# branch is delivered, and WHICH branch delivered it is exactly what this test must not care
# about. That is the whole reason a raced twin's delivery counts.
claims_is_archived() {
    if printf '%s\n' "$1" | awk -v b="$2" '
        { n = length($0); m = length(b); if (n > m && substr($0, n - m) == "/" b) { found = 1; exit } }
        END { exit found ? 0 : 1 }
    '; then
        printf 'true'
    else
        printf 'false'
    fi
}

# DOES THIS BRANCH STILL HOLD CONTENT THAT IS ON NO OTHER REF? $1 = base ref, $2 = the claim's
# TIP ref, $3 = the claim's stamped artifact list (comma-separated, the scan's tenth field).
# Echoes one JSON line and never fails:
#   {"state": "empty"|"non_empty"|"unanswerable", "reason": "", "files": [...], "count": N}
#
# WHY IT EXISTS (2026-08-31, mission `prove-a-claim-branch-is-empty-before-deleting-it`).
# `claims_superseded` proves *this unit's tickets are archived on the base* and its consumers
# read that as *this branch can never land and holds no work*. Those are two questions and
# neither implies the other: a ticket archived under ANOTHER branch's directory satisfies the
# first while the claim branch still carries files that exist in no other ref. Measured on this
# repository 2026-08-31: two branches carrying ~300 lines and a doc section reachable from
# nothing else were reported finished and offered for deletion, and only a 403 refusing the
# delete kept the work alive. This is the reading that asks the second question. Nothing acts on
# it here — `claims_superseded` composes it, and the composition is where the proof narrows.
#
# TWO DIFFS, INTERSECTED, AND NEVER ANCESTRY. A squash-merged branch is never an ancestor of the
# base, which is exactly why the existing proof is derived from the tree; an ancestry term here
# would answer `non_empty` for every squash-merged branch and refuse every legitimate
# retirement. Neither single diff answers the question either:
#
#   `merge-base..tip`  the branch's OWN paths — but compared against the base as it was, so a
#                      branch whose content the base has since taken reads non-empty forever.
#                      Measured against the suite's squash-merged fixture, which archives its
#                      tickets on the branch: those archive paths are the branch's own changes
#                      and are also on the base, and this diff cannot tell.
#   `base..tip`        every path where the two trees differ — including everything the BASE
#                      changed and this branch never touched, which is most of the repository
#                      on any branch more than an hour old.
#
# The intersection is the question: **paths this branch changed, that still differ from the base
# tip**. A path the branch introduced and the base has since taken (by a squash, by a twin) drops
# out; a path the base moved on without the branch was never the branch's to hold.
#
# WHAT IS SUBTRACTED IS THE LOOP'S OWN BOOKKEEPING ON THIS BRANCH, AND NOTHING ELSE. A claim
# branch always carries writes the protocol itself made, so a raw diff is never empty — measured
# on the reproduction, the branch holding a claim commit and a heartbeat and nothing else still
# differs from the base. Four kinds — three of them keyed so they can only ever reach THIS
# branch's own records, the fourth read from the one rule that already says what is generated —
# and each named with what already proved it holds nothing of its own:
#
#   1. THE CLAIM'S OWN STAMPED ARTIFACTS, from the list the scan already carries. A claim writes
#      `claim: <branch>` into the artifacts it claims, so the claim commit itself changes the
#      tree. Matched by exact path AND — for a path inside the queue directory — by filename,
#      because the stamped list is written at CLAIM time while the tip may hold the same ticket
#      at its migrated path: `gather/scripts/migrate-todo-owners.sh` flattens
#      `todo/<user-slug>/X.md` to `todo/X.md` at the next write seam, so one artifact has two
#      paths across that convergence. The filename arm is bounded to `.workaholic/tickets/todo/`
#      and to the claim's OWN artifacts' filenames, which are timestamp-prefixed and unique in
#      the queue, so it cannot reach a ticket the branch minted itself.
#   2. THIS BRANCH'S OWN STORY, `.workaholic/stories/<branch>.md`. It exists to describe this
#      branch and describes nothing else, and the branch name is in its filename, so the
#      subtraction cannot reach another unit's story.
#   3. THE GENERATED OKF INDEXES, through `ship/scripts/lib/conflict-class.sh`'s
#      `conflict_class_generated_path` — the ONE place that says which paths are generated,
#      read rather than restated, exactly as `claim-mergeability.sh` reads it. Every archive
#      commit regenerates them (`okf/scripts/refresh-index.sh` writes each wholesale from what
#      is on disk), so a branch that archived anything differs from the base there by
#      construction. Sourced inside the command substitution, so no claims consumer gains those
#      functions; if the file is absent nothing is subtracted, which over-strands rather than
#      over-deletes.
#   4. THIS BRANCH'S OWN TICKET ARCHIVE, `.workaholic/tickets/archive/<branch>/`. This is
#      reached only AFTER the archive test passed, and that test is filename-keyed and
#      deliberately content-blind — *a ticket archived under ANY branch is delivered, and which
#      branch delivered it is exactly what this test must not care about* (`claims_is_archived`).
#      So by the time the diff term runs, every file in this directory is one the proof has
#      already established reached the base. Refusing on it would contradict the very test
#      above it. The suite's own fixture pins the case: a recovery that landed *refined rather
#      than verbatim* is still a delivery.
#
# The branch is derived from the ref's own basename rather than passed in, so the two
# branch-keyed subtractions cannot be aimed at a branch other than the one being read.
#
# ANYTHING SUBTRACTED IS CONTENT THE LOOP IS WILLING TO DELETE UNSEEN, and the costs are named
# rather than hidden. At the mission grain the stamped artifact is `mission.md`, which the
# archive test does NOT prove is on the base — it proves the mission's TICKETS are — so a
# mission claim that also edited its own `mission.md` (a `## Changelog` line, an acceptance
# tick) and whose tickets landed through another branch loses those edits. And a ticket in (3)
# carries this run's own `## Final Report`, which a twin's delivery of the same ticket does not
# reproduce. Both are the racing-twin semantics `superseded` already has; the alternative —
# refusing every retirement whose branch archived anything — would leave the branches this
# reading exists to bound standing forever.
#
# `unanswerable` IS ITS OWN STATE AND NEVER READS AS `empty`, on `claims_merged_state`'s
# precedent: a wrong `empty` licenses a delete, a wrong `non_empty` only leaves a branch
# standing, so a reading we could not make is never promoted to the one that permits the act.
#
# IT MAKES NO NETWORK CALL AND TOUCHES NO REF, INDEX OR WORKTREE — one `merge-base` plus one
# `diff --name-only` against refs the caller has already fetched, `claim-mergeability.sh`'s own
# property. Measured on this repository (1156 archived ticket paths): ~8.3 ms per claim against
# the archive listing's ~4.0 ms, so it can afford to run per row; it is composed LAST anyway, so
# it only runs where every cheaper condition already said `true`.
#
# THE FILE LIST IS BOUNDED. A branch differing in a thousand files reports the first few names
# and the full count, never a thousand names into a question a person has to read.
CLAIMS_BRANCH_DIFF_MAX=${CLAIMS_BRANCH_DIFF_MAX:-5}

claims_branch_diff_reading() {
    _cbd_base="$1"
    _cbd_ref="${2:-}"
    _cbd_arts="${3:-}"

    _cbd_emit() { # $1 state, $2 reason, $3 files-json, $4 count
        printf '{"state": "%s", "reason": "%s", "files": [%s], "count": %s}' \
            "$1" "${2:-}" "${3:-}" "${4:-0}"
    }

    [ -n "$_cbd_ref" ] && [ -n "$_cbd_base" ] || {
        _cbd_emit unanswerable no_ref "" 0
        return 0
    }

    _cbd_mb=$(git merge-base "$_cbd_base" "$_cbd_ref" 2>/dev/null || true)
    if [ -z "$_cbd_mb" ]; then
        # A truncated clone cannot see the merge base, and that is a different fact from two
        # refs with no common ancestor. Both are `unanswerable`; the reason says which.
        if [ "$(claims_shallow)" = "true" ]; then
            _cbd_emit unanswerable shallow_history "" 0
        else
            _cbd_emit unanswerable no_merge_base "" 0
        fi
        return 0
    fi

    # `--diff-filter=d` EXCLUDES DELETIONS FROM BOTH SIDES, and that is a statement about what
    # the question is: *what does this branch HOLD that is on no other ref*. A path the branch
    # removed carries no content that deleting the branch could lose, and a path the base has
    # that the branch does not is not the branch's to hold. Without the filter, a unit that
    # drained its queue by moving tickets out of `todo/` would read as holding every one of
    # them — a deletion rendered as work.
    _cbd_own=$(git diff --name-only --diff-filter=d "$_cbd_mb" "$_cbd_ref" 2>/dev/null) || {
        _cbd_emit unanswerable diff_failed "" 0
        return 0
    }
    if [ -z "$_cbd_own" ]; then
        _cbd_emit empty "" "" 0
        return 0
    fi
    _cbd_differs=$(git diff --name-only --diff-filter=d "$_cbd_base" "$_cbd_ref" 2>/dev/null) || {
        _cbd_emit unanswerable diff_failed "" 0
        return 0
    }

    # The intersection, minus this branch's own bookkeeping. BOTH path lists go in through `-v`
    # rather than one through stdin: awk applies escape processing to `-v` values, so a path git
    # quoted would be transformed on one side only and the intersection would drop it — which is
    # the direction that turns a held file into an `empty` reading.
    _cbd_branch=${_cbd_ref##*/}
    _cbd_story=".workaholic/stories/${_cbd_branch}.md"
    _cbd_archive=".workaholic/tickets/archive/${_cbd_branch}/"
    _cbd_candidates=$(awk -v own="$_cbd_own" -v differs="$_cbd_differs" -v arts="$_cbd_arts" \
        -v story="$_cbd_story" -v archive="$_cbd_archive" '
        BEGIN {
            queue = ".workaholic/tickets/todo/"
            n = split(own, o, "\n");  for (i = 1; i <= n; i++) if (o[i] != "") mine[o[i]] = 1
            m = split(arts, a, ",")
            for (i = 1; i <= m; i++) {
                if (a[i] == "") continue
                skip[a[i]] = 1
                if (substr(a[i], 1, length(queue)) == queue) {
                    base = a[i]; sub(/^.*\//, "", base); queued[base] = 1
                }
            }
            k = split(differs, d, "\n")
            for (i = 1; i <= k; i++) {
                p = d[i]
                if (p == "" || !(p in mine) || (p in skip)) continue
                if (p == story) continue
                if (substr(p, 1, length(archive)) == archive) continue
                if (substr(p, 1, length(queue)) == queue) {
                    b = p; sub(/^.*\//, "", b)
                    if (b in queued) continue
                }
                print p
            }
        }')

    # The generated paths come out through the ONE rule that owns them. Sourced inside this
    # command substitution's own subshell, so no consumer of this library gains those functions;
    # with the file absent nothing is subtracted, which over-strands rather than over-deletes.
    _cbd_held=$(
        _cbd_cc="${CLAIMS_LIB_DIR:-}/../../../ship/scripts/lib/conflict-class.sh"
        # shellcheck disable=SC1090 -- resolved from the library's own directory at runtime.
        [ -n "${CLAIMS_LIB_DIR:-}" ] && [ -f "$_cbd_cc" ] && . "$_cbd_cc" >/dev/null 2>&1
        printf '%s\n' "$_cbd_candidates" | while IFS= read -r _cbd_p; do
            [ -n "$_cbd_p" ] || continue
            if command -v conflict_class_generated_path >/dev/null 2>&1 \
                && conflict_class_generated_path "$_cbd_p"; then
                continue
            fi
            printf '%s\n' "$_cbd_p"
        done
    )

    if [ -z "$_cbd_held" ]; then
        _cbd_emit empty "" "" 0
        return 0
    fi

    _cbd_count=$(printf '%s\n' "$_cbd_held" | awk 'NF' | wc -l | tr -d ' ')
    _cbd_files=$(printf '%s\n' "$_cbd_held" | awk -v max="$CLAIMS_BRANCH_DIFF_MAX" '
        NF && shown < max {
            gsub(/\\/, "\\\\"); gsub(/"/, "\\\"")
            printf "%s\"%s\"", sep, $0; sep = ", "; shown++
        }')
    _cbd_emit non_empty "" "$_cbd_files" "$_cbd_count"
}

# The reading as the one word `claims_superseded` needs: `true` only for `empty`. Same arguments.
# An `unanswerable` reading answers `false` — a degradation must never license a delete.
claims_branch_diff_empty() {
    case "$(claims_branch_diff_reading "$@")" in
        *'"state": "empty"'*) printf 'true' ;;
        *) printf 'false' ;;
    esac
}

# HAS EVERY TICKET OF THIS MISSION UNIT LANDED ON THE BASE? $1 = base ref, $2 = the claim's
# TIP ref, $3 = the `mission.md` artifact path. Echoes true|false, never fails.
#
# The mission grain's answer to the question `claims_superseded`'s batch branch already
# answers from the tree, and it is the SAME test: every one of the unit's tickets archived on
# the base, matched by filename under any branch directory. What differs is only how the
# unit's ticket set is found — a batch claim stamps its tickets, a mission claim stamps
# `mission.md`, so the tickets are read the other way round, off the claim's own TIP, through
# the one walk this library already makes.
#
# WHY THE TIP AND NOT THE BASE. The tip is the branch's own statement of what its unit is.
# Reading the base would ask the twin's question rather than this claim's, and a mission whose
# tickets the base has already archived and re-planned would answer about work this branch
# never held.
#
# `every`, NOT `any` — a unit half of whose tickets landed elsewhere still has work, and
# calling it superseded would hide that half. This is the batch grain's existing rule and it
# does not move.
#
# A UNIT WITH NO TICKETS AT THE TIP ANSWERS `false`, and the caller then falls through to the
# merged-pull-request lookup: a mission whose plan is not written yet is a tree that CANNOT
# answer, and a proof that gates a destructive act is never taken from an empty set.
claims_mission_landed() {
    _cml_base="$1"
    _cml_tip="${2:-}"
    _cml_art="${3:-}"
    [ -n "$_cml_tip" ] || { printf 'false'; return 0; }
    case "$_cml_art" in
        */missions/*/mission.md) ;;
        *) printf 'false'; return 0 ;;
    esac
    _cml_slug="${_cml_art%/mission.md}"
    _cml_slug="${_cml_slug##*/}"
    [ -n "$_cml_slug" ] || { printf 'false'; return 0; }

    _cml_set=$( { claims_tickets_for_mission "$_cml_tip" .workaholic/tickets/todo "$_cml_slug"
                  claims_tickets_for_mission "$_cml_tip" .workaholic/tickets/archive "$_cml_slug"; } )
    [ -n "$_cml_set" ] || { printf 'false'; return 0; }

    _cml_listed=$(claims_archived_on_base "$_cml_base")
    _cml_total=0
    _cml_archived=0
    for _cml_t in $_cml_set; do
        _cml_total=$((_cml_total + 1))
        if [ "$(claims_is_archived "$_cml_listed" "${_cml_t##*/}")" = "true" ]; then
            _cml_archived=$((_cml_archived + 1))
        fi
    done
    if [ "$_cml_total" -gt 0 ] && [ "$_cml_total" -eq "$_cml_archived" ]; then
        printf 'true'
    else
        printf 'false'
    fi
}

# HAS THIS UNIT'S WORK REACHED THE BASE BY ANOTHER ROUTE? The delivery half of `superseded`,
# with the same four arguments and the same answer it gave before 2026-08-31. Split out (mission
# `prove-a-claim-branch-is-empty-before-deleting-it`) so the two halves of the proof can be told
# apart: delivered-and-empty is `superseded`, delivered-and-still-holding-work is `stranded`, and
# a claim that was never delivered is neither. Nothing outside this file calls it — consumers
# read `claims_superseded` or the row's own verdict word.
claims_delivered() {
    _csp_base="$1"
    _csp_arts="${2:-}"
    # $3 = the claim's SHORT branch name, for the merged-pull-request lookup a non-ticket
    # artifact routes to. Optional: a caller with no branch in hand keeps the local test only.
    _csp_branch="${3:-}"
    # $4 = the claim's TIP REF, for the mission grain's own local test (2026-08-30, mission
    # `stop-two-runs-from-claiming-and-driving-one-unit`). Optional and absent-means-unchanged:
    # with no tip ref the mission grain routes straight to the merged lookup exactly as it did
    # before this argument existed, so every caller that does not pass it is byte-for-byte what
    # it was.
    _csp_tip="${4:-}"
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
            # A NON-TICKET ARTIFACT — in practice a mission claim's `mission.md` — is answered
            # by the merged-pull-request lookup instead (2026-08-26). It used to answer `false`
            # outright, on the ground that the equivalent local test would need a second parser
            # of the many-valued `mission:` relation "for a shape nothing has measured". The
            # shape has since been measured: three of five claims on this repository headed
            # pull requests #521, #537 and #546, all merged, all mission units, one of them
            # offered `resumable: true` five days after its own pull request merged. The
            # reasoning is replaced rather than deleted — the relation is still not parsed
            # twice, because the lookup reads no artifact at all; it asks whether a merged
            # pull request has this branch as its head, which is grain-agnostic by
            # construction.
            #
            # THE LOCAL TEST STAYS FIRST AND STAYS NETWORK-FREE for a batch unit: the loop only
            # reaches here on an artifact that is not a ticket, so an offline batch verdict is
            # byte-identical to what it has always been.
            #
            # AN `unanswerable` LOOKUP ANSWERS `false`, which is precisely today's verdict for
            # this grain — the degradation contract, not a new state.
            # AND SINCE 2026-08-30 THE TREE IS ASKED FIRST AT THIS GRAIN TOO (mission
            # `stop-two-runs-from-claiming-and-driving-one-unit`). The 2026-08-26 note above
            # is right that `mission.md` is never archived; what it missed is that the
            # mission's TICKETS are, and the very test the batch grain already applies answers
            # for them. Measured 2026-08-30: two runs claimed
            # `draft-a-dateless-direction-with-the-operator-s-one-week-default` four seconds
            # apart, all four of `work-20260830-055314`'s tickets landed on the base under the
            # twin's `work-20260830-055318/`, and the loser still read `report_undelivered` —
            # so `retire-claim.sh` refused it, CI's retirement turn found no candidate, and
            # `catch-up-claim.sh` was left trying to resolve a collision between a unit and
            # itself.
            #
            # THE RELATION IS STILL NOT PARSED TWICE, which is the objection that kept this
            # test out at the mission grain. `claims_tickets_for_mission` is the ONE walk
            # `claims_remaining_tickets` already made, lifted out and handed a different path;
            # nothing here reads `mission:` on its own.
            #
            # THE LOOKUP STAYS AS THE FALLBACK, and it is reached in every case the tree does
            # not answer `true`: a mission with no tickets written yet, a mission still holding
            # queued work, an absent tip ref. So this can only ever ADD a `superseded` the
            # chain would not have reached — it can never take one away, which is the direction
            # that matters when a proof gates a destructive act.
            *)
                IFS="$_csp_old_ifs"
                if [ "$(claims_mission_landed "$_csp_base" "$_csp_tip" "$_csp_p")" = "true" ]; then
                    printf 'true'
                    return 0
                fi
                if [ "$(claims_merged_state "$_csp_branch")" = "merged" ]; then
                    printf 'true'
                else
                    printf 'false'
                fi
                return 0
                ;;
        esac
        if [ "$_csp_have_list" = "false" ]; then
            _csp_listed=$(claims_archived_on_base "$_csp_base")
            _csp_have_list=true
        fi
        _csp_total=$((_csp_total + 1))
        if [ "$(claims_is_archived "$_csp_listed" "${_csp_p##*/}")" = "true" ]; then
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

# WHAT BECAME OF THIS CLAIM'S WORK — `superseded`, `stranded`, or `none`. $1 = base ref,
# $2 = the claim's stamped artifacts (comma-separated), $3 = the SHORT branch name,
# $4 = the claim's TIP ref. Echoes one word and never fails.
#
# TWO HALVES, TOLD APART (2026-08-31, mission `prove-a-claim-branch-is-empty-before-deleting-it`).
# `claims_delivered` above answers *are this unit's TICKETS on the base*; `claims_branch_diff_*`
# answers *does this BRANCH still hold content of its own*. Neither implies the other — a ticket
# archived under ANOTHER branch's directory satisfies the first while the claim branch still
# carries files that exist in no other ref — and until this split the first stood in for both.
# Measured 2026-08-31: two branches carrying ~300 lines and a doc section reachable from nothing
# else were reported finished and offered for deletion, and only a 403 refusing the delete kept
# the work alive.
#
#   superseded  delivered, and the branch holds nothing of its own. The PROOF, unchanged in
#               meaning from what every consumer already read it to mean.
#   stranded    delivered, and the branch still holds content. A JUDGEMENT: the work is
#               stranded rather than finished, and what becomes of it is a person's to decide.
#   none        not delivered, or the diff could not be read.
#
# AN `unanswerable` DIFF IS `none`, NOT `stranded`. It is the absence of a reading, and the two
# failures it must not cause are opposite: calling it `superseded` licenses a delete, and calling
# it `stranded` sends a person after a branch nobody could read. So it falls through to the
# ordinary verdict chain, exactly as it did before either word existed.
#
# IT IS THE MOST EXPENSIVE READING THAT CAN STILL CHANGE A VERDICT — the archive listing's
# ~4.0 ms per claim against the diff term's ~8.3 ms, measured on this repository — so the scan
# reaches it only after the identity, ancestry and liveness gates have all passed.
claims_delivery() {
    [ "$(claims_delivered "$@")" = "true" ] || { printf 'none'; return 0; }
    case "$(claims_branch_diff_reading "$1" "${4:-}" "${2:-}")" in
        *'"state": "empty"'*)     printf 'superseded' ;;
        *'"state": "non_empty"'*) printf 'stranded' ;;
        *)                        printf 'none' ;;
    esac
}

# THE PROOF, as every consumer outside this file reads it. Same four arguments and same name it
# has always had; what changed on 2026-08-31 is that it now proves BOTH halves.
#
# IT CAN ONLY EVER REMOVE A `superseded`, NEVER ADD ONE, and that direction is the whole safety
# argument: this is one of exactly two proofs in the protocol and it gates a destructive act, so
# anything that makes it HARDER to establish is safe and anything that makes it easier is not.
#
# THAT MAKES `$4` REQUIRED FOR A `true` ANSWER at either grain. With no tip ref the diff reading
# is `unanswerable:no_ref`, so a caller that omits it gets `false` where the batch grain used to
# answer from the tree alone. Every caller in the tree passes it; the one caller that
# deliberately does not is a drill row asserting the pre-2026-08-30 mission-grain composition,
# which reaches `false` inside `claims_delivered` for its own reason.
claims_superseded() {
    if [ "$(claims_delivery "$@")" = "superseded" ]; then
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
    #
    # WORKAHOLIC_CLAIM_IDENTITY IS AN OVERRIDE, NOT A DEFAULT (2026-08-29, mission
    # `make-the-two-executors-agree-about-a-proved-empty-claim`). Unset — every container and
    # every developer's checkout — this is byte-for-byte the line it has always been, and no
    # gate, order or verdict moves. It exists for the OTHER executor: `actions/checkout@v4`
    # configures no `user.email`, so CI read `identity_unresolved` for every claim and
    # `superseded` was never reached, leaving `Claim Retirement` green while three proved-empty
    # branches stood (measured 2026-08-29; reproduced offline, candidates 3 → 0 on this term
    # alone). Who may set it, and the bound that stops it becoming *CI owns every claim*, is
    # `lib/runner-identity.sh` — the value must be an address the committed mapping names.
    _cs_me=${WORKAHOLIC_CLAIM_IDENTITY:-$(git config user.email 2>/dev/null || true)}

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

        # WHAT THIS UNIT STILL HAS QUEUED, DERIVED ONCE (2026-08-27, mission
        # `stop-re-resuming-a-declared-handoff-unit`). Two readings below are built on the same
        # set -- "is there anything left to drive?" and "was that remaining work declared
        # unverifiable here?" -- so it is computed here and passed to both rather than walked
        # twice. The declaration is reported on EVERY row, on the precedent `_cs_reported` set
        # one change earlier: a reader that consults a signal only where one branch happens to
        # need it leaves every other consumer to derive it again.
        _cs_remaining=$(claims_remaining_tickets "$_cs_ref" "$_cs_artifacts_tip")
        _cs_declared_handoff=$(claims_declared_handoff "$_cs_ref" "$_cs_artifacts_tip" "$_cs_remaining")

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
        elif _cs_delivery=$(claims_delivery "$_cs_base" "$_cs_artifacts" "$_cs_branch" "$_cs_ref")
             [ "$_cs_delivery" != "none" ]; then
            # The unit's work is already on the base by another route (see `claims_delivery`).
            # It sits AFTER `claim_active` on purpose: liveness is what gates a takeover, so a
            # run that is still committing keeps the reading that protects it, and only a lapsed
            # claim is relabelled. It sits BEFORE the drained fork because both of that fork's
            # answers would be wrong here -- `queue_drained` says a human is waiting at a pull
            # request that need not exist, and `report_incomplete` would offer a mandatory
            # takeover of a branch that cannot land.
            #
            # THE ASSIGNMENT RIDES THE CONDITION LIST so the reading is made ONCE. `if` takes a
            # list and uses the last command's status, so `_cs_delivery=$(…)` followed by the
            # test is one evaluation; writing it as two `elif`s would repeat the diff read and,
            # at the mission grain, the merged-pull-request lookup's network call.
            _cs_resumable=false
            if [ "$_cs_delivery" = "stranded" ]; then
                # DELIVERED, AND STILL HOLDING CONTENT OF ITS OWN (2026-08-31, mission
                # `prove-a-claim-branch-is-empty-before-deleting-it`). A SIBLING WORD rather than
                # a narrowed `superseded`, on the `awaiting_verification` precedent: the two
                # states call for different next actions -- retire the claim versus tell a
                # person their work is stranded -- and one word answering both is what offered
                # branches carrying ~300 lines for deletion.
                #
                # `resumable: false`: a takeover would re-drive nothing (the tickets are on the
                # base) and would push a `Resume` commit onto a branch whose content nobody has
                # decided about. What the branch needs is a RULING -- port the work, open it as
                # its own pull request, or discard it deliberately -- and that is a person's.
                # `/moderate`'s `stranded-branches` step asks its holder, once.
                _cs_reason=stranded
            else
                _cs_reason=superseded
            fi
        elif [ "$(claims_has_work "$_cs_ref" "$_cs_artifacts_tip" "$_cs_remaining")" = "false" ]; then
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
                # AND A REPORTED UNIT IS ITSELF TWO STATES (2026-08-27, see
                # `claims_merge_outcome`). `queue_drained` means *waiting on a person*, and it
                # was also covering the loop's own undelivered work — a unit whose merge the
                # transport refused, which no later survey offers and nobody was told about.
                # The split is read off the branch story the run already committed, so it costs
                # no network call and cannot disagree with the run that made the attempt.
                #
                # `resumable: false`, and the reason is NOT the one `queue_drained` gives.
                # The next action here is a MERGE RETRY, which is not a takeover: `claim.sh
                # resume` would push an empty `Resume` commit onto a branch whose pull request
                # is open, which is precisely the 2026-08-01 gate. The 2026-08-19 split went
                # `resumable: true` because its unit had never reported and the takeover had
                # real work to do (write the story, open the pull request); this one has
                # already done both. So it is REPORTED and it forbids `ok` (`../SKILL.md` §7)
                # rather than being offered as a takeover.
                case "$(claims_merge_outcome "$_cs_ref" "$_cs_branch")" in
                    merge_refused*)
                        _cs_resumable=false
                        _cs_reason=report_undelivered
                        ;;
                    *)
                        _cs_resumable=false
                        _cs_reason=queue_drained
                        ;;
                esac
            else
                _cs_resumable=true
                _cs_reason=report_incomplete
            fi
        elif [ "$_cs_reported" = "true" ]; then
            if [ "$_cs_declared_handoff" = "true" ]; then
                # AND A *REPORTED* UNIT WITH WORK LEFT IS TWO STATES TOO (2026-08-27, mission
                # `stop-re-resuming-a-declared-handoff-unit`). `parked_with_pr`'s own contract
                # says *the follow-up tickets on its branch are why it still has work. Taking it
                # over is legitimate* -- and that sentence is FALSE BY DECLARATION for a unit
                # whose remaining work carries `verification_handoff:`. §6 routed it to the
                # handoff route precisely because nothing unattended can finish it, and the
                # oracle then offered the takeover anyway: measured on PR #647, routed at 02:14
                # UTC and taken over again at 06:43 for nothing.
                #
                # A SIBLING WORD, NOT A NARROWED `parked_with_pr`, on the `report_undelivered`
                # precedent: the two states call for different next actions -- take it over
                # versus satisfy the declared verification -- and one word answering both is
                # what made this invisible for thirteen days.
                #
                # `resumable: false`, for its own reason: the next action belongs to a PERSON,
                # and resuming would push an empty `Resume` commit onto a branch whose pull
                # request is open -- the 2026-08-01 gate exactly.
                #
                # IT RELEASES ITSELF. The declaration is read from the work still QUEUED, so
                # once that ticket is driven the reading answers `false` and the unit reads
                # `parked_with_pr` or `queue_drained` again, with nothing stored anywhere.
                _cs_resumable=false
                _cs_reason=awaiting_verification
            else
                # Resumable, but PARKED rather than dead: it reported and opened a PR, and the
                # follow-up tickets on its branch are why it still has work. Taking it over is
                # legitimate; being FORCED to take it over ahead of fresh work is not, so the
                # reason is distinct and /drive treats it as reportable rather than mandatory.
                _cs_resumable=true
                _cs_reason=parked_with_pr
            fi
        else
            _cs_resumable=true
            _cs_reason=heartbeat_lapsed
        fi

        # `reported` and `declared_handoff` sit BEFORE the artifact list, never after it: the
        # artifact list is last because a trailing empty field is the one case `read` handles
        # correctly (see the note above), so a new column appended after it would land inside
        # it. Both are always `true` or `false`, so neither can be the empty middle field that
        # rule exists to forbid.
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$_cs_unit" "$_cs_branch" "$_cs_at" "$_cs_stale" \
            "$_cs_author" "$_cs_resumable" "$_cs_reason" "$_cs_reported" \
            "$_cs_declared_handoff" "$_cs_artifacts"
    done
}

# ---------------------------------------------------------------------------
# RESOLVING A UNIT ID TO THE ONE CLAIM ROW A WRITER MAY ACT ON (2026-08-27).
#
# A unit can legitimately be held by TWO claim branches since 2026-08-26: a `superseded`
# one the survey ignores, and the fresh one a later run took its work on. Every writer
# resolved a unit to *a* branch by taking the FIRST match out of `claims_scan`, and
# `claims_scan` walks refs in name order -- so the first match is the OLDEST branch, which
# for this shape is precisely the dead one. Measured 2026-08-27 on this repository, on unit
# `make-workaholify-converge-the-account-s-routines` held by `work-20260819-113836`
# (superseded) and `work-20260827-003544` (claim_active): `claim.sh resume` refused on the
# superseded branch's verdict, so the LIVE claim could not be resumed by anything, and
# `release-claim.sh` tore down the superseded branch and reported `half_released` while the
# live claim stood.
#
# The two-branch shape is NEW, which is why first-match was right until now: before a fresh
# claim could be taken over a superseded one, a unit had exactly one branch.
#
# ONE DERIVATION, THREE VIEWS. The resolution lives here rather than in each caller because
# three copies of a lookup is exactly how these three disagreed. Callers read
# `claims_unit_resolution` to decide whether they may act, and `claims_unit_row` for the row.
#
#   none            no claim in flight for this unit
#   single          exactly one claim, whatever its verdict -- byte-identical to first-match
#   live            one live claim beside one or more superseded ones -- the live one wins
#   superseded_only every claim for this unit is superseded; the first is returned, so a
#                   caller keeps refusing under `superseded` exactly as it did before
#   ambiguous       TWO OR MORE LIVE CLAIMS. Reported, never picked. This row read *the
#                   protocol settles a race by the push, so this state cannot arise from the
#                   sanctioned path at all* until 2026-08-30, and that premise was FALSE for a
#                   fresh claim: `create.sh` mints a clock-derived name, so two runners that
#                   survey before either pushes name two different refs and both win
#                   (`../reference/claims.md`, *What the claim contends for*). So it does
#                   arise, and the refusal is MORE necessary rather than less -- picking one
#                   of two live branches silently is how a runner would resume, or release,
#                   work another run is still driving. Name both branches instead. Since
#                   2026-08-30 this reading also reaches a person: `list-raced-units.sh`
#                   composes it and `/moderate`'s `raced-units` step asks the claim holders
#                   which branch keeps going. It is a JUDGEMENT -- a race resolves the moment
#                   one branch merges -- so no consumer may act on it.

# Every claim row for this unit, in scan order. $1 = rows, $2 = unit.
claims_unit_all_rows() {
    printf '%s\n' "$1" | awk -F'\t' -v u="$2" '$1 == u && NF > 1'
}

# The branches of this unit's LIVE (non-superseded) claims, comma-joined -- what an
# `ambiguous` refusal reports so a human sees both. $1 = rows, $2 = unit.
claims_unit_live_branches() {
    claims_unit_all_rows "$1" "$2" \
        | awk -F'\t' '$7 != "superseded" { printf "%s%s", (n++ ? "," : ""), $2 } END { printf "\n" }'
}

# One of the words above. $1 = rows, $2 = unit.
claims_unit_resolution() {
    _cu_all=$(claims_unit_all_rows "$1" "$2")
    _cu_total=$(printf '%s\n' "$_cu_all" | grep -c . || true)
    [ "$_cu_total" -gt 0 ] || { printf 'none\n'; return 0; }
    _cu_live=$(printf '%s\n' "$_cu_all" | awk -F'\t' '$7 != "superseded"' | grep -c . || true)
    if [ "$_cu_live" -eq 0 ]; then
        printf 'superseded_only\n'
    elif [ "$_cu_live" -gt 1 ]; then
        printf 'ambiguous\n'
    elif [ "$_cu_total" -eq 1 ]; then
        printf 'single\n'
    else
        printf 'live\n'
    fi
}

# The row to act on -- the live one when there is one, else the first superseded one.
# EMPTY for `none` and for `ambiguous`: a caller that gets no row must refuse rather than
# fall back to a guess. $1 = rows, $2 = unit.
claims_unit_row() {
    case "$(claims_unit_resolution "$1" "$2")" in
        none | ambiguous) return 0 ;;
        superseded_only) claims_unit_all_rows "$1" "$2" | head -n 1 ;;
        *) claims_unit_all_rows "$1" "$2" | awk -F'\t' '$7 != "superseded" { print; exit }' ;;
    esac
}
