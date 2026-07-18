#!/bin/sh -eu
# Regenerate the .workaholic/ OKF bundle indexes (see the okf SKILL.md).
#
# Writes the bundle-root .workaholic/index.md (frontmatter: okf_version — the one
# index.md frontmatter the OKF spec permits) and a per-area index.md for the flat
# knowledge areas and trips/, deriving every entry from what exists on disk.
# stories/index.md (report-maintained) and the tickets/ tree (queue scripts and
# structure guards own it) are linked, never written.
#
# Ownership model for the flat knowledge areas (concerns, deployments, ...): the
# generated entry list lives inside a MARKED region
#   <!-- okf:generated:begin --> ... <!-- okf:generated:end -->
# This script owns the bytes between the markers; a human owns everything outside
# them. That is the fix for the defect where a full regenerate silently deleted a
# hand-written /ship rule and section: prose around the markers now survives
# verbatim. First-touch rules for an index that predates the markers:
#   * body is purely the old generated shape (only the H1 and `* [...]` bullets)
#     -> rewrite in the marked form (lossless migration; it keeps updating).
#   * body carries any hand-authored prose (extra headings, paragraphs)
#     -> preserve it verbatim and leave it untouched. A human opts back into
#        generation by adding the markers.
# Within the region, an entry's description is the entry file's `description:`
# frontmatter, falling back to the description the prior region already carried
# for that link — so a hand-written description survives instead of degrading to
# a bare link.
#
# A directory is listed only when git will carry it (>=1 tracked file). An empty,
# untracked, or ignored-only directory is not knowledge and a fresh clone would
# 404 on the link, so it is not indexed.
#
# Deterministic (LC_ALL=C ordering, no timestamps): same tree in, same bytes out,
# so repeated runs never dirty a clean working tree. Idempotence is NOT the same
# property as safety — this script is safe because it preserves what it does not
# own, not because it is deterministic.
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

BEGIN_MARK='<!-- okf:generated:begin -->'
END_MARK='<!-- okf:generated:end -->'

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

# Description carried by a prior generated entry line for a given basename, read
# from the existing index ("" when absent). A generated entry reads
# "* [Title](basename) - description"; this recovers the "description" part so a
# hand-written description survives a regenerate even when the entry file itself
# has no `description:` frontmatter.
prior_desc() {
  [ -f "$1" ] || return 0
  awk -v link="]($2)" '
    { i = index($0, link)
      if (i > 0) {
        rest = substr($0, i + length(link))
        if (substr(rest, 1, 3) == " - ") { print substr(rest, 4); exit }
      }
    }' "$1"
}

# One OKF index entry line for a document. $2 (optional) is the existing index
# file: when the entry file carries no `description:`, fall back to the one the
# prior generated region held for this link.
entry_line() {
  entry_file="$1"
  entry_old_index="${2:-}"
  entry_base=$(basename "$entry_file")
  entry_title=$(title_of "$entry_file")
  entry_desc=$(fm_field "$entry_file" description)
  if [ -z "$entry_desc" ] && [ -n "$entry_old_index" ]; then
    entry_desc=$(prior_desc "$entry_old_index" "$entry_base")
  fi
  if [ -n "$entry_desc" ]; then
    printf '* [%s](%s) - %s\n' "$entry_title" "$entry_base" "$entry_desc"
  else
    printf '* [%s](%s)\n' "$entry_title" "$entry_base"
  fi
}

# True when the directory will be carried by git — at least one tracked file
# under it. Empty / untracked / ignored-only directories fail this: a fresh clone
# would 404 on a link to them, so they are not indexed.
dir_is_tracked() {
  [ -n "$(git ls-files -- "$1" 2>/dev/null | head -n 1)" ]
}

# True when an index file is safe to (re)generate into the marked form: it does
# not exist yet, or its whole body is the old purely-generated shape (only the H1
# and `* [...]` bullets, no hand-authored prose). A body with any other line is
# hand-authored and must be preserved untouched.
index_is_pure_generated() {
  [ -f "$1" ] || return 0
  awk '
    /^[[:space:]]*$/ { next }
    /^# / { next }
    /^\* \[/ { next }
    { exit 1 }
  ' "$1"
}

# Emit the generated region for a flat area: one entry line per *.md file, then
# (blank-line separated) one link per tracked subdirectory. $2 is the existing
# index, threaded through for the description fallback.
build_region() {
  region_dir="$1"
  region_old_index="${2:-}"
  region=""
  region_files=$(find "$region_dir" -maxdepth 1 -name '*.md' -type f ! -name 'index.md' 2>/dev/null | LC_ALL=C sort)
  if [ -n "$region_files" ]; then
    for region_f in $region_files; do
      region="$region$(entry_line "$region_f" "$region_old_index")
"
    done
  fi
  region_subs=""
  region_dirs=$(find "$region_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort)
  for region_d in $region_dirs; do
    dir_is_tracked "$region_d" || continue
    region_sub=$(basename "$region_d")
    region_subs="$region_subs* [${region_sub}/](${region_sub}/)
"
  done
  if [ -n "$region_subs" ]; then
    region="$region
$region_subs"
  fi
  printf '%s' "$region"
}

# Replace the bytes between the markers in an existing marked index with the
# lines of a region file, preserving everything outside the markers verbatim.
splice_region() {
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v rf="$2" '
    $0 == b { print; while ((getline line < rf) > 0) print line; close(rf); skip=1; next }
    $0 == e { skip=0; print; next }
    skip { next }
    { print }
  ' "$1"
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
# The generated entry list lives inside a marked region so hand-written prose
# around it survives; the region carries only directories git will actually ship.
region_tmp=$(mktemp)
trap 'rm -f "$region_tmp"' EXIT
for area in concerns deployments release-notes specs terms; do
  dir="$ROOT/$area"
  [ -d "$dir" ] || continue
  index="$dir/index.md"
  region=$(build_region "$dir" "$index")

  if [ -f "$index" ] && grep -qF "$BEGIN_MARK" "$index" && grep -qF "$END_MARK" "$index"; then
    # Marked index: regenerate only inside the markers; preserve prose outside.
    printf '%s\n' "$region" > "$region_tmp"
    write_index "$index" "$(splice_region "$index" "$region_tmp")
"
  elif index_is_pure_generated "$index"; then
    # Fresh area, or a legacy purely-generated index: emit the marked form. The
    # migration is lossless — the old body held only the entries this reproduces.
    write_index "$index" "# ${area}

${BEGIN_MARK}
${region}
${END_MARK}
"
  else
    # Hand-authored index with no markers: preserve it verbatim, untouched. A
    # human adds the markers to opt this area's list back into generation.
    :
  fi
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

# --- Missions ------------------------------------------------------------------
# Two-area artifact (active/ and archive/, keyed off each mission's status by the
# mission scripts' living migration): one `## <area>` section per non-empty area,
# one entry per mission linking its mission.md, described by the frontmatter
# title. Legacy flat mission dirs (a pre-migration tree the mission scripts have
# not touched yet) are listed first, at the top level, so nothing disappears from
# the index before the migration runs.
if [ -d "$ROOT/missions" ]; then
  body="# missions
"
  flat=$(find "$ROOT/missions" -maxdepth 1 -mindepth 1 -type d ! -name active ! -name archive 2>/dev/null | LC_ALL=C sort)
  if [ -n "$flat" ]; then
    body="$body
"
    for d in $flat; do
      mission=$(basename "$d")
      if [ -f "$d/mission.md" ]; then
        desc=$(fm_field "$d/mission.md" title)
        if [ -n "$desc" ]; then
          body="$body* [${mission}](${mission}/mission.md) - ${desc}
"
        else
          body="$body* [${mission}](${mission}/mission.md)
"
        fi
      else
        body="$body* [${mission}/](${mission}/)
"
      fi
    done
  fi
  for area in active archive; do
    missions=$(find "$ROOT/missions/$area" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | LC_ALL=C sort)
    [ -n "$missions" ] || continue
    body="$body
## ${area}

"
    for d in $missions; do
      mission=$(basename "$d")
      if [ -f "$d/mission.md" ]; then
        desc=$(fm_field "$d/mission.md" title)
        if [ -n "$desc" ]; then
          body="$body* [${mission}](${area}/${mission}/mission.md) - ${desc}
"
        else
          body="$body* [${mission}](${area}/${mission}/mission.md)
"
        fi
      else
        body="$body* [${mission}/](${area}/${mission}/)
"
      fi
    done
  done
  write_index "$ROOT/missions/index.md" "$body"
fi

# --- Bundle root -----------------------------------------------------------------
root_body="---
okf_version: \"0.1\"
---

# Workaholic Knowledge Base

The development knowledge this project's workaholic workflows generate and maintain,
organized as an Open Knowledge Format bundle. Enter any area through its index.

"
for area in tickets stories missions concerns deployments release-notes specs terms trips; do
  dir="$ROOT/$area"
  [ -d "$dir" ] || continue
  case "$area" in
    tickets)       root_body="$root_body* [tickets/](tickets/) - implementation tickets (todo / archive / icebox queues)
" ;;
    stories)       root_body="$root_body* [stories](stories/index.md) - branch development narratives (PR descriptions and historical record)
" ;;
    missions)      root_body="$root_body* [missions](missions/index.md) - long-lived goals spanning many tickets, with acceptance progress and an append-only changelog
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
