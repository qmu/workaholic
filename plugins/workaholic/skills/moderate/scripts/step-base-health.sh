#!/bin/sh -eu
# Step 20 — did the base survive what the loop merged?
#
# WHY THIS STEP EXISTS (2026-08-27, mission
# `read-whether-the-base-survived-what-the-loop-merged`). A red base reached a person through
# NO PATH AT ALL. `/implement` may not ask anyone anything; `step-stuck-prs.sh` and
# `step-merge-conflicts.sh` read PULL REQUESTS and find nothing wrong with one that already
# merged; `step-stalled-units.sh` reads stale claims and a red base has no claim. This tick is
# the one surface that reaches a person by name, and it had no step that looked at the base.
#
# WHICH SIBLING IT FOLLOWS, ON EACH AXIS (the ticket required this stated):
#
#   whose question       the ATTRIBUTED MERGE'S AUTHOR — `stalled-units`' axis. A real person
#                        who made the change and can act on it, rather than the repository's
#                        owner in the abstract.
#   running identity     `undrivable-units`'. NEVER consulted. A red base is a fact about the
#                        repository, so an hourly question that answered differently per
#                        container is exactly the failure that axis exists to prevent.
#   what it may read     `undrivable-units`'. The ticket-2 walk (`attribute-base-red.sh`,
#                        composing the ticket-1 reader) and nothing else. `plan-units.sh` is
#                        REFUSED for the reason `closable-missions` records: the survey reaches
#                        the mission readers, which carry the living migrations and STAGE what
#                        they converge, and a step whose contract is *writes nothing* may not
#                        reach it through something that writes.
#
# THE KEY IS THE COMMIT, NOT THE TICK AND NOT THE DAY. `base-red:<commit>` is what makes
# "exactly once per broken commit" mechanical rather than a rule somebody remembers: twenty-four
# ticks may see one red base and exactly one question goes out.
#
# `unattributable` STILL ASKS, keyed on the TIP. The base is red and that is worth a person's
# attention whether or not the walk could name a culprit; the question says plainly that the
# attribution failed and why, so nobody is sent after a merge this step did not identify. Left
# silent it would be the shape this mission exists to remove — a real finding with no path to
# a person.
#
# A DEGRADED READ ASKS NOTHING and is reported by name. `unanswerable` is a reading WE could
# not make, not a finding about the repository — the rule `direction-health` already holds for
# `unreadable` and `strategy-pace` for our own degradation. Spending a person's attention on
# our own blindness is what those steps refuse.
#
# IT ASKS AND NOTHING ELSE. It never re-runs a check ("flake" is not a root cause and a re-run
# is an ACT), never reverts, never merges, never touches a claim, and writes nothing anywhere
# but its own tick-log line. What it reads is a JUDGEMENT, not a proof: a re-run can turn a red
# check green (`drive/reference/claims.md`, *Proofs and judgements*), so acting on it is
# forbidden and reporting it is the whole job.
#
# THE SUMMARY CARRIES NO TIMESTAMP AND NO BARE SHA-ONLY DIFFERENCE, for the correctness reason
# `step-stalled-units.sh`'s header records: the moderation root calls a step changed when its
# summary differs from the same step's an hour ago, and `render-tick-post.sh` normalises out a
# timestamp, a bare hex object name and a clock time — and only those. So the summary names the
# READING and the failing checks, which is what genuinely distinguishes one hour's answer from
# the last, and the sha it carries is normalised away rather than making every tick "changed".
#
# Usage: step-base-health.sh --tick <tick-id> [--root <repo-root>]
# Output: one JSON line — {step, status, reason, summary, needs_agent, event}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
DRIVE_SCRIPTS="${SCRIPT_DIR}/../../drive/scripts"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"

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
    printf '{"step": "base-health", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

walker="${DRIVE_SCRIPTS}/attribute-base-red.sh"
[ -f "$walker" ] || emit degraded no_walker "attribute-base-red.sh is not present beside this skill"

out=$( ( cd "$ROOT" && sh "$walker" ) 2>/dev/null || true )
[ -n "$out" ] || emit degraded walk_unreadable "the base attribution produced no output"

printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    || emit degraded walk_unparseable "the base attribution produced output this step could not parse"

state=$(printf '%s' "$out" | jq -r '.state // ""')
reason=$(printf '%s' "$out" | jq -r '.reason // ""')
tip=$(printf '%s' "$out" | jq -r '.tip // ""')
# WHICH COMMIT THE VERDICT ACTUALLY RESTS ON (2026-09-01, issue #785). The tip of a base this
# loop writes to is usually a bookkeeping commit no workflow ran on, so the reading is normally
# an ANCESTOR's. Saying `green at <tip>` when the tip carried no checks would be the guess the
# three-valued reader exists to prevent; saying how far back it was is the honest sentence and
# is more useful than the silence this replaced.
checked_at=$(printf '%s' "$out" | jq -r '.checked_at // ""')
checked_behind=$(printf '%s' "$out" | jq -r '.checked_behind // 0')

# A DECLARED SUITE THAT NEVER RAN ON THE TIP (2026-09-03, mission
# `make-a-red-base-impossible-for-the-loop-to-miss`). It rides BESIDE the colour rather than
# instead of it -- a tip can carry a green verdict and an unverified suite at once, and
# collapsing them loses precisely the fact that was missed for an hour. One extra call, once per
# tick, against the TIP: the attribution walk passes no flag and its cost does not move.
#
# A DEGRADED DECLARED-READ IS NAMED AS DEGRADED, never rendered as *every suite ran* -- the same
# rule this step already holds for the colour itself.
unverified_clause=""
reader="${DRIVE_SCRIPTS}/read-base-checks.sh"
if [ -f "$reader" ] && [ -n "$tip" ]; then
    tip_look=$( ( cd "$ROOT" && sh "$reader" "$tip" --declared ) 2>/dev/null || true )
    uv_readable=$(printf '%s' "$tip_look" | jq -r '.unverified_readable // false' 2>/dev/null || printf false)
    if [ "$uv_readable" = "true" ]; then
        uv_names=$(printf '%s' "$tip_look" | jq -r '(.unverified // []) | join(", ")' 2>/dev/null || printf '')
        if [ -n "$uv_names" ]; then
            unverified_clause="; unverified on the tip (no run there): ${uv_names}"
        fi
    else
        uv_reason=$(printf '%s' "$tip_look" | jq -r '.unverified_reason // ""' 2>/dev/null || printf '')
        [ -n "$uv_reason" ] || uv_reason="unreadable"
        unverified_clause="; which declared suites ran on the tip could not be read (${uv_reason})"
    fi
fi

case "$state" in
    green)
        if [ -n "$checked_at" ]; then
            emit ok "" "the base is green at ${checked_at}, ${checked_behind} commit(s) behind the tip — the tip itself carries no checks${unverified_clause}"
        else
            emit ok "" "the base is green at ${tip}${unverified_clause}"
        fi
        ;;
    unanswerable)
        emit degraded "base_unreadable:${reason}" \
            "the base's checks could not be read (${reason}); a red base is indistinguishable from a green one this tick${unverified_clause}"
        ;;
    red|unattributable) ;;
    *)
        emit degraded walk_unparseable "the base attribution reported no state this step recognises"
        ;;
esac

# THE FAILING CHECKS ARE NAMED BY THE READER, ONCE. Asking it again for them would be a second
# call about a commit the walk already read, and the two could disagree.
commit="$tip"
author=""
pull_request=""
if [ "$state" = "red" ]; then
    commit=$(printf '%s' "$out" | jq -r '.attributed.commit // ""')
    author=$(printf '%s' "$out" | jq -r '.attributed.author // ""')
    pull_request=$(printf '%s' "$out" | jq -r '.attributed.pull_request // ""')
fi
[ -n "$commit" ] || commit="$tip"

failing="[]"
if [ -f "$reader" ]; then
    look=$( ( cd "$ROOT" && sh "$reader" "$commit" ) 2>/dev/null || true )
    got=$(printf '%s' "$look" | jq -c '.failing // []' 2>/dev/null || printf '')
    if [ -n "$got" ]; then failing="$got"; fi
fi

# THE ADDRESSEE IS AN ADDRESS, NOT A LOGIN. The walk names the pull request's GitHub login and
# the check-in mentions a person by their git address, so the one mapping reader converts it —
# and a login the mapping does not name leaves the question addressed to nobody rather than
# stamping an address nobody verified. That is `undrivable-units`' finding, not this step's to
# guess at.
owner="unknown"
if [ -n "$author" ] && [ -f "${GATHER_SCRIPTS}/identity.sh" ]; then
    ident=$( sh "${GATHER_SCRIPTS}/identity.sh" "$author" 2>/dev/null || true )
    if [ "$(printf '%s' "$ident" | jq -r '.resolved // false' 2>/dev/null || printf false)" = "true" ]; then
        owner=$(printf '%s' "$ident" | jq -r '.canonical // ""' 2>/dev/null || printf '')
        [ -n "$owner" ] || owner="unknown"
    fi
fi

names=$(printf '%s' "$failing" | jq -r '[.[].name] | join(", ")' 2>/dev/null || printf '')
[ -n "$names" ] || names="check names unavailable"

if [ "$state" = "red" ]; then
    summary="the base is red at ${commit}; attributed to that merge; failing: ${names}${unverified_clause}"
else
    summary="the base is red at ${tip}; unattributable (${reason}); failing: ${names}${unverified_clause}"
fi

row=$(printf '%s' "$out" | jq -c \
    --arg commit "$commit" --arg owner "$owner" --arg names "$names" \
    --arg pr "$pull_request" --arg st "$state" \
    '{state: $st,
      commit: $commit,
      pull_request: (if $pr == "" then "unknown" else $pr end),
      owner: $owner,
      failing: $names,
      attribution: (if $st == "red" then "attributed" else ("unattributable: " + (.reason // "")) end),
      last_green: (.last_green // ""),
      walked: (.walked // 0),
      key: ""}' 2>/dev/null || printf '')
[ -n "$row" ] || emit degraded walk_unparseable "the base attribution could not be turned into a question"

# THE ROOT LINE — supplied ONLY for a red base (2026-08-27, the mission's fourth ticket). A
# green base supplies none, so a healthy hour renders nothing at all; a degraded read supplies
# none either, because it is OUR failure to read rather than a repository event, and it is
# already named in `summary`. That is the independent guard the renderer's own rule states: **a
# step with no event renders no line** — so a nothing-happened line cannot reach the root even
# on a tick whose diff calls this step changed.
#
# IT IS NOT A SECOND POSTING GATE. The root posts when the tick has at least one question; this
# event never opens one on its own, and on a red tick this step has supplied the question anyway.
#
# EVERY ROOT LINE LINKS ITS ITEM, so a person following the line reaches the commit rather than
# the tick. The base URL is derived from the LOCAL remote — no network call, `step-direction
# -health.sh`'s precedent — and an absent remote degrades to the bare short sha rather than to a
# broken link.
remote=$( ( cd "$ROOT" && git config --get remote.origin.url ) 2>/dev/null || true )
case "$remote" in
    git@*:*) repo_base="https://github.com/$(printf '%s' "$remote" | sed 's/^git@[^:]*://; s/\.git$//')" ;;
    https://*) repo_base=$(printf '%s' "$remote" | sed 's/\.git$//') ;;
    *) repo_base="" ;;
esac
short=$(printf '%s' "$commit" | cut -c1-7)
if [ -n "$repo_base" ]; then
    commit_link="<${repo_base}/commit/${commit}|${short}>"
else
    commit_link="$short"
fi

if [ "$state" = "red" ]; then
    if [ -n "$pull_request" ]; then
        event="the base went red at ${commit_link} — ${names} failing, from <${pull_request}|that merge>"
    else
        event="the base went red at ${commit_link} — ${names} failing"
    fi
else
    event="the base is red at ${commit_link} — ${names} failing; the merge that broke it could not be attributed"
fi

# A RED BASE IS REPORTED, NOT ASKED ABOUT (2026-09-03, mission
# `make-a-red-base-impossible-for-the-loop-to-miss`). It used to be a `base-red:<commit>` question,
# and `ask-question.sh` holds a question under `quiet_hours` -- rightly, because a question
# addresses a named person and nobody should be paged at 23:00 to choose between two dates. A red
# base asks the operator to decide NOTHING: it reports that the ground everything is landing on is
# broken, while the loop keeps merging into it all night. So the reason the quiet window exists
# does not apply, and the announcement moves onto `🔴 Blocked`, which already exists for exactly
# that class and is governed by its own failure-signature cool-down.
#
# THE `base-red:<commit>` QUESTION IS RETIRED rather than kept beside the report. Two
# announcements of one fact is the noise this repository has twice retired status roots for, and
# the report is strictly the better of the two: it reaches the channel when the base breaks
# instead of the next working morning.
#
# THE COOL-DOWN IS COMPOSED, NEVER RE-DERIVED -- `workaholic:notify`'s own rule, whose expiry is
# the earlier of 24 hours and the start of the next working day, built from the check-in gate's
# `WORKAHOLIC_WORK_DAYS` / `WORKAHOLIC_QUIET_HOURS` / `WORKAHOLIC_QUIET_TZ`. No second clock gate
# and no new constant: a third copy is how three copies drift.
#
# THE SIGNATURE CARRIES NO SHA, by that same rule -- a dedup key that changes every commit
# suppresses nothing. It is the failing check names, so *the same suite still failing* is one
# alert however many red commits carry it, and a newly broken suite is a fresh root.
#
# THE ATTRIBUTION WALK IS UNTOUCHED: who broke it is still `attribute-base-red.sh`'s answer, and
# it rides the report's own sentence.
needs=$(printf '%s' "$row" | jq -c --arg names "$names" '{action: "report_the_red_base_as_a_blocked_alert",
    shape: "🔴 Blocked",
    signature: ("base red: " + $names),
    bound: "a REPORT, never a question: it is addressed to nobody, it is NOT held by `quiet_hours` or `WORKAHOLIC_WORK_DAYS`, and it is deduped by `signature` under `workaholic:notify`s existing red-alert cool-down -- composed from that rule, never re-derived here. The tick reports and never re-runs a check, reverts, merges or touches a claim",
    compose: "name the commit, its pull request and the failing checks, and say that a re-run may clear it -- this is a reading, not a verdict; when `attribution` is not `attributed`, say plainly that the walk could not name the merge and why, and send nobody after a merge this step did not identify",
    base: .}' 2>/dev/null || echo '{}')

emit ok "" "$summary" "$needs" "$event"
