#!/bin/bash
# List all carry-over files under .workaholic/concerns/ with status: active.
# Output: JSON array of {path, kind, status, origin_pr, origin_pr_url,
#                       origin_branch, origin_commit, paired_slug,
#                       housekeeping_ticket_emitted, body}
#
# Used by /report to feed the work:carryover-judge subagent.

set -e

dir=".workaholic/concerns"

if [[ ! -d "$dir" ]]; then
  echo "[]"
  exit 0
fi

# Read a frontmatter field from a file. Strips surrounding whitespace.
read_field() {
  local file="$1"
  local field="$2"
  awk -v f="$field" '
    /^---$/ { c++; next }
    c==1 && $0 ~ "^"f":" {
      sub("^"f":[[:space:]]*", "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$file"
}

# Read the body (everything after the second ---), trimming leading dash.
read_body() {
  local file="$1"
  awk '
    /^---$/ { c++; next }
    c>=2 {
      sub(/^- /, "")
      print
    }
  ' "$file" | sed '/^$/d' | head -c 4000
}

# JSON-escape a string.
escape_json() {
  python3 -c 'import json, sys; sys.stdout.write(json.dumps(sys.stdin.read()))' 2>/dev/null \
    || node -e 'process.stdout.write(JSON.stringify(require("fs").readFileSync(0,"utf8")))' 2>/dev/null \
    || perl -e 'use JSON::PP; print encode_json(do { local $/; <STDIN> })'
}

first=1
echo -n "["
for file in "$dir"/*.md; do
  [[ -e "$file" ]] || continue
  [[ "$(basename "$file")" == "README.md" ]] && continue

  status=$(read_field "$file" "status")
  [[ "$status" != "active" ]] && continue

  kind=$(read_field "$file" "kind")
  origin_pr=$(read_field "$file" "origin_pr")
  origin_pr_url=$(read_field "$file" "origin_pr_url")
  origin_branch=$(read_field "$file" "origin_branch")
  origin_commit=$(read_field "$file" "origin_commit")
  paired_slug=$(read_field "$file" "paired_slug")
  housekeeping=$(read_field "$file" "housekeeping_ticket_emitted")
  body=$(read_body "$file")

  body_json=$(printf '%s' "$body" | escape_json)
  path_json=$(printf '%s' "$file" | escape_json)
  kind_json=$(printf '%s' "$kind" | escape_json)
  url_json=$(printf '%s' "$origin_pr_url" | escape_json)
  branch_json=$(printf '%s' "$origin_branch" | escape_json)
  commit_json=$(printf '%s' "$origin_commit" | escape_json)
  paired_json=$(printf '%s' "$paired_slug" | escape_json)

  if [[ $first -eq 0 ]]; then
    echo -n ","
  fi
  first=0
  echo -n "{"
  echo -n "\"path\":$path_json,"
  echo -n "\"kind\":$kind_json,"
  echo -n "\"status\":\"active\","
  echo -n "\"origin_pr\":${origin_pr:-0},"
  echo -n "\"origin_pr_url\":$url_json,"
  echo -n "\"origin_branch\":$branch_json,"
  echo -n "\"origin_commit\":$commit_json,"
  echo -n "\"paired_slug\":$paired_json,"
  echo -n "\"housekeeping_ticket_emitted\":${housekeeping:-false},"
  echo -n "\"body\":$body_json"
  echo -n "}"
done
echo "]"
