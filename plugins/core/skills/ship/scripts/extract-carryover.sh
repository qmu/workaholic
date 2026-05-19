#!/bin/bash
# Extract concerns and ideas from a shipped story and persist them under
# .workaholic/concerns/. One file per bullet. Paired concern/idea items share
# a <pr-number>-<slug> prefix when section 6 and section 7 have equal counts.
#
# Usage: extract-carryover.sh <branch> <pr-number> <pr-url>
#
# Output: single JSON line summarizing what was extracted.

set -e

branch="$1"
pr_number="$2"
pr_url="$3"

if [[ -z "$branch" || -z "$pr_number" || -z "$pr_url" ]]; then
  echo '{"status":"error","reason":"missing_args","extracted":0}'
  exit 1
fi

story_file=".workaholic/stories/${branch}.md"

if [[ ! -f "$story_file" ]]; then
  echo "{\"status\":\"skipped\",\"reason\":\"no_story_file\",\"path\":\"$story_file\",\"extracted\":0}"
  exit 0
fi

mkdir -p .workaholic/concerns

origin_commit=$(git rev-parse --short HEAD)
created_at=$(date -Iseconds)

# Extract bullets from a numbered section. Each bullet must start with "- "
# at column 0; blank lines and other text are ignored. Multi-paragraph
# bullets are not supported (consistent with how stories are written).
extract_bullets() {
  local section_num="$1"
  awk -v num="$section_num" '
    $0 ~ "^## "num"\\. " { capture=1; next }
    capture && /^## [0-9]+\. / { exit }
    capture && /^- / { print substr($0, 3) }
  ' "$story_file"
}

# Derive a kebab-case slug from a bullet body. Strips backticks, links,
# punctuation; takes the first ~6 meaningful words; caps length at 60.
slugify() {
  echo "$1" \
    | sed -E 's/\[([^]]+)\]\([^)]+\)/\1/g' \
    | sed -E 's/`([^`]+)`/\1/g' \
    | sed -E 's/\(see [^)]+\)//g' \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9 ]/ /g' \
    | awk '{for(i=1;i<=6 && i<=NF;i++) printf "%s%s",$i,(i<6 && i<NF?"-":"")}' \
    | sed 's/-\+/-/g' \
    | sed 's/^-//; s/-$//' \
    | cut -c1-60
}

write_file() {
  local kind="$1"
  local slug_base="$2"   # e.g. 42-pathspec-modern-git
  local paired_slug="$3" # empty or same as slug_base
  local body="$4"

  local path=".workaholic/concerns/${slug_base}-${kind}.md"

  if [[ -e "$path" ]]; then
    return 0
  fi

  {
    echo "---"
    echo "kind: ${kind}"
    echo "origin_pr: ${pr_number}"
    echo "origin_pr_url: ${pr_url}"
    echo "origin_branch: ${branch}"
    echo "origin_commit: ${origin_commit}"
    echo "created_at: ${created_at}"
    echo "status: active"
    echo "resolved_by_pr:"
    echo "resolved_by_commit:"
    if [[ -n "$paired_slug" ]]; then
      echo "paired_slug: ${paired_slug}"
    else
      echo "paired_slug:"
    fi
    echo "housekeeping_ticket_emitted: false"
    echo "---"
    echo
    echo "- ${body}"
  } > "$path"

  echo "$path"
}

# Read both sections into arrays.
mapfile -t concerns < <(extract_bullets 6 | grep -v -i '^none$' || true)
mapfile -t ideas    < <(extract_bullets 7 | grep -v -i '^none$' || true)

concern_count=${#concerns[@]}
idea_count=${#ideas[@]}

# Determine whether we can pair items by position.
paired=0
if [[ "$concern_count" -gt 0 && "$concern_count" -eq "$idea_count" ]]; then
  paired=1
fi

written=()

i=0
while [[ $i -lt $concern_count ]]; do
  body="${concerns[$i]}"
  slug=$(slugify "$body")
  if [[ -z "$slug" ]]; then
    slug="item-$((i+1))"
  fi
  slug_base="${pr_number}-${slug}"
  pair=""
  if [[ $paired -eq 1 ]]; then
    pair="$slug_base"
  fi
  out=$(write_file "concern" "$slug_base" "$pair" "$body")
  if [[ -n "$out" ]]; then
    written+=("$out")
  fi
  i=$((i+1))
done

i=0
while [[ $i -lt $idea_count ]]; do
  body="${ideas[$i]}"
  if [[ $paired -eq 1 ]]; then
    # Reuse the slug from the paired concern.
    concern_body="${concerns[$i]}"
    slug=$(slugify "$concern_body")
    if [[ -z "$slug" ]]; then
      slug="item-$((i+1))"
    fi
    slug_base="${pr_number}-${slug}"
    pair="$slug_base"
  else
    slug=$(slugify "$body")
    if [[ -z "$slug" ]]; then
      slug="idea-$((i+1))"
    fi
    slug_base="${pr_number}-${slug}"
    pair=""
  fi
  out=$(write_file "idea" "$slug_base" "$pair" "$body")
  if [[ -n "$out" ]]; then
    written+=("$out")
  fi
  i=$((i+1))
done

total=${#written[@]}

if [[ $total -eq 0 ]]; then
  echo "{\"status\":\"ok\",\"extracted\":0,\"concerns\":${concern_count},\"ideas\":${idea_count},\"paired\":${paired},\"files\":[]}"
  exit 0
fi

# Build JSON list of paths.
files_json="["
for idx in "${!written[@]}"; do
  if [[ $idx -gt 0 ]]; then
    files_json+=","
  fi
  files_json+="\"${written[$idx]}\""
done
files_json+="]"

# Stage and commit the new files.
git add .workaholic/concerns/ >/dev/null
git commit -m "Carry over concerns from PR #${pr_number}" >/dev/null

echo "{\"status\":\"ok\",\"extracted\":${total},\"concerns\":${concern_count},\"ideas\":${idea_count},\"paired\":${paired},\"files\":${files_json}}"
