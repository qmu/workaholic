#!/bin/sh -eu
# Step 6 — the pull requests that failed to auto-merge, and what each needs.
#
# WHAT MAKES THIS USEFUL IS THE SECOND HALF. "PR #12 is red" is a fact a human can
# already see; "PR #12 needs a review that nobody has been asked for" is a
# decision. So every row carries `blocked_by`, resolved mechanically from GitHub's
# own mergeability fields, and the report the agent composes names the decision
# rather than the colour.
#
# THIS STEP NO LONGER FEEDS A SLACK POST (2026-08-19, issue #525). It fed the
# tick's `🔧 Needs a decision` reminder until then, and the reporter asked that
# pull-request status, merge-conflict and merge-readiness messaging leave Slack.
# THE FINDING STAYED AND THE POST WENT: everything below is unchanged and lands in
# the run's report and the tick log instead. `action` reads `report` rather than
# `remind` for exactly that reason — an unattended agent handed a row saying
# "remind" would be told to do the thing the change removed.
#
# ONE REPORT PER DISTINCT STATE. The key is `stuck:<digest>` over the sorted
# `<number>:<blocked_by>` set, so a pull request that is still stuck for the same
# reason next hour earns no second row, while a NEW pull request or a CHANGED
# reason does. THE DERIVATION IS LEFT BYTE-IDENTICAL to what it was when it keyed
# a post, deliberately: re-cutting a settled dedup key is churn this repository has
# recorded twice, and a later relocation of the post should reuse this verbatim.
# With nothing on the wire there is no `workaholic:notify` search to run, so the
# single gate is the tick log's own `stuck-prs-filed` entry.
#
# ITS KEY IS DELIBERATELY DISTINCT from `[Prepare Release]`'s `deploy:<digest>`:
# one reports what is waiting to deploy, this reports what is waiting on a human,
# and a shared key would let either dedup the other away.
#
# THE HEADLINE NAMES THE KIND (2026-08-18, issue #513). The finding's varying half
# was its second line while its first read `<N> pull request(s) waiting on a human`
# every time, so a reader saw one invariant heading whether the finding was a
# conflict, an un-run auto-merge or a failing check. `headline` is derived from the
# `blocked_by` set this script already computes, so a conflict finding and a review
# finding differ at the first line.
#
# CONFLICTS RIDE THIS ROW TOO. Step 4 reports conflict state and emits nothing of
# its own; two reports about one pull request in one tick is the noise the gate
# exists to prevent.
#
# Usage: step-stuck-prs.sh --tick <id> --root <repo-root> [--limit <n>]
# Output: one JSON line {"step","status","reason","summary","headline","needs_agent":[...],"key":"stuck:<digest>"}

# ONE OBJECT PER LINE, VIA awk. `tr '}' '}\n'` looks like it splits the JSON and
# does not: tr maps one character to one character, so the replacement's second
# character is dropped and the whole payload stays on one line — after which a
# greedy `sed 's/.*"number": //'` reads the LAST pull request's number for every
# match. Measured 2026-08-17: two open pull requests, one conflicted, reported as
# "#13 conflicted" when #12 was the conflicted one.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LOG_READ="${SCRIPT_DIR}/log-read.sh"
ROOT='.'
LIMIT=10

while [ $# -gt 0 ]; do
    case "$1" in
        --limit) LIMIT="${2:-10}"; shift 2 ;;
        --root)  ROOT="${2:-}"; shift 2 ;;
        --tick)  shift 2 ;;
        *) shift ;;
    esac
done

state=$(sh "${SCRIPT_DIR}/pulls-state.sh" --limit "$LIMIT" 2>/dev/null || true)

case "$state" in
    *'"ok": true'*) ;;
    *)
        reason=$(printf '%s' "$state" | sed 's/.*"reason": "//; s/".*//')
        [ -n "$reason" ] || reason=gh_unavailable
        printf '{"step": "stuck-prs", "status": "degraded", "reason": "%s", "summary": "pull requests unreadable — no stuck-set finding can be trusted this tick", "headline": "", "needs_agent": [], "key": ""}\n' "$reason"
        exit 0
        ;;
esac

rows=$(printf '%s' "$state" | awk '{ gsub(/}/, "}\n"); print }' | grep '"blocked_by": "' | grep -v '"blocked_by": ""' || true)
count=$(printf '%s' "$rows" | awk 'NF { n++ } END { print n + 0 }')

if [ "$count" -eq 0 ]; then
    printf '{"step": "stuck-prs", "status": "ok", "reason": "", "summary": "nothing is stuck: every open pull request is mergeable", "headline": "", "needs_agent": [], "key": ""}\n'
    exit 0
fi

# The digest is over the STATE, not the count: a different pull request, or the
# same one blocked for a different reason, is a different answer and earns a post.
pairs=$(printf '%s' "$rows" | sed 's/.*"number": \([0-9]*\).*"blocked_by": "\([a-z]*\)".*/\1:\2/' | sort | tr '\n' ' ')
digest=$(printf '%s' "$pairs" | cksum | awk '{ print $1 }')
KEY="stuck:${digest}"

# The heading's varying half. Derived from the SAME `blocked_by` set the digest is
# taken over, but never fed back into it: this is wording, the key is the contract.
kinds=$(printf '%s' "$rows" | sed 's/.*"blocked_by": "\([a-z]*\)".*/\1/' | sort -u)
kind_count=$(printf '%s' "$kinds" | awk 'NF { n++ } END { print n + 0 }')
plural='pull request'
[ "$count" -eq 1 ] || plural='pull requests'
if [ "$kind_count" -eq 1 ]; then
    case "$kinds" in
        conflict) what='conflicting with main' ;;
        review)   what='waiting on review' ;;
        checks)   what='with a failing check' ;;
        draft)    what='still in draft' ;;
        behind)   what='behind main' ;;
        unknown)  what='with mergeability not yet computed' ;;
        *)        what='waiting on a human' ;;
    esac
else
    what="stuck: $(printf '%s' "$kinds" | tr '\n' ',' | sed 's/,/, /g; s/, $//')"
fi
HEADLINE="${count} ${plural} ${what}"

if [ -f "$LOG_READ" ]; then
    seen=$(sh "$LOG_READ" --root "$ROOT" --step stuck-prs-filed --contains "$KEY" 2>/dev/null | sed 's/.*"count": //; s/,.*//')
    if [ -n "$seen" ] && [ "$seen" != "0" ]; then
        printf '{"step": "stuck-prs", "status": "ok", "reason": "already_filed", "summary": "%s pull request(s) stuck, unchanged since an earlier tick reported %s", "headline": "%s", "needs_agent": [], "key": "%s"}\n' \
            "$count" "$KEY" "$HEADLINE" "$KEY"
        exit 0
    fi
fi

needs=$(printf '%s' "$rows" | awk -v key="$KEY" '
    NF {
        n = $0; sub(/.*"number": /, "", n); sub(/,.*/, "", n)
        b = $0; sub(/.*"blocked_by": "/, "", b); sub(/".*/, "", b)
        u = $0; sub(/.*"url": "/, "", u); sub(/".*/, "", u)
        decision = "a human decision"
        if (b == "conflict") decision = "the claim holder must resolve the conflict — nobody else may push to that branch"
        else if (b == "review") decision = "a required review or gate is unsatisfied — somebody must review it"
        else if (b == "checks") decision = "a check is failing — the author must fix it or say it is expected"
        else if (b == "draft")  decision = "it is still a draft — the author must mark it ready or close it"
        else if (b == "behind") decision = "the base moved — the claim holder must update it"
        else if (b == "unknown") decision = "GitHub has not computed mergeability yet — re-read before acting"
        printf "%s{\"action\": \"report\", \"pull\": %s, \"url\": \"%s\", \"blocked_by\": \"%s\", \"decision\": \"%s\", \"key\": \"%s\"}",
            (c++ ? ", " : ""), n, u, b, decision, key
    }')

printf '{"step": "stuck-prs", "status": "blocked", "reason": "", "summary": "%s (%s) — reported, keyed %s", "headline": "%s", "needs_agent": [%s], "key": "%s"}\n' \
    "$HEADLINE" "$(printf '%s' "$pairs" | sed 's/ $//')" "$KEY" "$HEADLINE" "$needs" "$KEY"
