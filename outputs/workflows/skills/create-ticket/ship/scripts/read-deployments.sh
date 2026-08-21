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
#   read-deployments.sh --mapping    # the target<->environment mapping + named gaps
#   read-deployments.sh --scaffold [slug]  # a BLANK record for a human to fill (stdout only)
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
#
# --mapping IS A READ, AND THE AREA'S RULE IS WHY (2026-08-17, mission
# `correct-the-release-note-automation-to-its-intended-design`). The ask was
# "derive which deploy targets exist and which software environment each
# corresponds to". A HUMAN writes a deployment record; `/ship` is the only live
# reader and never a writer (`.workaholic/deployments/README.md`), so deriving
# the mapping means: report what is DECLARED, mark what was DEFAULTED, name what
# is MISSING, and hand a human a blank scaffold — never synthesise a populated
# record from the repository's shape. A generated record would make the next
# `/ship` gate on a machine's guess about how production is reached, which is
# the one thing the confirmation gate exists to prevent. The precedent is
# `story/scripts/area-freshness.sh`: it reports, it never writes.
#
# Every mapping field therefore carries a `source`:
#   declared        - the record states it
#   defaulted       - the record is silent and a documented default applies
#   body_declaration/frontmatter/unresolved - deploy_model's existing vocabulary
#
# Gaps are named, never rendered as an empty result:
#   no_targets                  - no `deployments/` record at all
#   environment_undeclared      - a target whose environment is unstated
#   path_attribution_undeclared - a target with no `paths:`, so it claims the
#                                 whole range and counts every commit as its own
#   unmatched_component         - a top-level component matching no target's
#                                 `paths:` (reported only once SOME target
#                                 declares `paths:`; with none declared the
#                                 whole-range default already covers everything
#                                 and a component gap would be noise)

set -eu

MODE=all
WANT_SLUG=""
WANT_SECTION=""
case "${1:-}" in
  --slugs) MODE=slugs ;;
  --mapping) MODE=mapping ;;
  --scaffold)
    MODE=scaffold
    WANT_SLUG="${2:-<target-slug>}"
    ;;
  --section)
    MODE=section
    WANT_SLUG="${2:-}"
    WANT_SECTION="${3:-}"
    [ -n "$WANT_SLUG" ] && [ -n "$WANT_SECTION" ] || { echo '{"reason": "usage"}' >&2; exit 1; }
    ;;
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

# The scaffold is a BLANK template printed to stdout. It writes no file on
# purpose: the human who authors it decides where production is and how it is
# confirmed, and a machine that wrote the file would be answering that for them.
if [ "$MODE" = scaffold ]; then
  cat <<SCAFFOLD
---
type: Deployment
title: <human-readable name of this deployable component>
environment: <production | staging | preview | ... — the software environment this target IS>
confirmation_method: <http | command | other — how a machine can prove the deploy landed>
url:
endpoint:
command: <the non-secret one-liner that confirms it, e.g. \`curl -fsS <endpoint>\`>
deploy_model: <deploy-on-merge | deploy-from-branch — does merging to the base deploy this?>
paths: [<glob>, <glob>]
---

# ${WANT_SLUG}

<!-- What is this target, in one paragraph? Which component of the tree ships here? -->

## Procedure

<!-- Copy-paste executable steps that perform the release. Written for a human who
     has never done it. If a step needs a credential, name the credential — never
     paste it. -->

## Confirmation

<!-- The executable proof that the deploy succeeded, and what its output looks like
     when it did. \`/ship\` gates on this section: a target with no confirmation
     method halts the flow rather than shipping unverified. Say what command runs
     and what it returns — an assertion that it was checked is not evidence. -->
SCAFFOLD
  exit 0
fi

if [ ! -d "$dir" ]; then
  case "$MODE" in
    slugs) exit 0 ;;
    one) printf '{}\n'; exit 0 ;;
    mapping)
      printf '{"ok": true, "count": 0, "targets": [], "gaps": [{"kind": "no_targets", "target": "", "detail": "no .workaholic/deployments/ directory - run read-deployments.sh --scaffold <slug> and fill it in"}], "scaffold_available": true}\n'
      exit 0
      ;;
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

# --section prints ONE section's raw body, unescaped, for a caller that wants to
# QUOTE the human's authored text rather than re-parse the record (2026-08-17).
# It exists so `draft-release-note.sh` can quote `## Procedure` / `## Confirmation`
# verbatim while this file stays the single parser of that frontmatter and those
# sections: a second reader would be exactly the fork the area's rule forbids.
# Missing target or missing section prints nothing and exits 0 — "the record does
# not declare this" is a state the caller renders, not an error.
if [ "$MODE" = section ]; then
  file="${dir}/${WANT_SLUG}.md"
  [ -f "$file" ] || exit 0
  read_section "$file" "$WANT_SECTION"
  exit 0
fi

if [ "$MODE" = mapping ]; then
  targets=""
  gaps=""
  tsep=""
  gsep=""
  count=0
  any_paths=0
  declared_globs=""

  for file in "$dir"/*.md; do
    [ -e "$file" ] || continue
    base=$(basename "$file")
    [ "$base" = "README.md" ] && continue
    [ "$base" = "index.md" ] && continue

    build_entry "$file"
    count=$((count + 1))
    slug=$(basename "$file" .md)

    environment=$(read_field "$file" "environment")
    if [ -n "$environment" ]; then
      env_source=declared
    else
      env_source=undeclared
      gaps="${gaps}${gsep}{\"kind\": \"environment_undeclared\", \"target\": \"$slug\", \"detail\": \"the record states no environment: - a target with no environment cannot be mapped to one\"}"
      gsep=", "
    fi

    deploy_model=$(read_field "$file" "deploy_model")
    if [ -n "$deploy_model" ]; then
      dm_source=frontmatter
    else
      deploy_model=$(awk 'match($0, /deploy-(on-merge|from-branch)/) { print substr($0, RSTART, RLENGTH); exit }' "$file")
      if [ -n "$deploy_model" ]; then dm_source=body_declaration; else dm_source=unresolved; fi
    fi

    paths_raw=$(read_field "$file" "paths")
    paths_items=$(printf '%s' "$paths_raw" | tr -d '[]' | tr ',' ' ' \
      | awk '{ for (i = 1; i <= NF; i++) printf "%s\"%s\"", (i > 1 ? "," : ""), $i }')
    if [ -n "$paths_items" ]; then
      paths_source=declared
      attribution=explicit
      any_paths=1
      declared_globs="$declared_globs $(printf '%s' "$paths_raw" | tr -d '[]' | tr ',' ' ')"
    else
      paths_source=defaulted
      attribution=whole_range
      gaps="${gaps}${gsep}{\"kind\": \"path_attribution_undeclared\", \"target\": \"$slug\", \"detail\": \"no paths: - this target claims the whole range, so every commit on the base counts as unreleased for it, including a commit that only writes its own note\"}"
      gsep=", "
    fi

    confirmation_method=$(read_field "$file" "confirmation_method")
    if [ -n "$confirmation_method" ]; then cm_source=declared; else cm_source=undeclared; fi

    slug_json=$(printf '%s' "$slug" | escape_json)
    env_json=$(printf '%s' "$environment" | escape_json)
    dm_json=$(printf '%s' "$deploy_model" | escape_json)
    cm_json=$(printf '%s' "$confirmation_method" | escape_json)

    targets="${targets}${tsep}{\"slug\":$slug_json,\"environment\":{\"value\":$env_json,\"source\":\"$env_source\"},\"deploy_model\":{\"value\":$dm_json,\"source\":\"$dm_source\"},\"paths\":{\"value\":[$paths_items],\"source\":\"$paths_source\",\"attribution\":\"$attribution\"},\"confirmation_method\":{\"value\":$cm_json,\"source\":\"$cm_source\"},\"has_confirmation\":$ENTRY_HAS_CONF}"
    tsep=", "
  done

  if [ "$count" -eq 0 ]; then
    gaps="{\"kind\": \"no_targets\", \"target\": \"\", \"detail\": \".workaholic/deployments/ holds no target record - run read-deployments.sh --scaffold <slug> and fill it in\"}"
  fi

  # A component gap is only meaningful once SOME target has claimed a subtree.
  # With every target on the whole-range default the tree is covered by
  # definition, and reporting each directory as unmatched would be noise.
  if [ "$any_paths" -eq 1 ]; then
    # `set -f` matters: the declared values ARE globs (`api/**`), so an unquoted
    # expansion of them in a `for` list would be pathname-expanded against the
    # working directory and the comparison would run against whatever files
    # happened to match. Compare the declared text, never its expansion.
    set -f
    for comp in $(git -C "$root" ls-files 2>/dev/null | awk -F/ 'NF > 1 { print $1 }' | sort -u); do
      case "$comp" in .*) continue ;; esac
      matched=0
      for glob in $declared_globs; do
        prefix=${glob%%[*?]*}
        prefix=${prefix%%/}
        [ -n "$prefix" ] || continue
        case "$comp/" in "${prefix%/}"/*) matched=1 ;; esac
        [ "$comp" = "${prefix%/}" ] && matched=1
      done
      if [ "$matched" -eq 0 ]; then
        gaps="${gaps}${gsep}{\"kind\": \"unmatched_component\", \"target\": \"$comp\", \"detail\": \"this top-level component matches no target's paths: - either it ships nowhere, or a target has not claimed it\"}"
        gsep=", "
      fi
    done
    set +f
  fi

  printf '{"ok": true, "count": %d, "targets": [%s], "gaps": [%s], "scaffold_available": true}\n' \
    "$count" "$targets" "$gaps"
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
