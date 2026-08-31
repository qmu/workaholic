#!/bin/sh -eu
# answer-outcome.sh — WHAT BECAME OF THIS ANSWER? One reader, one question.
#
#   answer-outcome.sh --key <content-key> [--root <repo-root>]
#
# Output: {"ok": bool, "key": "...", "slug": "...", "state": "...", "outcome": "...",
#          "issue": n|null, "issue_state": "", "issue_reason": "", "reason": ""}
#   `outcome` is one of `settled:nothing_filed` | `settled:issue_closed` | `pending` |
#   `unreadable:<reason>`. Always exit 0.
#
# ═══ WHY IT EXISTS (2026-08-31, mission
# `make-the-tick-s-questions-readable-and-close-them-in-the-thread`) ══════════════════
# Nothing could answer *what came of this answer*. The tick log records that an answer was
# recorded (`record-answer.sh`) and, when the answer asked for something, that an `[FB]`
# issue was filed — but whether that issue became work, and whether that work landed, was
# read by nobody. So the person who answered in the thread got a `:ballot_box_with_check:`
# saying *received* and never a word about what happened next.
#
# ═══ IT COMPOSES WHAT EXISTS AND DERIVES NOTHING TWICE ═══════════════════════════════
# `question-state.sh` is the one reader of a question's life and answers whether this key is
# `answered`; `log-read.sh` is the log's only parser and answers what the filing line says;
# `gather/scripts/gh-rest.sh` is the one GitHub transport. This script owns the ASSEMBLY and
# no other script's vocabulary — a normalised word would send a reader to a string no script
# printed.
#
# ═══ A QUESTION WITH NO RECORDED ANSWER IS REFUSED, NEVER CALLED `unreadable` ═════════
# `ok: false` with `reason: not_answered:<state>` and an EMPTY `outcome`. It is not a
# degradation — there is simply no answer for anything to have become of — and rendering it
# as `unreadable` would be exactly the collapse this vocabulary's `unreadable` exists to
# close. The candidate set is the caller's: `step-question-answers.sh` already derives the
# answered set in the one pass it makes over the ledger, so this script is handed one key.
#
# ═══ THE CHAIN IS THE LOG'S OWN FILED LINE, NOT A SEARCH ═════════════════════════════
# `question-answers-filed-<slug>` is written by the agent at filing time and names either
# `filed: #<n>` or `not_filed: <reason>` — the `<step>-filed` convention `inbound-sweep`,
# `doc-drift`, `unanswered-asks` and `thread-reconcile` already use. No cursor, no second
# marker, no second reader, and no issue search: the question-to-issue link is a line the
# writer already had in hand.
#
# ═══ ONE BOUNDED REST READ PER *FILED* CANDIDATE, AND NONE FOR THE REST ══════════════
# An answer that filed nothing is `settled:nothing_filed` immediately, with no network call
# at all: nothing is owed and the outcome is known the moment the line is read. Only a
# candidate naming an issue costs one `GET /repos/{slug}/issues/{n}`.
#
# ═══ EVERY VALUE IS A JUDGEMENT ══════════════════════════════════════════════════════
# `../../drive/reference/claims.md`, *Whether a recorded answer has been acted on*. An issue
# is DESIGNED to change state — anybody can close it, and anybody can reopen it after its
# pull request merged — which is the one property a proof must not have, and
# `unreadable:<reason>` is besides that the absence of a reading. So no consumer may merge,
# close, gate, hold work or re-ask on it. The licence is to REPORT, and to post the one
# outcome reply the catalog names.
#
# ═══ WHY `settled:issue_closed` RATHER THAN "closed by a merged pull request" ════════
# Proving the *merge* closed it needs the issue's timeline — a second bounded call per
# candidate for a distinction the reader does not act on. `state_reason` is carried instead,
# verbatim, so the reply can say what came of it: `completed` is what GitHub records when a
# merging pull request closes an issue, and `not_planned` is equally an outcome the person
# who answered is owed. Both settle; neither is guessed at.
#
# REST, NOT `gh issue view` (`rules/shell.md`): the subcommand is GraphQL-backed and a Claude
# Code Web session may 403 mid-run.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
. "${SCRIPT_DIR}/lib/question-id.sh"
LOG_READ="${SCRIPT_DIR}/log-read.sh"
QUESTION_STATE="${SCRIPT_DIR}/question-state.sh"
GATHER="${SCRIPT_DIR}/../../gather/scripts/"

KEY=''
ROOT='.'
while [ $# -gt 0 ]; do
    case "$1" in
        --key) KEY="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

SLUG=''
STATE=''

emit() {
    # $1 ok  $2 outcome  $3 issue (number or `null`)  $4 issue_state  $5 issue_reason  $6 reason
    printf '{"ok": %s, "key": "%s", "slug": "%s", "state": "%s", "outcome": "%s", "issue": %s, "issue_state": "%s", "issue_reason": "%s", "reason": "%s"}\n' \
        "$1" "$KEY" "$SLUG" "$STATE" "$2" "$3" "${4:-}" "${5:-}" "${6:-}"
    exit 0
}

[ -n "$KEY" ] || emit false "" null "" "" no_key
command -v jq >/dev/null 2>&1 || emit false "unreadable:jq_unavailable" null "" "" jq_unavailable
[ -f "$QUESTION_STATE" ] || emit false "unreadable:no_question_reader" null "" "" no_question_reader
[ -f "$LOG_READ" ] || emit false "unreadable:no_log_reader" null "" "" no_log_reader

SLUG=$(question_slug "$KEY")

qs=$(sh "$QUESTION_STATE" --key "$KEY" --root "$ROOT" 2>/dev/null || printf '')
[ -n "$qs" ] || emit false "unreadable:question_state_unreadable" null "" "" question_state_unreadable
STATE=$(printf '%s' "$qs" | jq -r '.state // ""' 2>/dev/null || printf '')
[ -n "$STATE" ] || emit false "unreadable:question_state_unreadable" null "" "" question_state_unreadable

case "$STATE" in
    answered) ;;
    unreadable) emit false "unreadable:question_state_unreadable" null "" "" question_state_unreadable ;;
    # NOT A DEGRADATION. There is no recorded answer, so nothing has become of anything; the
    # caller filters these out and a stray one is refused by name rather than dressed up as a
    # reading we could not make.
    *) emit false "" null "" "" "not_answered:${STATE}" ;;
esac

filed=$(sh "$LOG_READ" --root "$ROOT" --step "question-answers-filed-${SLUG}" 2>/dev/null || printf '')
[ -n "$filed" ] || emit false "unreadable:log_unreadable" null "" "" log_unreadable

read_ok=$(printf '%s' "$filed" | jq -r '.read // false' 2>/dev/null || printf 'unparseable')
case "$read_ok" in
    true) ;;
    # An ABSENT log area is a readable answer everywhere in this skill: nothing was ever
    # filed. Any other refusal is our own degradation.
    false)
        why=$(printf '%s' "$filed" | jq -r '.reason // "unknown"' 2>/dev/null || printf 'unknown')
        [ "$why" = "no_log_area" ] || emit false "unreadable:log_unreadable" null "" "" "$why"
        ;;
    *) emit false "unreadable:log_unreadable" null "" "" log_unparseable ;;
esac

# The newest filing line wins, for `question-state.sh`'s reason: the log is append-only, so a
# correction is a later line rather than an edit of the old one.
line=$(printf '%s' "$filed" | jq -r '[.entries[]?] | sort_by(.tick) | last | .summary // ""' 2>/dev/null || printf '')

# NO LINE AT ALL is not `nothing_filed`: the agent has not reported what it did with this
# answer yet, so the outcome is simply not known and the reply waits.
[ -n "$line" ] || emit true pending null "" "" no_filing_line

case "$line" in
    *not_filed:*) emit true "settled:nothing_filed" null "" "" \
        "$(printf '%s' "$line" | sed -n 's/.*not_filed: *\([^ ]*\).*/\1/p')" ;;
esac

number=$(printf '%s' "$line" | sed -n 's/.*filed: *#\([0-9][0-9]*\).*/\1/p')
[ -n "$number" ] || emit false "unreadable:filing_line_unparseable" null "" "" filing_line_unparseable

sh "${GATHER}/gh-rest.sh" available >/dev/null 2>&1 \
    || emit false "unreadable:gh_unavailable" "$number" "" "" gh_unavailable
slug_repo=$(sh "${GATHER}/gh-rest.sh" slug 2>/dev/null || printf '')
[ -n "$slug_repo" ] || emit false "unreadable:read_failed" "$number" "" "" slug_unresolved

resp=$(sh "${GATHER}/gh-rest.sh" api "repos/${slug_repo}/issues/${number}" 2>/dev/null || printf '')
[ -n "$resp" ] || emit false "unreadable:read_failed" "$number" "" "" read_failed
printf '%s' "$resp" | jq -e . >/dev/null 2>&1 \
    || emit false "unreadable:read_failed" "$number" "" "" read_failed
# A 404 comes back as a well-formed body with a `message` and no `number`, so the shape is
# what distinguishes it — never the exit status, which the transport has already absorbed.
have=$(printf '%s' "$resp" | jq -r '.number // ""' 2>/dev/null || printf '')
[ -n "$have" ] || emit false "unreadable:not_found" "$number" "" "" not_found

istate=$(printf '%s' "$resp" | jq -r '.state // ""' 2>/dev/null || printf '')
ireason=$(printf '%s' "$resp" | jq -r '.state_reason // ""' 2>/dev/null || printf '')
case "$ireason" in null) ireason='' ;; esac

case "$istate" in
    closed) emit true "settled:issue_closed" "$number" "$istate" "$ireason" "" ;;
    open)   emit true pending "$number" "$istate" "$ireason" "" ;;
    *)      emit false "unreadable:read_failed" "$number" "$istate" "$ireason" unknown_issue_state ;;
esac
