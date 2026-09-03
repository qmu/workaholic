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
# `/implement`'s catch-up, which reads the class off a claim row that already has it and
# attempts it (`catchup-blocked` was retired 2026-09-02).
#
# IT IS WORDING ONLY. `stuck:<digest>`, the `blocked_by` set, `headline` and the
# `needs_agent` shape are byte-identical — the header above records that the heading was
# once mistaken for the dedup key, and this change touches neither.
#
# Usage: step-stuck-prs.sh --tick <id> --root <repo-root> [--limit <n>]
# Output: one JSON line {"step","status","reason","summary","headline","needs_agent":[...],"key":"","ask_key":"stuck-<digest>","uncomputed":<n>}
#
# `uncomputed` counts the rows GitHub had not finished computing when we asked. They are
# counted and never asked about (see the filter below) — evidence for the run report, and
# nothing a person can act on.

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

all_rows=$(printf '%s' "$state" | awk '{ gsub(/}/, "}\n"); print }' | grep '"blocked_by": "' | grep -v '"blocked_by": ""' || true)

# AN UNCOMPUTED MERGEABLE STATE LEAVES THE PASS INSTEAD OF REACHING A PERSON (2026-09-02,
# mission `resolve-a-conflicted-pull-request-in-the-tick-not-report-it`, ticket
# `20260902042630-drop-the-notification-for-an-uncomputed-mergeable-state`). The operator's
# words: that is not worth a notification. `blocked_by: "unknown"` is `pulls-state.sh`'s word
# for `mergeable == null` — GitHub simply has not finished computing it — so it says nothing
# about the pull request and everything about when we asked. Its own header records four pull
# requests reading `unknown` hour after hour and one re-read settling all four. There is no act
# to ask anybody for; the next tick reads it again.
#
# THE FILTER IS AT CANDIDATE SELECTION, NOT AT THE POST, and the difference is the whole
# ticket. `ask-question.sh` records a key as asked when the question is composed, so filtering
# at the post would leave the key spent — the row would reach nobody AND be marked answered-to.
# A row that never becomes a candidate cannot become a key.
#
# IT IS DROPPED FROM THE QUESTION *AND* FROM THE DIGEST. `ask_key` is the digest over the
# sorted `<number>:<blocked_by>` set, so leaving `unknown` in it would let an uncomputed row
# change the key of a question about a DIFFERENT pull request, re-asking a settled subject for
# a reason no reader could see.
uncomputed=$(printf '%s' "$all_rows" | grep -c '"blocked_by": "unknown"' || true)
case "$uncomputed" in '' | *[!0-9]*) uncomputed=0 ;; esac
rows=$(printf '%s' "$all_rows" | grep -v '"blocked_by": "unknown"' || true)
count=$(printf '%s' "$rows" | awk 'NF { n++ } END { print n + 0 }')

# THE COUNT IS KEPT, IN ITS OWN FIELD, AND DELIBERATELY NOT IN THE COMPARED SUMMARY. The
# ticket asked for it "in the step summary"; `step-merge-conflicts.sh` had exactly that and it
# was removed on 2026-09-01 (ticket `20260901122448`) for a measured reason that applies here
# with more force. `render-tick-post.sh` compares `(step, status, stabilized summary)` for the
# impairment diff, and this step's `blocked` row is IN that diff — so an uncomputed count in
# the summary would open a root every time GitHub finished computing one pull request, which is
# the hourly noise the gate exists to prevent. The `uncomputed` FIELD carries it instead, the
# sibling step's own shape, so the run report and any other reader still have the number.
if [ "$count" -eq 0 ]; then
    # A tick with nothing stuck keeps today's wording byte-identically; one holding only
    # uncomputed rows never claims they are mergeable, and never reports `blocked`, because a
    # `blocked` row with no candidate renders an impairment line about a row nobody may act on.
    if [ "$uncomputed" -eq 0 ]; then
        printf '{"step": "stuck-prs", "status": "ok", "reason": "", "summary": "nothing is stuck: every open pull request is mergeable", "headline": "", "needs_agent": [], "key": "", "uncomputed": 0}\n'
    else
        printf '{"step": "stuck-prs", "status": "ok", "reason": "mergeability_uncomputed", "summary": "nothing is stuck: no open pull request reads as blocked, some not yet computed by GitHub", "headline": "", "needs_agent": [], "key": "", "uncomputed": %s}\n' \
            "$uncomputed"
    fi
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
        # No `unknown` arm: an uncomputed row left the pass above, so it can never reach the
        # headline. The arm is deleted rather than left unreachable — a dead branch reading
        # "with mergeability not yet computed" is exactly the stale sentence a later session
        # would restore the behaviour from.
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
        if (b == "conflict") decision = "resolving this conflict belongs to an [Implement] run rather than to this tick, which reads and does not merge; a hunk the merge itself cannot settle needs a person and is named by the act that meets it"
        else if (b == "review") decision = "a required review or gate is unsatisfied — somebody must review it"
        else if (b == "checks") decision = "a check is failing — the author must fix it or say it is expected"
        else if (b == "draft")  decision = "it is still a draft — the author must mark it ready or close it"
        else if (b == "behind") decision = "the base moved — the claim holder must update it"
        # No `unknown` arm, for the reason the headline has none: the row is gone before this
        # program runs. Its text asked a person to "re-read before acting", which is not an act
        # anybody can take and is the notification the operator refused.
        printf "%s{\"action\": \"ask\", \"pull\": %s, \"url\": \"%s\", \"blocked_by\": \"%s\", \"decision\": \"%s\", \"key\": \"%s\"}",
            (c++ ? ", " : ""), n, u, b, decision, key
    }')

# THE SUMMARY IS COMPARED, SO IT CARRIES WHAT MOVED IN THE REPOSITORY (2026-09-01, ticket
# `20260901122448-keep-a-transport-derived-state-list-out-of-the-post-gate`). It used to
# carry the `<number>:<blocked_by>` pair list, and `render-tick-post.sh` compares summaries
# verbatim after a stabilizer whose named list strips a timestamp, a bare hex object name
# and a clock time — none of which a pair list looks like. So the gate built to stop hourly
# noise was the thing producing it: measured across nine consecutive ticks the pairs read
# `(403:unknown 407:unknown 409:unknown)` four times, then four pull requests, then one
# conflicting, then five, then one with a failing check, while the repository did not move.
# Reproduced before the change with two pair lists over the SAME three pull requests and the
# SAME set of classes, differing only in which pull request held which — the stabilizer left
# them different and the gate opened a root.
#
# THE FIX IS HERE AND NOT IN `stabilize()`. That function's own header says its list is short
# and named on purpose; a pattern broad enough to catch `403:unknown` would also catch counts
# and identifiers that are real news. The volatility belongs to one step's summary.
#
# WHAT STAYS IS WHAT MOVED IN THE REPOSITORY: `HEADLINE` carries how many are stuck and by
# what class, so a pull request ENTERING or LEAVING the stuck set still changes the count and
# still opens a root, and a class appearing or clearing still does. What no longer opens one
# is a re-shuffle of which pull request holds which class at an unchanged count and class set.
#
# THE QUESTION SIDE IS BYTE-IDENTICAL: `ask_key` is still the digest over the sorted pair
# set, `headline` is unchanged, and `needs_agent` still names every pull request with its
# `blocked_by` and its decision — nothing a person is asked loses detail. Only the compared
# string is coarsened.
printf '{"step": "stuck-prs", "status": "blocked", "reason": "", "summary": "%s — candidates for step 10, never a status post", "headline": "%s", "needs_agent": [%s], "key": "", "ask_key": "%s", "uncomputed": %s}\n' \
    "$HEADLINE" "$HEADLINE" "$needs" "$ASK_KEY" "$uncomputed"
