#!/bin/bash
# Emit housekeeping tickets for active carry-over items that have not yet
# been promoted. Coalesces paired concern+idea items (same paired_slug) into
# a single ticket. Skips items where housekeeping_ticket_emitted is already
# true. Deduplicates by slug against .workaholic/tickets/todo/.
#
# Output: JSON summary {emitted: N, skipped: N, paths: [...]}.

set -e

dir=".workaholic/concerns"
todo_dir=".workaholic/tickets/todo"

if [[ ! -d "$dir" ]]; then
  echo '{"emitted":0,"skipped":0,"paths":[]}'
  exit 0
fi

mkdir -p "$todo_dir"

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

read_body() {
  awk '
    /^---$/ { c++; next }
    c>=2 { print }
  ' "$1" | sed '/^$/d'
}

set_flag_true() {
  local file="$1"
  awk '
    /^---$/ { c++ }
    c==1 && /^housekeeping_ticket_emitted:/ { print "housekeeping_ticket_emitted: true"; next }
    { print }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

# Build a unique list of work units. A "unit" is either a single carry-over
# or a paired (concern + idea) pair keyed by paired_slug.
declare -A seen_paired
units=()  # each entry: "key|concern_path|idea_path"

for file in "$dir"/*.md; do
  [[ -e "$file" ]] || continue
  [[ "$(basename "$file")" == "README.md" ]] && continue

  status=$(read_field "$file" "status")
  [[ "$status" != "active" ]] && continue

  emitted=$(read_field "$file" "housekeeping_ticket_emitted")
  [[ "$emitted" == "true" ]] && continue

  kind=$(read_field "$file" "kind")
  paired_slug=$(read_field "$file" "paired_slug")

  if [[ -n "$paired_slug" ]]; then
    if [[ -n "${seen_paired[$paired_slug]:-}" ]]; then
      continue
    fi
    seen_paired[$paired_slug]=1
    concern_path="$dir/${paired_slug}-concern.md"
    idea_path="$dir/${paired_slug}-idea.md"
    [[ ! -f "$concern_path" ]] && concern_path=""
    [[ ! -f "$idea_path" ]] && idea_path=""
    units+=("$paired_slug|$concern_path|$idea_path")
  else
    base=$(basename "$file" .md)
    if [[ "$kind" == "concern" ]]; then
      units+=("$base|$file|")
    else
      units+=("$base||$file")
    fi
  fi
done

emitted_paths=()
skipped=0

author=$(git config user.email)
created_at=$(date -Iseconds)

slug_exists_in_todo() {
  local slug="$1"
  if compgen -G "$todo_dir/*-${slug}.md" > /dev/null; then
    return 0
  fi
  return 1
}

for unit in "${units[@]}"; do
  IFS='|' read -r key concern_path idea_path <<< "$unit"

  # Strip pr-number prefix from key to get a stable slug for dedup
  slug_for_dedup=$(echo "$key" | sed -E 's/^[0-9]+-//')

  if slug_exists_in_todo "$slug_for_dedup"; then
    skipped=$((skipped+1))
    # Still flip the flag so we don't re-check next run.
    [[ -n "$concern_path" ]] && set_flag_true "$concern_path"
    [[ -n "$idea_path" ]] && set_flag_true "$idea_path"
    continue
  fi

  ts=$(date +%Y%m%d%H%M%S)
  ticket_path="${todo_dir}/${ts}-${slug_for_dedup}.md"

  # Derive title and overview
  title="Address carried-over concern: ${slug_for_dedup}"
  origin_pr=""
  origin_pr_url=""

  concern_body=""
  if [[ -n "$concern_path" ]]; then
    concern_body=$(read_body "$concern_path")
    origin_pr=$(read_field "$concern_path" "origin_pr")
    origin_pr_url=$(read_field "$concern_path" "origin_pr_url")
  fi

  idea_body=""
  if [[ -n "$idea_path" ]]; then
    idea_body=$(read_body "$idea_path")
    [[ -z "$origin_pr" ]] && origin_pr=$(read_field "$idea_path" "origin_pr")
    [[ -z "$origin_pr_url" ]] && origin_pr_url=$(read_field "$idea_path" "origin_pr_url")
  fi

  {
    echo "---"
    echo "created_at: ${created_at}"
    echo "author: ${author}"
    echo "type: housekeeping"
    echo "layer: [Config]"
    echo "effort:"
    echo "commit_hash:"
    echo "category:"
    echo "depends_on:"
    echo "---"
    echo
    echo "# Housekeeping: ${slug_for_dedup}"
    echo
    echo "## Overview"
    echo
    echo "Carried over from PR #${origin_pr} (${origin_pr_url}). This concern/idea has survived at least one PR cycle without being addressed; the carry-over judge marked it \`still_active\` during the latest \`/report\`. Promote it into the work queue so it can be planned and resolved."
    echo
    if [[ -n "$concern_body" ]]; then
      echo "### Concern"
      echo
      echo "$concern_body"
      echo
    fi
    if [[ -n "$idea_body" ]]; then
      echo "### Idea"
      echo
      echo "$idea_body"
      echo
    fi
    echo "## Related Carry-Over Files"
    echo
    [[ -n "$concern_path" ]] && echo "- \`${concern_path}\`"
    [[ -n "$idea_path" ]] && echo "- \`${idea_path}\`"
    echo
    echo "## Implementation Steps"
    echo
    echo "1. Review the carry-over file(s) above and confirm the concern still applies."
    echo "2. If still applicable, implement the fix or improvement."
    echo "3. After landing, the next \`/report\` will run \`work:carryover-judge\` and mark the carry-over \`resolved\` once it detects the change."
  } > "$ticket_path"

  emitted_paths+=("$ticket_path")
  [[ -n "$concern_path" ]] && set_flag_true "$concern_path"
  [[ -n "$idea_path" ]] && set_flag_true "$idea_path"

  # Ensure unique timestamps if multiple emit in same second
  sleep 1 2>/dev/null || true
done

# Stage and commit if anything changed.
if [[ ${#emitted_paths[@]} -gt 0 || $skipped -gt 0 ]]; then
  git add "$dir" "$todo_dir" >/dev/null 2>&1 || true
  if ! git diff --cached --quiet; then
    git commit -m "Emit housekeeping tickets from active carry-overs" >/dev/null
  fi
fi

paths_json="["
for idx in "${!emitted_paths[@]}"; do
  if [[ $idx -gt 0 ]]; then
    paths_json+=","
  fi
  paths_json+="\"${emitted_paths[$idx]}\""
done
paths_json+="]"

echo "{\"emitted\":${#emitted_paths[@]},\"skipped\":${skipped},\"paths\":${paths_json}}"
