#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
INPUT=""
[ "${1:-}" = --input ] && INPUT=${2:-} || runtime_usage "usage: read-capabilities.sh --input FILE"
runtime_require_json_file "$INPUT"
jq -e '
  def tri: . == true or . == false or . == null;
  (.capabilities | type == "object") and
  ([.capabilities.c1,.capabilities.c2,.capabilities.c3,.capabilities.c4] | all(tri)) and
  (.cli_available | tri) and (.persistent_process | tri)' "$INPUT" >/dev/null 2>&1 \
  || runtime_usage "invalid capability input"
jq -c '
  . as $i | .capabilities as $c
  | (if ($c.c1 == true and $c.c2 == true and $c.c3 == true) then "native"
     elif $c.c4 == true then "scheduler"
     elif (.cli_available == true and .persistent_process == true) then "supervisor"
     else "once" end) as $mode
  | {protocol:"workaholic.runtime/v1",request_id:(.request_id // "read-capabilities"),status:"ok",reason:"",
     data:{mode:$mode,capabilities:$c,evidence:(.evidence // {}),unknown:([$c|to_entries[]|select(.value==null)|.key] + ([{key:"cli_available",value:$i.cli_available},{key:"persistent_process",value:$i.persistent_process}]|map(select(.value==null)|.key)))}}' "$INPUT"

