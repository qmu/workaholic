#!/bin/sh -eu
# Step — a claim branch whose work landed elsewhere while the branch still holds content of
# its own, and who must decide what becomes of it.
#
# WHY THIS STEP EXISTS (2026-08-31, mission `prove-a-claim-branch-is-empty-before-deleting-it`).
# `superseded` proved the unit's TICKETS were on the base and every consumer read it as *the
# branch holds no work*. Those are two questions, and until the proof was split a branch whose
# tickets landed under another branch's directory while it still carried files reachable from no
# other ref was reported finished and offered for deletion. Measured 2026-08-31: two branches
# carrying ~300 lines and a doc section that exist nowhere else, and only a 403 refusing the
# delete kept the work alive. Narrowing the proof stops the delete; it does not tell anybody the
# work is sitting there. This step is the telling.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS:
#
#   whose question           `handoff-units`'. The claim HOLDER wrote what is on that branch and
#                            is the only person who can say what should become of it. The
#                            claim's own `author` is the addressee.
#   running identity         `undrivable-units`'. Never consulted. The finding is about the
#                            branch, not about which container noticed it, and a question whose
#                            addressee depended on the runner would be asked differently per
#                            account.
#   what it may read         `handoff-units`'. `list-claims.sh` is a pure read; `plan-units.sh`
#                            is REFUSED, because the survey reaches the mission readers, which
#                            carry the living migrations and STAGE what they converge.
#
# THE CANDIDATE SET IS THE ORACLE'S OWN VERDICT, NOT A RE-DERIVATION. `stranded` is what
# `lib/claims.sh` already answers for a delivered claim whose branch diff is non-empty. A second
# opinion about whether a branch holds work is exactly the disagreement that would let one of
# the two answers license a delete.
#
# THE QUESTION NAMES THE FILES, because that is what makes it answerable. "A claim branch is
# stranded" sends a person to the repository to find out what is at risk; "it still holds
# src/foo.ts and two other files" lets them decide from the message. `drive/scripts/
# stranded-claim-detail.sh` resolves them — the reading the verdict was derived from, carried
# verbatim, bounded to a few names and then a count, and read once per candidate and for nothing
# else. A candidate whose files could not be read is REPORTED as unresolved rather than asked
# about with a blank list: asking somebody about content nobody could name is worse than not
# asking.
#
# IT ASKS AND NOTHING ELSE. `stranded` is a JUDGEMENT (`drive/reference/claims.md`, *Proofs and
# judgements*), and the right act for a stranded branch is genuinely unclear — the work may want
# porting onto a live branch, opening as its own pull request, or discarding deliberately. So
# nothing here merges, closes, deletes, reverts, retires, claims, or touches the branch, and no
# automatic recovery path exists. **A branch stranded for weeks with nobody answering stays
# stranded**: the question is asked once per unit, its age rides the heading through
# `condition-age.sh`, and the branch is never touched by this tick whatever that age says.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason
# `step-stalled-units.sh`'s header records: the root calls a step changed when its summary
# differs from the same step's an hour ago, so an age would make this step changed hourly by
# construction.
#
# Usage: step-stranded-branches.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/read-age.sh"
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

emit() {
    printf '{"step": "stranded-branches", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

lister="${DRIVE_SCRIPTS}/list-claims.sh"
[ -f "$lister" ] || emit degraded no_claim_reader "list-claims.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$lister" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded claims_unreadable "list-claims.sh produced no output"

printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded claims_unparseable "list-claims.sh produced output this step could not parse"

fetched=$(printf '%s' "$out" | jq -r '.fetched // false')
shallow=$(printf '%s' "$out" | jq -r '.shallow // false')

# Unmerged remote branches are the ONLY claim oracle, so a scan that could not reach the remote
# has not found "nothing stranded" — it has found nothing at all.
[ "$fetched" = "true" ] || emit degraded origin_unreachable \
    "the claim scan could not reach the remote; what is stranded could not be read this tick"
[ "$shallow" = "true" ] && emit degraded shallow_history \
    "the claim scan ran over truncated history; a stranded branch is indistinguishable from a merged one"

total=$(printf '%s' "$out" | jq '[.claims[]?] | length')
candidates=$(printf '%s' "$out" | jq -c '[.claims[]? | select(.resume_reason == "stranded")]')
n=$(printf '%s' "$candidates" | jq 'length')

summary="${total} claimed unit(s); ${n} delivered but still holding content of their own"

if [ "$n" -eq 0 ]; then
    emit ok "" "$summary"
fi

detail="${DRIVE_SCRIPTS}/stranded-claim-detail.sh"
rows=""
rsep=""
unresolved=0
for branch in $(printf '%s' "$candidates" | jq -r '.[].branch'); do
    files='[]'
    count=null
    if [ -f "$detail" ]; then
        arts=$(printf '%s' "$candidates" | jq -r --arg b "$branch" \
            '.[] | select(.branch == $b) | .artifacts[]?' 2>/dev/null || printf '')
        # shellcheck disable=SC2086 -- artifact paths are repository-relative and carry no spaces.
        look=$( ( cd "$ROOT" && sh "$detail" "$branch" $arts ) 2>/dev/null || true )
        if printf '%s' "$look" | jq -e '.readable == true and (.count // 0) > 0' >/dev/null 2>&1; then
            files=$(printf '%s' "$look" | jq -c '.files')
            count=$(printf '%s' "$look" | jq -r '.count')
        fi
    fi
    if [ "$count" = "null" ]; then
        unresolved=$((unresolved + 1))
        continue
    fi
    key="stranded-branch:$(printf '%s' "$candidates" | jq -r --arg b "$branch" \
        '.[] | select(.branch == $b) | .unit')"
    # HOW LONG THIS BRANCH HAS BEEN ASKED ABOUT, the reader's words verbatim (2026-08-30's
    # rule): an unreadable age is named as unreadable, an absent one is simply not mentioned,
    # and losing the age never loses the question.
    age=$(read_age "$key" "$ROOT")
    row=$(printf '%s' "$candidates" | jq -c --arg b "$branch" --arg k "$key" \
        --argjson f "$files" --argjson c "$count" --argjson a "$age" '
            .[] | select(.branch == $b)
            | {unit, branch, owner: (.author // "unknown"),
               files: $f, file_count: $c, age: $a, key: $k}' 2>/dev/null || printf '')
    [ -n "$row" ] || { unresolved=$((unresolved + 1)); continue; }
    rows="${rows}${rsep}${row}"
    rsep=","
done
rows="[${rows}]"
asked=$(printf '%s' "$rows" | jq 'length')

if [ "$unresolved" -gt 0 ]; then
    summary="${summary}; ${unresolved} whose held files could not be read"
fi

if [ "$asked" -eq 0 ]; then
    emit ok "" "$summary"
fi

needs=$(printf '%s' "$rows" | jq -c '{action: "ask_the_claim_holder_what_should_become_of_the_work_left_on_a_stranded_branch",
    bound: "one question per unit, addressed to the claim holder, keyed on `key` so it is asked once; the tick asks and never merges, closes, deletes, reverts, retires or claims anything, and adds no recovery path",
    compose: "lead with the plain fact that this branch was finished by another route while still holding files nothing else has, name the files and the count in the heading, and ask the one thing: whether to port the work, open it as its own pull request, or discard it",
    stranded: .}' 2>/dev/null || echo '{}')

if [ "$asked" -eq 1 ]; then
    event="a claim branch was finished by another route while still holding work of its own"
else
    event="${asked} claim branches were finished by another route while still holding work of their own"
fi

emit ok "" "$summary" "$needs" "$event"
