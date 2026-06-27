#!/bin/sh -eu
# validate.sh - Validate that expected output files exist and are non-empty
#
# Usage: sh validate.sh <directory> <file1> <file2> ...
# Output: JSON with per-file status and overall pass/fail

set -eu

dir="${1:-}"
# Guard shift so a no-arg call falls through to the usage error instead of
# aborting under set -e (POSIX `shift` errors when $# is 0).
[ $# -gt 0 ] && shift || true

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
