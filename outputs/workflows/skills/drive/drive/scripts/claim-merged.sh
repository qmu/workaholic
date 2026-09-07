#!/bin/sh -eu
# Has this claim branch's work reached the base? One reader, GRAIN-AGNOSTIC, answering
# exactly that and nothing else.
#
# WHY IT EXISTS (2026-08-26, mission `tell-a-merged-claim-from-a-live-one-at-both-grains`).
# `claims_superseded` answers the same question offline, from the tickets a batch unit
# stamps — and by construction it cannot answer for a mission claim, which stamps only
# `mission.md`. A squash merge compounds it: the content reaches the base while no branch
# commit does, so `git rev-list --count base..ref` stays positive and the claim is claimed
# forever. Measured on this repository: three of five claims headed pull requests #521,
# #537 and #546, all merged, all mission units, one of them offered `resumable: true` five
# days after its own pull request merged.
#
# THE QUESTION IS ASKED OF THE PULL REQUEST, NOT OF THE TREE. "Is there a MERGED pull
# request whose head is this branch?" answers at both grains without reading a single
# artifact — no `mission:` relation, no ticket, no `## Acceptance`. That constraint is the
# whole reason this reader is worth having: the alternative, walking every ticket on the
# base and reading its many-valued `mission:` relation, is a second parser of a field this
# repository deliberately keeps behind one reader.
#
# IT IS THREE-VALUED, AND THE THIRD VALUE IS THE POINT. `merged` and `not_merged` are facts
# about the repository; `unanswerable` is a fact about US — no `gh`, a refused transport, a
# rate limit, a response we could not parse. Collapsing that third case into `not_merged`
# would turn every offline run into a confident "still claimed", which is precisely the
# failure the claim protocol's own reader spends its longest comment refusing. A caller
# keeps its offline verdict when the answer is `unanswerable`.
#
# IT EXITS 0 IN EVERY CASE, INCLUDING EVERY DEGRADATION. A reader that exits non-zero turns
# a degraded read into a failed scan, and a failed scan reports no claims at all — the one
# outcome worse than an over-reported claim.
#
# WHY IT IS EXECUTED RATHER THAN SOURCED. This is the claim protocol's ONE network read, and
# keeping it a separate process is what makes it separable: a caller can decide not to spend
# it, a test can stub `gh` on PATH and drive all three states, and nothing it defines can
# leak into `claims_scan`'s variable space, which is a shell library sharing one flat
# namespace with a loop that already carries thirty `_cs_` locals.
#
# WHY IT SITS BESIDE `lib/` RATHER THAN INSIDE IT, though `claims.sh` is its only consumer:
# the bundle build detects a cross-skill closure by the literal form
# `${SCRIPT_DIR}/../../<skill>/scripts/`, which is only writable from `scripts/`. From inside
# `lib/` the same reference needs a third `../` and `verify.mjs` reports it as undetectable —
# so a reader in `lib/` would ship to every non-Claude agent with its transport missing. The
# convention bends to the build, and the build's rule is the one with a failure mode.
#
# IT ALSO ANSWERS WHAT BECAME OF THE PULL REQUEST (2026-08-27, mission
# `close-the-units-the-loop-already-finished`). Every claim excluded `claimed_reported` is a
# unit the loop finished and reported, and nothing asked what happened to it afterwards. That
# question is NOT the one `state` answers: `state=closed` made an OPEN pull request return an
# empty array, so `open`, `closed-without-merging` and `no pull request at all` collapsed into
# one `not_merged` — measured 2026-08-27, #622/#625/#633/#635 all open, green and reported
# `not_merged`, indistinguishable from a branch nobody ever opened one for.
#
# IT IS WIDENED RATHER THAN JOINED BY A SECOND READER, deliberately: the claim protocol
# holds ONE network read, and this question is answered by the same call. `state=all` is a
# superset of `state=closed`, and `merged` is still exactly "some pull request for this head
# has a non-null `merged_at`" — so **`state` and `reason` are byte-identical to what they
# were**, and every existing consumer is untouched. The new fields are additive and describe
# the pull request, never a judgement about it: whether a scan finding holds it open or a
# transport refusal did is a different question, and answering it here would give two callers
# one answer.
#
# Usage: claim-merged.sh <branch-name>
# Output: one JSON line
#   {"branch", "state": "merged|not_merged|unanswerable", "reason",
#    "pr_state": "merged|open|closed|none|unanswerable",
#    "pr_number": <n>|null, "pr_url": "<url>", "open_hours": <n>|null}
#
#   pr_state   what became of the head's pull request. `none` means the lookup succeeded and
#              found no pull request at all — a fact, and the one `not_merged` used to hide.
#   open_hours how long an OPEN pull request has been open, in whole hours; null for every
#              other state and for a `created_at` that could not be parsed. An age we could
#              not read is null, never 0 — a pull request whose date is unreadable is exactly
#              the one a reader must not call fresh (`step-stalled-units.sh`'s rule).

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GH_REST="${SCRIPT_DIR}/../../gather/scripts/gh-rest.sh"

BRANCH="${1:-}"

# $1 state, $2 reason, $3 pr_state, $4 pr_number (JSON), $5 pr_url, $6 open_hours (JSON).
# The defaults are the degraded shape, so every `emit unanswerable <reason>` call above and
# below stays exactly as it was written.
emit() {
    printf '{"branch": "%s", "state": "%s", "reason": "%s", "pr_state": "%s", "pr_number": %s, "pr_url": "%s", "open_hours": %s}\n' \
        "$BRANCH" "$1" "${2:-}" "${3:-unanswerable}" "${4:-null}" "${5:-}" "${6:-null}"
    exit 0
}

[ -n "$BRANCH" ] || emit unanswerable no_branch
[ -f "$GH_REST" ] || emit unanswerable no_transport_script

# NO SEPARATE AVAILABILITY PROBE. `gh-rest.sh available` would answer the same question one
# round trip earlier, and this reader runs once per claim — so the probe would double the
# network cost of the scan to learn what the call itself reports. The failure of the one
# call is classified instead, which is also the only classification that stays honest when
# the transport dies BETWEEN a probe and the call.
slug=$(sh "$GH_REST" slug 2>/dev/null || true)
case "$slug" in
    */*) ;;
    *) emit unanswerable slug_unresolved ;;
esac
owner="${slug%%/*}"

# REPOSITORY-SCOPED, AND FILTERED LOCALLY. `search/*` is refused outright by a bound
# session (`rules/shell.md`), so the lookup is the `pulls` collection narrowed by `head`,
# which the REST API supports as `<owner>:<branch>`. `merged_at` is what separates merged
# from closed-unmerged — a pull request somebody closed without merging is emphatically NOT
# this branch's work reaching the base.
#
# `state=all` RATHER THAN `state=closed` (2026-08-27). Closed is the superset of *merged*,
# which is all the original question needed — and it is why an open pull request came back as
# an empty array and read `not_merged`. `all` is a superset of `closed`, so the merged test
# below is unchanged; what it adds is the ability to say `open` and `none` apart.
if ! body=$(sh "$GH_REST" api \
        "repos/${slug}/pulls?state=all&head=${owner}:${BRANCH}&per_page=50" 2>&1); then
    # EACH FAILURE NAMED DISTINCTLY ENOUGH TO REPORT, which is what the consuming step needs
    # in order to say what it could not read rather than what it did not find.
    case "$body" in
        *"not on PATH"*) emit unanswerable gh_unavailable ;;
        *"rate limit"*|*"rate_limit"*|*"API rate"*) emit unanswerable rate_limited ;;
        *"not enabled for this session"*|*"not permitted for this session"*)
            emit unanswerable session_refused ;;
        *) emit unanswerable transport_error ;;
    esac
fi

# An unparseable body is ours too: it is never evidence that nothing merged.
printf '%s' "$body" | jq -e 'type == "array"' >/dev/null 2>&1 || emit unanswerable unparseable_response

merged=$(printf '%s' "$body" | jq '[.[] | select(.merged_at != null)] | length' 2>/dev/null || echo "")
case "$merged" in
    ''|*[!0-9]*) emit unanswerable unparseable_response ;;
esac

# WHICH PULL REQUEST THE EXTRA FIELDS DESCRIBE, in a fixed order so two runs over one branch
# never disagree: a merged one wins, then the newest open one, then the newest closed one.
# A branch normally has exactly one; the order matters only for a head that was reopened or
# re-proposed, and there the merged one is the only answer that is about the base.
row=$(printf '%s' "$body" | jq -c '
    (   ([.[] | select(.merged_at != null)] | sort_by(.merged_at) | last)
     // ([.[] | select(.state == "open")]   | sort_by(.created_at) | last)
     // ([.[] | select(.merged_at == null)] | sort_by(.created_at) | last)
    ) // empty' 2>/dev/null || true)

pr_number=null
pr_url=""
open_hours=null
if [ -z "$row" ]; then
    # THE LOOKUP SUCCEEDED AND THERE IS NO PULL REQUEST. That is a fact about the repository,
    # not a degradation, so it is `none` and never `unanswerable`.
    pr_state=none
else
    pr_number=$(printf '%s' "$row" | jq '.number // null' 2>/dev/null || echo null)
    case "$pr_number" in '' ) pr_number=null ;; esac
    pr_url=$(printf '%s' "$row" | jq -r '.html_url // ""' 2>/dev/null || printf '')
    if [ "$(printf '%s' "$row" | jq -r '.merged_at // "null"' 2>/dev/null || printf 'null')" != "null" ]; then
        pr_state=merged
    elif [ "$(printf '%s' "$row" | jq -r '.state // ""' 2>/dev/null || printf '')" = "open" ]; then
        pr_state=open
        # `date -d`, not jq's `fromdateiso8601` — the same choice `step-stalled-units.sh`
        # records: an age we could not parse must read null rather than 0.
        created=$(printf '%s' "$row" | jq -r '.created_at // ""' 2>/dev/null || printf '')
        if [ -n "$created" ]; then
            epoch=$(date -d "$created" +%s 2>/dev/null || true)
            [ -n "$epoch" ] && open_hours=$(( ( $(date +%s) - epoch ) / 3600 ))
        fi
    else
        pr_state=closed
    fi
fi

if [ "$merged" -gt 0 ]; then
    emit merged "" "$pr_state" "$pr_number" "$pr_url" "$open_hours"
else
    emit not_merged "" "$pr_state" "$pr_number" "$pr_url" "$open_hours"
fi
