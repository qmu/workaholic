#!/bin/sh -eu
# Validate a host's semantic PR-unit partition before counting or dispatching it.
# Input: {backlog:[{path,depends_on?}],groups:[{id,tickets:[path],reason}]}
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/../../runtime/scripts/lib/result.sh"
[ "$#" -eq 2 ] && [ "$1" = --input ] || runtime_usage "usage: partition-backlog.sh --input FILE"
runtime_require_json_file "$2"
jq -c '
  def strings: type=="array" and all(.[];type=="string" and length>0);
  def dependencies:
    if . == null or . == "" then [] elif type=="array" then .
    elif type=="string" then sub("^\\[";"") | sub("\\]$";"") | split(",") |
      map(gsub("^[\\s\"\u0027]+|[\\s\"\u0027]+$";""))
    else error("invalid dependencies") end;
  . as $p |
  if (.backlog|type)!="array" or (.groups|type)!="array" then error("backlog and groups required") else . end |
  [.backlog[].path] as $available |
  if ($available|strings|not) or ($available|unique|length)!=($available|length) then error("invalid backlog") else . end |
  if all(.groups[]; (.id|type=="string" and test("^[A-Za-z0-9][A-Za-z0-9._-]*$")) and
    (.reason|type=="string" and length>0) and (.tickets|strings) and (.tickets|length)>0) then . else error("invalid group") end |
  [.groups[].tickets[]] as $assigned |
  if ($assigned|sort)!=($available|sort) or ([.groups[].id]|unique|length)!=(.groups|length)
    then error("partition must cover each ticket exactly once") else . end |
  if all(.groups[]; . as $g | all($p.backlog[]|select(.path as $path|$g.tickets|index($path));
      all((.depends_on | dependencies)[]; . as $dep |
        [$available[] | select(. == $dep or (split("/")|last) == ($dep|split("/")|last))] as $matches |
        all($matches[]; . as $match | ($g.tickets|index($match)) != null))))
    then {readable:true,backlog_units:(.groups|length),groups:.groups}
    else error("dependent backlog cannot dispatch concurrently") end
' "$2" 2>/dev/null || runtime_usage "invalid or overlapping backlog partition"
