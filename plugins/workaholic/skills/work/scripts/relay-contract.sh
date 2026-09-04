#!/bin/sh -eu
# Validate the credential-free contract between a connector-less Codex worker and its owning chat.
# Usage: relay-contract.sh envelope <path> | acknowledgement <envelope> <ack> | reconcile <envelope> [ack]

PROTOCOL=workaholic.codex-slack-relay/v1
cmd="${1:-}"

fail() {
    printf '{"ok":false,"reason":"%s"}\n' "$1"
    exit 1
}

command -v jq >/dev/null 2>&1 || fail jq_missing

validate_envelope() {
    file=$1
    [ -s "$file" ] || fail envelope_missing
    jq -e --arg protocol "$PROTOCOL" '
      .protocol == $protocol and
      (.tick_id | type == "string" and length > 0) and
      (.outcome == "ok" or .outcome == "pending" or .outcome == "blocked") and
      (.slack_intents | type == "array") and
      ([.slack_intents[].key] | length == (unique | length)) and
      all(.slack_intents[];
        (.key | type == "string" and length > 0) and
        (.operation == "search_exact" or .operation == "read_thread" or
         .operation == "post_root" or .operation == "post_reply" or
         .operation == "add_reaction") and
        (.channel | type == "string" and length > 0) and
        (has("notified") | not) and
        (if .operation == "search_exact" then
           (.query | type == "string" and length > 0) and .private_inclusive == true
         elif .operation == "read_thread" then
           (.thread_ts | type == "string" and length > 0)
         elif .operation == "post_root" then
           (.text | type == "string" and length > 0)
         elif .operation == "post_reply" then
           (.thread_ts | type == "string" and length > 0) and
           (.text | type == "string" and length > 0)
         else
           (.timestamp | type == "string" and length > 0) and
           (.emoji | type == "string" and length > 0)
         end))
    ' "$file" >/dev/null || fail malformed_envelope
}

validate_ack() {
    envelope=$1 ack=$2
    validate_envelope "$envelope" >/dev/null
    [ -s "$ack" ] || fail acknowledgement_missing
    jq -e --arg protocol "$PROTOCOL" --slurpfile envelope "$envelope" '
      .protocol == $protocol and
      .tick_id == $envelope[0].tick_id and
      (.results | type == "array") and
      ([.results[].key] | length == (unique | length)) and
      ([.results[].key] | sort) == ([$envelope[0].slack_intents[].key] | sort) and
      all(.results[];
        (.key | type == "string" and length > 0) and
        (.outcome == "delivered" or .outcome == "post_refused" or
         .outcome == "thread_unresolved" or .outcome == "parent_absent" or
         .outcome == "invalid_intent"))
    ' "$ack" >/dev/null || fail malformed_acknowledgement
}

case "$cmd" in
    envelope)
        validate_envelope "${2:-}"
        jq -c '{ok:true,protocol,tick_id,outcome,intents:(.slack_intents|length)}' "$2"
        ;;
    acknowledgement)
        validate_ack "${2:-}" "${3:-}"
        jq -c '{ok:true,protocol,tick_id,results:(.results|length)}' "$3"
        ;;
    reconcile)
        envelope="${2:-}" ack="${3:-}"
        validate_envelope "$envelope" >/dev/null
        if [ -z "$ack" ] || [ ! -s "$ack" ]; then
            jq -c '{ok:true,relay:"pending",tick_id,undelivered:[.slack_intents[].key]}' "$envelope"
            exit 0
        fi
        validate_ack "$envelope" "$ack" >/dev/null
        jq -cn --slurpfile envelope "$envelope" --slurpfile ack "$ack" '
          {ok:true,
           relay:(if all($ack[0].results[]; .outcome == "delivered") then "delivered" else "incomplete" end),
           tick_id:$envelope[0].tick_id,
           undelivered:[$ack[0].results[] | select(.outcome != "delivered") | {key,outcome}]}'
        ;;
    *) fail usage ;;
esac
