#!/bin/sh -eu
# The CI-side CANDIDATE READER: which claim branches has the oracle proved may be deleted?
#
# Usage: list-retirable-claims.sh
# Output: {"ok": bool, "reason": "", "fetched": bool, "shallow": bool,
#          "candidates": [{"unit": "...", "branch": "work-...",
#                          "state": "present"|"already_gone",
#                          "candidate_reason": "superseded_only"|"pull_request_merged"
#                                              |"pull_request_closed_unmerged"
#                                              |"mission_not_active",
#                          "mission_status": "achieved"|"abandoned"|"carried"|"",
#                          "branch_empty": "true"|"false"|"unanswerable"}],
#          "pull_request_unreadable": [{"branch": "work-...", "reason": "<named>"}]}
#         Always exit 0 — a degraded read is an answer, and its caller (a workflow step)
#         reports it rather than failing the job on it.
#
# FOUR CANDIDATE CLASSES, EACH CARRYING ITS OWN WORD (2026-09-01, mission
# `leave-only-live-work-in-the-unmerged-branch-list`; the fourth 2026-09-02, mission
# `retire-a-claim-whose-work-is-finished-or-abandoned`). `candidate_reason` rides every row so
# the classes stay told apart at a glance and no caller loses information:
#
#   superseded_only                 the claim oracle proved the unit's content reached the base
#                                   and the branch is empty against it — the original class,
#                                   unchanged
#   pull_request_merged             this branch's own pull request MERGED
#   pull_request_closed_unmerged    a person CLOSED this branch's pull request without merging
#   mission_not_active              the unit's MISSION has ended — `close.sh` moved it into
#                                   `missions/archive/`, and `mission_status` rides the row
#
# THE THIRD CLASS IS NEVER FOLDED INTO THE SECOND. They answer different questions — *the loop
# delivered this* and *a person discarded this* — and one word answering two questions is how
# two questions drift. Measured 2026-09-01: five branches whose pull requests the operator
# closed unmerged as superseded (#801, #802, #790 by #800; #520 by #519; #466 by #465), one
# closing comment reading *"this branch and `main` repaired the same defect twice"*. A
# hand-closed branch is not empty by construction, so `superseded` can never reach it.
#
# `branch_empty` RIDES BOTH PULL-REQUEST CLASSES AS EVIDENCE, NEVER AS A GATE — three-valued,
# with `unanswerable` named rather than assumed. It matters most on the closed-unmerged class,
# where the proof is a person's DECISION about the branch rather than a reading of the tree:
# such a branch may still hold work found on no other ref, and closing its pull request
# unmerged is the operator saying that work is not wanted. Recording it first means CI's own
# record answers *how often does that actually happen* from real data, before anything is
# gated on it. A `superseded_only` row carries no such field: that verdict already asserts the
# emptiness, and a second copy of one fact is how two copies come to disagree.
#
# WHY THE SECOND CLASS EXISTS. Measured 2026-09-01: 30 unmerged branches, 17 of them with a
# merged pull request. A squash merge never makes the branch an ancestor of the base, so
# `--no-merged` lists it forever, and `delete_branch_on_merge` — the only cleanup — is
# FORWARD-ONLY, so every branch merged before that setting was applied stands permanently.
# `superseded` reaches almost none of them: it is keyed on a UNIT and needs a claim commit,
# and a publish-tree publication has none. The printed "ready-to-run deletion command" was 17
# lines long and nobody had run it.
#
# A MERGED PULL REQUEST IS A PROOF in this repository's own sense (`../reference/claims.md`,
# *Proofs and judgements*): the tree established it, and looking again cannot make it false.
# That is the same standing `superseded` has, and it is why a destructive act may rest on it.
#
# A LIVE ROW BEATS IT, ALWAYS. A unit the oracle holds any live row for is never a candidate
# whatever its pull request says — a run may be driving a fresh claim over a merged
# predecessor, and the merged pull request is a fact about the OLD work. The rule stays the
# library's (`claims_unit_resolution`), not a second copy of it.
#
# AN UNREADABLE PULL REQUEST IS NOT A MERGED ONE. `branch-pull-request-state.sh` answers
# `ok: false` with no `state` key at all for every degradation, and such a branch contributes
# no candidate and lands in `pull_request_unreadable[]` with its reason — never a bare
# omission, which reads exactly like a branch whose pull request is open.
#
# THE COST IS ONE BOUNDED READ PER UNCLAIMED `work-*` BRANCH, and it is spent in CI rather
# than in the hourly tick: the reader is composed by `claim-retirement.yml`, which already
# defines a full-history checkout for the scan. A branch already named by the first class is
# not read again.
#
# WHY IT EXISTS (2026-08-28, mission `finish-a-proved-retirement-where-the-write-is-permitted`).
# Act 2 of the retirement — the remote branch delete — is refused in the container the loop runs
# in, by every available transport (`retire-claim.sh`, Act 2; `../reference/claims.md`, *When an
# act of the retirement is refused*). The act therefore moves to a different EXECUTOR, on
# `release-note-draft.yml`'s precedent, and before CI can take it something has to answer WHICH
# BRANCHES MAY BE DELETED. This is that answer, and nothing else: it deletes nothing, closes
# nothing and writes nothing anywhere.
#
# IT IS NOT A SECOND ORACLE, AND THAT IS THE WHOLE POINT. The obvious shortcut — a workflow
# shelling out to `git for-each-ref` and matching `work-*` — would delete branches nothing proved
# empty. `superseded` means the unit's content already reached the base, which is exactly why the
# branch can never land, so the derivation stays the claim oracle's: this composes
# `list-claims.sh` (one walk of the refs, not a second) and re-reads nothing itself. It adds no
# queue, no cursor, no stored state and no field on any artifact.
#
# THE LIVE-ROW RULE IS THE LIBRARY'S, NOT A COPY. A unit can be held by a `superseded` branch AND
# a live one — the shape a fresh claim over a superseded one creates — and first-match is the
# OLDEST, i.e. the dead one, so a caller that resolved by first-match would hand CI a branch a
# run is still driving. `claims_unit_resolution` is called here over a TSV PROJECTION of the
# reader's own rows: the same derivation `claim.sh`, `release-claim.sh` and `retire-claim.sh`
# read, evaluated once more rather than reimplemented. Only `superseded_only` is a candidate —
# a unit with any live row governs itself and the dead branch governs nothing.
#
# A DEGRADED READ YIELDS NO CANDIDATES AND ITS REASON, NEVER A BARE EMPTY SET. Unmerged remote
# branches are the only claim oracle, so a scan that could not reach the remote has not found
# "nothing to retire" — it has found nothing at all, and a proof that could not be read is not a
# proof. A shallow scan is the same shape one step over: a superseded claim is indistinguishable
# from a live one across a graft boundary, which is why CI defines its own full-history checkout.
# The words are `step-retire-claims.sh`'s own, deliberately — the CI side answers the same
# questions and must not invent a second vocabulary for them.
#
# `already_gone` IS A SUCCESS, not a degradation, and matches Act 2's own word. A branch absent
# from origin needs no delete, so a re-run over a set CI already took is a clean no-op rather
# than a run full of errors about work that is already done.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAIMS_LIB_DIR="${SCRIPT_DIR}/lib"
. "${SCRIPT_DIR}/lib/claims.sh"
. "${SCRIPT_DIR}/lib/runner-identity.sh"

LISTER="${SCRIPT_DIR}/list-claims.sh"
PR_STATE="${SCRIPT_DIR}/branch-pull-request-state.sh"
MISSION_STATE="${SCRIPT_DIR}/claim-mission-state.sh"

FETCHED=false
SHALLOW=false
UNREADABLE=""
unreadable_sep=""

emit() {
    printf '{"ok": %s, "reason": "%s", "fetched": %s, "shallow": %s, "candidates": [%s], "pull_request_unreadable": [%s]}\n' \
        "$1" "$2" "$FETCHED" "$SHALLOW" "${3:-}" "$UNREADABLE"
    exit 0
}

[ -f "$LISTER" ] || emit false no_claim_reader

out=$(sh "$LISTER" 2>/dev/null || true)
[ -n "$out" ] || emit false claims_unreadable
printf '%s' "$out" | jq -e . >/dev/null 2>&1 || emit false claims_unparseable

FETCHED=$(printf '%s' "$out" | jq -r '.fetched // false')
SHALLOW=$(printf '%s' "$out" | jq -r '.shallow // false')

[ "$FETCHED" = "true" ] || emit false origin_unreachable
[ "$SHALLOW" = "true" ] && emit false shallow_history

# WHERE THIS EXECUTOR HAS NO IDENTITY OF ITS OWN, RE-DERIVE PER MAPPED AUTHOR (2026-08-29,
# mission `make-the-two-executors-agree-about-a-proved-empty-claim`). `actions/checkout@v4`
# configures no `user.email`, so every row above reads `identity_unresolved` and `superseded`
# — the proof this reader exists to find — is never reached. The scan is re-run once per
# DISTINCT author the committed mapping names, and only that author's own rows are taken from
# each pass, so no claim is ever read under somebody else's identity.
#
# It is bounded three ways and each one is load-bearing: it is reachable ONLY with no configured
# identity (a container is byte-identical), it scans only as an author `identity.sh` resolves
# (an unmapped address stays `identity_unresolved` and is never impersonated), and it changes no
# gate — `claim_active` still outranks `superseded`, so a live claim reads live under every
# identity. The cost is one extra scan per distinct mapped author, and none at all otherwise.
if runner_identity_absent; then
    authors=$(printf '%s' "$out"         | jq -r '[.claims[]? | select(.resume_reason == "identity_unresolved") | .author // ""]
                 | map(select(. != "")) | unique | .[]' 2>/dev/null || true)
    for author in $authors; do
        [ -n "$author" ] || continue
        scan_as=$(runner_identity_for_author "$author")
        [ -n "$scan_as" ] || continue
        as_out=$(WORKAHOLIC_CLAIM_IDENTITY="$scan_as" sh "$LISTER" 2>/dev/null || true)
        [ -n "$as_out" ] || continue
        printf '%s' "$as_out" | jq -e . >/dev/null 2>&1 || continue
        out=$(printf '%s
%s' "$out" "$as_out" | jq -s --arg a "$author" '
            (.[1].claims // []) as $re
            | .[0]
            | .claims = [ .claims[]? as $c
                          | ( [ $re[] | select(.branch == $c.branch and (.author // "") == $a) ] | first )
                            // $c ]' 2>/dev/null || printf '%s' "$out")
    done
fi

# The TSV projection the library's resolver reads: field 1 the unit, field 2 the branch, field 7
# the verdict. The intervening columns are the scan's own and are not consulted by the resolver,
# so they are left empty rather than invented here.
rows=$(printf '%s' "$out" \
    | jq -r '.claims[]? | [.unit, .branch, "", "", "", "", .resume_reason] | @tsv' 2>/dev/null || true)

units=$(printf '%s' "$out" \
    | jq -r '[.claims[]? | select(.resume_reason == "superseded") | .unit] | unique | .[]' 2>/dev/null || true)

candidates=""
sep=""
named=""
for unit in $units; do
    [ -n "$unit" ] || continue
    # THE LIVE ROW WINS. A unit whose claims are not ALL superseded is governed by its live
    # claim, and the superseded branch beside it is reported by the oracle and acted on by
    # nothing — which is what "reported, never acted on" has always meant.
    [ "$(claims_unit_resolution "$rows" "$unit")" = "superseded_only" ] || continue
    row=$(claims_unit_row "$rows" "$unit")
    [ -n "$row" ] || continue
    branch=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
    [ -n "$branch" ] || continue
    if git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
        state=present
    else
        state=already_gone
    fi
    candidates="${candidates}${sep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"state\": \"${state}\", \"candidate_reason\": \"superseded_only\"}"
    sep=", "
    named="${named}${branch}
"
done

# --- The second class: this branch's own pull request merged -------------------------------
# Enumerated from the REFS rather than from the oracle's rows, because the branches this class
# exists for have no claim commit at all — a publish-tree publication is exactly that shape.
# The `work-YYYYMMDD-HHMMSS` pattern is the one `branching/scripts/create.sh` names and
# `guard-git-branch.sh` enforces; a ref outside it was never minted by this protocol.
BASE_REF=$(claims_base)
if [ -f "$PR_STATE" ]; then
    for ref in $(git for-each-ref --format='%(refname:short)' 'refs/remotes/origin/work-*' 2>/dev/null || true); do
        branch=${ref#origin/}
        printf '%s' "$branch" | grep -q '^work-[0-9]\{8\}-[0-9]\{6\}$' || continue
        # Already named by the first class — one read per branch, never two.
        printf '%s\n' "$named" | grep -qx "$branch" && continue

        # The oracle's own word about this branch's unit, when it has one. A live row governs.
        unit=$(printf '%s\n' "$rows" | awk -F'\t' -v b="$branch" '$2 == b { print $1; exit }')
        if [ -n "$unit" ]; then
            case "$(claims_unit_resolution "$rows" "$unit")" in
                live | single | ambiguous) continue ;;
            esac
        fi

        pr=$(sh "$PR_STATE" "$branch" 2>/dev/null || true)
        pr_ok=$(printf '%s' "$pr" | jq -r '.ok // false' 2>/dev/null || printf 'false')
        if [ "$pr_ok" != "true" ]; then
            why=$(printf '%s' "$pr" | jq -r '.reason // "unreadable"' 2>/dev/null || printf 'unreadable')
            UNREADABLE="${UNREADABLE}${unreadable_sep}{\"branch\": \"${branch}\", \"reason\": \"${why}\"}"
            unreadable_sep=", "
            continue
        fi
        case "$(printf '%s' "$pr" | jq -r '.state // ""' 2>/dev/null || printf '')" in
            merged)          why=pull_request_merged ;;
            closed_unmerged) why=pull_request_closed_unmerged ;;
            *)               continue ;;
        esac

        # THE EMPTINESS READING RIDES EVERY ROW AS EVIDENCE, NEVER AS A GATE. `true` / `false` /
        # `unanswerable`, the third named rather than assumed. It matters most on the
        # closed-unmerged class, where the proof is a person's DECISION about the branch rather
        # than a reading of the tree: such a branch may still hold work found on no other ref,
        # and closing its pull request unmerged is the operator saying that work is not wanted.
        # Recording it here means CI's own record answers *how often does that actually happen*
        # from real data, before anything is gated on it.
        empty=$(claims_branch_empty_against_base "$BASE_REF" "origin/${branch}")
        case "$empty" in true|false) ;; *) empty=unanswerable ;; esac

        candidates="${candidates}${sep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"state\": \"present\", \"candidate_reason\": \"${why}\", \"branch_empty\": \"${empty}\"}"
        sep=", "
        named="${named}${branch}
"
    done
fi

# --- The fourth class: the unit's MISSION has ended -----------------------------------------
# (2026-09-02, mission `retire-a-claim-whose-work-is-finished-or-abandoned`.)
#
# WHAT THE OTHER THREE CANNOT REACH. Measured: the operator closed a pull request and closed
# its mission `abandoned`, and the tick reported that branch as stuck work hourly until a
# person deleted it. `superseded` needs the branch empty AND its tickets on the base; and the
# per-ref arm above skips every unit the ORACLE has a row for — the `live | single | ambiguous`
# test — which is exactly a claim branch, because a claim branch carries a `Claim` commit by
# construction. So a claim whose mission has ended was reachable by no class at all.
#
# IT IS ENUMERATED FROM THE ORACLE'S ROWS, not from the refs: the subject is a UNIT (a mission
# slug), and the refs arm above has no unit for the branches it walks.
#
# THE BOUNDS, EACH ONE A REFUSAL RATHER THAN A JUDGEMENT CALL:
#
#   resolution `single`   exactly one claim row for the unit. `live` and `ambiguous` are
#                         refused — a live row governs, which is the rule every class here
#                         already reads from `claims_unit_resolution` — and `superseded_only`
#                         belongs to the first class.
#   not `claim_active`    the heartbeat is fresh, so a run is driving this branch NOW. An
#                         ended mission is not a licence to delete work in flight, and this is
#                         the one bound that cannot be recovered from.
#   mission `not_active`  `claim-mission-state.sh`, composed and never reimplemented. `active`
#                         and `kind: batch` yield nothing; an `ok: false` yields NO candidate
#                         and its reason on `pull_request_unreadable[]`.
#   pull request not open THE BOUND IS NOT WIDENED, and the argument is written here and in
#                         `../reference/claims.md`: deleting the head branch of an OPEN pull
#                         request leaves it unmergeable by anybody forever — the headless
#                         shape this repository measured on #813, #799, #688, #635 and #625
#                         and had to have a person close by hand. So an open pull request is
#                         skipped rather than handed to an act that would refuse it hourly,
#                         and the act's own `pull_request_open` bound stays exactly as it is.
#
# `branch_empty` RIDES AS EVIDENCE HERE AND IS A GATE IN THE ACT, exactly as it is for
# `pull_request_closed_unmerged`: a mission's end state is a person's decision about the WORK
# and says nothing about what this BRANCH holds. Issue #788 measured the cost of assuming
# otherwise — two branches with ~300 lines present on no other ref, offered for deletion.
if [ -f "$MISSION_STATE" ] && [ -f "$PR_STATE" ]; then
    mission_units=$(printf '%s\n' "$rows" | awk -F'\t' '$1 != "" { print $1 }' | sort -u)
    for unit in $mission_units; do
        [ -n "$unit" ] || continue
        [ "$(claims_unit_resolution "$rows" "$unit")" = "single" ] || continue
        row=$(claims_unit_row "$rows" "$unit")
        [ -n "$row" ] || continue
        verdict=$(printf '%s' "$row" | awk -F'\t' '{print $7}')
        [ "$verdict" != "claim_active" ] || continue
        branch=$(printf '%s' "$row" | awk -F'\t' '{print $2}')
        [ -n "$branch" ] || continue
        printf '%s\n' "$named" | grep -qx "$branch" && continue

        ms=$(sh "$MISSION_STATE" "$unit" 2>/dev/null || true)
        if [ "$(printf '%s' "$ms" | jq -r '.ok // false' 2>/dev/null || printf 'false')" != "true" ]; then
            why=$(printf '%s' "$ms" | jq -r '.reason // "mission_unreadable"' 2>/dev/null || printf 'mission_unreadable')
            UNREADABLE="${UNREADABLE}${unreadable_sep}{\"branch\": \"${branch}\", \"reason\": \"${why}\"}"
            unreadable_sep=", "
            continue
        fi
        [ "$(printf '%s' "$ms" | jq -r '.state // ""' 2>/dev/null || printf '')" = "not_active" ] || continue
        mstatus=$(printf '%s' "$ms" | jq -r '.status // ""' 2>/dev/null || printf '')

        pr=$(sh "$PR_STATE" "$branch" 2>/dev/null || true)
        if [ "$(printf '%s' "$pr" | jq -r '.ok // false' 2>/dev/null || printf 'false')" != "true" ]; then
            why=$(printf '%s' "$pr" | jq -r '.reason // "unreadable"' 2>/dev/null || printf 'unreadable')
            UNREADABLE="${UNREADABLE}${unreadable_sep}{\"branch\": \"${branch}\", \"reason\": \"${why}\"}"
            unreadable_sep=", "
            continue
        fi
        [ "$(printf '%s' "$pr" | jq -r '.state // ""' 2>/dev/null || printf '')" != "open" ] || continue

        if git rev-parse --verify --quiet "refs/remotes/origin/${branch}" >/dev/null 2>&1; then
            state=present
        else
            state=already_gone
        fi
        empty=$(claims_branch_empty_against_base "$(claims_base)" "origin/${branch}")
        case "$empty" in true|false) ;; *) empty=unanswerable ;; esac

        candidates="${candidates}${sep}{\"unit\": \"${unit}\", \"branch\": \"${branch}\", \"state\": \"${state}\", \"candidate_reason\": \"mission_not_active\", \"mission_status\": \"${mstatus}\", \"branch_empty\": \"${empty}\"}"
        sep=", "
        named="${named}${branch}
"
    done
fi

emit true "" "$candidates"
