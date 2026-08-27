#!/bin/sh -eu
# Step 19 — retire the claims the oracle proved hold nothing.
#
# WHY THIS STEP EXISTS (2026-08-27, mission `deliver-and-retire-what-the-loop-already-proved-finished`).
# `superseded` proves a claim's content already reached the base, and it has been *reported, never
# acted on* since it shipped — so its branch, its worktree and its open pull request stayed
# forever and the claim table only ever grew. Measured 2026-08-27 on this repository: 7 claims,
# 4 of them `superseded`, two naming missions archived days ago, the oldest branch last touched
# 2026-08-21. `retire-claim.sh` is the writer; this is its ONLY caller, deliberately, because one
# caller is what keeps the retirement's bounds checkable.
#
# IT ASKS NOBODY ANYTHING, and `needs_agent` is empty for that reason. A retirement is not a
# person's business: the claim is proved empty, so there is no judgement to make and nothing for
# a human to weigh. This is the sharpest contrast with `stalled-units`, `undrivable-units` and
# `undelivered-units` beside it — each of those hands a person a reading it cannot act on, while
# this one acts and reports. Spending a question on a fact nobody needs to rule on is exactly
# what `strategy-pace` refuses to do with our own degradations.
#
# IT ACTS DIRECTLY RATHER THAN HANDING OFF, which is where it diverges from `closable-missions`
# and for a stated reason. That step hands its act to the agent because `close.sh` WRITES INTO
# THE TREE and needs a publish tree to do it. `retire-claim.sh` writes nothing into the tree at
# all — one REST `PATCH`, one branch delete, one local worktree reap — so there is no tree seam
# to cross and no reason to spend a round trip. The tick's *writes nothing but its own log line*
# contract is intact.
#
# THE RE-PROOF IS THE WRITER'S OWN, AT THE MOMENT OF THE ACT. This step reads `list-claims.sh`
# once for candidates, and `retire-claim.sh` then re-reads the oracle and re-derives the verdict
# itself before touching anything — so a row that went stale between the two reads is refused by
# the writer rather than acted on from this step's snapshot. That is the `closable-missions`
# precedent (2026-08-24) applied where it belongs: the proof is re-taken where the act happens,
# not trusted from an earlier read. A row the re-proof rejects is REPORTED, not retired.
#
# IT READS `list-claims.sh`, NEVER `plan-units.sh` — the rule `undelivered-units` and
# `undrivable-units` carry and `closable-missions` first recorded. The survey reaches the mission
# readers, which run the living migrations and STAGE what they converge; a step whose contract is
# *writes nothing into the tree* may not reach it through something that writes. `list-claims.sh`
# is a pure read.
#
# A DEGRADED READ RETIRES NOTHING. Unmerged remote branches are the only claim oracle, so a scan
# that could not reach the remote has not found "nothing to retire" — it has found nothing at
# all, and a proof that could not be read is not a proof. Reported `degraded` by name.
#
# A RETIREMENT IS A REPOSITORY EVENT, AND THIS LINE IS NOT A POSTING GATE. The root posts only
# when the tick has at least one QUESTION, and this step never has one — so its line is visible
# on a root some OTHER step's question already opened, and on a tick with no questions it is
# visible only in the log below. That is correct and deliberate: the root exists to carry
# questions, and a retirement addressed to nobody is exactly the status line two keyed roots were
# already retired for. Stated here so a later reader does not read the event as a reason to post.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason `stalled-units`'
# header records: the root calls a step changed when its summary differs from the same step's an
# hour ago, and only a timestamp, a bare hex object name and a clock time are normalised out. A
# count of what was retired this tick is stable when nothing happens, which is what the diff
# needs.
#
# Usage: step-retire-claims.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done
: "${TICK:?}"

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it.
# Empty means nothing happened here, and the renderer then emits no line at all — which is
# exactly the state of a tick that retired nothing.
emit() {
    printf '{"step": "retire-claims", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

lister="${DRIVE_SCRIPTS}/list-claims.sh"
[ -f "$lister" ] || emit degraded no_claim_reader "list-claims.sh is not present beside this skill"

retirer="${DRIVE_SCRIPTS}/retire-claim.sh"
[ -f "$retirer" ] || emit degraded no_retirement_writer "retire-claim.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$lister" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded claims_unreadable "list-claims.sh produced no output"

printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded claims_unparseable "list-claims.sh produced output this step could not parse"

fetched=$(printf '%s' "$out" | jq -r '.fetched // false')
shallow=$(printf '%s' "$out" | jq -r '.shallow // false')

[ "$fetched" = "true" ] || emit degraded origin_unreachable \
    "the claim scan could not reach the remote; nothing was proved and nothing retired"
[ "$shallow" = "true" ] && emit degraded shallow_history \
    "the claim scan ran over truncated history; a superseded claim is indistinguishable from a live one, so nothing was retired"

total=$(printf '%s' "$out" | jq '[.claims[]?] | length')
units=$(printf '%s' "$out" | jq -r '[.claims[]? | select(.resume_reason == "superseded") | .unit] | unique | .[]' 2>/dev/null || true)

n=0
for _ in $units; do n=$((n + 1)); done

if [ "$n" -eq 0 ]; then
    emit ok "" "${total} claimed unit(s); none proved superseded"
fi

# THE PER-ROW DETAIL LIVES IN `summary`, WHICH IS THE LOG-FACING FIELD — the tick log is the
# audit trail, and this step's outcomes are exactly what somebody diagnosing a retirement needs.
# `needs_agent` is NOT the home for it: that field is a request to the agent, and a payload with
# no action would be read as one. A retired row names all three acts and a refused row names its
# reason, so `retired` and `refused` are never a bare count somebody has to go digging behind.
retired=0
refused=0
detail=""
for unit in $units; do
    [ -n "$unit" ] || continue
    res=$( ( cd "$ROOT" && sh "$retirer" "$unit" ) 2>/dev/null || true )
    if [ -z "$res" ] || ! printf '%s' "$res" | jq -e . >/dev/null 2>&1; then
        res=$(printf '{"retired": false, "unit": "%s", "pull_request_closed": "not_attempted", "remote_branch_deleted": "not_attempted", "worktree_reaped": "not_attempted", "reason": "writer_unreadable"}' "$unit")
    fi
    if printf '%s' "$res" | jq -e '.retired == true' >/dev/null 2>&1; then
        retired=$((retired + 1))
        line=$(printf '%s' "$res" | jq -r '"\(.unit) retired (pr \(.pull_request_closed), branch \(.remote_branch_deleted), worktree \(.worktree_reaped))"' 2>/dev/null || printf '')
    else
        refused=$((refused + 1))
        line=$(printf '%s' "$res" | jq -r '"\(.unit) refused (\(if (.reason // "") == "" then "unstated" else .reason end))"' 2>/dev/null || printf '')
    fi
    [ -n "$line" ] || continue
    # The summary is one JSON string on one line; a quote or a control character from a unit id
    # would break the line the log and the diff both read.
    line=$(printf '%s' "$line" | sed -e 's/\\/\\\\/g' -e 's/"/'"'"'/g' -e 's/[[:cntrl:]]/ /g')
    detail="${detail:+${detail}; }${line}"
done

summary="${total} claimed unit(s); ${n} proved superseded, ${retired} retired, ${refused} refused${detail:+ — ${detail}}"

# A RETIREMENT IS A REPOSITORY EVENT (2026-08-23's rule): a pull request was closed, a branch
# deleted, a worktree reaped. A tick that retired NOTHING supplies no event and so renders no
# line at all — the independent guard against a nothing-happened line reaching the root. A tick
# that only refused is in that same class: a refusal is this step's bookkeeping, and the row is
# in the log for whoever diagnoses the tick.
event=""
if [ "$retired" -eq 1 ]; then
    event="a claim proved finished was retired — its pull request closed and its branch deleted"
elif [ "$retired" -gt 1 ]; then
    event="${retired} claims proved finished were retired — their pull requests closed and their branches deleted"
fi

# `needs_agent` IS EMPTY BY DESIGN. The act is already done; there is nothing for the agent to
# carry out and nothing for the check-in to ask. The rows below are the report, not a request.
emit ok "" "$summary" "" "$event"
