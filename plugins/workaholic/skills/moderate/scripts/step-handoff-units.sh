#!/bin/sh -eu
# Step 15 — what the loop declared it cannot verify, and who must run that verification.
#
# WHY THIS STEP EXISTS (2026-08-27, mission `ask-for-the-one-act-a-declared-handoff-is-waiting-on`).
# `awaiting_verification` appeared nowhere outside `drive/`. §6 routes such a unit to the handoff
# route — pull request open on purpose, claim standing on purpose — and then nothing addressed
# anybody again: no step of this tick read the verdict, so the one surface in this plugin that
# reaches a person BY NAME never learned there was anything to say. Measured 2026-08-27: three
# units parked on a human act, queued since 2026-08-18, 2026-08-19 and 2026-08-26, each naming
# its own blocker in its own ticket, none mentioned to the account holder since the hour it routed.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS:
#
#   whose question           `stalled-units`'. The claim HOLDER drove this unit and is the person
#                            who can run the declared verification or hand it on. The claim's own
#                            `author` is the addressee.
#   running identity         `undrivable-units`'. Never consulted. An hourly question that
#                            depended on which container asked it would answer differently per
#                            account, and this finding is about the unit, not about the runner.
#   what it may read         `undrivable-units`'. `list-claims.sh` is a pure read; `plan-units.sh`
#                            is REFUSED, because the survey reaches the mission readers, which
#                            carry the living migrations and STAGE what they converge. A step
#                            whose contract is *writes nothing* may not reach it through
#                            something that writes — the reason `closable-missions` records.
#
# THE CANDIDATE SET IS THE ORACLE'S OWN VERDICT, NOT A RE-DERIVATION. `awaiting_verification` is
# what `lib/claims.sh` already answers for a reported unit whose still-QUEUED work carries
# `verification_handoff:`. A second opinion about whether a pull request is held by a declaration
# or by an ordinary park is exactly the disagreement that would reintroduce the silence.
#
# AND IT NAMES WHICH MEMBERS HOLD IT (2026-09-07, mission
# `hand-off-the-members-that-declare-and-drive-the-rest`). `awaiting_verification` used to mean
# *some member of this unit declared something*, so the unit id was the whole answer; it now means
# *every remaining member declares*, and what the addressee has to act on is the tickets, not the
# claim. `declared_members` rides each row straight off `declared-handoff-detail.sh`'s own
# partition -- no second reading, no new field on any artifact -- and the composer names them.
# THE KEY IS UNTOUCHED: `already_asked` keys on the step id `lib/question-id.sh` derives from
# `handoff-unit:<unit>`, so a body that changed re-asks nothing, and changing the key would
# re-ask every standing question.
#
# THE QUESTION NAMES THE DECLARED REASON VERBATIM, which is the whole point of it. "A claimed
# unit has not moved for a day or more" sends a person to look at a claim; "the deploy needs an
# API token added as a repository secret" tells them the one act. The string is resolved per
# candidate by `drive/scripts/declared-handoff-detail.sh` — one tip read and one
# `claim-merged.sh` lookup per candidate, and only for candidates. An `unanswerable` lookup
# leaves the coordinates unstated and KEEPS the finding: the unit waits on a person whether or
# not we could name its URL.
#
# THE SUMMARY CARRIES NO AGE AND NO TIMESTAMP, for the correctness reason
# `step-stalled-units.sh`'s header records: the root calls a step changed when its summary
# differs from the same step's an hour ago, and `render-tick-post.sh` normalises out a timestamp,
# a bare hex object name and a clock time — and ONLY those. An age increments every tick, so it
# would make this step changed HOURLY by construction.
#
# IT ASKS AND NOTHING ELSE. `awaiting_verification` is a JUDGEMENT
# (`drive/reference/claims.md`, *Proofs and judgements*), so nothing here clears a handoff,
# retries a verification, merges or closes the pull request, touches the claim, or withdraws the
# declaration. The field keeps its two writers (`/ticket` and `/specificate`) and a run never
# declares it for its own unit.
#
# Usage: step-handoff-units.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
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
# Empty means nothing happened here, and the renderer then emits no line at all.
emit() {
    printf '{"step": "handoff-units", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
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
# has not found "nothing awaiting verification" — it has found nothing at all. Named rather than
# rendered as a step that ran and found nothing.
[ "$fetched" = "true" ] || emit degraded origin_unreachable \
    "the claim scan could not reach the remote; what is awaiting verification could not be read this tick"
[ "$shallow" = "true" ] && emit degraded shallow_history \
    "the claim scan ran over truncated history; a standing handoff is indistinguishable from a merged unit"

total=$(printf '%s' "$out" | jq '[.claims[]?] | length')
candidates=$(printf '%s' "$out" \
    | jq -c '[.claims[]? | select(.resume_reason == "awaiting_verification")]')
n=$(printf '%s' "$candidates" | jq 'length')

summary="${total} claimed unit(s); ${n} awaiting a declared verification"

if [ "$n" -eq 0 ]; then
    emit ok "" "$summary"
fi

# THE DECLARED REASON AND THE PULL REQUEST, one resolution per candidate and no more. A candidate
# whose reason could not be resolved is REPORTED as unresolved rather than emitted with a blank
# string: asking somebody to satisfy a verification nobody named is worse than not asking.
detail="${DRIVE_SCRIPTS}/declared-handoff-detail.sh"
rows=""
rsep=""
unresolved=0
for branch in $(printf '%s' "$candidates" | jq -r '.[].branch'); do
    reason=""
    members="[]"
    pr_url=""
    open_hours=null
    if [ -f "$detail" ]; then
        arts=$(printf '%s' "$candidates" | jq -r --arg b "$branch" \
            '.[] | select(.branch == $b) | .artifacts[]?' 2>/dev/null || printf '')
        # shellcheck disable=SC2086 -- artifact paths are repository-relative and carry no spaces.
        look=$( ( cd "$ROOT" && sh "$detail" "$branch" $arts ) 2>/dev/null || true )
        reason=$(printf '%s' "$look" | jq -r '.reason // ""' 2>/dev/null || printf '')
        members=$(printf '%s' "$look" | jq -c '.members // []' 2>/dev/null || printf '[]')
        pr_url=$(printf '%s' "$look" | jq -r '.pull_request // ""' 2>/dev/null || printf '')
        open_hours=$(printf '%s' "$look" | jq -r '.open_hours // "null"' 2>/dev/null || printf 'null')
        case "$open_hours" in ''|*[!0-9]*) open_hours=null ;; esac
    fi
    if [ -z "$reason" ]; then
        unresolved=$((unresolved + 1))
        continue
    fi
    row=$(printf '%s' "$candidates" | jq -c --arg b "$branch" --arg r "$reason" --arg u "$pr_url" \
        --argjson h "$open_hours" --argjson m "$members" '
            .[] | select(.branch == $b)
            | {unit, branch, owner: (.author // "unknown"),
               declared_reason: $r,
               declared_members: $m,
               pull_request: (if $u == "" then "unknown" else $u end),
               open_hours: $h,
               key: ("handoff-unit:" + .unit)}' 2>/dev/null || printf '')
    [ -n "$row" ] || { unresolved=$((unresolved + 1)); continue; }
    rows="${rows}${rsep}${row}"
    rsep=","
done
rows="[${rows}]"
asked=$(printf '%s' "$rows" | jq 'length')

if [ "$unresolved" -gt 0 ]; then
    summary="${summary}; ${unresolved} whose declared reason could not be resolved"
fi

if [ "$asked" -eq 0 ]; then
    # Nothing nameable to ask about: a fact for the log, and no root line, because the finding's
    # whole delivery is the question and there is none.
    emit ok "" "$summary"
fi

needs=$(printf '%s' "$rows" | jq -c '{action: "ask_the_claim_holder_to_run_the_verification_this_unit_was_declared_to_need",
    bound: "one question per unit, addressed to the claim holder, keyed on `key` so it is asked once; the tick asks and never clears a handoff, retries a verification, merges the pull request or touches the claim",
    compose: "lead with what happened in words a channel reader understands — the work is finished as far as this environment can take it and one verification is left — then the identifier, then quote the declared reason verbatim as the one act asked of the addressee, and link its open pull request. Name the tickets in `declared_members` as what they must act on: since 2026-09-07 a declaration holds its own members rather than the whole unit, so the unit id alone sends a person to a claim where a ticket path would send them to the sentence they have to satisfy. Never open with the unit id, a claim verdict or a step name.",
    handoffs: .}' 2>/dev/null || echo '{}')

if [ "$asked" -eq 1 ]; then
    event="a finished unit is waiting on a verification only a person can run"
else
    event="${asked} finished units are waiting on verifications only a person can run"
fi

emit ok "" "$summary" "$needs" "$event"
