#!/bin/sh -eu
# closing-residue.sh — WHAT A DIRECTION LEAVES BEHIND, composed at the moment somebody is
# deciding whether to end it.
#
#   closing-residue.sh <slug> [window] [workaholic-root]
#     --state-row <file|->      a `direction-state.sh` row for <slug>, already in hand
#     --open-proposals <file>   a held open-proposal read, passed straight through to the
#                               lifecycle reader so no caller pays for that one network call
#                               twice (its own contract, inherited unchanged)
#
# Output (one JSON object):
#   {ok, readable, reason, slug, window, exhaustive: false,
#    waiting:   {readable, reason, count, missions, mission_slugs[], describing, advancing},
#    residue:   {readable, reason, missions: [{slug, path, queued}], tickets: [{path}],
#               mission_count, ticket_count},
#    lifecycle: {readable, reason, state, state_reason, title, assignees,
#                target_date, days_to_target, landed}}
#
#   Exit 0 in every case. Pure read: it writes nothing, commits nothing, creates no branch,
#   and makes NO NETWORK CALL the composed readers do not already make.
#
# ═══ WHY IT EXISTS ═══════════════════════════════════════════════════════════════════
#
# Every reading in the direction layer is bounded to `status: active`, so the moment a
# direction is closed everything about it stops being legible — and the operator is asked to
# close it with none of that in front of them. The three facts a person actually needs are
# ALREADY IN THE TREE and ALREADY READABLE:
#
#   what it never reached      `attributed-work.sh`'s waiting grains
#   what no direction claimed  `unattributed-work.sh`'s residue
#   its last lifecycle reading `direction-state.sh`
#
# Nothing composed them, so nothing could state them AT THE MOMENT OF THE DECISION. After the
# close it is a post-mortem; before it, it is evidence. This is the composition and nothing
# else.
#
# ═══ IT COMPOSES; IT DERIVES NOTHING ═════════════════════════════════════════════════
#
# There is NO SECOND WALKER here, NO RELATION OF ITS OWN and NO FIELD ON ANY ARTIFACT. Each
# fact comes from that fact's existing single reader, and this script owns only the
# ASSEMBLY — which is exactly one thing, so that a consumer never assembles it a second time
# and drifts (the rule `direction-state.sh` states for the lifecycle and `attributed-work.sh`
# states for the attribution).
#
# `--state-row` is how the assembly stays single without recursing: `direction-state.sh`
# carries this reading onto its own rows by handing the row it already computed BACK to this
# script, so the lifecycle and the residue are CARRIED rather than re-read, and this script
# never calls back into the reader that called it. A caller with no row in hand omits the flag
# and the three readers are consulted directly.
#
# ═══ A READING WE COULD NOT MAKE IS NEVER AN EMPTY ONE ═══════════════════════════════
#
# Each block carries its OWN `readable` and its OWN reason, and a degraded block reports
# NULL counts rather than zeroed ones — the `unreadable`-is-never-`dormant` precedent, and
# `unattributed-work.sh`'s own rule that an empty residue and a residue we could not read are
# different answers. A degraded block also makes the TOP-LEVEL `readable` false, naming the
# source (`waiting_unreadable:<reason>`), because this output exists to be rendered beside a
# decision and half of it rendered as silence is worse than none of it.
#
# A NON-DEGRADED EMPTY IS NOT A DEGRADATION. `attributed-work.sh`'s `no_citing_artifacts`,
# `no_activity_in_window` and an empty residue are all REAL answers about a real tree, and
# they read `readable: true` with honest zeros.
#
# A CLOSED DIRECTION IS READABLE, NOT DEGRADED. `direction-state.sh` is bounded to the
# `active` set by design, so a direction that has just been closed has no row there; that is
# the answer `not_active`, reported as a state with `readable: true`. Calling it unreadable
# would make the one caller that reads this AFTER a close (`/specificate`'s *ended* route)
# unable to state anything at all.
#
# ═══ WHAT IT DOES NOT ANSWER ═════════════════════════════════════════════════════════
#
# `exhaustive` is `false`, ALWAYS and by construction, inherited from what it composes: the
# attribution walk is transitive and lossy at both hops, and the residue over-reports at the
# mission grain (a loose queued ticket is residue by construction there). So this is EVIDENCE
# FOR A DECISION and never an assertion that closing is correct — it says what is visibly
# outstanding, never that nothing else is.
#
# It closes nothing, proposes nothing, amends nothing and lifts no gate. The strategy artifact
# keeps its three writers (`create.sh`, `amend.sh`, `close.sh`) and this is none of them.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ATTRIBUTED="${SCRIPT_DIR}/attributed-work.sh"
UNATTRIBUTED="${SCRIPT_DIR}/unattributed-work.sh"
STATE="${SCRIPT_DIR}/direction-state.sh"

STATE_ROW=''
OPEN=''
while [ $# -gt 0 ]; do
  case "$1" in
    --state-row) STATE_ROW="${2:-}"; shift 2 ;;
    --open-proposals) OPEN="${2:-}"; shift 2 ;;
    --)          shift; break ;;
    -*)          printf '{"ok": false, "readable": false, "reason": "usage", "slug": "", "exhaustive": false}\n'; exit 0 ;;
    *)           break ;;
  esac
done

SLUG="${1:-}"
WINDOW="${2:-}"
ROOT="${3:-.workaholic}"

json_str() { printf '%s' "${1:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-200; }

emit_refusal() {
  printf '{"ok": true, "readable": false, "reason": "%s", "slug": "%s", "window": "%s", "exhaustive": false, "waiting": {"readable": false, "reason": "%s", "count": null, "missions": null, "mission_slugs": [], "describing": null, "advancing": null}, "residue": {"readable": false, "reason": "%s", "missions": [], "tickets": [], "mission_count": null, "ticket_count": null}, "lifecycle": {"readable": false, "reason": "%s", "state": "", "state_reason": "", "title": "", "assignees": "", "target_date": "", "days_to_target": null, "landed": null}}\n' \
    "$(json_str "$1")" "$(json_str "$SLUG")" "$(json_str "$WINDOW")" \
    "$(json_str "$1")" "$(json_str "$1")" "$(json_str "$1")"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_refusal "jq_unavailable"
[ -n "$SLUG" ] || emit_refusal "no_slug"

# --- 0. A row handed in is CARRIED, never re-read ----------------------------------------
# This is what keeps the assembly single while `direction-state.sh` attaches this reading to
# its own rows: every one of the three facts comes off the row it already computed, so
# attaching the leaving costs NOT ONE extra read of the tree and no second network call.
ROW=''
if [ -n "$STATE_ROW" ]; then
  if [ "$STATE_ROW" = "-" ]; then
    ROW="$(cat)"
  elif [ -f "$STATE_ROW" ]; then
    ROW="$(cat "$STATE_ROW")"
  fi
  if [ -z "$ROW" ] || ! printf '%s' "$ROW" | jq -e . >/dev/null 2>&1; then
    emit_refusal "state_row_unreadable"
  fi
fi

# --- 1. What it never reached: the waiting grains ---------------------------------------
WAITING='{"readable": false, "reason": "no_attributed_work_script", "count": null, "missions": null, "mission_slugs": [], "describing": null, "advancing": null}'
if [ -n "$ROW" ] && [ "$(printf '%s' "$ROW" | jq -r 'has("waiting")')" = "true" ]; then
  WAITING="$(printf '%s' "$ROW" | jq -c '.waiting
    | {readable: true, reason: "",
       count: (.count // 0), missions: (.missions // 0),
       mission_slugs: (.mission_slugs // []),
       describing: (.describing // 0), advancing: (.advancing // 0)}')"
elif [ -f "$ATTRIBUTED" ]; then
  if [ -n "$WINDOW" ]; then
    A_OUT="$(sh "$ATTRIBUTED" "$SLUG" "$WINDOW" "$ROOT" 2>/dev/null || true)"
  else
    A_OUT="$(sh "$ATTRIBUTED" "$SLUG" "1 day ago" "$ROOT" 2>/dev/null || true)"
  fi
  if [ -n "$A_OUT" ] && printf '%s' "$A_OUT" | jq -e . >/dev/null 2>&1; then
    WAITING="$(printf '%s' "$A_OUT" | jq -c '
      # `found: false` is the one shape that is a DEGRADATION rather than an answer: there is
      # no artifact to read. Every other empty (`no_feedback_refs`, `no_citing_artifacts`,
      # `no_activity_in_window`) is a real reading of a real tree and keeps honest zeros.
      if ((.found // false) | not)
      then {readable: false, reason: (.empty_reason // "not_found"),
            count: null, missions: null, mission_slugs: [], describing: null, advancing: null}
      else {readable: true, reason: (.empty_reason // ""),
            count: (.waiting_count // 0),
            missions: (.waiting_missions // 0),
            mission_slugs: (.waiting_mission_slugs // []),
            describing: (.waiting_describing // 0),
            advancing: (.waiting_advancing // 0)} end')"
  else
    WAITING='{"readable": false, "reason": "attributed_work_unreadable", "count": null, "missions": null, "mission_slugs": [], "describing": null, "advancing": null}'
  fi
fi

# --- 2. The lifecycle reading, and the residue that rides with it -----------------------
if [ -n "$ROW" ]; then
  LIFECYCLE="$(printf '%s' "$ROW" | jq -c '{readable: true, reason: "",
                                            state: (.state // ""),
                                            state_reason: (.reason // ""),
                                            title: (.title // ""),
                                            assignees: (.assignees // ""),
                                            target_date: (.target_date // ""),
                                            days_to_target: .days_to_target,
                                            landed: .landed}')"
  # The row's own residue: `unattributed-work.sh`'s answer, read once by the survey and
  # carried from there. It is the mission-grain projection (slug + queued count) the survey
  # keeps; `path` and the loose-ticket list are the direct read's, below.
  RESIDUE="$(printf '%s' "$ROW" | jq -c '(.residue // {readable: false, reason: "absent"})
    | {readable: (.readable // false), reason: (.reason // ""),
       missions: ((.missions // []) | map({slug: .slug, path: (.path // ""), queued: (.queued // 0)})),
       tickets: (.tickets // []),
       mission_count: .mission_count, ticket_count: .ticket_count}')"
else
  LIFECYCLE='{"readable": false, "reason": "no_direction_state_script", "state": "", "state_reason": "", "title": "", "assignees": "", "target_date": "", "days_to_target": null, "landed": null}'
  if [ -f "$STATE" ]; then
    if [ -n "$OPEN" ]; then
      S_OUT="$(sh "$STATE" --open-proposals "$OPEN" "$WINDOW" "$ROOT" 2>/dev/null || true)"
    else
      S_OUT="$(sh "$STATE" "$WINDOW" "$ROOT" 2>/dev/null || true)"
    fi
    if [ -n "$S_OUT" ] && printf '%s' "$S_OUT" | jq -e . >/dev/null 2>&1; then
      LIFECYCLE="$(printf '%s' "$S_OUT" | jq -c --arg slug "$SLUG" '
        if ((.readable // false) | not)
        then {readable: false, reason: (.reason // "direction_state_unreadable"),
              state: "", state_reason: "", title: "", assignees: "",
              target_date: "", days_to_target: null, landed: null}
        else ((.strategies // []) | map(select(.slug == $slug)) | first) as $r
          | if $r == null
            # NOT a degradation. The reader is bounded to the `active` set by design, so a
            # direction that has been closed simply is not there — and `not_active` is the
            # true answer, not a failure to read one.
            then {readable: true, reason: "", state: "not_active",
                  state_reason: "the direction is no longer active",
                  title: "", assignees: "", target_date: "", days_to_target: null, landed: null}
            else {readable: true, reason: "",
                  state: ($r.state // ""), state_reason: ($r.reason // ""),
                  title: ($r.title // ""), assignees: ($r.assignees // ""),
                  target_date: ($r.target_date // ""),
                  days_to_target: $r.days_to_target, landed: $r.landed} end end')"
    else
      LIFECYCLE='{"readable": false, "reason": "direction_state_unreadable", "state": "", "state_reason": "", "title": "", "assignees": "", "target_date": "", "days_to_target": null, "landed": null}'
    fi
  fi

  # --- 3. What no direction claimed, from that fact's own single reader ----------------
  RESIDUE='{"readable": false, "reason": "no_unattributed_work_script", "missions": [], "tickets": [], "mission_count": null, "ticket_count": null}'
  if [ -f "$UNATTRIBUTED" ]; then
    U_OUT="$(sh "$UNATTRIBUTED" --root "$ROOT" 2>/dev/null || true)"
    if [ -n "$U_OUT" ] && printf '%s' "$U_OUT" | jq -e . >/dev/null 2>&1; then
      RESIDUE="$(printf '%s' "$U_OUT" | jq -c '
        if ((.readable // false) | not)
        then {readable: false, reason: (.reason // "residue_unreadable"),
              missions: [], tickets: [], mission_count: null, ticket_count: null}
        else {readable: true, reason: "",
              missions: ((.missions // []) | map({slug: .slug, path: (.path // ""), queued: (.queued // 0)})),
              tickets: ((.tickets // []) | map({path: .path})),
              mission_count: .mission_count, ticket_count: .ticket_count} end')"
    else
      RESIDUE='{"readable": false, "reason": "residue_unreadable", "missions": [], "tickets": [], "mission_count": null, "ticket_count": null}'
    fi
  fi
fi

jq -nc \
  --arg slug "$SLUG" \
  --arg window "$WINDOW" \
  --argjson waiting "$WAITING" \
  --argjson residue "$RESIDUE" \
  --argjson lifecycle "$LIFECYCLE" '
  # The top-level answer is false the moment ANY source is, naming that source: this output is
  # rendered beside a decision, and a half-read leaving presented as a whole one is the exact
  # collapse the mission exists to remove.
  [ (if ($waiting.readable   | not) then "waiting_unreadable:"   + ($waiting.reason   // "") else empty end),
    (if ($residue.readable   | not) then "residue_unreadable:"   + ($residue.reason   // "") else empty end),
    (if ($lifecycle.readable | not) then "lifecycle_unreadable:" + ($lifecycle.reason // "") else empty end)
  ] as $bad
  | {ok: true,
     readable: (($bad | length) == 0),
     reason: ($bad | join("; ")),
     slug: $slug,
     window: $window,
     waiting: $waiting,
     residue: $residue,
     lifecycle: $lifecycle,
     # ALWAYS false, by construction: every source it composes is lossy and says so.
     exhaustive: false}'
