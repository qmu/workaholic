#!/bin/sh -eu
# Validate per-feedback evidence before composing an implementation finish line.
# Input: {items:[{feedback,verified_surface,evidence:[],queue_readable,
# queued,implementation_pr:{merged,verified},deployment,thread:{status,complete}}]}
#
# THE EXPECTED SURFACE IS READ OFF THE ARTIFACT, NEVER TAKEN FROM THE CALLER
# (2026-09-19, ticket `20260919094701`). `expected_surface` used to arrive in this
# input beside `verified_surface`, so both sides of the comparison were written by
# whoever composed the facts — the party the comparison exists to check. It is now
# resolved per item through `review-surface.sh`, the one reader, off the feedback
# record the ask itself was captured into; a caller that still passes the field is
# IGNORED rather than refused, so no call site breaks and none can override.
# `verified_surface` stays a caller fact and correctly so: it is what this run
# observed, which is the claim being checked.
#
# ABSENT AND UNREADABLE ARE DIFFERENT, and the ladder keeps them apart:
#   `surface_unresolved`  — the record names no surface. The ordinary case.
#   `surface_unreadable`  — no record, or one that could not be read. An absence of a
#                           reading is never a pass, and never rounds to an absence of
#                           a surface; `surface_reason` on the row names which.
# Output: bare {items:[{feedback,state,deployment,notification,evidence,
#                       expected_surface,surface_reason}]} — NOT the runtime envelope.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: feedback-outcome.sh --input FILE"
runtime_require_json_file "$2"

INPUT=$2

# One resolver call for the whole item set, refs in input order and one line per item
# INCLUDING an empty one, so the answers line up by index and a duplicated ref keeps
# its own row.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
jq -r '.items[]? | (.feedback // "")' "$INPUT" >"$tmp/refs" 2>/dev/null || : >"$tmp/refs"
sh "$SCRIPT_DIR/../../feedback/scripts/review-surface.sh" --stdin <"$tmp/refs" >"$tmp/surfaces.json" 2>/dev/null \
  || printf '{"surfaces": []}\n' >"$tmp/surfaces.json"
jq -e '(.surfaces|type) == "array"' "$tmp/surfaces.json" >/dev/null 2>&1 \
  || printf '{"surfaces": []}\n' >"$tmp/surfaces.json"

jq -c --slurpfile surfaces "$tmp/surfaces.json" '
  if (.items|type)!="array" then error("items required") else . end |
  (($surfaces[0].surfaces) // []) as $s |
  {items:[.items | to_entries[] | .key as $ix | .value | . as $i |
    # A resolver row this walk could not produce at all is an unreadable reading, not
    # an absent surface: `// {}` would make the two the same answer.
    ($s[$ix] // {readable:false, reason:"surface_unresolvable", surface:""}) as $row |
    ($row.surface // "") as $expected |
    (if .queue_readable != true then "unreadable"
     elif (.queued|type)!="number" or .queued<0 then "unreadable"
     elif .queued>0 then "still_queued"
     elif .implementation_pr.merged != true then "not_implemented"
     elif .implementation_pr.verified != true then "not_verified"
     elif $row.readable != true then "surface_unreadable"
     elif ($expected|type)!="string" or $expected=="" then "surface_unresolved"
     elif $expected != .verified_surface then "surface_mismatch"
     elif (.evidence|type)!="array" or (.evidence|length)==0 or
       (all(.evidence[];type=="string" and length>0)|not) then "evidence_missing"
     else "implemented_and_verified" end) as $state |
    {feedback:.feedback,state:$state,deployment:(.deployment // "unreadable"),
     expected_surface:$expected,surface_reason:($row.reason // ""),
     notification:(if $state != "implemented_and_verified" then "held"
       elif .thread.status=="found" then "reply"
       elif .thread.status=="missing" and .thread.complete==true then "create_description_root"
       else "thread_unresolved" end),evidence:(.evidence // [])}]}
' "$INPUT" 2>/dev/null || runtime_usage "invalid feedback evidence"
