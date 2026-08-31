#!/bin/sh
# The one derivation of what a question's ask line carries besides its prose. Sourced,
# never executed.
#
# WHY IT IS A LIBRARY (2026-08-28, mission `let-an-answer-in-the-thread-turn-back-into-the-loop-s-work`).
# A later tick can only read a question's own thread if it knows where that thread is, and
# the agent knows the coordinate at the moment it posts — so the coordinate is recorded then
# and never searched for later. That is the same property the inbound sweep's receipt relies
# on: the `slack-ref` it writes *is* `<channel>:<ts>` (`workaholic:notify`, the receipt entry).
#
# NO NEW STORE AND NO NEW FIELD. The tick log is line-oriented and `log-append.sh` takes a
# single `--summary`, so both facts ride that summary as fixed, parseable tokens on the
# `human-checkin-ask-<slug>` line the gate already writes. The writer (`ask-question.sh`)
# and the reader (`question-state.sh`) source this file, so the format has one home and they
# cannot drift — the same reason `lib/question-id.sh` exists.
#
# TWO TOKENS, AND THE KEY IS ONE OF THEM. The step id is a lossy hash of the content key
# (`question_slug`), so a line carrying only the id cannot be turned back into a key — and
# `record-answer.sh` takes a key. Recording it is what makes the return path possible at all;
# it is not a second identity, because the id is still derived from the key by one function.
#
#   - `<prose> posted-at:<channel>:<ts> key:<content key>`
#
# The key token is LAST and runs to end of line, so a key containing anything but a newline
# survives; the coordinate token is fixed-shape and is matched as such. A line carrying
# neither is exactly what every line written before this existed looks like, and both readers
# answer a NAMED ABSENCE for it rather than an error or a guess.
#
# Usage: . <this file>
#   qc_line "<prose>" "<coordinate>" "<key>"  -> the summary to log
#   qc_coordinate "<summary>"                 -> "<channel>:<ts>" or ""
#   qc_key "<summary>"                        -> "<content key>" or ""
#   qc_valid "<coordinate>"                   -> 0 when it is <channel>:<ts>, 1 otherwise

# A coordinate is a Slack channel id and a message ts. Validated by shape rather than
# trusted, because a malformed one recorded here is a thread read that silently reads
# nothing a tick later, with no way to tell that from a question nobody answered.
qc_valid() {
    case "${1:-}" in
        '') return 1 ;;
        *' '*) return 1 ;;
        *:*) : ;;
        *) return 1 ;;
    esac
    _qc_ch=$(printf '%s' "$1" | cut -d: -f1)
    _qc_ts=$(printf '%s' "$1" | cut -d: -f2-)
    [ -n "$_qc_ch" ] || return 1
    [ -n "$_qc_ts" ] || return 1
    case "$_qc_ts" in *:*) return 1 ;; esac
    case "$_qc_ts" in ''|*[!0-9.]*) return 1 ;; esac
    return 0
}

qc_line() {
    _qc_prose="${1:-}"
    _qc_coord="${2:-}"
    _qc_key="${3:-}"
    [ -n "$_qc_prose" ] || _qc_prose=asked
    _qc_out="$_qc_prose"
    if [ -n "$_qc_coord" ] && qc_valid "$_qc_coord"; then
        _qc_out="$_qc_out posted-at:$_qc_coord"
    fi
    # Last, and to end of line: see the header.
    [ -n "$_qc_key" ] && _qc_out="$_qc_out key:$_qc_key"
    printf '%s' "$_qc_out"
}

qc_coordinate() {
    printf '%s' "${1:-}" \
        | sed -n 's/.*posted-at:\([^ ]\{1,\}\).*/\1/p' \
        | head -1
}

qc_key() {
    printf '%s' "${1:-}" | sed -n 's/.* key:\(.*\)$/\1/p' | head -1
}
