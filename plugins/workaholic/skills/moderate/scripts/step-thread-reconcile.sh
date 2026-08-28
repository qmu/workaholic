#!/bin/sh -eu
# thread-reconcile — an announced item whose thread may still be calling it in flight.
#
# WHY THIS STEP EXISTS (2026-08-28, mission `reconcile-a-stale-thread-with-the-unit-s-real-state`).
# A finish line is posted by the run that **finishes** a unit (`workaholic:notify`, *Which thread
# an `/implement` unit's posts land in*), so a pull request a person merges or closes by hand gets
# its finish posted by nobody: the item's thread keeps `🔵 Proposed` or `🟡 Handoff` as its last
# word while the work is long merged. No other step can see it — `stuck-prs` and `merge-conflicts`
# read **open** pull requests, `handoff-units` reads a standing claim, `stalled-units` a stale tip.
#
# THE SPLIT IS `step-unanswered-asks.sh`'s AND `step-question-answers.sh`'s, FOR THEIR REASON:
# **Slack is a connector held by the session, not by a script.** This step owns the mechanical
# half — which candidates, which bounds, and what an earlier tick already reconciled — and the
# agent owns the lookup, the thread read and the post. Neither half is guessable from the other.
#
# ITS `event` IS ALWAYS THE EMPTY STRING, following those two steps deliberately: at the moment
# `run.sh` reads this line nobody has read a thread yet, so any event would be a claim about a
# reading not made. A step with no event renders no root line, which is right — this step's
# finding is delivered by the reply the agent then posts, or by nothing at all.
#
# THE SET IS BOUNDED, AND THE BOUND IS REPORTED. `WORKAHOLIC_RECONCILE_READ_MAX` (default 10, in
# line with `WORKAHOLIC_ANSWER_READ_MAX` rather than a new constant), newest first — the thread a
# person is plausibly still reading — and the number beyond the bound is reported rather than
# dropped.
#
# THE `<step>-filed` LINE IS AN OPTIMISATION, NOT THE GATE. The real dedup is **structural**: the
# agent reads the thread before writing, so a thread already carrying its finish is never touched
# however many ticks run. The ledger only saves a lookup on a candidate an earlier tick already
# settled. Do not add a cursor or a second ledger on the strength of it.
#
# AN ABSENT LOG AND AN UNREADABLE ONE ARE DIFFERENT ANSWERS. `no_log_area` is a **readable**
# answer — nothing has ever been reconciled — and yields an empty already-done set. Any other
# refusal, or a missing reader, is `degraded` by name and hands back **nothing**: filing against a
# ledger that could not be read is how one thread gets a second reply.
#
# IT MUST NOT READ `plan-units.sh`. The survey runs the living migrations and **stages** what they
# change, which `closable-missions` and `undrivable-units` both refused for a step whose contract
# is *writes nothing*. The candidate set comes from `reconcile-candidates.sh`, a pure read.
#
# Usage: step-thread-reconcile.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOG_READ="${SCRIPT_DIR}/log-read.sh"
CANDIDATES="${SCRIPT_DIR}/reconcile-candidates.sh"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it
# (2026-08-23). This step always supplies the empty string — see the header.
emit() {
    printf '{"step": "thread-reconcile", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$(json_escape "$3")" "${4:-}" "${5:-}"
    exit 0
}

MAX="${WORKAHOLIC_RECONCILE_READ_MAX:-10}"
case "$MAX" in ''|*[!0-9]*) MAX=10 ;; esac

# --- The already-reconciled set ----------------------------------------------
[ -f "$LOG_READ" ] || emit degraded no_log_reader \
    "log-read.sh is not present beside this skill; what an earlier tick already reconciled could not be read"

ledger=$(sh "$LOG_READ" --root "$ROOT" --step thread-reconcile-filed 2>/dev/null || true)
[ -n "$ledger" ] || emit degraded ledger_unreadable \
    "log-read.sh produced no output; what an earlier tick already reconciled could not be read"

read_ok=$(printf '%s' "$ledger" | jq -r '.read // false' 2>/dev/null || echo unparseable)
case "$read_ok" in
    true) ;;
    false)
        reason=$(printf '%s' "$ledger" | jq -r '.reason // "unknown"' 2>/dev/null || echo unknown)
        [ "$reason" = "no_log_area" ] || emit degraded ledger_unreadable \
            "the tick log refused: ${reason} — what an earlier tick already reconciled could not be read"
        ;;
    *) emit degraded ledger_unreadable \
        "the tick log's output could not be parsed; what an earlier tick already reconciled could not be read" ;;
esac

done_keys=$(printf '%s' "$ledger" \
    | jq -r '.entries[]? | .summary' 2>/dev/null \
    | grep -o 'thread-reconcile:[A-Za-z0-9._:-]*' 2>/dev/null \
    | sed 's/^thread-reconcile://' \
    | sort -u || true)
done_json=$(printf '%s' "$done_keys" | jq -Rsc 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')

# --- The candidates ----------------------------------------------------------
[ -f "$CANDIDATES" ] || emit degraded no_candidate_reader \
    "reconcile-candidates.sh is not present beside this skill; the candidates could not be derived"

raw=$(sh "$CANDIDATES" --root "$ROOT" 2>/dev/null || true)
[ -n "$raw" ] || emit degraded candidates_unreadable \
    "reconcile-candidates.sh produced no output; the candidates could not be derived"

cand_ok=$(printf '%s' "$raw" | jq -r '.ok // false' 2>/dev/null || echo unparseable)
case "$cand_ok" in
    true) ;;
    false)
        reason=$(printf '%s' "$raw" | jq -r '.reason // "unknown"' 2>/dev/null || echo unknown)
        emit degraded "candidates_${reason}" \
            "the candidate reader refused: ${reason} — nothing was looked at, which is not the same as nothing being stale" ;;
    *) emit degraded candidates_unreadable \
        "the candidate reader's output could not be parsed; the candidates could not be derived" ;;
esac

rows=$(printf '%s' "$raw" | jq -c --argjson done "$done_json" --argjson max "$MAX" '
    (.candidates // [])
    | map(. + {key: ("thread-reconcile:" + (.number | tostring))})
    | map(select((.key | ltrimstr("thread-reconcile:")) as $k | ($done | index($k)) | not))
    | sort_by(.merged_at) | reverse
    | {pending: length, candidates: .[0:$max], beyond_bound: ((length - $max) | if . < 0 then 0 else . end)}
' 2>/dev/null || true)

[ -n "$rows" ] || emit degraded candidates_underivable \
    "the candidate rows could not be derived from the reader's output"

n_pending=$(printf '%s' "$rows" | jq -r '.pending' 2>/dev/null || echo 0)
n_cand=$(printf '%s' "$rows" | jq -r '.candidates | length' 2>/dev/null || echo 0)
n_beyond=$(printf '%s' "$rows" | jq -r '.beyond_bound' 2>/dev/null || echo 0)
n_done=$(printf '%s' "$done_json" | jq 'length' 2>/dev/null || echo 0)
n_unres=$(printf '%s' "$raw" | jq -r '.unresolved | length' 2>/dev/null || echo 0)

summary="${n_pending} finished item(s) whose thread has not been checked; ${n_cand} thread(s) to read, ${n_beyond} beyond the ${MAX}-read bound; ${n_done} already reconciled by an earlier tick; ${n_unres} with no feedback record and therefore no thread"

if [ "$n_cand" = "0" ]; then
    emit ok "" "$summary" "" ""
fi

needs=$(printf '%s' "$rows" | jq -c --arg tick "$TICK" '
    {action: "reconcile_each_finished_item_thread_with_the_unit_real_state",
     surface: "slack",
     tick: $tick,
     bound: "per candidate, find the thread through workaholic:notify stateless lookup — exact-string searches only, AT MOST TWO queries, cases 2 and 3 only, no channel history read anywhere, fuzzy matching prohibited; case 4 does NOT apply, because a lookup that finds no thread means the loop never announced this item and there is nothing stale to correct",
     read_first: "read that thread BEFORE writing anything. Only a thread whose LATEST status reply is 🔵 Proposed or 🟡 Handoff is a candidate; a latest status of 🟢, 🚀, 🔴 or a reconciliation this loop already posted is NOT — and when unsure, post nothing and say what made you unsure",
     post: "the catalog shape for the state the reader gives: merged reuses 🟢 Implemented with the sentence naming that it merged outside the loop, by whom and when; closed unmerged uses ⚫ Closed. Never invent an author or a time — an unresolved one is STATED as unresolved",
     record: "one thread-reconcile-filed line per candidate through log-append.sh naming its key and its outcome, then persist-log.sh --tick again — the second persist, without which the line dies with the container",
     outcomes: "per candidate, exactly one: posted, or a named not-posted reason — no_thread, already_finished, unsure, no_slack_transport, thread_unreadable, post_failed. A candidate handed back with no outcome is non-conformant on its face",
     never: "never merges, closes or reopens anything, never touches a claim, never posts a root, never posts into any thread but the item own, and never posts twice",
     candidates: .candidates,
     beyond_bound: .beyond_bound}' 2>/dev/null || echo '{}')

emit ok "" "$summary" "$needs" ""
