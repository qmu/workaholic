#!/bin/sh

transport_result() {
    _tr_status=$1 _tr_reason=$2 _tr_request=$3 _tr_data=$4
    jq -cn --arg r "$_tr_request" --arg s "$_tr_status" --arg why "$_tr_reason" --argjson d "$_tr_data" \
      '{protocol:"workaholic.transport/v1",request_id:$r,status:$s,reason:$why,data:$d}'
}

transport_usage() {
    transport_result error invalid_input invalid-input "$(jq -cn --arg detail "$1" '{detail:$detail}')"
    printf '%s\n' "$1" >&2
    exit 2
}

transport_request() {
    [ -n "${1:-}" ] && [ -f "$1" ] || transport_usage "missing request file"
    jq -e '
      type=="object" and .protocol=="workaholic.transport/v1" and
      (.request_id|type=="string" and length>0) and
      (.repo_root|type=="string" and length>0) and
      (.instance_id|type=="string" and length>0) and
      (.input|type=="object") and
      (.operation=="discover" or .operation=="read_channel_delta" or
       .operation=="list_thread_changes" or
       .operation=="read_thread" or .operation=="search_exact" or
       .operation=="post_root" or .operation=="post_reply" or
       .operation=="add_reaction" or .operation=="reconcile_send")
    ' "$1" >/dev/null 2>&1 || transport_usage "invalid transport request"
}

transport_parse_request_arg() {
    [ "${1:-}" = --request ] && [ -n "${2:-}" ] && [ "$#" -eq 2 ] || transport_usage "usage: --request FILE"
    TRANSPORT_REQUEST_FILE=$2
    transport_request "$TRANSPORT_REQUEST_FILE"
    TRANSPORT_REQUEST_ID=$(jq -r .request_id "$TRANSPORT_REQUEST_FILE")
    TRANSPORT_OPERATION=$(jq -r .operation "$TRANSPORT_REQUEST_FILE")
}
