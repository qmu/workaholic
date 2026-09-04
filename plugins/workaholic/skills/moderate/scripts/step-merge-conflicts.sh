#!/bin/sh -eu
# Step 4 — the pull requests whose merge is blocked by conflict state.
#
# IT DOES NOT REBASE (resolved 2026-08-17, the ticket's Open Decision). The ask
# says "rebase where necessary"; this reports instead, and the reason is
# structural rather than stylistic. A `work-*` branch **is** a claim: the
# heartbeat is its tip and `archive.sh` pushes it after each archive commit, so a
# third party rebasing it races the claim holder's own pushes and can strand or
# duplicate a unit. That is one of the three unit-less writer designs
# `workaholic:ship` §7 measured and refused.
#
# The two alternatives were considered and are refused on the repository's own
# standing decisions, not on taste. Rebasing only branches with **no live claim**
# needs a staleness rule the claim protocol deliberately does not have — it
# reports staleness and never acts on it, precisely so that "old" never becomes a
# licence to take someone's work. Rebasing anything accepts the race knowingly.
# And the drive loop already assigns this repair to its owner: a merge-conflict
# notice tells the claim holder to resolve it, which is the person who knows which
# side of the conflict keeps its behaviour.
#
# ITS FINDING RIDES STEP 6'S REMINDER, and it posts nothing of its own — two Slack
# lines about the same pull request in the same tick is the noise a gated post
# exists to prevent. This step's output is the log line and the report row.
#
# THE STANDING RULE ABOVE IS NARROWED, NOT REVERSED (2026-08-29, mission
# `land-the-loop-s-own-work-when-the-base-moves-under-it`). `drive/scripts/catch-up-claim.sh`
# does now bring a claim branch back onto the base — but both halves of the reasoning above are
# answered rather than dropped: it is not a THIRD PARTY (the claim is that identity's own, and a
# live one is refused `claim_active`, so the race this header is about cannot arise), and it is
# not a REBASE (a merge commit keeps the holder's checkout valid, which is precisely what a
# history rewrite destroys). What stays untouched is the contested case: a `content` conflict is
# refused, the branch is left byte-identical, and the person who knows which side keeps its
# behaviour is asked — which is what this header has always said the repair is.
#
# AND THIS STEP STILL REPORTS EVERY CONFLICTED PULL REQUEST, including one the catch-up
# asks about. Filtering them here was written and then REFUSED, on a measurement rather than on
# taste: the only way to know which units that step asks about is to read the claim oracle, and
# `list-claims.sh` fetches — so a filter here would put a network fetch inside a step whose
# whole cost is one bounded REST read, and inside a hermetic suite whose fixture for this step
# carries a real `origin` URL. The ticket's requirement ("one asks and the other counts") is met
# without it, because this step ASKS NOBODY ANYTHING: `needs_agent` is empty by construction,
# its finding rides step 6's reminder, and the only question a person receives about such a unit
# belongs to `/implement`'s catch-up, which attempts it. Where two steps could each ASK, the split is enforced —
# `undelivered-units` filters a `mergeability: content` row out of its own candidates and counts
# it instead.
#
# Usage: step-merge-conflicts.sh --tick <id> --root <repo-root> [--limit <n>]
# Output: one JSON line {"step","status","reason","summary","needs_agent":[],"conflicted":[...]}

# ONE OBJECT PER LINE, VIA awk. `tr '}' '}\n'` looks like it splits the JSON and
# does not: tr maps one character to one character, so the replacement's second
# character is dropped and the whole payload stays on one line — after which a
# greedy `sed 's/.*"number": //'` reads the LAST pull request's number for every
# match. Measured 2026-08-17: two open pull requests, one conflicted, reported as
# "#13 conflicted" when #12 was the conflicted one.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LIMIT=10

while [ $# -gt 0 ]; do
    case "$1" in
        --limit) LIMIT="${2:-10}"; shift 2 ;;
        --tick|--root) shift 2 ;;
        *) shift ;;
    esac
done

state=$(sh "${SCRIPT_DIR}/pulls-state.sh" --limit "$LIMIT" 2>/dev/null || true)

case "$state" in
    *'"ok": true'*) ;;
    *)
        reason=$(printf '%s' "$state" | sed 's/.*"reason": "//; s/".*//')
        [ -n "$reason" ] || reason=gh_unavailable
        printf '{"step": "merge-conflicts", "status": "degraded", "reason": "%s", "summary": "pull requests unreadable — conflict state unknown this tick", "needs_agent": [], "conflicted": []}\n' "$reason"
        exit 0
        ;;
esac

conflicted=$(printf '%s' "$state" | awk '{ gsub(/}/, "}\n"); print }' | grep '"blocked_by": "conflict"' || true)
count=$(printf '%s' "$conflicted" | awk 'NF { n++ } END { print n + 0 }')
total=$(printf '%s' "$state" | sed 's/.*"total_open": //; s/,.*//')
truncated=$(printf '%s' "$state" | sed 's/.*"truncated": //; s/,.*//')

# THE FOURTH ANSWER, WHICH THIS SENTENCE USED TO SWALLOW (2026-08-29, ticket `20260829092046`).
# GitHub computes `mergeable` LAZILY — `null` until a background merge job finishes — and
# `pulls-state.sh` maps that to `blocked_by: unknown` precisely so the state is nameable. This
# step counted only `conflict` rows, so a tick that COULD NOT LOOK and a tick that looked and
# FOUND NOTHING both reported `none conflicted`, in the voice of a completed reading. Measured
# on tick `20260829-085055` (issue #710): this step said `none conflicted` over the same open
# set in which step 6 named four — #622, #625, #633, #688, the oldest unmergeable since
# 2026-08-26. It is the *found nothing* versus *could not look* collapse this repository has
# repaired by name in `attributed-work.sh`, in the three-valued merged lookup and in
# `ci-retirement-turn.sh`: a reading we could not make is never dressed as one we did.
#
# `unknown` IS NOT `degraded` AND NOT `blocked`, and the choice is deliberate. `degraded` names
# a transport this step could not read, and the transport answered fine; `blocked` asserts a
# conflict nobody proved, which would send a claim holder after one — the wrong direction, on
# the merged-lookup precedent that a wrong verdict costs more in one direction than the other.
# It is a named part of an `ok` reading.
#
# AND IT ADDS NO `event`. This step posts nothing of its own by design — its finding rides step
# 6's reminder — so an `event` here would draw a second Slack line about the same pull request
# in the same tick, which is the noise the gate exists to prevent.
uncomputed=$(printf '%s' "$state" | awk '{ gsub(/}/, "}\n"); print }' | grep -c '"blocked_by": "unknown"' || true)
case "$uncomputed" in ''|*[!0-9]*) uncomputed=0 ;; esac

# `UNKNOWN_NOTE` IS RETIRED AND THE EVENT NO LONGER CARRIES IT (2026-09-02, mission
# `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`, ticket
# `20260902042630-drop-the-notification-for-an-uncomputed-mergeable-state`). The operator's
# ruling: an uncomputed mergeable state is not worth a notification. The `event` is the ROOT
# CHANGE LINE — the one thing this step puts on the channel — so the note was the whole of
# what a reader was told about a state that says nothing about the pull request and everything
# about when we happened to ask. GitHub computes it asynchronously and the next tick reads it.
#
# THE COUNT IS NOT LOST. It stays on the `uncomputed` field, where the run report and every
# other reader already take it, and — for the zero-conflict branch — in that branch's own
# summary, which carries no event and so reaches nobody's channel. The 2026-09-01 removal of
# this count from the COMPARED summary stands unchanged and for its own separate reason; this
# removes it from the CHANNEL. The variable is deleted rather than emptied: an unused
# `UNKNOWN_NOTE=""` still threaded into the format string is how the note comes back.

# THE UNCOMPUTED COUNT IS TRANSPORT-DERIVED AND NO LONGER RIDES THE COMPARED SUMMARY
# (2026-09-01, ticket `20260901122448-name-every-step-summary-carrying-transport-derived-
# volatility`). `render-tick-post.sh` compares `(step, status, stabilized summary)` for the
# change diff and again for the impairment diff, and this step's blocked row is in both. A
# row reads `uncomputed` purely because GitHub has not finished computing `mergeable` yet —
# `pulls-state.sh`'s own header records four pull requests reading `unknown` hour after hour
# and a single re-read settling all four — so the count moves with nothing in the repository
# moving, and every time it moved this step opened a root.
#
# WHAT STAYS IS THE REPOSITORY FACT: how many of how many open pull requests conflict, and
# which. A pull request whose mergeability finally computes as `false` still changes that
# count and still speaks. The `uncomputed` FIELD is untouched, so every reader that wants the
# number still has it; only the compared string is coarsened, and `reason` never reaches the
# tick log so `mergeability_uncomputed` cannot enter the comparison either.
#
# It USED to survive on the `event`, on the reasoning that a change line is rendered only when
# the summary already moved, so it could add detail without earning a root of its own. That
# reasoning was sound about ROOTS and beside the point about READERS: the event is the line a
# person actually sees, and 2026-09-02 the operator ruled the detail itself unwanted. It is
# gone from there too (above); the count keeps its field.
if [ "$count" -eq 0 ]; then
    # A tick with neither conflicts nor uncomputed rows keeps today's wording byte-identically;
    # one with uncomputed rows never claims `none conflicted` about them.
    if [ "$uncomputed" -eq 0 ]; then
        printf '{"step": "merge-conflicts", "status": "ok", "reason": "", "summary": "%s open pull request(s), none conflicted (read cap %s, truncated: %s)", "needs_agent": [], "conflicted": [], "uncomputed": 0}\n' \
            "$total" "$LIMIT" "$truncated"
    else
        printf '{"step": "merge-conflicts", "status": "ok", "reason": "mergeability_uncomputed", "summary": "%s open pull request(s), none read as conflicted, some not yet computed by GitHub (read cap %s, truncated: %s)", "needs_agent": [], "conflicted": [], "uncomputed": %s}\n' \
            "$total" "$LIMIT" "$truncated" "$uncomputed"
    fi
    exit 0
fi

numbers=$(printf '%s' "$conflicted" | sed 's/.*"number": //; s/,.*//' | tr '\n' ' ' | sed 's/ $//')
printf '{"step": "merge-conflicts", "status": "blocked", "reason": "conflict", "summary": "%s of %s open pull request(s) conflicted (#%s) — resolving them belongs to an [Implement] run rather than to this tick, which reads and does not merge; what the merge itself cannot settle waits on a person", "needs_agent": [], "conflicted": [%s], "uncomputed": %s, "event": "%s of %s open pull request(s) cannot merge: conflicted (#%s)"}\n' \
    "$count" "$total" "$(printf '%s' "$numbers" | sed 's/ /, #/g')" \
    "$(printf '%s' "$numbers" | tr ' ' '\n' | awk 'NF { printf "%s%s", (n++ ? ", " : ""), $0 }')" \
    "$uncomputed" \
    "$count" "$total" "$(printf '%s' "$numbers" | sed 's/ /, #/g')"
