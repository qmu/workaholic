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
# THE HEADLINE NAMES THE KIND, AND THE KEY DOES NOT MOVE (2026-08-18, issue #513).
# The reminder's varying half was its second line while its first read
# `<N> pull request(s) waiting on a human` every time, so a reader scanning the
# channel saw one invariant heading whether the finding was a conflict, an un-run
# auto-merge or a failing check. `headline` is derived from the `blocked_by` set
# this script already computes, so a conflict finding and a review finding differ
# at the first line. It is VISIBLE WORDING ONLY: `stuck:<digest>` is still the
# sorted `<number>:<blocked_by>` set and nothing searches the heading — the
# release tick's 2026-08-17 heading rename was reversed the next day precisely
# because the heading was mistaken for the dedup key.
#
# CONFLICTS RIDE THIS REMINDER TOO. Step 4 reports conflict state and posts
# nothing; two Slack lines about one pull request in one tick is the noise the
# gate exists to prevent.
#
# AND THE CONFLICT ROW NAMES WHICH ACTOR CLEARS IT (2026-09-01, ticket
# `20260901082633`). The operator's words were that Moderation "only spews reports and
# shows no sign of resolving anything", and the measurement behind them was four
# conflicting pull requests, all four colliding on `.workaholic/stories/index.md` — the
# loop's own generated OKF index — two of them on nothing else, reported hourly as
# somebody's work. The ACTING half already existed: `catch-up-claim.sh` clears a
# `mechanical` conflict on this identity's own reported claim and
# `settle-stranded-publication.sh` clears a publication's, both from `/implement`. Only
# the TELLING half was wrong — this row read "the claim holder must resolve the
# conflict" for EVERY conflict, so the one class the loop repairs itself was announced
# to a person as theirs, queued behind a budget of ten questions a day.
#
# THE CORRECTION IS GENERIC, AND THAT IS A CONSTRAINT RATHER THAN A PREFERENCE. The
# class lives in `ship/scripts/lib/conflict-class.sh` via `claim-mergeability.sh`, which
# needs the branch REF — and this step reads GitHub over REST through `pulls-state.sh`,
# which carries no class, while the reader that fetches (`list-claims.sh`) is not
# composed here and `step-merge-conflicts.sh`'s own header refuses a network read inside
# these steps on a measurement. So the row names both classes and their actors rather
# than deciding which one this pull request is; the per-branch judgement stays with
# `catchup-blocked` (§26), which reads the class off a claim row that already has it.
#
# IT IS WORDING ONLY. `stuck:<digest>`, the `blocked_by` set, `headline` and the
# `needs_agent` shape are byte-identical — the header above records that the heading was
# once mistaken for the dedup key, and this change touches neither.
#
# Usage: step-stuck-prs.sh --tick <id> --root <repo-root> [--limit <n>]
# Output: one JSON line {"step","status","reason","summary","headline","needs_agent":[...],"key":"","ask_key":"stuck-<digest>"}

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
        printf '{"step": "stuck-prs", "status": "degraded", "reason": "%s", "summary": "pull requests unreadable — no reminder can be trusted this tick", "headline": "", "needs_agent": [], "key": ""}\n' "$reason"
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
ASK_KEY="stuck-${digest}"

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

# THE QUESTION IS HELD ONCE THIS FINDING HAS BECOME WORK (2026-08-29, mission
# `let-the-tick-s-own-findings-become-the-loop-s-work`). While an open finding issue carries this
# step's finding, the loop is already driving the repair, so asking a person about it asks them —
# the same person, in the same hour — about the thing in flight. Keyed on the SUBJECT, so a
# filing about another step's finding silences nothing here; an unreadable read holds nothing;
# and the suppression is derived, so merging or closing the issue makes the question reachable
# again with no state anywhere. The headline, the summary and the `ask_key` are untouched — only
# the questions are withheld.
#
# READ WITHOUT `jq`, deliberately: this step has never required it, and adding the dependency
# for one boolean would make an existing step degrade on a container where it is missing.
# `held.steps` is the only array of step ids in the reader's output.
finding_held=false
suppression="${SCRIPT_DIR}/finding-suppression.sh"
if [ -f "$suppression" ]; then
    fsupp=$(sh "$suppression" 2>/dev/null || true)
    case "$fsupp" in
        *'"readable": true'*)
            held_steps=$(printf '%s' "$fsupp" | sed -n 's/.*"steps": \[\([^]]*\)\].*/\1/p')
            case "$held_steps" in
                *'"stuck-prs"'*) finding_held=true ;;
            esac
            ;;
    esac
fi
if [ "$finding_held" = "true" ]; then rows=''; fi

needs=$(printf '%s' "$rows" | awk -v key="$ASK_KEY" '
    NF {
        n = $0; sub(/.*"number": /, "", n); sub(/,.*/, "", n)
        b = $0; sub(/.*"blocked_by": "/, "", b); sub(/".*/, "", b)
        u = $0; sub(/.*"url": "/, "", u); sub(/".*/, "", u)
        decision = "a human decision"
        if (b == "conflict") decision = "a generated-index conflict is cleared by the catch-up on the next [Implement] tick; a real content collision belongs to the claim holder, and nobody else may push to that branch"
        else if (b == "review") decision = "a required review or gate is unsatisfied — somebody must review it"
        else if (b == "checks") decision = "a check is failing — the author must fix it or say it is expected"
        else if (b == "draft")  decision = "it is still a draft — the author must mark it ready or close it"
        else if (b == "behind") decision = "the base moved — the claim holder must update it"
        else if (b == "unknown") decision = "GitHub has not computed mergeability yet — re-read before acting"
        printf "%s{\"action\": \"ask\", \"pull\": %s, \"url\": \"%s\", \"blocked_by\": \"%s\", \"decision\": \"%s\", \"key\": \"%s\"}",
            (c++ ? ", " : ""), n, u, b, decision, key
    }')

printf '{"step": "stuck-prs", "status": "blocked", "reason": "", "summary": "%s (%s) — candidates for step 10, never a status post", "headline": "%s", "needs_agent": [%s], "key": "", "ask_key": "%s"}\n' \
    "$HEADLINE" "$(printf '%s' "$pairs" | sed 's/ $//')" "$HEADLINE" "$needs" "$ASK_KEY"
