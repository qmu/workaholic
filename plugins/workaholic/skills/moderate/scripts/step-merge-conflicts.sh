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
# AND THIS STEP STILL REPORTS EVERY CONFLICTED PULL REQUEST, including one `catchup-blocked`
# asks about. Filtering them here was written and then REFUSED, on a measurement rather than on
# taste: the only way to know which units that step asks about is to read the claim oracle, and
# `list-claims.sh` fetches — so a filter here would put a network fetch inside a step whose
# whole cost is one bounded REST read, and inside a hermetic suite whose fixture for this step
# carries a real `origin` URL. The ticket's requirement ("one asks and the other counts") is met
# without it, because this step ASKS NOBODY ANYTHING: `needs_agent` is empty by construction,
# its finding rides step 6's reminder, and the only question a person receives about such a unit
# is `catchup-blocked`'s. Where two steps could each ASK, the split is enforced —
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

if [ "$count" -eq 0 ]; then
    printf '{"step": "merge-conflicts", "status": "ok", "reason": "", "summary": "%s open pull request(s), none conflicted (read cap %s, truncated: %s)", "needs_agent": [], "conflicted": []}\n' \
        "$total" "$LIMIT" "$truncated"
    exit 0
fi

numbers=$(printf '%s' "$conflicted" | sed 's/.*"number": //; s/,.*//' | tr '\n' ' ' | sed 's/ $//')
printf '{"step": "merge-conflicts", "status": "blocked", "reason": "conflict", "summary": "%s of %s open pull request(s) conflicted (#%s) — reported to their claim holders, never rebased here", "needs_agent": [], "conflicted": [%s], "event": "%s of %s open pull request(s) cannot merge: conflicted (#%s)"}\n' \
    "$count" "$total" "$(printf '%s' "$numbers" | sed 's/ /, #/g')" \
    "$(printf '%s' "$numbers" | tr ' ' '\n' | awk 'NF { printf "%s%s", (n++ ? ", " : ""), $0 }')" \
    "$count" "$total" "$(printf '%s' "$numbers" | sed 's/ /, #/g')"
