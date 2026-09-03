#!/bin/sh -eu
# Read .workaholic/release-notes/ — the ONE parser for release-note frontmatter.
#
# Usage:
#   read-release-notes.sh                    # every note, newest first
#   read-release-notes.sh --latest-for <slug> [--exclude <path-or-basename>]
#                                            # the newest note for one deploy target
#
# Output (list mode):
#   {"count": N, "notes": [{path, branch, released_at, targets: [...]}]}
# Output (--latest-for mode):
#   {"match": "declared" | "recency" | "none", "note": {...} | null}
#
# WHY THIS EXISTS (2026-08-13). The notes are the only knowledge area in
# `.workaholic/` with no reader: 96 files keyed by `branch:`, parsed nowhere.
# The deployment-plan consolidation needs "the latest note for this target", so
# rather than let a second script grow its own frontmatter parser, the area gets
# the reader it lacked — the same rule `read-deployments.sh` holds for targets.
#
# HOW A NOTE IS ATTRIBUTED TO A TARGET, and why the answer is reported. Notes
# are keyed by BRANCH, not by target, so until a note declares `targets:` there
# is no join to make. Two tiers, and the caller is always told which one it got:
#   declared - the note's `targets:` names the slug. Trustworthy.
#   recency  - no note declares it, so the newest note overall is returned. This
#              is a WEAK answer and says so; a reader that cannot tell the two
#              apart would treat an unrelated branch's note as this target's.
# `--exclude` drops one note from consideration. The plan writer passes the note
# it is WRITING: without it, a note that has just stamped its own `targets:`
# becomes its own "latest note for this target" on the next run, which is both
# useless to a reader and a churn source — the answer would flip from `recency`
# to `declared` on the second pass and the refresh would never settle.
#
# `none` when the area is empty. Newest is resolved by filename, which carries
# the branch's `work-YYYYMMDD-HHMMSS` stamp (and the `-2`, `-3` re-ship suffix
# sorts after its base note, which is the order those ships happened in).

set -eu

MODE=list
WANT_SLUG=""
EXCLUDE=""
case "${1:-}" in
  --latest-for)
    MODE=latest
    WANT_SLUG="${2:-}"
    [ -n "$WANT_SLUG" ] || { echo '{"reason": "usage"}' >&2; exit 1; }
    if [ "${3:-}" = "--exclude" ]; then
      EXCLUDE=$(basename "${4:-}")
    fi
    ;;
  "") ;;
  *) echo '{"reason": "usage"}' >&2; exit 1 ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
dir="${root}/.workaholic/release-notes"

if [ ! -d "$dir" ]; then
  case "$MODE" in
    latest) printf '{"match": "none", "note": null}\n' ;;
    *) printf '{"count": 0, "notes": []}\n' ;;
  esac
  exit 0
fi

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

escape_json() {
  # NON-ASCII STAYS RAW UTF-8 IN THE JSON STRING (2026-09-03, ticket
  # `20260903053345`). A field serialised here reaches a human-facing Markdown
  # heading through a `sed` extraction that never JSON-decodes, so an
  # ASCII-escaped title rendered as `\u30ea\u30dd...` in a drafted Deployment
  # Plan and had to be decoded by hand. Raw UTF-8 is still valid JSON, so every
  # JSON-parsing consumer is untouched; what changes is that the one consumer
  # which treats a string value as text now gets text.
  #
  # ALL THREE INTERPRETERS ARE PINNED, not only the branch that happens to run.
  # Measured on one input: python3 emitted `\uXXXX`, node emitted UTF-8, and
  # perl emitted mojibake - it re-encoded bytes it had never decoded - so the
  # serialisation depended on which interpreter was installed. They now agree
  # byte for byte on node's answer.
  python3 -c 'import json,sys; sys.stdout.buffer.write(json.dumps(sys.stdin.buffer.read().decode("utf-8","surrogateescape"), ensure_ascii=False).encode("utf-8","surrogateescape"))' 2>/dev/null \
    || node -e 'process.stdout.write(JSON.stringify(require("fs").readFileSync(0,"utf8")))' 2>/dev/null \
    || perl -e 'use JSON::PP; binmode(STDIN, ":encoding(UTF-8)"); binmode(STDOUT, ":raw"); print encode_json(do { local $/; <STDIN> })'
}

# Newest first. Filenames carry the branch timestamp, so a reverse sort is
# chronological; README.md and the OKF index.md are not notes.
note_files() {
  find "$dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null \
    | grep -v '/README\.md$' \
    | grep -v '/index\.md$' \
    | LC_ALL=C sort -r \
    || true
}

# Build NOTE_JSON and NOTE_TARGETS (space-separated) for one file.
build_note() {
  file="$1"
  rel=".workaholic/release-notes/$(basename "$file")"
  branch=$(read_field "$file" "branch")
  released_at=$(read_field "$file" "released_at")
  targets_raw=$(read_field "$file" "targets")

  NOTE_TARGETS=$(printf '%s' "$targets_raw" | tr -d '[]' | tr ',' ' ')
  targets_items=$(printf '%s' "$NOTE_TARGETS" \
    | awk '{ for (i = 1; i <= NF; i++) printf "%s\"%s\"", (i > 1 ? "," : ""), $i }')

  rel_json=$(printf '%s' "$rel" | escape_json)
  branch_json=$(printf '%s' "$branch" | escape_json)
  ra_json=$(printf '%s' "$released_at" | escape_json)

  NOTE_JSON="{\"path\":$rel_json,\"branch\":$branch_json,\"released_at\":$ra_json,\"targets\":[$targets_items]}"
}

if [ "$MODE" = latest ]; then
  newest=""
  for file in $(note_files); do
    [ -n "$EXCLUDE" ] && [ "$(basename "$file")" = "$EXCLUDE" ] && continue
    [ -n "$newest" ] || newest="$file"
    build_note "$file"
    for t in $NOTE_TARGETS; do
      if [ "$t" = "$WANT_SLUG" ]; then
        printf '{"match": "declared", "note": %s}\n' "$NOTE_JSON"
        exit 0
      fi
    done
  done
  if [ -z "$newest" ]; then
    printf '{"match": "none", "note": null}\n'
    exit 0
  fi
  build_note "$newest"
  printf '{"match": "recency", "note": %s}\n' "$NOTE_JSON"
  exit 0
fi

count=0
out="["
first=1
for file in $(note_files); do
  build_note "$file"
  [ "$first" -eq 0 ] && out="$out,"
  first=0
  out="$out$NOTE_JSON"
  count=$((count + 1))
done
out="$out]"

printf '{"count": %d, "notes": %s}\n' "$count" "$out"
