#!/bin/sh -eu
# Validate per-feedback evidence before composing an implementation finish line.
# Input: {items:[{feedback,expected_surface,verified_surface,evidence:[],queue_readable,
# queued,implementation_pr:{merged,verified},deployment,thread:{status,complete}}]}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: feedback-outcome.sh --input FILE"
runtime_require_json_file "$2"
jq -c '
  if (.items|type)!="array" then error("items required") else . end |
  {items:[.items[] | . as $i |
    (if .queue_readable != true then "unreadable"
     elif (.queued|type)!="number" or .queued<0 then "unreadable"
     elif .queued>0 then "still_queued"
     elif .implementation_pr.merged != true then "not_implemented"
     elif .implementation_pr.verified != true then "not_verified"
     elif (.expected_surface|type)!="string" or .expected_surface=="" then "surface_unresolved"
     elif .expected_surface != .verified_surface then "surface_mismatch"
     elif (.evidence|type)!="array" or (.evidence|length)==0 or
       (all(.evidence[];type=="string" and length>0)|not) then "evidence_missing"
     else "implemented_and_verified" end) as $state |
    {feedback:.feedback,state:$state,deployment:(.deployment // "unreadable"),
     notification:(if $state != "implemented_and_verified" then "held"
       elif .thread.status=="found" then "reply"
       elif .thread.status=="missing" and .thread.complete==true then "create_description_root"
       else "thread_unresolved" end),evidence:(.evidence // [])}]}
' "$2" 2>/dev/null || runtime_usage "invalid feedback evidence"
