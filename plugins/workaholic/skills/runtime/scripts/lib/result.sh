#!/bin/sh

runtime_json_result() {
    _rr_status=$1 _rr_reason=$2 _rr_request=$3 _rr_data=$4
    jq -cn --arg p workaholic.runtime/v1 --arg r "$_rr_request" \
        --arg s "$_rr_status" --arg why "$_rr_reason" --argjson d "$_rr_data" \
        '{protocol:$p,request_id:$r,status:$s,reason:$why,data:$d}'
}

runtime_usage() {
    jq -cn --arg detail "$1" '{protocol:"workaholic.runtime/v1",request_id:"invalid-input",status:"error",reason:"invalid_input",data:{detail:$detail}}'
    printf '%s\n' "$1" >&2
    exit 2
}

runtime_require_json_file() {
    [ -n "$1" ] && [ -f "$1" ] || runtime_usage "missing input file"
    jq -e 'type == "object"' "$1" >/dev/null 2>&1 || runtime_usage "input must be a JSON object"
}
