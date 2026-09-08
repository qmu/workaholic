#!/bin/sh -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
REQUEST="" RESULT=""
while [ $# -gt 0 ]; do case "$1" in --request) REQUEST=${2:-}; shift 2;; --result) RESULT=${2:-}; shift 2;; *) transport_usage "unknown argument";; esac; done
transport_request "$REQUEST"; [ -s "$RESULT" ] || transport_usage "missing result file"
rid=$(jq -r .request_id "$REQUEST"); op=$(jq -r .operation "$REQUEST")
jq -e --arg rid "$rid" --arg op "$op" '
  type=="object" and .request_id==$rid and .operation==$op and
  (.status=="ok" or .status=="absent" or .status=="unavailable" or .status=="error") and
  (.target|type=="object") and (.data|type=="object")
' "$RESULT" >/dev/null 2>&1 || transport_usage "observation does not match request"
expected=$(jq -c '.input.binding|{workspace,channel,channel_id}' "$REQUEST")
actual=$(jq -c '.target|{workspace,channel,channel_id}' "$RESULT")
printf '%s\n%s\n' "$expected" "$actual" | jq -s -e '.[0].workspace==.[1].workspace and ((.[0].channel_id//.[0].channel)==(.[1].channel_id//.[1].channel))' >/dev/null 2>&1 \
  || { transport_result deferred target_mismatch "$rid" '{}'; exit 0; }
status=$(jq -r .status "$RESULT")
case "$status" in absent) transport_result ok "" "$rid" '{"messages":[],"observed_absent":true}'; exit 0;; unavailable) transport_result deferred connector_unavailable "$rid" '{}'; exit 0;; error) transport_result deferred connector_failure "$rid" '{}'; exit 0;; esac
case "$op" in
  list_thread_changes)
    data=$(jq -c '.data | {threads:(.threads//[]),next_cursor:(.next_cursor//null),has_more:(.has_more//false),observed_at:(.observed_at//null)}' "$RESULT")
    ;;
  read_channel_delta|read_thread|search_exact)
    data=$(jq -c '.data | {messages:(.messages//[]),next_cursor:(.next_cursor//null),has_more:(.has_more//false),observed_at:(.observed_at//null)}' "$RESULT")
    ;;
  post_root|post_reply|add_reaction|reconcile_send)
    jq -e '.data.delivered==true and (.data.ts|type=="string" and length>0)' "$RESULT" >/dev/null 2>&1 || { transport_result deferred delivery_unconfirmed "$rid" '{}'; exit 0; }
    expected_sender=$(jq -r '.input.expected_sender_id // .input.binding.sender_id // empty' "$REQUEST"); actual_sender=$(jq -r '.data.sender_id // empty' "$RESULT")
    [ -z "$expected_sender" ] || [ "$expected_sender" = "$actual_sender" ] || { transport_result deferred sender_mismatch "$rid" "$(jq -c '{sender_id:(.data.sender_id//null)}' "$RESULT")"; exit 0; }
    data=$(jq -c .data "$RESULT")
    ;;
  *) transport_usage "unsupported observation operation" ;;
esac
transport_result ok "" "$rid" "$data"
