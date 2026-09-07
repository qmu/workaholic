#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/../../runtime/scripts/lib/result.sh"
[ "${1:-}" = --request ] || runtime_usage "usage: normalize-input.sh --request FILE"; REQUEST=${2:-}
runtime_require_json_file "$REQUEST"
jq -e '.protocol=="workaholic.runtime/v1" and (.request_id|type=="string" and length>0) and .operation=="normalize_input" and (.input|type=="object") and (.input.body|type=="string") and ((.input.explicit_subject//null)==null or (.input.explicit_subject|type=="object")) and ((.input.transport//{})|type=="object")' "$REQUEST" >/dev/null 2>&1 || runtime_usage "invalid normalize input request"
id=$(jq -r .request_id "$REQUEST")
jq -c --arg id "$id" '
  .input as $i
  | ($i.explicit_subject // null) as $explicit
  | (if (($i.transport.original_author_verified // false)==true) then ($i.transport.original_author // null) else null end) as $verified
  | (if $explicit != null then {value:$explicit,source:"explicit"}
     elif $verified != null then {value:$verified,source:"verified_transport"}
     else {value:{kind:"unknown",identity:null},source:"unknown"} end) as $subject
  | {protocol:"workaholic.runtime/v1",request_id:$id,status:"ok",reason:"",data:{
      input_id:($i.input_id // $id),body:$i.body,original_subject:($subject.value + {source:$subject.source}),
      transport_actor:($i.transport.actor // null),authorizing_direction:($i.authorization.direction // null),
      authorization_ref:($i.authorization.ref // null),answered_decisions:($i.answers // {}),source:($i.source // null),capture_state:"captured"}}' "$REQUEST"
