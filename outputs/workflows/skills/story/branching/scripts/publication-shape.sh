#!/bin/sh -eu
# Normalize GitHub-style file patches into the shared publication refusal stream.
# A routine extension must preserve every old line except an additive feedback list,
# link newly added feedback, and add tickets to that same mission. Missing patches fail closed.
# Usage: publication-shape.sh --input FILE
[ "$#" -eq 2 ] && [ "$1" = --input ] && [ -f "$2" ] || exit 2
jq -r '
  def refs: sub("^feedback:[[:space:]]*";"") | gsub("[\\[\\],]";" ") | split(" ") | map(select(length>0));
  . as $files |
  .[] | . as $file |
  (.patch // "" | split("\n")) as $lines |
  [$lines[]|select(startswith("-"))|ltrimstr("-")] as $removed |
  [$lines[]|select(startswith("+"))|ltrimstr("+")] as $added |
  [$removed[]|select(startswith("feedback:"))|refs[]] as $old |
  [$added[]|select(startswith("feedback:"))|refs[]] as $new |
  (.filename | split("/") | .[-2]) as $mission |
  (if .status == "modified" and (.filename|test("^\\.workaholic/missions/active/[^/]+/mission\\.md$")) and
    ($removed|length)>0 and all($removed[];startswith("feedback:")) and
    ($old-$new|length)==0 and ($new-$old|length)>0 and
    all(($new-$old)[]; . as $ref | any($files[];
      .status=="added" and .filename==(".workaholic/feedbacks/"+$ref))) and
    any($files[]; .status=="added" and (.filename|startswith(".workaholic/tickets/todo/")) and
      any((.patch // "" | split("\n"))[]; .==("+mission: "+$mission)))
    then "extension" else "" end) as $extension |
  [(if .status=="added" then "A" elif .status=="modified" then "M" elif .status=="removed" then "D"
     elif .status=="renamed" then "R" else "?" end), .filename,
    (if (.status == "modified" and (.patch|type) != "string") or
      any($lines[];test("^[+-]feedback:")) then "1" else "0" end),$extension] | @tsv
' "$2"
