#!/bin/sh -eu
# THE DAILY PER-TARGET NOTE CADENCE — the generation half of the repository tick.
#
#   run-note-cadence.sh [--target <slug>] [--dry-run] [--force] [base]
#
# Output (one JSON line):
#   {"ok": true, "tz": "Asia/Tokyo", "day": "YYYY-MM-DD", "idle": <bool>,
#    "count": N, "wrote": N,
#    "targets": [{"slug","stage","stage_reason","due","reason","changed","written",
#                 "divergences":[...]}]}
#   {"ok": false, "reason": "gh_unavailable"|"no_targets"|...}
#
# ── ONE ROUTINE OR TWO (the Open Decision, ruled 2026-08-17) ──
#
# ONE. The generation rides the existing repository-scoped `[Prepare Release]` tick
# rather than adding a fourth routine, and the routine STAYS HOURLY.
#
#   (c) fold into `[Implement]` — ruled out by the scope reasoning of 2026-08-14
#       (issue #451): `[Implement]` is `developer`-scoped, so N developers would
#       each run a repository-scoped generator.
#   (b) a second repository-scoped routine beside the reader — its only gain over
#       riding the existing tick is a cron field, and its cost is a second
#       repository-scoped setup step for every consuming repository. The scope
#       exists to keep that number at one.
#   (a) replace the reader with a daily generator — CHOSEN, minus its stated cost.
#       The ticket's objection to (a) was that it "changes an hourly reader into a
#       daily writer and loses the hourly 'something needs your hand' signal". It
#       does not have to: the tick stays hourly and keeps reporting hourly, and the
#       GENERATION is what is bounded to once a day. One routine, both jobs, and
#       the signal that a human is needed is not delayed by up to a day.
#
# WHY THE ROUTINE IS STILL NOT A REPOSITORY WRITER. Under the sync ruling
# (`workaholic:ship`, *The two copies*) the draft lives in a GitHub draft release,
# so the generation writes NO file, NO commit and NO branch. The property
# `prepare-release.md` defends — an `allowed_tools` with no `Write`/`Edit` — survives
# this change untouched, and the 2026-08-13 objection that an hourly agent rewriting
# a document on `main` is a new class of unattended write never comes due, because
# no write to `main` happens.
#
# "DAILY" IS A FLOOR DERIVED FROM STATE, NEVER A STORED CURSOR. The gate is: has
# the draft release already been updated during today's `Asia/Tokyo` day? That is
# read off the authoritative store's own `updatedAt`, not off a file this script
# keeps — there is no cursor to go stale, and a fresh clone behaves identically.
# The timezone is stated because the container runs UTC while the workspace is
# `Asia/Tokyo`, and "daily" without one is ambiguous by a day boundary.
#
# AND IT ALSO REFRESHES WHEN THE RELEASE ADVANCES. The sync is idempotent — equal
# bodies make no API call — so running it when the stage has moved costs nothing
# and keeps "updated as the release progresses" literal rather than up-to-a-day
# stale. The stage is derived from git and the release record, never stored:
#   draft      no `.workaholic/releases/` record newer than the last one seen
#   staging    a release record exists whose `status:` is `staging` (a window is cut)
#   confirmed  the newest release record's `status:` is `confirmed`
#
# AN IDLE DAY IS SILENT AND FREE. Nothing unreleased and nothing changed means no
# write, no post, and a reported no-op (`idle: true`, `wrote: 0`).

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TZ_NAME="${WORKAHOLIC_NOTE_CADENCE_TZ:-Asia/Tokyo}"

WANT_TARGET=""
DRY_RUN=""
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) WANT_TARGET="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=--dry-run; shift ;;
    --force) FORCE=1; shift ;;
    --) shift; break ;;
    -*) echo '{"ok": false, "reason": "usage"}' >&2; exit 1 ;;
    *) break ;;
  esac
done
BASE="${1:-main}"

if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo '{"ok": false, "reason": "not_a_git_repo"}' >&2
  exit 1
fi

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

DAY=$(TZ="$TZ_NAME" date +%Y-%m-%d)

# --- the release stage, derived ----------------------------------------------
STAGE=draft
STAGE_REASON=no_release_record
RELEASES="${ROOT}/.workaholic/releases"
if [ -d "$RELEASES" ]; then
  newest=$(find "$RELEASES" -maxdepth 1 -name 'release-*.md' -type f 2>/dev/null | LC_ALL=C sort -r | head -n 1)
  if [ -n "$newest" ]; then
    rec_status=$(sed -n 's/^status:[[:space:]]*//p' "$newest" | head -n 1)
    case "$rec_status" in
      confirmed) STAGE=confirmed; STAGE_REASON="release_record:$(basename "$newest" .md)" ;;
      staging)   STAGE=staging;   STAGE_REASON="release_record:$(basename "$newest" .md)" ;;
      *)         STAGE=draft;     STAGE_REASON="release_record_status:${rec_status:-unset}" ;;
    esac
  fi
fi

if ! command -v gh >/dev/null 2>&1; then
  printf '{"ok": false, "reason": "gh_unavailable", "tz": "%s", "day": "%s", "stage": "%s"}\n' \
    "$TZ_NAME" "$DAY" "$STAGE"
  exit 0
fi

# --- has today's generation already happened? --------------------------------
# Read off the authoritative store, so there is no cursor anywhere to go stale.
already_today() {
  view=$(gh release view "draft/$1" --json updatedAt 2>/dev/null) || return 1
  updated=$(printf '%s' "$view" | sed -n 's/.*"updatedAt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  [ -n "$updated" ] || return 1
  # The stored instant is UTC (`...Z`); compare the DAY it falls on in TZ_NAME.
  updated_day=$(TZ="$TZ_NAME" date -d "$updated" +%Y-%m-%d 2>/dev/null) || return 1
  [ "$updated_day" = "$DAY" ]
}

SLUGS=$(sh "${SCRIPT_DIR}/read-deployments.sh" --slugs)
[ -z "$WANT_TARGET" ] || SLUGS="$WANT_TARGET"

out=""
sep=""
count=0
wrote=0
idle=true

for slug in $SLUGS; do
  count=$((count + 1))

  due=true
  reason=""
  if [ "$FORCE" -eq 0 ] && [ "$STAGE" = draft ] && already_today "$slug"; then
    # The daily floor is met and the release has not advanced: nothing to do, and
    # saying so is the whole of an idle tick's job.
    due=false
    reason=already_generated_today
  fi

  changed=false
  written=false
  divs="[]"

  if [ "$due" = true ]; then
    res=$(sh "${SCRIPT_DIR}/sync-release-note.sh" --target "$slug" ${DRY_RUN:+$DRY_RUN} "$BASE" 2>/dev/null || true)
    if printf '%s' "$res" | grep -q '"ok": true'; then
      changed=$(printf '%s' "$res" | sed -n 's/.*"changed": \([a-z]*\).*/\1/p' | head -n 1)
      written=$(printf '%s' "$res" | sed -n 's/.*"written": \([a-z]*\).*/\1/p' | head -n 1)
      reason=$(printf '%s' "$res" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p' | head -n 1)
      divs=$(printf '%s' "$res" | sed -n 's/.*"divergences": \(\[[^]]*\]\).*/\1/p' | head -n 1)
      [ -n "$divs" ] || divs="[]"
      [ -n "$changed" ] || changed=false
      [ -n "$written" ] || written=false
      if [ "$written" = true ]; then
        wrote=$((wrote + 1))
        idle=false
      fi
    else
      reason=$(printf '%s' "$res" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p' | head -n 1)
      [ -n "$reason" ] || reason=sync_failed
    fi
  fi

  out="${out}${sep}{\"slug\": \"$(json_escape "$slug")\", \"stage\": \"${STAGE}\", \"stage_reason\": \"$(json_escape "$STAGE_REASON")\", \"due\": ${due}, \"reason\": \"$(json_escape "$reason")\", \"changed\": ${changed}, \"written\": ${written}, \"divergences\": ${divs}}"
  sep=", "
done

if [ "$count" -eq 0 ]; then
  printf '{"ok": false, "reason": "no_targets", "tz": "%s", "day": "%s", "count": 0, "targets": []}\n' \
    "$TZ_NAME" "$DAY"
  exit 0
fi

printf '{"ok": true, "tz": "%s", "day": "%s", "stage": "%s", "idle": %s, "count": %d, "wrote": %d, "targets": [%s]}\n' \
  "$TZ_NAME" "$DAY" "$STAGE" "$idle" "$count" "$wrote" "$out"
