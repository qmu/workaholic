#!/bin/sh -eu
# Step 11 — what is claimed, and how long it has not moved.
#
# WHY THIS STEP EXISTS (2026-08-23, issue #584 / the report filed as osbrjp/coop-csnet#83).
# A consuming repository's loop stopped for eleven consecutive ticks. Every tick ran,
# reported `blocked` correctly, and spent agent-hours; the only outbound signal was a
# mention-less reply inside a feedback thread written the previous day. Slack notified
# nobody, channel level showed nothing, and the developer found the stall by noticing the
# channel had not moved in ten hours.
#
# There was no path from *the loop is stuck* to *a person is asked*. `/implement` cannot
# ask — no `AskUserQuestion` anywhere, at any step — and this tick's check-in, the one
# surface in this plugin that names a person and therefore notifies them, asked only about
# what its own steps had found. No step read the state of claimed work, so the surface that
# could ask never learned there was anything to ask about.
#
# THE COUPLING IS A READER, NOT A HANDOFF — the same shape as `strategy-pace` beside it.
# A `/implement` run writes nothing into the tree about its own blockers and its container
# is discarded, so it could not leave a finding here even if it wanted to. This step calls
# the claim oracle itself: `drive/scripts/list-claims.sh`, a pure read over unmerged remote
# branches, which is already the only thing in this plugin allowed to answer "what is
# claimed". Two readers of one script is not two sources of truth.
#
# THE AGE COMES FROM THE CLAIM BRANCH TIP AND NOWHERE ELSE. The heartbeat already advances
# that tip (`drive/scripts/heartbeat.sh`), so "how long since this unit moved" is already
# recorded by the protocol. Deriving a second notion of last activity — a file, a stored
# cursor, a mission field — would give the claim protocol two clocks, and the one that
# drifted would be believed.
#
# IT REPORTS EVERY CLAIM AND FILTERS NOTHING. What counts as *long enough to matter* is a
# judgement, and it belongs to the step that asks (`human-checkin`), not to the step that
# reads. A threshold here would decide in a script what a person should be asked about, and
# the eleven-tick stall is what happens when that judgement is made silently.
#
# IT CHANGES NO OBSERVABLE BEHAVIOUR. It posts nothing, asks nothing, touches no claim, and
# emits an empty `needs_agent`: the asking is its sibling ticket's subject, and shipping the
# reading first means this lands provable and inert.
#
# A DEGRADED READ IS NAMED, NEVER RENDERED AS CALM. `fetched: false` means the claim scan
# could not reach the remote, and unmerged remote branches are the *only* claim oracle — so
# a local-only scan does not mean nothing is stalled, it means nothing could be read.
# `shallow: true` means the history was truncated and a merged unit can look claimed. Both
# report `degraded` with the reason, exactly as every other reader in this tick does.
#
# Usage: step-stalled-units.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...]}

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

emit() {
    printf '{"step": "stalled-units", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s]}\n' \
        "$1" "$2" "$3" "${4:-}"
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

# Unmerged remote branches are the ONLY claim oracle, so a scan that could not reach the
# remote has not found "no stalled units" — it has found nothing at all.
[ "$fetched" = "true" ] || emit degraded origin_unreachable \
    "the claim scan could not reach the remote; what is claimed could not be read this tick"
[ "$shallow" = "true" ] && emit degraded shallow_history \
    "the claim scan ran over truncated history; a merged unit is indistinguishable from a held one"

# Per claim: the unit, its branch, who holds it, how long since the branch last moved, and
# whether it ever reached a pull request. `reported` is the claim oracle's own offline
# signal (the branch carries the story file `/story` commits when it opens the PR) — this
# step does not ask GitHub, so a tick with no network still answers.
#
# THE AGE IS COMPUTED WITH `date`, NOT WITH jq's `fromdateiso8601`. That builtin accepts
# only the `Z` form, and the claim oracle emits `%cI` — a git committer date, which carries
# the committing machine's offset (`+09:00` here). Parsing those in jq reported five of
# seven live claims as "unknown age" on the first run of this step, which is precisely the
# reading a stalled-unit reader must never get wrong.
now=$(date +%s)
rows='[]'
tsv=$(printf '%s' "$out" | jq -r '.claims[]? | [.unit, .branch, (.author // "unknown"), (.last_commit_at // ""), (.reported // false), (.resume_reason // "")] | @tsv' 2>/dev/null || true)
if [ -n "$tsv" ]; then
    rows=$(
        printf '%s\n' "$tsv" | while IFS='	' read -r u b o at rep rr; do
            [ -n "$u" ] || continue
            hours=null
            if [ -n "$at" ] && [ "$at" != "unknown" ]; then
                epoch=$(date -d "$at" +%s 2>/dev/null || true)
                [ -n "$epoch" ] && hours=$(( (now - epoch) / 3600 ))
            fi
            printf '%s\n' "$u" "$b" "$o" "$at" "$rep" "$rr" "$hours" \
                | jq -Rn --argjson h "$hours" '
                    [inputs] as $f
                    | {unit: $f[0], branch: $f[1], owner: $f[2],
                       last_commit_at: (if $f[3] == "" then "unknown" else $f[3] end),
                       stalled_hours: $h,
                       has_pull_request: ($f[4] == "true"),
                       resume_reason: $f[5]}'
        done | jq -sc '.'
    )
fi
[ -n "$rows" ] || rows='[]'

count=$(printf '%s' "$rows" | jq 'length' 2>/dev/null || echo 0)
[ "$count" -eq 0 ] && emit ok "" "nothing is claimed; no unit is stopped"

# An age the tip could not date is reported as unknown rather than as zero: a claim whose
# timestamp is unreadable is exactly the one a reader must not call fresh.
unknown_age=$(printf '%s' "$rows" | jq '[.[] | select(.stalled_hours == null)] | length')
oldest=$(printf '%s' "$rows" | jq '[.[] | .stalled_hours // 0] | max // 0')
with_pr=$(printf '%s' "$rows" | jq '[.[] | select(.has_pull_request)] | length')

emit ok "" \
  "${count} claimed unit(s); oldest stopped ${oldest}h, ${with_pr} at a pull request, ${unknown_age} of unknown age"
