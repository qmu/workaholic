#!/bin/sh -eu
# direction-state.sh — THE ONE READER of "what is the lifecycle state of this direction".
# Pure read: it writes nothing, commits nothing, creates no branch, and makes no network call
# that `survey-strategies.sh` does not already make.
#
# Usage: direction-state.sh [window] [workaholic-root]
#   --open-proposals <file>  passed straight through to the survey (see COST below)
#   --aim-kind <kind>        passed straight through to the survey
#   --with-leaving           attach `leaving` to every row (see THE LEAVING below)
#   window: any `git log --since` expression; the survey's own default applies when omitted.
#
# Output (one JSON object):
#   {ok, readable, reason, window, repository, active_count,
#    strategies: [{slug, state, reason, title, assignees, days_to_target, target_date, landed,
#                  waiting, residue, leaving?}],
#    counts: {live, arrived, overdue, expiring, dormant, unreadable}}
#
#   state       "live" | "arrived" | "overdue" | "expiring" | "dormant" | "unreadable", one per
#               active strategy
#   repository  "ok" | "none" (no `active` strategy exists at all) | "unreadable"
#   residue     the survey's own {readable, reason, missions: [{slug, queued}], mission_count,
#               ticket_count} — WHAT NO DIRECTION CLAIMS, carried through unchanged. It is a
#               fact about the repository, so it is identical on every row; a consumer names
#               it beside an `arrived` reading and never re-reads it.
#   waiting     the survey's own waiting grains — WHAT THIS DIRECTION NEVER REACHED, projected
#               exactly like `landed`: {count, missions, mission_slugs, describing, advancing}.
#   leaving     ONLY under `--with-leaving`: `closing-residue.sh`'s composition of the three,
#               for this row. See below.
#
# ═══ THE LEAVING (2026-08-28) ════════════════════════════════════════════════════════
#
# What a direction leaves when it ends — what it never reached, what no direction claimed, and
# its own last lifecycle reading — is exactly the evidence a person needs BEFORE deciding to
# close it, and `closing-residue.sh` is the one place that composition lives. A consumer that
# assembled it here would be a SECOND ASSEMBLY of one reading, which is the same defect this
# whole script exists to prevent one level down.
#
# So the row is handed BACK to that script (`--state-row`), which carries the lifecycle, the
# residue and the waiting grains off the row rather than re-reading any of them: no recursion,
# no second assembly, and NOT ONE EXTRA READ of the tree or the network. `--with-leaving` is
# opt-in so a caller that does not need it pays nothing and its output shape does not move.
#
# IT IS ATTACHED PER ROW, WHATEVER THE READING (2026-08-29). `arrived` and `overdue` are the two
# that consume it today and `expiring` is the third, on the same grounds: a person asked to
# re-date a direction before its date needs the same evidence as one asked to close it after.
# Nothing about the attachment is keyed on the state, which is what keeps a new rung from
# costing a second code path — and a row whose leaving could not be composed is NAMED at every
# reading alike, never emptied.
#
# ═══ WHY THIS SCRIPT EXISTS AT ALL ════════════════════════════════════════════════════
#
# `survey-strategies.sh` emits four readings — `overdue`, `expiring`, `dormant` and `quiescent` —
# beside `pace` and the refusal list. A consumer that assembled a lifecycle answer out of them would be A SECOND
# DERIVATION of a state this repository insists has one reader (the same rule that keeps
# `attributed-work.sh` the only walker of the attribution, and `read-relation.sh` the only
# parser of `mission:`). Two consumers would drift the first time a term moved.
#
# SO THIS COMPOSES, IT NEVER RE-DERIVES. There is no date arithmetic here and no attribution
# walk: every state is a projection of a field the survey emitted, and the only thing this
# script owns is the PRECEDENCE, which is fixed and stated once:
#
#   unreadable  >  arrived  >  overdue  >  expiring  >  dormant  >  live
#
# `unreadable` first because a reading we could not make must never be dressed as one we did.
# `overdue` before `dormant` because a direction past its date is the operator's to re-date or
# close whatever else is true of it, and reporting the same direction twice under two names
# would double the question the consumer asks about it.
#
# ═══ WHY `expiring` SITS BETWEEN `overdue` AND `dormant` ══════════════════════════════
#
# AGAINST `overdue`, ABOVE IT: a date that has GONE is a stronger fact than one approaching, and
# the two ask the operator for the SAME act with different urgency — *re-date it, end it, or say
# it still stands*. Where one word must be chosen, the fact that has already happened wins;
# reporting a direction as *about to expire* when it expired last week would understate what the
# person is looking at. (Contrast `arrived`, which outranks both because it asks for a DIFFERENT
# act — that is the block below, and it is why a rung is not just a severity ordering.)
#
# AGAINST `dormant`, BELOW IT: a direction near its date and silent is about to be silenced BY
# THE DATE first, and the date is the fact with a deadline on it. `dormant` says *nothing is
# answering this*, which stays true tomorrow; `expiring` stops being actionable the moment the
# date passes, at which point the reading becomes `overdue` and the warning was never given.
#
# A rung with no reason recorded is what this header exists to prevent, so both neighbours are
# argued rather than one.
#
# ═══ WHY `arrived` OUTRANKS `overdue` ═════════════════════════════════════════════════
#
# `arrived` is projected from the survey's `quiescent` — a direction that is legible, live,
# owned, cited, WITH ITS WORK LANDED and nothing in flight. It carries no date term at all,
# which is deliberate on the survey's side and load-bearing here: ARRIVAL IS INDEPENDENT OF
# THE DATE, so a direction that finished late is both `quiescent` and `overdue` and the
# precedence has to choose.
#
# It chooses `arrived`, because the two states ask a person for DIFFERENT ACTS. `overdue`
# says *re-date this or close it*; `arrived` says *your work is in, is this done?*. A
# direction whose work is all in is the operator's to CLOSE whatever its date says, and
# reporting that success as lateness is naming a success as a failure — the exact defect
# this reading was added to remove. Ranking `overdue` first would make `arrived` unreachable
# for the one case it exists to serve, since a finished direction is very often a late one.
#
# IT IS A CANDIDATE, NEVER A VERDICT. A strategy's "Reached when" is prose no script reads,
# so nothing here can know whether the aim was actually met — only that everything attributed
# to the direction has landed and nothing is queued. The reading therefore says *this looks
# finished*; the operator's answer decides, and NOTHING in this repository closes a direction
# on a reading (`workaholic:strategy`).
#
# ═══ WHAT IT DOES NOT ANSWER ══════════════════════════════════════════════════════════
#
# It never closes a strategy, never proposes, never amends one, never lifts a gate and never
# edits anything: the artifact has three writers (`create.sh` creates, `amend.sh` revises the
# three revisable parts, `close.sh` ends) and this is none of them. Reading a direction's state
# and writing one are different acts; `amend.sh` is reached only from `/specificate`'s
# announcement route, never from a reader's own judgement that a direction looks stale.
# It is NOT a second `pace`: `pace` answers *will this arrive*, `overdue` answers *has the date
# passed*, `expiring` answers *is the date about to arrive*, `dormant` answers *is anything
# answering this at all*, and `arrived` answers *has its work all come in*. Five questions, five
# fields; one field answering two is how they drift.
#
# IT INHERITS THE SURVEY'S LOSSINESS AND REPORTS IT RATHER THAN HIDING IT, the posture
# `attributed-work.sh` sets in its own header:
#
#   * `dormant` and `quiescent` both require `owns == "mine"` in the survey, so a direction
#     assigned to SOMEBODY ELSE can only ever read `live`, `overdue` or `expiring` here. That is
#     a limit, not a verdict: this reader can see that another identity's direction has run out
#     of date — or is about to, since `expiring` carries no ownership term either — and cannot
#     see whether anything is answering it or whether it has arrived.
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
SURVEY="${SCRIPT_DIR}/../../propose/scripts/survey-strategies.sh"

PASS_THROUGH=''
WITH_LEAVING=0
while [ $# -gt 0 ]; do
  case "$1" in
    --open-proposals) PASS_THROUGH="${PASS_THROUGH} --open-proposals ${2:-}"; shift 2 ;;
    --aim-kind)       PASS_THROUGH="${PASS_THROUGH} --aim-kind ${2:-}"; shift 2 ;;
    --with-leaving)   WITH_LEAVING=1; shift ;;
    --)               shift; break ;;
    -*)               printf '{"ok": false, "reason": "usage", "detail": "unknown flag"}\n'; exit 0 ;;
    *)                break ;;
  esac
done

WINDOW="${1:-}"
ROOT="${2:-}"

emit_unreadable() {
  reason="$(printf '%s' "${1:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-200)"
  printf '{"ok": true, "readable": false, "reason": "%s", "window": "%s", "repository": "unreadable", "active_count": null, "strategies": [], "counts": {"live": 0, "arrived": 0, "overdue": 0, "expiring": 0, "dormant": 0, "unreadable": 0}}\n' \
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

RESULT="$(printf '%s' "$OUT" | jq -c '
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
          # THE DECLARED STAGE RIDES BESIDE THE READING AND NEVER ENTERS IT (2026-08-29,
          # mission `make-a-direction-s-lifecycle-a-declared-stage`). `state` below is DERIVED
          # — what the evidence says — and this is DECLARED, what the operator wrote down.
          # A sixth `state` value was refused for the reason `overdue` was kept out of `pace`
          # and `expiring` out of both: one field answering two questions is how the two
          # drift. So it is projected off the survey row, exactly as `target_date` and
          # `landed` are, and the precedence below is byte-identical across this change.
          stage: (.stage // ""),
          days_to_target: .days_to_target,
          # Projected, never derived: `target_date` comes straight off the survey row, and
          # `landed` is the length of the list it emitted (`landed_count` on a refused row,
          # the shape a refused-and-arrived direction arrives in). A consumer that must say
          # WHAT LANDED and BY WHEN reads these; nothing here counts anything itself.
          target_date: (.target_date // ""),
          landed: (.landed_count // ((.landed // []) | length)),
          # THE RESIDUE RIDES THROUGH (2026-08-28), projected exactly like everything else
          # here: the survey read it once and this carries that answer. A consumer must NOT
          # call `unattributed-work.sh` itself — two readings of one fact is how they drift,
          # which is the rule this whole script exists to hold.
          residue: (.residue // {readable: false, reason: "absent",
                                 missions: [], mission_count: null, ticket_count: null}),
          # THE WAITING GRAINS RIDE THROUGH TOO (2026-08-28), projected exactly like
          # `landed`: WHAT THIS DIRECTION NEVER REACHED is the other half of what it leaves,
          # and the survey already read it once per row. A consumer must not call
          # `attributed-work.sh` itself for the same reason it must not call
          # `unattributed-work.sh`: two readings of one fact drift.
          #
          # AND A ROW WHOSE WALK DID NOT COMPLETE CARRIES NULLS THROUGH (2026-08-29, mission
          # `keep-the-closing-link-readable-as-the-corpus-grows`). The survey emits null
          # rather than zero for exactly that row, so `// 0` here would put the zeroed
          # reading back one layer up — the same defect, one consumer further on. The state
          # is already `unreadable`, and these counts say the same thing rather than
          # contradicting it.
          waiting: (if ((.reason // "") == "attribution_unreadable")
                    then {count: null, missions: null, mission_slugs: null,
                          describing: null, advancing: null}
                    else {count:         (.waiting_count // 0),
                          missions:      (.waiting_missions // 0),
                          mission_slugs: (.waiting_mission_slugs // []),
                          describing:    (.waiting_describing // 0),
                          advancing:     (.waiting_advancing // .waiting_count // 0)} end),
          state: (if ((.reason // "") == "attribution_unreadable") then "unreadable"
                  elif (.quiescent == true) then "arrived"
                  elif (.overdue == true) then "overdue"
                  elif (.expiring == true) then "expiring"
                  elif (.dormant == true) then "dormant"
                  else "live" end),
          reason: (if ((.reason // "") == "attribution_unreadable") then "attribution_unreadable"
                   elif (.quiescent == true) then "its work has landed and nothing is waiting"
                   elif (.overdue == true) then "the target_date has passed"
                   elif (.expiring == true) then "the target_date is approaching"
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
              arrived:    ([$rows[] | select(.state == "arrived")]    | length),
              overdue:    ([$rows[] | select(.state == "overdue")]    | length),
              expiring:   ([$rows[] | select(.state == "expiring")]   | length),
              dormant:    ([$rows[] | select(.state == "dormant")]    | length),
              unreadable: ([$rows[] | select(.state == "unreadable")] | length)}}
')"

if [ "$WITH_LEAVING" != "1" ]; then
  printf '%s\n' "$RESULT"
  exit 0
fi

# ═══ THE LEAVING, ATTACHED PER ROW ══════════════════════════════════════════════════
# The row goes BACK to `closing-residue.sh`, which is where that composition lives and the
# only place it lives. It carries the lifecycle, the residue and the waiting grains straight
# off the row handed to it, so this attaches the reading WITHOUT one extra read of the tree,
# one extra network call, or a second assembly that could drift from the first.
#
# A ROW WHOSE LEAVING COULD NOT BE COMPOSED IS NAMED, NEVER DROPPED and never silently
# emptied: the row keeps every field it already had and its `leaving` says `readable: false`
# with its own reason, which is the rule every block of that output already follows.
COMPOSER="${SCRIPT_DIR}/closing-residue.sh"
n=$(printf '%s' "$RESULT" | jq -r '.strategies | length')
i=0
LEAVINGS='[]'
while [ "$i" -lt "$n" ]; do
  row=$(printf '%s' "$RESULT" | jq -c --argjson i "$i" '.strategies[$i]')
  if [ -f "$COMPOSER" ]; then
    slug=$(printf '%s' "$row" | jq -r '.slug')
    leaving=$(printf '%s' "$row" | sh "$COMPOSER" --state-row - "$slug" "$WINDOW" "${ROOT:-.workaholic}" 2>/dev/null || true)
  else
    leaving=''
  fi
  if [ -z "$leaving" ] || ! printf '%s' "$leaving" | jq -e . >/dev/null 2>&1; then
    leaving='{"ok": true, "readable": false, "reason": "leaving_uncomposable", "exhaustive": false}'
  fi
  LEAVINGS=$(printf '%s' "$LEAVINGS" | jq -c --argjson l "$leaving" '. + [$l]')
  i=$((i + 1))
done

printf '%s' "$RESULT" | jq -c --argjson leavings "$LEAVINGS" '
  .strategies = [ .strategies | to_entries[] | .value + {leaving: $leavings[.key]} ]'
