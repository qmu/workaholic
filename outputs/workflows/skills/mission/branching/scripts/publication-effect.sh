#!/bin/sh -eu
# publication-effect.sh — WAS THIS PULL REQUEST ACTED ON? One reader, one pull request.
#
#   publication-effect.sh <pull-request-number>
#
# Output: {"ok": bool, "number": N, "url": "...", "effect": "...", "age_hours": n|null,
#          "reason": ""}
#   `effect` is one of `merged` | `closed` | `open:<age>` | `unreadable`. Always exit 0.
#
# ═══ WHY IT EXISTS (2026-08-29, mission `follow-the-pull-requests-the-loop-opens-for-a-person`)
# The loop opens pull requests FOR A PERSON — the ones `publish-tree-pr.sh` refuses to
# auto-merge — and then nothing reads them back. Measured 2026-08-29: #694 sat 18 hours
# unanswered while `ruling-suppression.sh` held the very questions it would have settled.
#
# ═══ IT IS THE SHAPE `act-effect.sh` ALREADY USES, APPLIED ONE STEP OVER ═════════════
# That reader answers *did the act the loop took have its effect*, for the loop's own two acts
# on a proof. This answers the same question about the act the loop takes ON THE OPERATOR'S
# BEHALF: it opened a diff and asked somebody to rule on it. Same frame — a small closed
# vocabulary, a named degradation, exit 0 on every path — and, like that reader, it OWNS THE
# ASSEMBLY AND NO ACT'S VOCABULARY: every value here is read straight off GitHub's own state.
#
# ═══ IT ANSWERS *WHAT HAPPENED*, NEVER *WHOSE IT IS* ═════════════════════════════════
# Membership is `list-operator-facing-pulls.sh`'s question and is derived from the publish
# seam's refusal word. Two scripts deliberately: one script answering both is how two readings
# of one fact start to disagree, and the candidate set is passed in rather than re-derived here.
#
# ═══ EVERY VALUE IS A JUDGEMENT ══════════════════════════════════════════════════════
# `../../drive/reference/claims.md`, *Whether an operator-facing pull request was acted on*. A
# pull request is DESIGNED to change state — it can be merged, closed or reopened between two
# reads — which is the one property a proof must not have. So no consumer may merge, close,
# revert, re-run, gate, hold work or lift a gate on it. The licence is to report and to ask.
#
# ═══ THE SINGLE-PULL ENDPOINT, NOT THE LIST ══════════════════════════════════════════
# `GET /repos/{}/pulls` does not carry `merged_at` reliably for a closed-unmerged pull request,
# and that is exactly the distinction that makes `closed` a different answer from `merged`. The
# obvious shortcut would collapse a refusal into a ruling.
#
# ═══ `unreadable` CARRIES A NULL AGE, NEVER A ZERO ═══════════════════════════════════
# A zero reads as *just opened*, which is the most urgent thing this vocabulary can say. A read
# we could not make must not be the loudest answer in the set.
#
# REST, NOT `gh pr view` (`rules/shell.md`): the subcommand is GraphQL-backed and a Claude Code
# Web session may 403 mid-run.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GATHER="${SCRIPT_DIR}/../../gather/scripts/"

NUMBER="${1:-}"

emit() {
    # $1 ok  $2 effect  $3 age_hours (or `null`)  $4 reason  $5 url
    printf '{"ok": %s, "number": %s, "url": "%s", "effect": "%s", "age_hours": %s, "reason": "%s"}\n' \
        "$1" "${NUMBER:-0}" "${5:-}" "$2" "$3" "${4:-}"
    exit 0
}

case "$NUMBER" in
    ''|*[!0-9]*) NUMBER=0; emit false unreadable null no_pull_number "" ;;
esac

command -v jq >/dev/null 2>&1 || emit false unreadable null jq_unavailable ""
sh "${GATHER}/gh-rest.sh" available >/dev/null 2>&1 || emit false unreadable null gh_unavailable ""

slug="$(sh "${GATHER}/gh-rest.sh" slug 2>/dev/null || printf '')"
[ -n "$slug" ] || emit false unreadable null read_failed ""

resp="$(sh "${GATHER}/gh-rest.sh" api "repos/${slug}/pulls/${NUMBER}" 2>/dev/null || printf '')"
[ -n "$resp" ] || emit false unreadable null read_failed ""
printf '%s' "$resp" | jq -e . >/dev/null 2>&1 || emit false unreadable null read_failed ""

# A 404 comes back as a well-formed body with a `message` and no `number`, so the shape is what
# distinguishes it — never the exit status, which the transport has already absorbed.
have_number="$(printf '%s' "$resp" | jq -r '.number // ""')"
[ -n "$have_number" ] || emit false unreadable null not_found ""

url="$(printf '%s' "$resp" | jq -r '.html_url // ""')"
state="$(printf '%s' "$resp" | jq -r '.state // ""')"
merged_at="$(printf '%s' "$resp" | jq -r '.merged_at // ""')"
created_at="$(printf '%s' "$resp" | jq -r '.created_at // ""')"

case "$merged_at" in
    ''|null) ;;
    *) emit true merged null "" "$url" ;;
esac

if [ "$state" = "closed" ]; then
    emit true closed null "" "$url"
fi

# `open:<age>` — the age is what makes an un-acted pull request legible as a finding, and it is
# derived from `created_at` rather than stored anywhere.
age=null
if [ -n "$created_at" ] && [ "$created_at" != "null" ]; then
    opened_epoch="$(date -u -d "$created_at" +%s 2>/dev/null \
        || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$created_at" +%s 2>/dev/null \
        || printf '')"
    if [ -n "$opened_epoch" ]; then
        now="$(date -u +%s)"
        hours=$(( (now - opened_epoch) / 3600 ))
        [ "$hours" -ge 0 ] || hours=0
        age="$hours"
    fi
fi

if [ "$age" = "null" ]; then
    # The state is open and readable; only the clock arithmetic failed. That is a degraded AGE,
    # not a degraded reading, so the effect stays honest and the reason names what was lost.
    emit true "open:unknown" null age_unreadable "$url"
fi

emit true "open:${age}" "$age" "" "$url"
