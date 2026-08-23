#!/bin/sh -eu
# The one reader of a check-in question's life: never asked, asked, or answered.
#
# WHY THREE STATES AND NOT TWO (2026-08-23, issue #584). The gate knew only whether a key
# had been asked, so an answered question and one nobody will ever answer read identically —
# and the loop had no way to notice that the thing blocking it had been resolved. The three
# are now distinguishable from the tick log alone, with no new store:
#
#   never_asked  no `human-checkin-ask-<slug>` line
#   asked        that line exists, and no answer beside it
#   answered     `human-checkin-answered-<slug>` exists; its summary is the person's words
#
# IT READS AND NEVER WRITES. `log-read.sh` is the log's only reader and this composes it;
# `record-answer.sh` is the only writer of the answered line. A missing log is
# `never_asked` — a repository with no tick history has asked nothing — while a log that
# exists and cannot be read is `unreadable`, reported by name, because those are different
# facts and only one of them is calm.
#
# THE NEWEST ANSWER WINS. A person correcting themselves in a later tick appends a new line
# rather than editing the old one (the log is append-only), so the reader takes the last
# entry by tick. Both remain in the log, which is the audit trail.
#
# Usage: question-state.sh --key <content-key> [--root <repo-root>]
# Output: one JSON line
#   {"state": "never_asked|asked|answered|unreadable", "key": "...", "slug": "...",
#    "asked_tick": "", "answered_tick": "", "answer": ""}

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/question-id.sh"
LOG_READ="${SCRIPT_DIR}/log-read.sh"

KEY=''
ROOT='.'
while [ $# -gt 0 ]; do
    case "$1" in
        --key) KEY="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

emit() {
    printf '{"state": "%s", "key": "%s", "slug": "%s", "asked_tick": "%s", "answered_tick": "%s", "answer": %s}\n' \
        "$1" "$KEY" "${SLUG:-}" "${2:-}" "${3:-}" "${4:-\"\"}"
    exit 0
}

[ -n "$KEY" ] && [ -f "$LOG_READ" ] || { SLUG=''; emit unreadable; }

SLUG=$(question_slug "$KEY")

read_step() { sh "$LOG_READ" --root "$ROOT" --step "$1" 2>/dev/null || true; }

asked_out=$(read_step "human-checkin-ask-${SLUG}")
ans_out=$(read_step "human-checkin-answered-${SLUG}")

# A log-read that produced nothing at all is not "no entries": the reader always emits an
# envelope. Nothing means it could not run.
[ -n "$asked_out" ] || emit unreadable

last_field() {
    printf '%s' "$1" | jq -r --arg f "$2" '[.entries[]?] | sort_by(.tick) | last | .[$f] // ""' 2>/dev/null || printf ''
}

asked_tick=$(last_field "$asked_out" tick)
answered_tick=$(last_field "$ans_out" tick)
answer_json=$(printf '%s' "$ans_out" | jq -c '[.entries[]?] | sort_by(.tick) | last | .summary // ""' 2>/dev/null || printf '""')
[ -n "$answer_json" ] || answer_json='""'

if [ -n "$answered_tick" ]; then
    emit answered "$asked_tick" "$answered_tick" "$answer_json"
elif [ -n "$asked_tick" ]; then
    emit asked "$asked_tick"
else
    emit never_asked
fi
