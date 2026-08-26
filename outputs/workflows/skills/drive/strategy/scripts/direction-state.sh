#!/bin/sh -eu
# direction-state.sh — THE ONE READER of "what is the lifecycle state of this direction".
# Pure read: it writes nothing, commits nothing, creates no branch, and makes no network call
# that `survey-strategies.sh` does not already make.
#
# Usage: direction-state.sh [window] [workaholic-root]
#   --open-proposals <file>  passed straight through to the survey (see COST below)
#   --aim-kind <kind>        passed straight through to the survey
#   window: any `git log --since` expression; the survey's own default applies when omitted.
#
# Output (one JSON object):
#   {ok, readable, reason, window, repository, active_count,
#    strategies: [{slug, state, reason, title, assignees, days_to_target}],
#    counts: {live, overdue, dormant, unreadable}}
#
#   state       "live" | "overdue" | "dormant" | "unreadable", one per active strategy
#   repository  "ok" | "none" (no `active` strategy exists at all) | "unreadable"
#
# ═══ WHY THIS SCRIPT EXISTS AT ALL ════════════════════════════════════════════════════
#
# `survey-strategies.sh` emits two readings — `overdue` and `dormant` — beside `pace` and the
# refusal list. A consumer that assembled a lifecycle answer out of them would be A SECOND
# DERIVATION of a state this repository insists has one reader (the same rule that keeps
# `attributed-work.sh` the only walker of the attribution, and `read-relation.sh` the only
# parser of `mission:`). Two consumers would drift the first time a term moved.
#
# SO THIS COMPOSES, IT NEVER RE-DERIVES. There is no date arithmetic here and no attribution
# walk: every state is a projection of a field the survey emitted, and the only thing this
# script owns is the PRECEDENCE, which is fixed and stated once:
#
#   unreadable  >  overdue  >  dormant  >  live
#
# `unreadable` first because a reading we could not make must never be dressed as one we did.
# `overdue` before `dormant` because a direction past its date is the operator's to re-date or
# close whatever else is true of it, and reporting the same direction twice under two names
# would double the question the consumer asks about it.
#
# ═══ WHAT IT DOES NOT ANSWER ══════════════════════════════════════════════════════════
#
# It never closes a strategy, never proposes, never lifts a gate and never edits anything: the
# artifact has exactly two writers (`create.sh` creates, `close.sh` ends) and this is neither.
# It is NOT a second `pace`: `pace` answers *will this arrive*, `overdue` answers *has the date
# passed*, `dormant` answers *is anything answering this at all*.
#
# IT INHERITS THE SURVEY'S LOSSINESS AND REPORTS IT RATHER THAN HIDING IT, the posture
# `attributed-work.sh` sets in its own header:
#
#   * `dormant` requires `owns == "mine"` in the survey, so a direction assigned to SOMEBODY
#     ELSE can only ever read `live` or `overdue` here. That is a limit, not a verdict: this
#     reader can see that another identity's direction has run out of date, and cannot see
#     whether anything is answering it.
#   * A strategy whose attribution could not be read is `unreadable` and is never quietly
#     folded into `live` — the survey's own per-row reason is carried through verbatim.
#   * `none` is a REPOSITORY-level answer while the rest are per-strategy. Both live in one
#     output on purpose: a caller asking "what is the direction layer doing" must not have to
#     call twice to learn that it is empty.
#
# COST: the survey makes exactly one network call (the open-proposal gate) and this reader
# makes no second one. A caller that already holds that read passes `--open-proposals` through
# rather than paying for it twice.
#
# A SURVEY THAT REFUSES IS REPORTED, NEVER RENDERED AS QUIET. `ok: false` from the survey
# yields `readable: false`, `repository: "unreadable"`, the survey's own reason carried
# through, and exit 0 — a step that could not read must never announce silence.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SURVEY="${SCRIPT_DIR}/../../propose/scripts//survey-strategies.sh"

PASS_THROUGH=''
while [ $# -gt 0 ]; do
  case "$1" in
    --open-proposals) PASS_THROUGH="${PASS_THROUGH} --open-proposals ${2:-}"; shift 2 ;;
    --aim-kind)       PASS_THROUGH="${PASS_THROUGH} --aim-kind ${2:-}"; shift 2 ;;
    --)               shift; break ;;
    -*)               printf '{"ok": false, "reason": "usage", "detail": "unknown flag"}\n'; exit 0 ;;
    *)                break ;;
  esac
done

WINDOW="${1:-}"
ROOT="${2:-}"

emit_unreadable() {
  reason="$(printf '%s' "${1:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-200)"
  printf '{"ok": true, "readable": false, "reason": "%s", "window": "%s", "repository": "unreadable", "active_count": null, "strategies": [], "counts": {"live": 0, "overdue": 0, "dormant": 0, "unreadable": 0}}\n' \
    "$reason" "$(printf '%s' "$WINDOW" | tr -d '"\\')"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_unreadable "jq_unavailable"
[ -f "$SURVEY" ] || emit_unreadable "no_survey_script"

# shellcheck disable=SC2086
if [ -n "$ROOT" ]; then
  OUT="$(sh "$SURVEY" $PASS_THROUGH "${WINDOW:-14 days ago}" "$ROOT" 2>/dev/null || true)"
elif [ -n "$WINDOW" ]; then
  OUT="$(sh "$SURVEY" $PASS_THROUGH "$WINDOW" 2>/dev/null || true)"
else
  OUT="$(sh "$SURVEY" $PASS_THROUGH 2>/dev/null || true)"
fi

[ -n "$OUT" ] || emit_unreadable "survey_no_output"
printf '%s' "$OUT" | jq -e . >/dev/null 2>&1 || emit_unreadable "survey_unparseable"
if [ "$(printf '%s' "$OUT" | jq -r '.ok // false')" != "true" ]; then
  emit_unreadable "$(printf '%s' "$OUT" | jq -r '.reason // "survey_refused"')"
fi

printf '%s' "$OUT" | jq -c '
  # Every surveyed row, eligible and refused both. The refused list is where an OVERDUE
  # direction lives — `past_target_date` refuses it — so a reader taking only `eligible`
  # would see none of the states this script exists to report.
  ([(.eligible // []), (.refused // [])] | flatten
   # `not_active` is the one refusal that means "this is not a direction any more". Every
   # other refusal is an active strategy the survey declined to propose against, and its
   # lifecycle state is exactly what a consumer is asking for.
   | map(select((.reason // "") != "not_active"))
   | map({slug,
          title: (.title // .slug),
          assignees: (.assignees // ""),
          days_to_target: .days_to_target,
          state: (if ((.reason // "") == "attribution_unreadable") then "unreadable"
                  elif (.overdue == true) then "overdue"
                  elif (.dormant == true) then "dormant"
                  else "live" end),
          reason: (if ((.reason // "") == "attribution_unreadable") then "attribution_unreadable"
                   elif (.overdue == true) then "the target_date has passed"
                   elif (.dormant == true) then "nothing landed in the window and nothing is waiting"
                   else "" end)})
   | sort_by(.slug)) as $rows
  | {ok: true,
     readable: true,
     reason: "",
     window: .window,
     repository: (if ((.active_count // 0) == 0) then "none" else "ok" end),
     active_count: (.active_count // 0),
     strategies: $rows,
     counts: {live:       ([$rows[] | select(.state == "live")]       | length),
              overdue:    ([$rows[] | select(.state == "overdue")]    | length),
              dormant:    ([$rows[] | select(.state == "dormant")]    | length),
              unreadable: ([$rows[] | select(.state == "unreadable")] | length)}}
'
