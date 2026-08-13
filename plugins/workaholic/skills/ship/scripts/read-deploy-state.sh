#!/bin/sh -eu
# The deployment-plan CONSOLIDATION: per `Deployments` target, everything the
# drafting phase needs to say what is waiting to deploy and how it is verified.
#
#   read-deploy-state.sh [base]          # base defaults to main
#   read-deploy-state.sh --rows [base]   # one \037-separated line per target
#   read-deploy-state.sh --base-rev [base]  # "<base_rev>\037<short-sha>", the plan's datum
#
# `--exclude-note <path>` (before [base]) drops one release note from the
# note/target join — the plan writer passes the note it is writing so a note
# never becomes its own "latest note", which would never settle.
#
# Output (one JSON line):
#   {"ok": true, "base": "main", "base_rev": "origin/main", "count": N,
#    "reason": "",
#    "targets": [
#      {"slug": "...",
#       "target": { ...verbatim from read-deployments.sh --slug ... },
#       "latest_note": {path, branch, released_at, targets} | null,
#       "note_match": "declared" | "recency" | "none",
#       "attribution": "declared_paths" | "whole_range",
#       "since": "<sha>", "since_reason": "...",
#       "unreleased_count": N, "commits": [{"sha", "subject"}]}
#    ]}
#   {"ok": false, "reason": "base_unresolvable" | "not_a_git_repo"}
#
# `--rows` prints the same per-target state as one line each, in a fixed field
# order, for a POSIX-sh caller that must not grow a JSON parser:
#   slug, title, environment, deploy_model, deploy_model_reason,
#   confirmation_method, command, has_confirmation, attribution, since,
#   since_reason, unreleased_count, latest_note_path, note_match
# Fields are separated by \037 (US), NOT by tab: tab is an IFS *whitespace*
# character, so `read -r` collapses two adjacent tabs into one delimiter and
# silently shifts every later field whenever an optional value (an unresolvable
# `since`, an absent `command`) comes back empty. \037 is the separator
# survey-state.sh already uses for its `%x1f` git format.
# It prints nothing and exits 3 on a refusal, so a writer reading rows can tell
# "unreadable base" from "no targets" and skip rather than half-write.
#
# IT IS A PURE READ. It writes nothing, checks nothing out, and never touches a
# branch: the point of this unit is that an unattended tick can run it against
# the base safely. The prose belongs to the plan writer; a reader that also
# wrote would be the seam where "keep it up to date" quietly becomes "rewrite
# it every tick".
#
# IT COMPOSES THE EXISTING READERS AND PARSES NO FRONTMATTER OF ITS OWN.
# `read-deployments.sh` owns the deployment contract (its `--slugs` / `--slug`
# modes exist for exactly this) and `read-release-notes.sh` owns note
# frontmatter. Their JSON is spliced verbatim, so this script cannot disagree
# with the gate that acts on the same records.
#
# THE RANGE IS DERIVED THE WAY record-release-cut.sh DERIVES IT, and its origin
# is always reported. Four boundaries, most specific first:
#   prior_release   the newest .workaholic/releases/ record whose cut_sha resolves
#   latest_tag:<t>  the newest tag reachable from the base
#   full_history    no prior release and no tag - the range genuinely is everything
#   unresolvable    a truncated clone or an unreadable base; 0 commits, said plainly
# A range that quietly became empty is worse than one that says it could not be
# read, so `unresolvable` is a reported state and never a silent zero.
#
# ATTRIBUTION IS NAMED, NOT ASSUMED (the Open Decision this ticket carried).
# "The commit history for each deployment target" presumes a path->target map
# this repository has no data for. So: a target that declares `paths:` in its
# record gets its range filtered to those paths (`attribution: declared_paths`);
# a target that declares none gets the WHOLE unreleased range, reported as
# `attribution: whole_range`. That is honest with one target and visibly weak
# with several — which is the point of reporting it rather than picking it
# silently. Declaring `paths:` on the record is how a multi-target repository
# upgrades the answer, with no change here.

set -eu

MODE=json
EXCLUDE_NOTE=""
case "${1:-}" in
  --rows) MODE=rows; shift ;;
  --base-rev) MODE=base-rev; shift ;;
esac
if [ "${1:-}" = "--exclude-note" ]; then
  EXCLUDE_NOTE="${2:-}"
  shift 2
fi
BASE="${1:-main}"
LIST_MAX="${WORKAHOLIC_DEPLOY_STATE_COMMIT_MAX:-50}"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# A refusal is reported in BOTH modes, so a row-reading caller can never mistake
# "could not read the base" for "no targets": `--rows` prints nothing to stdout
# and exits 3, which is the writer's cue to report and skip rather than write a
# half-drafted plan.
fail() {
  if [ "$MODE" = rows ]; then
    printf '%s\n' "$1" >&2
    exit 3
  fi
  printf '{"ok": false, "reason": "%s", "base": "%s", "count": 0, "targets": []}\n' "$1" "$BASE"
  exit 0
}

if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo '{"ok": false, "reason": "not_a_git_repo", "count": 0, "targets": []}' >&2
  exit 1
fi

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

# One row field: a separator, tab or newline inside a value would break the
# record shape, so each collapses to a space rather than corrupting the parse.
field() {
  printf '%s' "$1" | tr '\037\t\n' '   '
}

# --- resolve the base --------------------------------------------------------
BASE_REV=""
for candidate in "origin/${BASE}" "$BASE"; do
  if git rev-parse --verify --quiet "${candidate}^{commit}" >/dev/null 2>&1; then
    BASE_REV="$candidate"
    break
  fi
done
[ -n "$BASE_REV" ] || fail base_unresolvable

if [ "$MODE" = base-rev ]; then
  printf '%s\037%s\n' "$BASE_REV" "$(git rev-parse --short=8 "$BASE_REV")"
  exit 0
fi

# --- resolve the previous release boundary (repo-level; the path filter is
# per-target) -----------------------------------------------------------------
SINCE=""
SINCE_REASON=""
RELEASES="${ROOT}/.workaholic/releases"
if [ -d "$RELEASES" ]; then
  for prior in $(find "$RELEASES" -maxdepth 1 -name 'release-*.md' -type f 2>/dev/null | LC_ALL=C sort -r); do
    prior_sha=$(sed -n 's/^cut_sha:[[:space:]]*//p' "$prior" | head -n 1)
    [ -n "$prior_sha" ] || continue
    prior_sha=$(git rev-parse --verify --quiet "${prior_sha}^{commit}" || true)
    [ -n "$prior_sha" ] || continue
    SINCE="$prior_sha"
    SINCE_REASON=prior_release
    break
  done
fi

if [ -z "$SINCE" ]; then
  tag=$(git describe --tags --abbrev=0 "$BASE_REV" 2>/dev/null || true)
  if [ -n "$tag" ]; then
    SINCE=$(git rev-parse --verify --quiet "${tag}^{commit}" || true)
    [ -n "$SINCE" ] && SINCE_REASON="latest_tag:${tag}"
  fi
fi

[ -n "$SINCE" ] || SINCE_REASON=full_history

if [ -n "$SINCE" ]; then
  RANGE="${SINCE}..${BASE_REV}"
else
  RANGE="$BASE_REV"
fi

# A shallow clone cannot walk to the boundary. Say so instead of reporting zero.
if ! git rev-list --count "$RANGE" >/dev/null 2>&1; then
  SINCE=""
  SINCE_REASON=unresolvable
  RANGE=""
fi

# --- per target --------------------------------------------------------------
count=0
out="["
first=1

for slug in $(sh "${SCRIPT_DIR}/read-deployments.sh" --slugs); do
  entry=$(sh "${SCRIPT_DIR}/read-deployments.sh" --slug "$slug")
  if [ -n "$EXCLUDE_NOTE" ]; then
    note=$(sh "${SCRIPT_DIR}/read-release-notes.sh" --latest-for "$slug" --exclude "$EXCLUDE_NOTE")
  else
    note=$(sh "${SCRIPT_DIR}/read-release-notes.sh" --latest-for "$slug")
  fi

  # `paths:` on the record is the only path->target data that exists.
  paths=$(printf '%s' "$entry" \
    | sed -n 's/.*"paths":\[\([^]]*\)\].*/\1/p' \
    | tr -d '"' | tr ',' ' ')
  if [ -n "$(printf '%s' "$paths" | tr -d '[:space:]')" ]; then
    attribution=declared_paths
  else
    attribution=whole_range
    paths=""
  fi

  t_since_reason="$SINCE_REASON"
  n=0
  commits=""
  c_sep=""
  if [ -n "$RANGE" ]; then
    if [ -n "$paths" ]; then
      # shellcheck disable=SC2086 - paths is a built argument list, deliberately split.
      n=$(git rev-list --count "$RANGE" -- $paths 2>/dev/null || echo 0)
      log=$(git log --no-merges --format='%h%x1f%s' --max-count="$LIST_MAX" "$RANGE" -- $paths 2>/dev/null || true)
    else
      n=$(git rev-list --count "$RANGE" 2>/dev/null || echo 0)
      log=$(git log --no-merges --format='%h%x1f%s' --max-count="$LIST_MAX" "$RANGE" 2>/dev/null || true)
    fi
    OLD_IFS=$IFS
    IFS='
'
    for line in $log; do
      sha=$(printf '%s' "$line" | cut -d"$(printf '\037')" -f1)
      subject=$(printf '%s' "$line" | cut -d"$(printf '\037')" -f2-)
      [ -n "$sha" ] || continue
      commits="${commits}${c_sep}{\"sha\": \"$(json_escape "$sha")\", \"subject\": \"$(json_escape "$subject")\"}"
      c_sep=", "
    done
    IFS=$OLD_IFS
  fi

  note_match=$(printf '%s' "$note" | sed -n 's/.*"match": "\([a-z]*\)".*/\1/p')
  note_obj=$(printf '%s' "$note" | sed -n 's/.*"note": \(.*\)}$/\1/p')
  [ -n "$note_obj" ] || note_obj=null

  paths_items=$(printf '%s' "$paths" \
    | awk '{ for (i = 1; i <= NF; i++) printf "%s\"%s\"", (i > 1 ? "," : ""), $i }')

  if [ "$MODE" = rows ]; then
    # One line per target, \037-separated, in the fixed order documented in the
    # header. The plan writer reads these instead of re-deriving anything, so
    # there is exactly one place the range and the attribution are decided.
    note_path=$(printf '%s' "$note" | sed -n 's/.*"path":"\([^"]*\)".*/\1/p')
    printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\n' \
      "$(field "$slug")" \
      "$(field "$(printf '%s' "$entry" | sed -n 's/.*"title":"\([^"]*\)".*/\1/p')")" \
      "$(field "$(printf '%s' "$entry" | sed -n 's/.*"environment":"\([^"]*\)".*/\1/p')")" \
      "$(field "$(printf '%s' "$entry" | sed -n 's/.*"deploy_model":"\([^"]*\)".*/\1/p')")" \
      "$(field "$(printf '%s' "$entry" | sed -n 's/.*"deploy_model_reason":"\([^"]*\)".*/\1/p')")" \
      "$(field "$(printf '%s' "$entry" | sed -n 's/.*"confirmation_method":"\([^"]*\)".*/\1/p')")" \
      "$(field "$(printf '%s' "$entry" | sed -n 's/.*"command":"\([^"]*\)".*/\1/p')")" \
      "$(field "$(printf '%s' "$entry" | sed -n 's/.*"has_confirmation":\([a-z]*\).*/\1/p')")" \
      "$(field "$attribution")" \
      "$(field "$SINCE")" \
      "$(field "$t_since_reason")" \
      "$n" \
      "$(field "$note_path")" \
      "$(field "$note_match")"
    count=$((count + 1))
    continue
  fi

  [ "$first" -eq 0 ] && out="$out,"
  first=0
  out="${out}{\"slug\": \"$(json_escape "$slug")\", \"target\": ${entry}, \"latest_note\": ${note_obj}, \"note_match\": \"${note_match}\", \"attribution\": \"${attribution}\", \"paths\": [${paths_items}], \"since\": \"$(json_escape "$SINCE")\", \"since_reason\": \"$(json_escape "$t_since_reason")\", \"unreleased_count\": ${n}, \"commits\": [${commits}]}"
  count=$((count + 1))
done

if [ "$MODE" = rows ]; then
  exit 0
fi

out="$out]"

reason=""
[ "$count" -eq 0 ] && reason="no_targets"

printf '{"ok": true, "base": "%s", "base_rev": "%s", "count": %d, "reason": "%s", "targets": %s}\n' \
  "$(json_escape "$BASE")" "$(json_escape "$BASE_REV")" "$count" "$reason" "$out"
