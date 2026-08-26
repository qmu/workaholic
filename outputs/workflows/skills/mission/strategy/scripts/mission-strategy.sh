#!/bin/sh -eu
# WHICH STRATEGY DOES THIS MISSION BELONG TO — the inverse of `attributed-work.sh`, and
# nothing more than that.
#
#   mission-strategy.sh [--root <.workaholic>] [<mission-slug>...]
#
#   No slugs -> every mission in the active area.
#
# Output: {"ok", "missions": [{"slug", "strategies": [{"slug", "title", "attribution"}],
#                              "attributed": true|false}],
#          "strategies_read", "unreadable": [{"slug", "reason"}], "exhaustive": false}
#   Exit 0 always. Pure read: it writes nothing and creates nothing.
#
# ═══ WHY IT EXISTS, AND WHY IT ADDS NO FIELD ═════════════════════════════════════════
# The operator's ask is that missions be designed to hang off a strategy — the normal case,
# because a strategy is created first and instructions are given in its context, and
# explicitly NOT mandatory. The link already exists and needs no new field:
# `attributed-work.sh` walks `strategy.feedback[] n artifact.feedback[]` plus the
# `via_mission:<slug>` hop, `/propose` puts the strategy's refs on the issue it opens, and
# `/specificate` carries them onto the mission. What was missing is that NOBODY COULD SEE
# IT: the roadmap, the mission file and every reader rendered a mission with no indication
# of which direction it serves.
#
# THE TEMPTATION IS A `strategy:` FIELD ON THE MISSION, which would make this trivial. It
# is refused three times over: the relation was retired on 2026-07-28 together with its
# ownership hop, the 2026-08-17 no-new-field ruling chose the citation walk deliberately,
# and the ask itself says the link need not be mandatory — a required frontmatter field is
# the opposite of optional. So this is a READER over the reader, composing
# `attributed-work.sh` rather than walking anything itself; `attributed-work.sh` stays the
# ONE attribution reader and this script reads no relation at all.
#
# ═══ IT IS AS LOSSY AS WHAT IT COMPOSES, AND IT SAYS SO ══════════════════════════════
# `exhaustive` is `false`, always and by construction. A mission that answers a direction
# without citing the same feedback record is invisible to both hops, so `attributed: false`
# means "no strategy could be attributed", NEVER "this mission belongs to no direction" —
# and a consumer renders it as an explicit *no strategy* line rather than as a blank, so the
# two readings cannot look alike. A strategy whose own read failed is named in `unreadable`
# rather than silently contributing nothing: an unreadable direction must never render as
# an absent one.
#
# A mission may belong to MORE THAN ONE strategy and is not de-duplicated across them —
# attribution is not a partition, and two directions can be advanced by one mission
# (`attributed-work.sh`'s own contract, unchanged here).

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=".workaholic"

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    --) shift; break ;;
    -*) printf '{"ok": false, "reason": "usage", "detail": "mission-strategy.sh [--root <dir>] [<mission-slug>...]"}\n' >&2; exit 0 ;;
    *) break ;;
  esac
done

command -v jq >/dev/null 2>&1 || {
  printf '{"ok": false, "reason": "jq_unavailable", "missions": [], "exhaustive": false}\n'
  exit 0
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

# The mission set: the slugs asked for, or every mission in the active area.
: > "${TMP}/missions"
if [ "$#" -gt 0 ]; then
  for m in "$@"; do
    [ -n "$m" ] && printf '%s\n' "$m" >> "${TMP}/missions"
  done
else
  if [ -d "${ROOT}/missions/active" ]; then
    find "${ROOT}/missions/active" -mindepth 2 -maxdepth 2 -name 'mission.md' -type f 2>/dev/null \
      | while IFS= read -r f; do basename "$(dirname "$f")"; done >> "${TMP}/missions" || :
  fi
fi
sort -u "${TMP}/missions" -o "${TMP}/missions"

LIST="$(sh "${SCRIPT_DIR}/list.sh" --status active 2>/dev/null || true)"
[ -n "$LIST" ] || LIST='{"strategies": []}'

printf '[]' > "${TMP}/pairs.json"
printf '[]' > "${TMP}/unreadable.json"
READ=0

for slug in $(printf '%s' "$LIST" | jq -r '.strategies[]?.slug // empty' 2>/dev/null || true); do
  [ -n "$slug" ] || continue
  READ=$((READ + 1))
  WORK="$(sh "${SCRIPT_DIR}/attributed-work.sh" "$slug" "" "$ROOT" 2>/dev/null || true)"
  if [ -z "$WORK" ] || ! printf '%s' "$WORK" | jq -e '.found // false' >/dev/null 2>&1; then
    jq -c --arg s "$slug" '. + [{slug: $s, reason: "unreadable"}]' \
      "${TMP}/unreadable.json" > "${TMP}/u.tmp" && mv "${TMP}/u.tmp" "${TMP}/unreadable.json"
    continue
  fi
  if [ "$(printf '%s' "$WORK" | jq -r '.unreadable // false')" = "true" ]; then
    jq -c --arg s "$slug" '. + [{slug: $s, reason: "attribution_unreadable"}]' \
      "${TMP}/unreadable.json" > "${TMP}/u.tmp" && mv "${TMP}/u.tmp" "${TMP}/unreadable.json"
    continue
  fi
  TITLE="$(printf '%s' "$LIST" | jq -r --arg s "$slug" '.strategies[]? | select(.slug == $s) | .title // $s' | head -n1)"
  printf '%s' "$WORK" | jq -c --arg s "$slug" --arg t "${TITLE:-$slug}" --slurpfile acc "${TMP}/pairs.json" '
    ($acc[0]) + ([.artifacts[]? | select(.kind == "mission")
                 | {mission: (.path | split("/") | .[-2]),
                    slug: $s, title: $t, attribution: .attribution}])' \
    > "${TMP}/p.tmp" && mv "${TMP}/p.tmp" "${TMP}/pairs.json"
done

jq -c -n \
  --slurpfile pairs "${TMP}/pairs.json" \
  --slurpfile unread "${TMP}/unreadable.json" \
  --argjson read "$READ" \
  --rawfile missions "${TMP}/missions" '
  ($pairs[0]) as $p
  | ($missions | split("\n") | map(select(length > 0))) as $ms
  | {ok: true,
     missions: ($ms | map(. as $m
       | ($p | map(select(.mission == $m)) | map({slug, title, attribution})) as $hit
       | {slug: $m, strategies: $hit, attributed: (($hit | length) > 0)})),
     strategies_read: $read,
     unreadable: ($unread[0]),
     # ALWAYS false: the attribution this composes is transitive and lossy, so no consumer
     # may render the answer as complete.
     exhaustive: false}'
