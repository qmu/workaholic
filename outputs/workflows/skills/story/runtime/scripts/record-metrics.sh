#!/bin/sh -eu
# Validate one request's measured cost. Unknown provider usage stays null.
[ "${1:-}" = --input ] || { printf '{"status":"error","reason":"input_required"}\n'; exit 2; }
INPUT=${2:-}
jq -e '(.request_id|type=="string" and length>0) and (.wall_ms|type=="number" and .>=0)
  and (.reader_calls|type=="number" and .>=0) and (.api_calls|type=="number" and .>=0)
  and (.worker_calls|type=="number" and .>=0) and (.read_bytes|type=="number" and .>=0)
  and ((.usage==null) or ((.usage.input|type=="number") and (.usage.cached|type=="number") and (.usage.output|type=="number")))' "$INPUT" >/dev/null 2>&1 || { printf '{"status":"error","reason":"invalid_metrics"}\n'; exit 2; }
jq -c '{protocol:"workaholic.runtime/v1",request_id,status:"ok",reason:"",data:{wall_ms,reader_calls,api_calls,worker_calls,read_bytes,usage:(.usage // null)}}' "$INPUT"
