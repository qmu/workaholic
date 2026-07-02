#!/bin/sh -eu
# Regenerate the .workaholic/ OKF bundle indexes (see the okf SKILL.md).
#
# Writes the bundle-root .workaholic/index.md (frontmatter: okf_version — the one
# index.md frontmatter the OKF spec permits) and a per-area index.md for the flat
# knowledge areas and trips/, deriving every entry from what exists on disk.
# stories/index.md (report-maintained) and the tickets/ tree (queue scripts and
# structure guards own it) are linked, never written. Deterministic: same tree in,
# same bytes out — so it is idempotent and safe before any commit.
#
# Each written index is git-staged so the caller's commit carries it. Exits 0 with
# {"refreshed": false} when there is no .workaholic/ directory.
#
# Usage: refresh-index.sh
# Output: JSON {refreshed, indexes}

set -eu

ROOT=".workaholic"
if [ ! -d "$ROOT" ]; then
  echo '{"refreshed": false, "reason": "no_workaholic_dir"}'
  exit 0
fi

# Read a frontmatter field's value from a file ("" when absent).
fm_field() {
  awk -v key="$2" '
    NR == 1 { if ($0 != "---") exit; next }
    /^---[ \t]*$/ { exit }
    substr($0, 1, length(key) + 1) == key ":" {
      val = substr($0, length(key) + 2)
      gsub(/^[ \t]+|[ \t]+$/, "", val)
      print val
      exit
    }' "$1"
}

# Title for an entry: frontmatter title, else first H1, else the filename.
title_of() {
  t=$(fm_field "$1" title)
  [ -n "$t" ] || t=$(sed -n 's/^# //p' "$1" | head -n 1)
  [ -n "$t" ] || t=$(basename "$1" .md)
  printf '%s' "$t"
}

# One OKF index entry line for a document.
entry_line() {
  entry_file="$1"
  entry_base=$(basename "$entry_file")
  entry_title=$(title_of "$entry_file")
  entry_desc=$(fm_field "$entry_file" description)
  if [ -n "$entry_desc" ]; then
    printf '* [%s](%s) - %s\n' "$entry_title" "$entry_base" "$entry_desc"
  else
    printf '* [%s](%s)\n' "$entry_title" "$entry_base"
  fi
}

WRITTEN=0

write_index() {
  index_path="$1"
  new_content="$2"
  if [ ! -f "$index_path" ] || [ "$(cat "$index_path")" != "$new_content" ]; then
    printf '%s' "$new_content" > "$index_path"
  fi
  git add "$index_path" 2>/dev/null || true
  WRITTEN=$((WRITTEN + 1))
}

# --- Flat knowledge areas ----------------------------------------------------
for area in concerns deployments release-notes specs terms; do
  dir="$ROOT/$area"
  [ -d "$dir" ] || continue
  body="# ${area}
"
  files=$(find "$dir" -maxdepth 1 -name '*.md' -type f ! -name 'index.md' 2>/dev/null | LC_ALL=C sort)
  if [ -n "$files" ]; then
    body="$body
"
    for f in $files; do
      body="$body$(entry_line "$f")
"
    done
  fi
  subdirs=$(find "$dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort)
  if [ -n "$subdirs" ]; then
    body="$body
"
    for d in $subdirs; do
      sub=$(basename "$d")
      body="$body* [${sub}/](${sub}/)
"
    done
  fi
  write_index "$dir/index.md" "$body"
done

# --- Trips ---------------------------------------------------------------------
if [ -d "$ROOT/trips" ]; then
  body="# trips
"
  trips=$(find "$ROOT/trips" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort)
  if [ -n "$trips" ]; then
    body="$body
"
    for d in $trips; do
      trip=$(basename "$d")
      if [ -f "$d/plan.md" ]; then
        desc=$(fm_field "$d/plan.md" instruction)
        if [ -n "$desc" ]; then
          body="$body* [${trip}](${trip}/plan.md) - ${desc}
"
        else
          body="$body* [${trip}](${trip}/plan.md)
"
        fi
      else
        body="$body* [${trip}/](${trip}/)
"
      fi
    done
  fi
  write_index "$ROOT/trips/index.md" "$body"
fi

# --- Bundle root -----------------------------------------------------------------
root_body="---
okf_version: \"0.1\"
---

# Workaholic Knowledge Base

The development knowledge this project's workaholic workflows generate and maintain,
organized as an Open Knowledge Format bundle. Enter any area through its index.

"
for area in tickets stories concerns deployments release-notes specs terms trips; do
  dir="$ROOT/$area"
  [ -d "$dir" ] || continue
  case "$area" in
    tickets)       root_body="$root_body* [tickets/](tickets/) - implementation tickets (todo / archive / icebox queues)
" ;;
    stories)       root_body="$root_body* [stories](stories/index.md) - branch development narratives (PR descriptions and historical record)
" ;;
    concerns)      root_body="$root_body* [concerns](concerns/index.md) - deferred concerns extracted at ship time, judged on later reports
" ;;
    deployments)   root_body="$root_body* [deployments](deployments/index.md) - deployment targets and confirmation methods
" ;;
    release-notes) root_body="$root_body* [release-notes](release-notes/index.md) - per-ship release records
" ;;
    specs)         root_body="$root_body* [specs](specs/index.md) - specification documents
" ;;
    terms)         root_body="$root_body* [terms](terms/index.md) - domain terminology
" ;;
    trips)         root_body="$root_body* [trips](trips/index.md) - trip rationale (directions, models, designs) per trip
" ;;
  esac
done
write_index "$ROOT/index.md" "$root_body"

echo "{\"refreshed\": true, \"indexes\": ${WRITTEN}}"
