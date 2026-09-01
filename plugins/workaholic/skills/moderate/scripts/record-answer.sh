#!/bin/sh -eu
# Record that a person ANSWERED a check-in question, and what they said.
#
# TWO ROUTES REACH IT SINCE 2026-08-28 (mission
# `let-an-answer-in-the-thread-turn-back-into-the-loop-s-work`), and the second is now the
# ordinary one: the developer answers **in the question's own thread**, and the next tick's
# `question-answers` step reads that thread on the coordinate the ask line recorded and hands
# the words here. The session-link route below still works and costs a session per answer.
# This script did not change: it is still the ONE writer of the answered line, still
# append-only through `log-append.sh`, and still parses nothing.
#
# WHY THIS EXISTS (2026-08-23, issue #584). The developer's flow ends where the plugin had
# nothing: they open the session link on the question, answer inside the moderator's own
# session, and expect the loop to continue. The tick had no notion of an answer —
# `ask-question.sh` recorded that a key WAS ASKED and refused to ask it again, and nothing
# recorded that it was ANSWERED. So an answered question and one nobody will ever answer
# were the same state, and whatever the person said died with the container.
#
# It is the same shape as the defect that made the tick's own feedback records evaporate:
# work done inside a routine's container reaches nobody unless something carries it to the
# base.
#
# IT ADDS NO STORE. The answer goes into the tick log through `log-append.sh` — the log's
# only writer, append-only, idempotent per (tick, step) — under the step id
# `human-checkin-answered-<slug>`, beside the `human-checkin-ask-<slug>` line the gate
# already writes. `persist-log.sh` then carries it to the base with no branch and no claim,
# exactly as it carries every other line. Three states, one place:
#
#   no line              never asked
#   ask line only        asked, unanswered
#   ask + answered line  answered, and the summary carries the words
#
# THE WORDS ARE THE POINT, not the flag. A recorded answer nobody can read is the same
# failure at one remove: the next run must be able to act on it. Nothing here parses the
# answer into a decision — it is a person's prose, and acting on it stays the next run's
# judgement. What this owes is that the words survive and are found.
#
# APPEND-ONLY IS PRESERVED BY CONSTRUCTION. `log-append.sh` is idempotent per (tick, step),
# so recording the same answer twice in one tick is a no-op and no line already on the base
# is ever rewritten. A second, different answer in a LATER tick appends its own line, and
# the reader takes the newest — a person correcting themselves is a new fact, not an edit.
#
# Usage:
#   record-answer.sh --tick <YYYYMMDD-HHMMSS> --key <content-key> --answer "<their words>"
#                    [--root <repo-root>]
# Output: one JSON line
#   {"recorded": true, "key": "...", "log_step": "human-checkin-answered-<slug>", "tick": "..."}
#   {"recorded": false, "reason": "no_key|no_answer|no_writer|log_refused"}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/question-id.sh"
LOG_APPEND="${SCRIPT_DIR}/log-append.sh"

TICK=''
KEY=''
ANSWER=''
ROOT='.'
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --key) KEY="${2:-}"; shift 2 ;;
        --answer) ANSWER="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

refuse() { printf '{"recorded": false, "reason": "%s"}\n' "$1"; exit 0; }

[ -n "$KEY" ] || refuse no_key
# An empty answer is refused rather than recorded: "answered with nothing" is indis-
# tinguishable from a mis-click, and it would clear the gate on a question still open.
[ -n "$ANSWER" ] || refuse no_answer
[ -f "$LOG_APPEND" ] || refuse no_writer

LOG_STEP="human-checkin-answered-$(question_slug "$KEY")"

# The summary carries the answer verbatim on one line — the log is line-oriented, so a
# newline would split the entry. Collapsing whitespace keeps the words; it does not
# summarise them.
FLAT=$(printf '%s' "$ANSWER" | tr '\n\t' '  ' | sed 's/  \{1,\}/ /g; s/^ //; s/ $//')

out=$(sh "$LOG_APPEND" --root "$ROOT" --tick "$TICK" --step "$LOG_STEP" \
        --status filed --summary "$FLAT" 2>/dev/null || true)
case "$out" in
    *'"logged": true'*) ;;
    *) refuse log_refused ;;
esac

printf '{"recorded": true, "key": "%s", "log_step": "%s", "tick": "%s"}\n' \
    "$KEY" "$LOG_STEP" "$TICK"
