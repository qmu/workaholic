#!/usr/bin/env bash
# validate.sh - Validate that expected output files exist and are non-empty
#
# Usage: bash validate.sh <directory> <file1> <file2> ...
# Output: JSON with per-file status and overall pass/fail

dir="${1:-}"
shift

if [ -z "$dir" ] || [ $# -eq 0 ]; then
  echo '{"pass":false,"error":"Usage: validate.sh <directory> <file1> <file2> ...","files":{}}'
  exit 1
fi

pass=true
files_json=""
sep=""

for file in "$@"; do
  path="$dir/$file"
  if [ ! -f "$path" ]; then
    status="missing"
    pass=false
  elif [ ! -s "$path" ]; then
    status="empty"
    pass=false
  else
    status="ok"
  fi
  files_json="${files_json}${sep}\"${file}\":\"${status}\""
  sep=","
done

echo "{\"pass\":${pass},\"files\":{${files_json}}}"
