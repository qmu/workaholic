#!/bin/sh -eu
# Read the project's deployment contract from .workaholic/deployments/*.md.
#
# Each file describes one deployment target with two body sections:
#   ## Procedure    - how to deploy/release (copy-paste executable)
#   ## Confirmation  - the executable way to confirm the deploy succeeded
# plus frontmatter: title, environment, confirmation_method, and optional
# NON-SECRET locators url / endpoint / command.
#
# Usage: bash read-deployments.sh
# Output: a single JSON object consumed by the /ship deployment-confirmation gate:
#   {"has_confirmation": <bool>, "count": N,
#    "deployments": [ {title, environment, confirmation_method,
#                      url, endpoint, command, procedure, confirmation} ]}
# has_confirmation is true iff at least one entry carries a non-empty
# confirmation_method AND a non-empty ## Confirmation body.

set -eu

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
dir="${root}/.workaholic/deployments"

if [ ! -d "$dir" ]; then
  printf '{"has_confirmation": false, "count": 0, "deployments": []}\n'
  exit 0
fi

# Read a frontmatter field (between the first two --- lines). Strips whitespace.
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

# Read a "## <heading>" section body, up to the next "## " heading.
read_section() {
  awk -v h="## $2" '
    $0 == h { insec=1; next }
    /^## / && insec { insec=0 }
    insec { print }
  ' "$1" | head -c 4000
}

# JSON-escape stdin into a quoted JSON string.
escape_json() {
  python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))' 2>/dev/null \
    || node -e 'process.stdout.write(JSON.stringify(require("fs").readFileSync(0,"utf8")))' 2>/dev/null \
    || perl -e 'use JSON::PP; print encode_json(do { local $/; <STDIN> })'
}

has_confirmation=false
count=0
out="["
first=1

for file in "$dir"/*.md; do
  [ -e "$file" ] || continue
  [ "$(basename "$file")" = "README.md" ] && continue

  title=$(read_field "$file" "title")
  environment=$(read_field "$file" "environment")
  confirmation_method=$(read_field "$file" "confirmation_method")
  url=$(read_field "$file" "url")
  endpoint=$(read_field "$file" "endpoint")
  cmd=$(read_field "$file" "command")
  procedure=$(read_section "$file" "Procedure")
  confirmation=$(read_section "$file" "Confirmation")

  conf_trimmed=$(printf '%s' "$confirmation" | tr -d '[:space:]')
  if [ -n "$confirmation_method" ] && [ -n "$conf_trimmed" ]; then
    has_confirmation=true
  fi

  title_json=$(printf '%s' "$title" | escape_json)
  env_json=$(printf '%s' "$environment" | escape_json)
  cm_json=$(printf '%s' "$confirmation_method" | escape_json)
  url_json=$(printf '%s' "$url" | escape_json)
  ep_json=$(printf '%s' "$endpoint" | escape_json)
  cmd_json=$(printf '%s' "$cmd" | escape_json)
  proc_json=$(printf '%s' "$procedure" | escape_json)
  conf_json=$(printf '%s' "$confirmation" | escape_json)

  if [ "$first" -eq 0 ]; then
    out="$out,"
  fi
  first=0
  out="$out{\"title\":$title_json,\"environment\":$env_json,\"confirmation_method\":$cm_json,\"url\":$url_json,\"endpoint\":$ep_json,\"command\":$cmd_json,\"procedure\":$proc_json,\"confirmation\":$conf_json}"

  count=$((count + 1))
done

out="$out]"
printf '{"has_confirmation": %s, "count": %d, "deployments": %s}\n' "$has_confirmation" "$count" "$out"
