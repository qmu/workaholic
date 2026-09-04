#!/bin/sh -eu
# THE CORPUS'S OWN MISSION-SIZE DISTRIBUTION, in one pass.
#
#   size-distribution.sh [workaholic-root]
#
# Output: {"ok", "reason", "readable", "floor", "missions", "tickets_scanned",
#          "buckets": [{"bucket": "...", "count": N}],
#          "below_floor": [{"slug", "area", "total"}]}
#   Always exit 0 -- a degraded read is an answer, and its caller reports it rather than failing.
#
# WHY IT EXISTS (2026-09-03, ticket `20260903053713-report-the-mission-size-distribution.md`).
# Rule 2 of `rules/workaholic.md`, *What a Mission Must Be Able to Hold*, is a position about the
# CORPUS, and nothing in the loop could see the corpus: the distribution that produced the rule
# (94 missions, one at a single ticket, 21% at four or fewer, 52% at exactly seven or eight) was
# counted by hand, and without a reading the next report of the defect would be another hand
# count.
#
# IT IS EVIDENCE AND NEVER A GATE. Nothing is refused, ordered, closed, held or sorted on it. It
# names no strategy and asks nobody anything -- *how many* is news and *which* is a task -- and
# the one place a slug appears is `below_floor`, which exists for `layout-doctor.sh`'s advisory
# about a mission the forward-only floor left behind.
#
# ONE PASS, NOT ONE PER MISSION. `queue-size.sh` answers one mission by walking the whole ticket
# tree, so composing it per mission is 126 x 1335 file reads -- measured at over ten minutes here,
# in an audit CI runs on every merge. This walks the tree ONCE, reading each ticket's `mission:`
# relation through `read-relation.sh` -- still the single reader of that many-valued field, never
# a second frontmatter parser -- and tallies by slug. The counts are `queue-size.sh`'s `total`
# (todo + archive) by construction: the floor is about how a mission was CREATED, so a fully
# driven mission still satisfies it.
#
# THE FLOOR IS READ, NEVER SPELLED. `queue-size.sh` holds the one derivation of the number; it is
# asked for it against an empty root, which costs two `[ -d ]` tests and answers instantly.
#
# A MISSION WHOSE COUNT COULD NOT BE READ IS NAMED, not silently bucketed: an unreadable walk
# answers `readable: false` with a named reason and NULL counts, never an empty distribution,
# which means the opposite.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RELATION="${SCRIPT_DIR}/read-relation.sh"
QUEUE_SIZE="${SCRIPT_DIR}/queue-size.sh"

root="${1:-}"
if [ -z "$root" ]; then
  if repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    root="${repo_root}/.workaholic"
  else
    root=".workaholic"
  fi
fi

FLOOR=""
MISSIONS=null
SCANNED=null

emit() {
  printf '{"ok": %s, "reason": "%s", "readable": %s, "floor": %s, "missions": %s, "tickets_scanned": %s, "buckets": [%s], "below_floor": [%s]}\n' \
    "$1" "${2:-}" "$3" "${FLOOR:-null}" "$MISSIONS" "$SCANNED" "${4:-}" "${5:-}"
  exit 0
}

[ -f "$RELATION" ] || emit false no_relation_reader false
[ -f "$QUEUE_SIZE" ] || emit false no_queue_reader false

# The floor, from its one derivation, against an empty root so the read is free.
_empty=$(mktemp -d 2>/dev/null || printf '')
[ -n "$_empty" ] || emit false no_tmpdir false
FLOOR=$(sh "$QUEUE_SIZE" __floor_probe__ "$_empty" 2>/dev/null \
  | sed -n 's/.*"floor": \([0-9][0-9]*\).*/\1/p' || printf '')
rmdir "$_empty" 2>/dev/null || true
case "$FLOOR" in
  ''|*[!0-9]*) FLOOR=""; emit false floor_unreadable false ;;
esac

[ -d "${root}/missions" ] || emit false no_missions_area false

work=$(mktemp -d 2>/dev/null || printf '')
[ -n "$work" ] || emit false no_tmpdir false
trap 'rm -rf "$work"' EXIT INT TERM

# --- one pass over the ticket tree ------------------------------------------
: > "${work}/slugs"
scanned=0
if [ -d "${root}/tickets" ]; then
  find "${root}/tickets" -type f -name '*.md' 2>/dev/null | LC_ALL=C sort > "${work}/files"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    scanned=$((scanned + 1))
    sh "$RELATION" "$f" 2>/dev/null >> "${work}/slugs" || true
  done < "${work}/files"
fi
SCANNED=$scanned
LC_ALL=C sort "${work}/slugs" | uniq -c | awk '{c=$1; $1=""; sub(/^ /,""); print $0"\t"c}' > "${work}/counts"

# --- one row per mission ----------------------------------------------------
: > "${work}/rows"
missions=0
for area in active archive; do
  [ -d "${root}/missions/${area}" ] || continue
  for mdir in "${root}/missions/${area}"/*; do
    [ -d "$mdir" ] || continue
    slug=$(basename "$mdir")
    missions=$((missions + 1))
    n=$(awk -F'\t' -v s="$slug" '$1==s {print $2; found=1} END {if (!found) print 0}' "${work}/counts")
    printf '%s\t%s\t%s\n' "$slug" "$area" "$n" >> "${work}/rows"
  done
done
MISSIONS=$missions

# --- buckets ----------------------------------------------------------------
# Fixed, named ranges rather than a histogram of every integer: the reading is about the SHAPE of
# the corpus, and `0` and `1` are each their own fact (one is a plan-less mission, the other is
# what rule 1 says cannot exist).
buckets=""
sep=""
for b in 0 1 2-3 4-6 7-8 9+; do
  n=$(awk -F'\t' -v b="$b" '
    { t=$3+0
      if (b=="0" && t==0) c++
      else if (b=="1" && t==1) c++
      else if (b=="2-3" && t>=2 && t<=3) c++
      else if (b=="4-6" && t>=4 && t<=6) c++
      else if (b=="7-8" && t>=7 && t<=8) c++
      else if (b=="9+" && t>=9) c++ }
    END { print c+0 }' "${work}/rows")
  buckets="${buckets}${sep}{\"bucket\": \"${b}\", \"count\": ${n}}"
  sep=", "
done

below=""
sep=""
while IFS="$(printf '\t')" read -r slug area n; do
  [ -n "${slug:-}" ] || continue
  [ "$n" -lt "$FLOOR" ] || continue
  below="${below}${sep}{\"slug\": \"${slug}\", \"area\": \"${area}\", \"total\": ${n}}"
  sep=", "
done < "${work}/rows"

emit true "" true "$buckets" "$below"
