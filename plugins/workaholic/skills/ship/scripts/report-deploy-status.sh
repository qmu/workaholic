#!/bin/sh -eu
# The repository-level DEPLOY STATUS: what is waiting to deploy right now, per target,
# and whether anything about it needs a human. Pure read — it writes no file, commits
# nothing, pushes nothing, and reaches no account.
#
#   report-deploy-status.sh [base]        # base defaults to main
#
# Output (one JSON line):
#   {"ok": true, "base": "main", "base_rev": "origin/main", "base_sha": "abcd1234",
#    "count": N, "digest": "<40-hex>", "actionable": <bool>,
#    "targets": [{"slug","title","environment","deploy_model","has_confirmation",
#                 "unreleased_count","since","since_reason","attribution",
#                 "latest_note","note_match","needs":["..."]}],
#    "mapping": <read-deployments.sh --mapping, spliced verbatim>}
#   {"ok": false, "reason": "not_a_git_repo"|"base_unresolvable"|..., "digest": ""}
#
# WHY THIS READS AND DOES NOT WRITE (the Open Decision on ticket
# `20260814064854-add-the-hourly-release-note-repo-routine`, resolved 2026-08-14 while
# driving it; the ask was "run /ship once per hour to update the release notes").
#
# A `## Deployment Plan` is a BRANCH's prospective section, drafted inside that unit's
# own pull request by whoever ships the unit (`workaholic:ship` §5 step 3). There is no
# unit-less WRITER for it that survives its own measurement:
#
#   (a) Refreshing a merged note on `main`. The plan's datum is the base sha, and for any
#       target that declares no `paths:` — the default, `attribution: whole_range`, and
#       what this repository's own `marketplace` record does — the refresh's OWN commit
#       increments `unreleased_count`. Each refresh therefore invalidates itself and the
#       next tick has something to write again: an hourly writer becomes a commit
#       treadmill, which is exactly what `draft-deploy-plan.sh`'s own header refuses when
#       it keeps a clock out of the section.
#   (b) Pushing the refresh into each open pull request's branch. Those branches are not
#       this routine's to write: a `work-*` branch under an active claim is pushed by
#       `archive.sh` and `heartbeat.sh` on the driving session's schedule, so an hourly
#       third writer races the claim protocol and a developer's own pushes for nothing.
#   (c) Running `/ship` itself hourly. `/ship` MERGES; an unattended hourly sweep with a
#       loose scope merges pull requests nobody expected, and giving `/ship` a unit-less
#       sweep mode is a second behaviour on one command.
#
# So the repository-scoped tick does the strongest thing a machine may honestly do to a
# document whose forward-looking half is a human's decision to act on: it CHECKS it and
# says what it found. The precedent is this repository's own `report/scripts/area-
# freshness.sh` — "it reports, it never writes" — adopted 2026-08-13 for the same class
# of problem. What is deliberately NOT delivered, rather than glossed: the release notes
# are not updated. That write is left to the operator, with (a)-(c) above as its input.
#
# THE DIGEST IS WHY AN IDLE TICK POSTS NOTHING. It is a hash of the SUBSTANTIVE per-target
# state — the fields a reader would act on — and deliberately NOT of the base sha, so a
# base that merely advanced does not read as news. A consumer posts the digest as a token
# and finds its own previous post by it (`workaholic:notify`, the stateless lookup), so
# the dedup needs no stored state anywhere.
#
# `needs[]` names, per target, what a human would have to do — never a forecast, only a
# fact already in the rows: `confirmation_method` (the target declares none, so `/ship`
# halts on it), `release` (commits are waiting), `note` (no release note has ever joined
# this target). An empty `needs` on every target is the quiet state.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BASE="${1:-main}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"ok": false, "reason": "not_a_git_repo", "digest": ""}' >&2
  exit 1
fi

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

ROWS="${TMPDIR:-/tmp}/wh-deploy-status.$$"
ERRS="${TMPDIR:-/tmp}/wh-deploy-status-err.$$"
SUBST="${ROWS}.subst"
trap 'rm -f "$ROWS" "$ERRS" "$SUBST"' EXIT INT TERM

if ! sh "${SCRIPT_DIR}/read-deploy-state.sh" --rows "$BASE" >"$ROWS" 2>"$ERRS"; then
  reason=$(head -n 1 "$ERRS" | tr -d '\n')
  [ -n "$reason" ] || reason=base_unresolvable
  printf '{"ok": false, "reason": "%s", "digest": ""}\n' "$(json_escape "$reason")"
  exit 0
fi

BASE_LINE=$(sh "${SCRIPT_DIR}/read-deploy-state.sh" --base-rev "$BASE")
US=$(printf '\037')
BASE_REV=$(printf '%s' "$BASE_LINE" | cut -d"$US" -f1)
BASE_SHA=$(printf '%s' "$BASE_LINE" | cut -d"$US" -f2)

: > "$SUBST"
out=""
sep=""
count=0
actionable=false

while IFS="$US" read -r slug title environment model model_reason \
  conf_method conf_command has_conf attribution since since_reason n note_path note_match; do
  [ -n "$slug" ] || continue
  count=$((count + 1))

  needs=""
  nsep=""
  if [ "$has_conf" != true ]; then
    needs="${needs}${nsep}\"confirmation_method\""; nsep=", "
  fi
  if [ "${n:-0}" -gt 0 ] 2>/dev/null; then
    needs="${needs}${nsep}\"release\""; nsep=", "
  fi
  if [ -z "$note_path" ]; then
    needs="${needs}${nsep}\"note\""; nsep=", "
  fi
  [ -z "$needs" ] || actionable=true

  # The digest's input: what a reader would ACT on. The base sha is absent on purpose —
  # a base that merely advanced is not news, and hashing it would make every tick news.
  printf '%s|%s|%s|%s|%s|%s\n' "$slug" "$has_conf" "${n:-0}" "$since" "$note_path" "$note_match" >> "$SUBST"

  out="${out}${sep}{\"slug\": \"$(json_escape "$slug")\", \"title\": \"$(json_escape "$title")\", \"environment\": \"$(json_escape "$environment")\", \"deploy_model\": \"$(json_escape "$model")\", \"deploy_model_reason\": \"$(json_escape "$model_reason")\", \"confirmation_method\": \"$(json_escape "$conf_method")\", \"has_confirmation\": ${has_conf:-false}, \"unreleased_count\": ${n:-0}, \"since\": \"$(json_escape "$since")\", \"since_reason\": \"$(json_escape "$since_reason")\", \"attribution\": \"$(json_escape "$attribution")\", \"latest_note\": \"$(json_escape "$note_path")\", \"note_match\": \"$(json_escape "$note_match")\", \"needs\": [${needs}]}"
  sep=", "
done < "$ROWS"

# git is the one hashing tool every caller of this plugin already has, and it is
# deterministic across platforms in a way `cksum`'s 32 bits are not.
DIGEST=$(git hash-object --stdin < "$SUBST")

# The target<->environment mapping rides this read rather than a second command
# (2026-08-17): the per-target axis is the same question this report already
# answers, and `read-deployments.sh` stays the single parser of that frontmatter.
# It is spliced verbatim and deliberately NOT hashed into the digest — the digest
# is "what a reader would act on right now", and a mapping that only restates
# what the records declare does not become news because a record was reformatted.
MAPPING=$(sh "${SCRIPT_DIR}/read-deployments.sh" --mapping 2>/dev/null \
  || printf '{"ok": false, "reason": "mapping_unreadable"}')

printf '{"ok": true, "base": "%s", "base_rev": "%s", "base_sha": "%s", "count": %d, "digest": "%s", "actionable": %s, "targets": [%s], "mapping": %s}\n' \
  "$(json_escape "$BASE")" "$(json_escape "$BASE_REV")" "$(json_escape "$BASE_SHA")" \
  "$count" "$DIGEST" "$actionable" "$out" "$MAPPING"
