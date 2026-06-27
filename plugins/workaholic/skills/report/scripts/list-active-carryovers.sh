#!/bin/sh -eu
# List all carry-over files under .workaholic/concerns/ with status: active.
# Output: JSON array of {path, status, severity, origin_pr, origin_pr_url,
#                       origin_branch, origin_commit, body}
#
# Used by /report to feed the carry-over judge (general-purpose) subagent.

set -eu

dir=".workaholic/concerns"

if [ ! -d "$dir" ]; then
  echo "[]"
  exit 0
fi

# Read a frontmatter field from a file. Strips surrounding whitespace.
# ($1 = file, $2 = field) — POSIX functions have no `local`.
read_field() {
  awk -v f="$2" '
    /^---$/ { c++; next }
    c==1 && $0 ~ "^"f":" {
      sub("^"f":[[:space:]]*", "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$1"
}

# Read the body (everything after the second ---) verbatim. ($1 = file)
read_body() {
  awk '
    /^---$/ { c++; next }
    c>=2 { print }
  ' "$1" | head -c 4000
}

# JSON-escape a string.
escape_json() {
  python3 -c 'import json, sys; sys.stdout.write(json.dumps(sys.stdin.read()))' 2>/dev/null \
    || node -e 'process.stdout.write(JSON.stringify(require("fs").readFileSync(0,"utf8")))' 2>/dev/null \
    || perl -e 'use JSON::PP; print encode_json(do { local $/; <STDIN> })'
}

first=1
printf '%s' "["
for file in "$dir"/*.md; do
  [ -e "$file" ] || continue
  [ "$(basename "$file")" = "README.md" ] && continue

  status=$(read_field "$file" "status")
  [ "$status" != "active" ] && continue

  severity=$(read_field "$file" "severity")
  origin_pr=$(read_field "$file" "origin_pr")
  origin_pr_url=$(read_field "$file" "origin_pr_url")
  origin_branch=$(read_field "$file" "origin_branch")
  origin_commit=$(read_field "$file" "origin_commit")
  body=$(read_body "$file")

  body_json=$(printf '%s' "$body" | escape_json)
  path_json=$(printf '%s' "$file" | escape_json)
  severity_json=$(printf '%s' "${severity:-moderate}" | escape_json)
  url_json=$(printf '%s' "$origin_pr_url" | escape_json)
  branch_json=$(printf '%s' "$origin_branch" | escape_json)
  commit_json=$(printf '%s' "$origin_commit" | escape_json)

  if [ "$first" -eq 0 ]; then
    printf '%s' ","
  fi
  first=0
  printf '%s' "{"
  printf '%s' "\"path\":$path_json,"
  printf '%s' "\"status\":\"active\","
  printf '%s' "\"severity\":$severity_json,"
  printf '%s' "\"origin_pr\":${origin_pr:-0},"
  printf '%s' "\"origin_pr_url\":$url_json,"
  printf '%s' "\"origin_branch\":$branch_json,"
  printf '%s' "\"origin_commit\":$commit_json,"
  printf '%s' "\"body\":$body_json"
  printf '%s' "}"
done
echo "]"
