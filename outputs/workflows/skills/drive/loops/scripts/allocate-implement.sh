#!/bin/sh -eu
# Pure allocation from observed inputs; never reads a remote or starts a worker.
# Usage: sh allocate-implement.sh --input FILE
# Input: {formation_pending:boolean,claimable:<reader JSON>,fanout:integer,
#         available_capacity:integer}. Unknown formation defers, unknown work grants one.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/../../runtime/scripts/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: allocate-implement.sh --input FILE"
runtime_require_json_file "$2"
jq -e '
  def nonnegative_integer: type == "number" and . >= 0 and floor == .;
  (.available_capacity | nonnegative_integer) and
  (.fanout | nonnegative_integer) and .fanout >= 1
' "$2" >/dev/null 2>&1 || runtime_usage "fanout must be positive and available_capacity a nonnegative integer"
jq -c '
  def count_readable: type == "number" and . >= 0 and floor == .;
  if .formation_pending == true then
    {runners:0,reason:"mission_formation_pending"}
  elif .formation_pending != false then
    {runners:0,reason:"formation_unreadable"}
  else
    (if (.claimable | type) != "object" then false
     else (.claimable.readable != false and (.claimable.claimable | count_readable)) end) as $readable
    | (if $readable then .claimable.claimable else 1 end) as $offer
    | ([.fanout, .available_capacity, $offer] | min) as $runners
    | {runners:$runners,
       reason:(if .available_capacity == 0 then "capacity_exhausted"
               elif $readable then (if $offer == 0 then "no_claimable_work" else "work_available" end)
               else "claimable_unreadable" end),
       claimable_readable:$readable,
       claimable_reason:(if $readable then "" else
         (if (.claimable | type) == "object" then (.claimable.reason // "invalid_reading") else "invalid_reading" end) end)}
  end
' "$2"
