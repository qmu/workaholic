#!/bin/sh -eu
# Read the project's deployment contract from .workaholic/deployments/*.md.
#
# Each file describes one deployment target with two body sections:
#   ## Procedure    - how to deploy/release (copy-paste executable)
#   ## Confirmation  - the executable way to confirm the deploy succeeded
# plus frontmatter: title, environment, confirmation_method, and optional
# NON-SECRET locators url / endpoint / command.
#
# Usage:
#   read-deployments.sh              # every target, one JSON object
#   read-deployments.sh --slugs      # target slugs, one per line (no JSON)
#   read-deployments.sh --slug <s>   # one target's entry object, or {} when absent
#
# Output (default mode): a single JSON object consumed by the /ship
# deployment-confirmation gate:
#   {"has_confirmation": <bool>, "count": N,
#    "deployments": [ {slug, title, environment, confirmation_method,
#                      url, endpoint, command, deploy_model, deploy_model_reason,
#                      paths, has_confirmation, procedure, confirmation} ]}
# has_confirmation (top level) is true iff at least one entry carries a non-empty
# confirmation_method AND a non-empty ## Confirmation body; the per-entry
# has_confirmation says the same thing about that one target.
#
# THE SLUG IS THE TARGET'S IDENTITY (2026-08-13). It is the filename without
# `.md` — nothing else in the tree names a target, and the plan drafted by
# `read-deploy-state.sh` has to key on something stable. The two single-target
# modes exist so a composing script can splice this reader's own JSON rather
# than re-parsing the record: exactly one frontmatter parser for deployment
# targets, so a second reader cannot disagree with the gate.
#
# deploy_model answers "does the merge deploy this target?" — the question the
# drafting phase cannot re-derive on its own. It is read from an explicit
# `deploy_model:` field when present (`deploy_model_reason: frontmatter`),
# otherwise from the first `deploy-on-merge` / `deploy-from-branch` literal in
# the record's own prose (`body_declaration`), otherwise reported `unresolved`
# rather than guessed.
#
# paths is the OPTIONAL per-target path attribution: the globs this target
# ships. Absent means the target has not claimed a subtree, which is a fact the
# consolidation reports (`attribution: whole_range`) rather than papering over.

set -eu

MODE=all
WANT_SLUG=""
case "${1:-}" in
  --slugs) MODE=slugs ;;
  --slug)
    MODE=one
    WANT_SLUG="${2:-}"
    [ -n "$WANT_SLUG" ] || { echo '{"reason": "usage"}' >&2; exit 1; }
    ;;
  "") ;;
  *) echo '{"reason": "usage"}' >&2; exit 1 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
dir="${root}/.workaholic/deployments"

if [ ! -d "$dir" ]; then
  case "$MODE" in
    slugs) exit 0 ;;
    one) printf '{}\n'; exit 0 ;;
    *) printf '{"has_confirmation": false, "count": 0, "deployments": []}\n'; exit 0 ;;
  esac
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

# Build one target's JSON object into ENTRY, and set ENTRY_HAS_CONF.
build_entry() {
  file="$1"
  slug=$(basename "$file" .md)

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
    ENTRY_HAS_CONF=true
  else
    ENTRY_HAS_CONF=false
  fi

  deploy_model=$(read_field "$file" "deploy_model")
  if [ -n "$deploy_model" ]; then
    dm_reason=frontmatter
  else
    deploy_model=$(awk 'match($0, /deploy-(on-merge|from-branch)/) { print substr($0, RSTART, RLENGTH); exit }' "$file")
    if [ -n "$deploy_model" ]; then
      dm_reason=body_declaration
    else
      dm_reason=unresolved
    fi
  fi

  # paths: [a, b] / paths: a b -> ["a","b"]. Absent -> [].
  paths_raw=$(read_field "$file" "paths")
  paths_items=$(printf '%s' "$paths_raw" | tr -d '[]' | tr ',' ' ' \
    | awk '{ for (i = 1; i <= NF; i++) printf "%s\"%s\"", (i > 1 ? "," : ""), $i }')

  slug_json=$(printf '%s' "$slug" | escape_json)
  title_json=$(printf '%s' "$title" | escape_json)
  env_json=$(printf '%s' "$environment" | escape_json)
  cm_json=$(printf '%s' "$confirmation_method" | escape_json)
  url_json=$(printf '%s' "$url" | escape_json)
  ep_json=$(printf '%s' "$endpoint" | escape_json)
  cmd_json=$(printf '%s' "$cmd" | escape_json)
  dm_json=$(printf '%s' "$deploy_model" | escape_json)
  dmr_json=$(printf '%s' "$dm_reason" | escape_json)
  proc_json=$(printf '%s' "$procedure" | escape_json)
  conf_json=$(printf '%s' "$confirmation" | escape_json)

  ENTRY="{\"slug\":$slug_json,\"title\":$title_json,\"environment\":$env_json,\"confirmation_method\":$cm_json,\"url\":$url_json,\"endpoint\":$ep_json,\"command\":$cmd_json,\"deploy_model\":$dm_json,\"deploy_model_reason\":$dmr_json,\"paths\":[$paths_items],\"has_confirmation\":$ENTRY_HAS_CONF,\"procedure\":$proc_json,\"confirmation\":$conf_json}"
}

if [ "$MODE" = slugs ]; then
  for file in "$dir"/*.md; do
    [ -e "$file" ] || continue
    base=$(basename "$file")
    [ "$base" = "README.md" ] && continue
    [ "$base" = "index.md" ] && continue
    basename "$file" .md
  done
  exit 0
fi

if [ "$MODE" = one ]; then
  file="${dir}/${WANT_SLUG}.md"
  if [ ! -f "$file" ] || [ "$WANT_SLUG" = "README" ] || [ "$WANT_SLUG" = "index" ]; then
    printf '{}\n'
    exit 0
  fi
  build_entry "$file"
  printf '%s\n' "$ENTRY"
  exit 0
fi

has_confirmation=false
count=0
out="["
first=1

for file in "$dir"/*.md; do
  [ -e "$file" ] || continue
  base=$(basename "$file")
  [ "$base" = "README.md" ] && continue
  [ "$base" = "index.md" ] && continue

  build_entry "$file"
  [ "$ENTRY_HAS_CONF" = true ] && has_confirmation=true

  if [ "$first" -eq 0 ]; then
    out="$out,"
  fi
  first=0
  out="$out$ENTRY"

  count=$((count + 1))
done

out="$out]"
printf '{"has_confirmation": %s, "count": %d, "deployments": %s}\n' "$has_confirmation" "$count" "$out"
