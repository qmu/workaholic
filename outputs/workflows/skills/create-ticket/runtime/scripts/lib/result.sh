#!/bin/sh

runtime_json_result() {
    _rr_status=$1 _rr_reason=$2 _rr_request=$3 _rr_data=$4
    jq -cn --arg p workaholic.runtime/v1 --arg r "$_rr_request" \
        --arg s "$_rr_status" --arg why "$_rr_reason" --argjson d "$_rr_data" \
        '{protocol:$p,request_id:$r,status:$s,reason:$why,data:$d}'
}

# The same result, with the data block read from a FILE rather than from `argv`
# (2026-09-19, ticket `20260919120809`). Linux caps one argument at MAX_ARG_STRLEN
# (32 x PAGE_SIZE -- 131072 bytes on a 4 KiB page), so a caller whose data block
# carries a whole durable record hits `E2BIG` and `runtime_json_result` then prints
# NOTHING AT ALL. This variant is added beside it rather than replacing its signature:
# every other runtime caller passes a bounded block and stays byte-identical.
# It returns non-zero rather than printing a partial result, so the caller answers by
# its own name (`state_write_failed` / `state_unreadable`) instead of falling through.
runtime_json_result_file() {
    _rr_status=$1 _rr_reason=$2 _rr_request=$3 _rr_file=$4
    [ -s "$_rr_file" ] || return 1
    jq -cn --arg p workaholic.runtime/v1 --arg r "$_rr_request" \
        --arg s "$_rr_status" --arg why "$_rr_reason" --slurpfile d "$_rr_file" \
        '($d[0] // null) as $data
         | if ($data|type) != "object" then error("data block must be a JSON object")
           else {protocol:$p,request_id:$r,status:$s,reason:$why,data:$data} end' || return 1
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
