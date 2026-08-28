#!/bin/sh -eu
# unattributed-work.sh — WHAT DOES NO DIRECTION CLAIM: the active missions and the queued
# tickets that `mission-strategy.sh` cannot attribute to any `active` strategy.
#
#   unattributed-work.sh [--root <.workaholic>]
#
# Output: {"ok", "readable", "reason",
#          "missions": [{"slug", "path", "queued"}],
#          "tickets": [{"path"}],
#          "mission_count", "ticket_count", "exhaustive": false}
#   Exit 0 always. Pure read: it writes nothing and creates nothing.
#
# ═══ WHY IT EXISTS ═══════════════════════════════════════════════════════════════════
# `quiescent` means *everything I could attribute has landed* and is projected as *this
# direction has arrived* — a reading that invites the operator to CLOSE the direction.
# Measured on this repository at 2026-08-28 00:41 UTC, the strategy
# `an-autonomous-improvement-loop-run-by-the-routines` read `quiescent: true` with 125 landed
# items while FOUR active missions and TEN queued tickets read `attributed: false`, three of
# them its own machinery. The arrival was true of everything the walk could see and blind to
# everything it could not, and nothing anywhere said what it could not see.
#
# So this names the blind spot. It does not shrink it: the walk is as lossy as it was, and
# making it guess is the one thing that would be worse than not reading it at all.
#
# ═══ IT COMPOSES; IT WALKS NOTHING ═══════════════════════════════════════════════════
# `mission-strategy.sh` already answers *which strategy does this mission belong to* for every
# mission in the active area, by composing `attributed-work.sh`. This is a reader over THAT
# reader — the same shape, one layer up — so there is no second walker, no relation of its own
# and NO FIELD ON ANY ARTIFACT. The temptation is a `strategy:` field on the mission, refused
# three times over (2026-07-28, 2026-08-17, 2026-08-26); a reader that needed one would be
# re-opening a decision this repository has already made three times.
#
# The queued tickets ride the same composition rather than a second parse of the `mission:`
# relation: `mission/scripts/read-relation.sh` is that relation's single reader and is what
# says which mission a queued ticket names.
#
#   a queued ticket naming an ATTRIBUTED active mission      -> claimed by a direction, absent here
#   a queued ticket naming an UNATTRIBUTED active mission    -> rides that mission's `queued`
#   a queued ticket naming no active mission at all          -> its own entry in `tickets`
#
# ═══ WHAT IT DOES NOT ANSWER, STATED SO IT IS NOT OVER-READ ══════════════════════════
# `exhaustive` is `false`, always and by construction — inherited from what it composes.
# `attributed: false` upstream means "NO STRATEGY COULD BE ATTRIBUTED", never "this belongs to
# no direction", so every entry here is a READING and not a verdict. A mission that answers a
# direction without citing the same feedback record is invisible to both hops and lands in
# this residue for an ordinary reason.
#
# THE THIRD BULLET ABOVE IS THE SHARPEST LIMIT. A loose queued ticket is residue BY
# CONSTRUCTION here, because the reader this composes answers only at the MISSION grain: it
# cannot say whether such a ticket's own `feedback:` refs cite a live direction. Naming it is
# the conservative direction — the residue over-reports rather than under-reports, and a
# consumer that renders it as *what I could not see* is saying exactly the true thing.
#
# ═══ AN EMPTY RESIDUE AND A RESIDUE WE COULD NOT READ ARE DIFFERENT ANSWERS ══════════
# That distinction is the whole point of the mission this was written for, so `readable:
# false` carries its own reason and NEVER a zeroed residue — the `unreadable`-is-never-
# `dormant` precedent, and `no_feedback_refs`'s rule that a gate that cannot be read is not a
# gate. A `mission-strategy.sh` that answered `ok: false`, or that named EVERY strategy it
# read in `unreadable[]`, is a read we did not make.
#
# A repository with no `active` strategy is READABLE, not degraded: the honest answer there is
# that no direction claims anything, which is a reading and not a failure.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"
ROOT=".workaholic"

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    --) shift; break ;;
    -*) printf '{"ok": false, "readable": false, "reason": "usage", "missions": [], "tickets": [], "mission_count": 0, "ticket_count": 0, "exhaustive": false}\n' >&2; exit 0 ;;
    *) break ;;
  esac
done

emit_unreadable() {
  reason="$(printf '%s' "${1:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-200)"
  # NO COUNTS AT ALL on a degraded read. A `mission_count: 0` beside `readable: false` is the
  # zeroed residue this script exists to refuse: a consumer skimming the counts would read an
  # empty residue where there was no reading.
  printf '{"ok": true, "readable": false, "reason": "%s", "missions": [], "tickets": [], "mission_count": null, "ticket_count": null, "exhaustive": false}\n' "$reason"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_unreadable "jq_unavailable"

READER="${SCRIPT_DIR}/mission-strategy.sh"
[ -f "$READER" ] || emit_unreadable "no_mission_strategy_script"

OUT="$(sh "$READER" --root "$ROOT" 2>/dev/null || true)"
[ -n "$OUT" ] || emit_unreadable "reader_no_output"
printf '%s' "$OUT" | jq -e . >/dev/null 2>&1 || emit_unreadable "reader_unparseable"
[ "$(printf '%s' "$OUT" | jq -r '.ok // false')" = "true" ] || emit_unreadable "reader_refused"

# EVERY STRATEGY UNREADABLE IS NOT AN EMPTY RESIDUE. `strategies_read` counts the `active`
# strategies the reader tried; when all of them failed, nothing could have been attributed and
# every mission would read as residue for the wrong reason. Zero strategies read is a
# different fact and stays readable.
READ_N="$(printf '%s' "$OUT" | jq -r '.strategies_read // 0')"
UNREAD_N="$(printf '%s' "$OUT" | jq -r '(.unreadable // []) | length')"
if [ "$READ_N" -gt 0 ] && [ "$UNREAD_N" -ge "$READ_N" ]; then
  emit_unreadable "all_strategies_unreadable"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM

printf '%s' "$OUT" | jq -r '.missions[]? | select(.attributed | not) | .slug' > "${TMP}/residue" 2>/dev/null || : > "${TMP}/residue"
printf '%s' "$OUT" | jq -r '.missions[]? | select(.attributed) | .slug' > "${TMP}/claimed" 2>/dev/null || : > "${TMP}/claimed"

# --- The queue, through the `mission:` relation's single reader --------------------
READ_RELATION="${MISSION_SCRIPTS}/read-relation.sh"
: > "${TMP}/loose"
: > "${TMP}/counts"
if [ -d "${ROOT}/tickets/todo" ] && [ -f "$READ_RELATION" ]; then
  find "${ROOT}/tickets/todo" -name '*.md' -type f 2>/dev/null | sort | while IFS= read -r t; do
    [ -n "$t" ] || continue
    slugs="$(sh "$READ_RELATION" "$t" 2>/dev/null || true)"
    if [ -n "$slugs" ] && printf '%s\n' "$slugs" | grep -qxFf "${TMP}/claimed" 2>/dev/null; then
      continue
    fi
    hit="$(printf '%s\n' "$slugs" | grep -xFf "${TMP}/residue" 2>/dev/null | head -n1 || true)"
    if [ -n "$hit" ]; then
      printf '%s\n' "$hit" >> "${TMP}/counts"
    else
      printf '%s\n' "$t" >> "${TMP}/loose"
    fi
  done
fi

jq -nc \
  --arg root "$ROOT" \
  --rawfile residue "${TMP}/residue" \
  --rawfile counts "${TMP}/counts" \
  --rawfile loose "${TMP}/loose" '
  def lines: split("\n") | map(select(length > 0));
  ($counts | lines) as $q
  | ($residue | lines
     | map({slug: ., path: ($root + "/missions/active/" + . + "/mission.md"),
            queued: (. as $s | $q | map(select(. == $s)) | length)})) as $m
  | ($loose | lines | map({path: .})) as $t
  | {ok: true, readable: true, reason: "",
     missions: $m, tickets: $t,
     mission_count: ($m | length), ticket_count: ($t | length),
     # ALWAYS false: what this composes is transitive and lossy, so no consumer may render
     # the residue as the complete set of work no direction claims.
     exhaustive: false}'
