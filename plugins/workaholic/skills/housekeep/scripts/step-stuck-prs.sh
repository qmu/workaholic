#!/bin/sh -eu
# Step 6 — the pull requests that failed to auto-merge, and what each needs.
#
# WHAT MAKES THIS USEFUL IS THE SECOND HALF. "PR #12 is red" is a fact a human can
# already see; "PR #12 needs a review that nobody has been asked for" is a
# decision. So every row carries `blocked_by`, resolved mechanically from GitHub's
# own mergeability fields, and the reminder the agent composes names the decision
# rather than the colour.
#
# ONE REMINDER PER DISTINCT STATE, exactly as `📦 Release Preparation` posts one line
# per distinct deploy digest. The key is `stuck:<digest>` over the sorted
# `<number>:<blocked_by>` set, so a pull request that is still stuck for the same
# reason next hour earns no second post, while a NEW pull request or a CHANGED
# reason does. Two gates, both required: something actionable, and no earlier post
# for this exact state — the tick log answers the second, and `workaholic:notify`'s
# stateless lookup answers it again on the wire before posting.
#
# ITS KEY IS DELIBERATELY DISTINCT from `[Prepare Release]`'s `deploy:<digest>`:
# one reports what is waiting to deploy, this reports what is waiting on a human,
# and a shared key would let either dedup the other away.
#
# CONFLICTS RIDE THIS REMINDER TOO. Step 4 reports conflict state and posts
# nothing; two Slack lines about one pull request in one tick is the noise the
# gate exists to prevent.
#
# Usage: step-stuck-prs.sh --tick <id> --root <repo-root> [--limit <n>]
# Output: one JSON line {"step","status","reason","summary","needs_agent":[...],"key":"stuck:<digest>"}

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
        printf '{"step": "stuck-prs", "status": "degraded", "reason": "%s", "summary": "pull requests unreadable — no reminder can be trusted this tick", "needs_agent": [], "key": ""}\n' "$reason"
        exit 0
        ;;
esac

rows=$(printf '%s' "$state" | awk '{ gsub(/}/, "}\n"); print }' | grep '"blocked_by": "' | grep -v '"blocked_by": ""' || true)
count=$(printf '%s' "$rows" | awk 'NF { n++ } END { print n + 0 }')

if [ "$count" -eq 0 ]; then
    printf '{"step": "stuck-prs", "status": "ok", "reason": "", "summary": "nothing is stuck: every open pull request is mergeable", "needs_agent": [], "key": ""}\n'
    exit 0
fi

# The digest is over the STATE, not the count: a different pull request, or the
# same one blocked for a different reason, is a different answer and earns a post.
pairs=$(printf '%s' "$rows" | sed 's/.*"number": \([0-9]*\).*"blocked_by": "\([a-z]*\)".*/\1:\2/' | sort | tr '\n' ' ')
digest=$(printf '%s' "$pairs" | cksum | awk '{ print $1 }')
KEY="stuck:${digest}"

if [ -f "$LOG_READ" ]; then
    seen=$(sh "$LOG_READ" --root "$ROOT" --step stuck-prs-filed --contains "$KEY" 2>/dev/null | sed 's/.*"count": //; s/,.*//')
    if [ -n "$seen" ] && [ "$seen" != "0" ]; then
        printf '{"step": "stuck-prs", "status": "ok", "reason": "already_filed", "summary": "%s pull request(s) stuck, unchanged since an earlier tick posted %s", "needs_agent": [], "key": "%s"}\n' \
            "$count" "$KEY" "$KEY"
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
        printf "%s{\"action\": \"remind\", \"pull\": %s, \"url\": \"%s\", \"blocked_by\": \"%s\", \"decision\": \"%s\", \"key\": \"%s\"}",
            (c++ ? ", " : ""), n, u, b, decision, key
    }')

printf '{"step": "stuck-prs", "status": "blocked", "reason": "", "summary": "%s pull request(s) waiting on a human (%s) — reminder keyed %s", "needs_agent": [%s], "key": "%s"}\n' \
    "$count" "$(printf '%s' "$pairs" | sed 's/ $//')" "$KEY" "$needs" "$KEY"
