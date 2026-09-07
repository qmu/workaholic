#!/bin/sh -eu
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/../../runtime/scripts/lib/result.sh"
[ "${1:-}" = --input ] || runtime_usage "usage: validate-plan.sh --input FILE"; INPUT=${2:-}
runtime_require_json_file "$INPUT"
jq -e '
  (.kind=="record_only" or .kind=="ticket" or .kind=="tickets" or .kind=="mission" or .kind=="strategy_change") and
  (.hypothesis|type=="object") and (.hypothesis.strategy|type=="string" and length>0) and
  (.hypothesis.evidence|type=="array") and (.hypothesis.expected_learning|type=="string" and length>0) and
  (.hypothesis.minimal_action|type=="string" and length>0) and (.hypothesis.success_condition|type=="string" and length>0) and
  (.hypothesis.stop_condition|type=="string" and length>0) and
  (if .kind=="record_only" then ((.tickets//[])|length)==0
   elif .kind=="ticket" then ((.tickets//[])|length)==1
   elif .kind=="tickets" then ((.tickets//[])|length)>=1
   elif .kind=="mission" then ((.tickets//[])|length)>=2 and (.mission|type=="object")
   else (.authorization|type=="object") and (.authorization.ref|type=="string" and length>0) end)' "$INPUT" >/dev/null 2>&1 || runtime_usage "plan does not match its declared kind"
canonical=$(jq -Sc '{kind,hypothesis,mission:(.mission//null),tickets:(.tickets//[]),strategy_change:(.strategy_change//null),authorization:(.authorization//null)}' "$INPUT")
fingerprint=$(printf '%s' "$canonical" | sha256sum | cut -d' ' -f1)
if jq -e --arg fp "$fingerprint" '(.previous_hypotheses // []) | index($fp) != null' "$INPUT" >/dev/null 2>&1; then
  runtime_json_result deferred unchanged_hypothesis validate-plan "$(jq -cn --arg fingerprint "$fingerprint" '{fingerprint:$fingerprint}')"
  exit 0
fi
runtime_json_result ok "" validate-plan "$(jq -cn --arg fingerprint "$fingerprint" --argjson plan "$canonical" '{fingerprint:$fingerprint,plan:$plan}')"
