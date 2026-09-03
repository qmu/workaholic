#!/bin/sh -eu
# Run a unit's DECLARED verification probe, at claim time, and answer what its exit status said.
#
#   run-verification-probe.sh mission <slug-or-file>
#   run-verification-probe.sh tickets <ticket-file>...
#   run-verification-probe.sh --probe '<command>'      (the command directly, for a caller that
#                                                       already read it)
#
# Output: one JSON line
#   {"ok", "outcome", "reason", "probe", "exit_status", "output", "truncated", "unit"}
#
# WHY IT EXISTS (2026-09-03, mission `make-a-verification-handoff-a-probe-re-run-at-claim-time`).
# `verification_handoff:` was free text quoted verbatim into `## Handoff`, so nothing could ever
# falsify it: a blocker true the day it was written stayed true forever, and the work behind it
# stopped being attempted. MEASURED on a consuming repository -- four pull requests parked, and
# three of the declarations FALSE when somebody finally probed them: a key already on disk, a
# secret-put CI that had already run, an entrance whose tokens were held all along.
#
# THE PROBE RUNS WHEN THE UNIT IS CLAIMED, NOT WHEN THE TICKET IS WRITTEN. That is the whole of
# the ask. A declaration is a claim about the environment the work will run in, and the only
# moment that environment is knowable is the moment a runner is standing in it.
#
# FOUR OUTCOMES, AND EACH SAYS WHAT THE CALLER MAY DO:
#
#   clean       the probe exited 0. This is NOT a handoff -- the environment the declaration said
#               was missing is here, and the unit takes its ordinary route.
#   blocking    the probe exited non-zero. The unit is handed over, and the probe's OWN OUTPUT is
#               the reason (a `302` and its redirect target say more than any sentence, and unlike
#               a sentence they go stale visibly).
#   unmeasured  a non-empty declaration carrying no probe. Not false, not true -- nobody can
#               re-probe it, so the declaration stands exactly as it did before this script
#               existed. **This is the answer for every declaration on disk today**, and it is why
#               nothing is retro-blocked.
#   unreadable  we could not get as far as an exit status (no such unit, the reader failed, the
#               probe timed out). The absence of a reading is never a clean probe: it leaves the
#               declaration standing, which is the safe direction.
#
# NOTHING IS INFERRED FROM THE OUTPUT, only from the EXIT STATUS. Parsing a probe's text would be
# the guess the field exists to avoid, and the output is carried for a person to read rather than
# for this script to interpret.
#
# IT IS BOUNDED. `WORKAHOLIC_PROBE_TIMEOUT_SECONDS` (default 60) caps the run, and the captured
# output is truncated to `WORKAHOLIC_PROBE_OUTPUT_MAX` bytes (default 2000) with `truncated: true`
# saying so -- a probe that printed a megabyte must not become a pull-request body.
#
# IT WRITES NOTHING. No file, no ref, no commit, no network call of its own; whatever the declared
# command does is the declaration's business and the operator wrote it.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
READER="${SCRIPT_DIR}/verification-handoff.sh"

TIMEOUT=${WORKAHOLIC_PROBE_TIMEOUT_SECONDS:-60}
OUT_MAX=${WORKAHOLIC_PROBE_OUTPUT_MAX:-2000}

UNIT=""
PROBE=""
DIRECT=false

json_escape() {
    # THE INTERIOR OF A JSON STRING, without the surrounding quotes -- `emit` supplies those in its
    # own `printf` template, which is why this cannot simply be `read-deployments.sh`'s
    # `escape_json`.
    #
    # NON-ASCII STAYS RAW UTF-8 (2026-09-03, ticket `20260903064753`). What travels through here is
    # a probe's CAPTURED OUTPUT, which reaches a person twice -- quoted into the `## Handoff`
    # section and into the `🟡 Handoff` Slack post -- so a probe that printed Japanese used to hand
    # its reader `\uXXXX` to decode. Raw UTF-8 is valid JSON, so every JSON-parsing consumer is
    # untouched.
    #
    # ALL THREE INTERPRETERS ARE PINNED, and the `sed` fallback is GONE rather than patched. It was
    # the second half of the defect: the two paths of one function disagreed, so which answer a
    # caller got depended on whether `python3` was installed. Measured on one input carrying a tab,
    # a carriage return and a `\001`, `sed` emitted all three RAW -- bytes a JSON string may not
    # contain at all, and a probe's output is exactly where such bytes turn up -- so it could never
    # be made to agree, only replaced. python3, node and perl agree byte for byte; this is
    # `read-deployments.sh`'s shape with the outer quotes trimmed.
    printf '%s' "${1:-}" | python3 -c 'import json,sys; sys.stdout.buffer.write(json.dumps(sys.stdin.buffer.read().decode("utf-8","surrogateescape"), ensure_ascii=False).encode("utf-8","surrogateescape")[1:-1])' 2>/dev/null \
        || printf '%s' "${1:-}" | node -e 'process.stdout.write(JSON.stringify(require("fs").readFileSync(0,"utf8")).slice(1,-1))' 2>/dev/null \
        || printf '%s' "${1:-}" | perl -MJSON::PP -e 'binmode(STDIN, ":encoding(UTF-8)"); binmode(STDOUT, ":raw"); my $s = do { local $/; <STDIN> }; my $j = JSON::PP->new->allow_nonref->utf8->encode($s); print substr($j, 1, length($j) - 2)'
}

emit() {
    # emit <ok> <outcome> <reason> <exit_status> <output> <truncated>
    printf '{"ok": %s, "outcome": "%s", "reason": "%s", "probe": "%s", "exit_status": %s, "output": "%s", "truncated": %s, "unit": "%s"}\n' \
        "$1" "$2" "$(json_escape "${3:-}")" "$(json_escape "$PROBE")" "${4:-null}" \
        "$(json_escape "${5:-}")" "${6:-false}" "$(json_escape "$UNIT")"
    exit 0
}

case "${1:-}" in
    --probe)
        [ $# -ge 2 ] || emit false unreadable no_probe_argument
        PROBE="$2"
        UNIT="(direct)"
        DIRECT=true
        ;;
    mission|tickets)
        MODE="$1"
        shift
        [ $# -ge 1 ] || emit false unreadable no_unit_argument
        UNIT="$1"
        [ -f "$READER" ] || emit false unreadable no_reader
        # THE PROBE IS READ THROUGH THE ONE READER, never re-parsed here: `verification-handoff.sh`
        # answers *what does this unit declare*, and a second parser of that field is exactly the
        # drift this repository single-sources against.
        read_out=$(sh "$READER" "$MODE" "$@" 2>/dev/null || printf '')
        [ -n "$read_out" ] || emit false unreadable reader_failed
        declared=$(printf '%s' "$read_out" | jq -r '.handoff // false' 2>/dev/null || printf 'false')
        PROBE=$(printf '%s' "$read_out" | jq -r '.probe // ""' 2>/dev/null || printf '')
        if [ "$declared" != "true" ]; then
            emit true clean no_declaration
        fi
        if [ -z "$PROBE" ]; then
            reason=$(printf '%s' "$read_out" | jq -r '.reason // ""' 2>/dev/null || printf '')
            emit true unmeasured "$reason"
        fi
        ;;
    *)
        emit false unreadable 'usage: run-verification-probe.sh mission <slug> | tickets <file>... | --probe <command>'
        ;;
esac

[ -n "$PROBE" ] || emit true unmeasured no_probe_declared

# THE RUN. `sh -c` because the declaration is a command line the operator wrote; stderr is folded
# into stdout because a failing probe usually says why on stderr and the caller wants the sentence
# it printed, wherever it printed it.
tmp=$(mktemp "${TMPDIR:-/tmp}/workaholic-probe.XXXXXX")
status=0
if command -v timeout >/dev/null 2>&1; then
    timeout "$TIMEOUT" sh -c "$PROBE" >"$tmp" 2>&1 || status=$?
else
    sh -c "$PROBE" >"$tmp" 2>&1 || status=$?
fi

raw=$(cat "$tmp" 2>/dev/null || printf '')
rm -f "$tmp"
truncated=false
if [ "$(printf '%s' "$raw" | wc -c | tr -d ' ')" -gt "$OUT_MAX" ]; then
    raw=$(printf '%s' "$raw" | cut -c1-"$OUT_MAX")
    truncated=true
fi

# 124 IS THE TIMEOUT'S OWN STATUS, and it is `unreadable` rather than `blocking`: we did not learn
# what the probe would have said, and the absence of a reading must never be dressed up as one.
if [ "$status" -eq 124 ] && command -v timeout >/dev/null 2>&1; then
    emit false unreadable "probe_timed_out_after_${TIMEOUT}s" "$status" "$raw" "$truncated"
fi

if [ "$status" -eq 0 ]; then
    emit true clean "" 0 "$raw" "$truncated"
fi
emit true blocking probe_failed "$status" "$raw" "$truncated"
