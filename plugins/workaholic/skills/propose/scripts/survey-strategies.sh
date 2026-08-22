#!/bin/sh -eu
# survey-strategies.sh — WHICH STRATEGIES MAY BE PROPOSED AGAINST THIS TICK, and for every
# one that may not, the named reason why. Pure read: it writes nothing, commits nothing and
# creates no branch. The one network call it makes is the open-proposal gate
# (`list-open-proposals.sh`), and it refuses the whole tick rather than proceed without it.
#
# Usage: survey-strategies.sh [window] [workaholic-root]
#   --open-proposals <file>  supply an already-performed `list-open-proposals.sh` read
#   window: any `git log --since` expression; defaults to "14 days ago" — wider than the
#           standup's day, because this judges a DIRECTION's progress, not a morning's.
#
# Output (one JSON object):
#   {ok, identity, window, cap, active_count,
#    eligible: [{slug, title, target_date, days_to_target, assignees, feedback_refs[],
#                empty_reason, count, active_count, waiting_count,
#                landed: [{kind, title, state, attribution, last_change}],
#                path}],
#    refused: [{slug, reason}], errors: [], selected: [<slug>...]}
#   or {ok: false, reason, detail} when a gate could not be read at all.
#
# ═══ THE GATES ARE THE BRAKE, AND THE BRAKE IS THE WHOLE DESIGN ═══════════════════════
#
# `/propose` is the first unattended routine in this repository to drop the standing
# conservative bar (`workaholic:specificate`, *The judgment bar*: when unsure, record only,
# and say what made you unsure). It drops it on purpose — a routine that only proposed what
# it was sure of would propose housekeeping, which is exactly what the ask refuses. What
# replaces the bar is not a softer judgment; it is this list of MECHANICAL, DERIVED gates,
# every one of them computed from state the repository already holds, none of them a call
# the running session can make differently:
#
#   not_active        `status` is not `active`. A closed direction is not pursued.
#   not_mine          the running identity is not among `assignees`. The ask is "the user's
#                     OWN assigned strategies"; a strategy is the one artifact where empty
#                     `assignees` is a refusal rather than team ownership, so `unowned`
#                     cannot occur and `other`/`unresolved` are both refusals here.
#   past_target_date  the date has passed. A dated direction that ran out of date is the
#                     operator's to re-date or close; proposing into it forever is the
#                     runaway this gate exists to stop.
#   no_feedback_refs  the strategy cites no feedback record, so `attributed-work.sh` can
#                     never attribute anything back to it — every proposal would land
#                     invisible and the loop could not close. Refused with the repair named
#                     rather than proposed into blindly. THIS IS THE ONE GATE THAT ANSWERS
#                     THE LOSSY READER: the judgment is made only where the reader can see.
#   work_waiting      attributable tickets are queued. The previous turn of the loop has
#                     not landed, so this one does not start. Together with `open_proposal`
#                     this is "one proposal per strategy IN FLIGHT at a time" — see below.
#   open_proposal     an open issue already carries this strategy's marker: the last
#                     proposal has not been ingested yet.
#
# `no_citing_artifacts` IS NOT A REFUSAL, and the distinction is the one most likely to be
# got wrong by a later reader. A brand-new strategy cites feedback but nothing cites it
# back, so `attributed-work.sh` reports `no_citing_artifacts` — and that is precisely the
# state in which a proposal is most wanted, because nothing has happened yet. Only
# `no_feedback_refs` (the strategy cites NOTHING, so nothing ever can cite it back) makes a
# strategy illegible. One means "no work yet"; the other means "no way to see work".
#
# THE TWO IN-FLIGHT GATES HAND OFF WITH NO WINDOW, which is what makes a per-day bound
# unnecessary and, worse, harmful: the ask is for three routines turning an HOURLY loop, and
# a daily cap on the only routine that originates work would cap the loop at one turn a day.
# From the issue opening until its `[Specificate]` pull request merges, `open_proposal`
# holds; from that merge onward the tickets it produced are queued and `work_waiting` holds;
# when they are driven and archived, the strategy is free and the next turn begins.
#
# EVERY ELIGIBLE STRATEGY, IN THE SAME TICK (2026-08-22, the developer's ruling). The tick
# proposes against ALL of them -- everything it can conclude at that moment. Eligible
# strategies are still ordered by `days_to_target` ascending, nearest date first, so a tick
# that dies partway has advanced the most urgent direction rather than an arbitrary one.
#
# THIS REPLACES "one proposal per tick, across all strategies" (`WORKAHOLIC_PROPOSE_MAX`,
# default 1), and the reasoning that carried it is ANSWERED rather than dropped. That
# reasoning was: a developer carrying eight strategies must not wake to eight issues at
# :40. But the volume bound was never this cap's to provide -- `work_waiting` and
# `open_proposal` together already give ONE PROPOSAL PER STRATEGY IN FLIGHT AT A TIME, so
# eight issues can only arrive when all eight directions are idle, and then eight
# directions each genuinely need their next move.
#
# WHAT THE CAP ACTUALLY DID, AND WHY IT RAN BACKWARDS. It reduced no total; it fixed an
# ORDER, putting some directions permanently behind others. And the ordering it produced
# was the wrong way round: a strategy is skipped while its OWN work is in flight, so the
# direction whose work takes LONGER is proposed against LESS often. The direction that
# most needs its next move is the one the cap starves. Measured on a consuming repository:
# two active strategies sharing a `target_date`, one building a platform whose build work
# sat queued for hours (`work_waiting` on every tick) and one documentation direction that
# drained fast and was therefore eligible on every tick. The channel filled with one
# direction's output for a day while the other never got a turn.
#
# The ceiling on issues opened per tick is raised, and that is the intent: the loop's
# output should be what it can conclude, and the brake belongs on work in flight PER
# DIRECTION, which already exists and is untouched here.
#
# WHY THE WINDOW IS 14 DAYS AND NOT THE STANDUP'S ONE. `landed[]` is not a changelog here;
# it is the evidence the judgment is made against — "how far has this direction actually
# got" — and a direction is not a morning. The window bounds what is SHOWN, never what is
# gated: the in-flight gates read `waiting_count`, which `attributed-work.sh` computes over
# the queue rather than the window.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts"

# `--open-proposals <file>` lets a caller supply the remote read it has ALREADY performed
# rather than making it twice: the run's first act is often `list-open-proposals.sh` in its
# own right, and a second call would double the network cost and could disagree with the
# first across the seconds between them. It is an input, never a bypass — a file that does
# not parse, or whose `ok` is not true, refuses the tick exactly as an unreadable inbox
# does, because a gate supplied wrong and a gate unread are the same missing gate.
OPEN_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --open-proposals) OPEN_FILE="${2:-}"; shift 2 ;;
    --) shift; break ;;
    -*) echo '{"ok": false, "reason": "usage", "detail": "unknown flag"}'; exit 0 ;;
    *) break ;;
  esac
done

WINDOW="${1:-14 days ago}"
ROOT="${2:-.workaholic}"

# UNBOUNDED BY DEFAULT (2026-08-22). `WORKAHOLIC_PROPOSE_MAX` survives as an explicit
# opt-in bound for an operator who really does want fewer; its default is NO BOUND, and
# the default is the point -- a default of 1 is what produced the starvation described in
# the header. An unset, empty or non-numeric value means unbounded; `0` also means
# unbounded rather than "propose nothing", because a cap of zero would silence the only
# routine that originates work and no operator asking for a bound means that.
CAP="${WORKAHOLIC_PROPOSE_MAX:-}"
case "$CAP" in
  ''|*[!0-9]*|0) CAP=-1 ;;
esac

emit_err() {
  detail="$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
  printf '{"ok": false, "reason": "%s", "detail": "%s"}\n' "$1" "$detail"
  exit 0
}

command -v jq >/dev/null 2>&1 || emit_err "jq_unavailable" "jq is not on PATH"

# The remote gate first: a tick that cannot read what it already has open proposes nothing.
if [ -n "$OPEN_FILE" ]; then
  OPEN="$(cat "$OPEN_FILE" 2>/dev/null || true)"
else
  OPEN="$(sh "${SCRIPT_DIR}/list-open-proposals.sh" 2>/dev/null || true)"
fi
[ -n "$OPEN" ] || emit_err "inbox_unreadable" "list-open-proposals.sh produced no output"
if [ "$(printf '%s' "$OPEN" | jq -r '.ok // false' 2>/dev/null || echo false)" != "true" ]; then
  emit_err "inbox_unreadable" "$(printf '%s' "$OPEN" | jq -r '.reason + ": " + (.detail // "")')"
fi
IDENTITY="$(printf '%s' "$OPEN" | jq -r '.identity')"

# The identity that OWNS work is the git email, not the GitHub login (`gather/scripts/
# owns.sh`); the login is the issue-assignment key. Both are read, neither is guessed.
ME="$(git config user.email 2>/dev/null || true)"

# EVERY strategy, not only the active ones. `not_active` is a documented gate, and a gate
# has to be able to REPORT: filtering here would make a closed direction vanish from the
# survey instead of being refused by name, which is exactly the "a skipped strategy and a
# refused one must never look alike" distinction the whole reporting contract rests on.
LIST="$(sh "${STRATEGY_SCRIPTS}/list.sh" "$ROOT" 2>/dev/null || true)"
[ -n "$LIST" ] || emit_err "strategy_list_unreadable" "list.sh produced no output"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

: > "${TMP}/rows"
printf '%s' "$LIST" | jq -r '.strategies[].slug' 2>/dev/null | while IFS= read -r slug; do
  [ -n "$slug" ] || continue
  work="$(sh "${STRATEGY_SCRIPTS}/attributed-work.sh" "$slug" "$WINDOW" "$ROOT" 2>/dev/null || true)"
  [ -n "$work" ] || work="{\"slug\": \"${slug}\", \"found\": false, \"unreadable\": true}"
  path="${ROOT}/strategies/${slug}.md"
  owns="unresolved"
  if [ -f "$path" ]; then
    owns="$(sh "${GATHER_SCRIPTS}/owns.sh" "$path" "$ME" 2>/dev/null || echo unresolved)"
  fi
  printf '%s' "$work" | jq -c --arg owns "$owns" --arg path "$path" '. + {owns: $owns, path: $path}' >> "${TMP}/rows"
done

TODAY="$(date -u +%Y-%m-%d)"

jq -sc \
  --argjson list "$(printf '%s' "$LIST")" \
  --argjson open "$(printf '%s' "$OPEN")" \
  --arg today "$TODAY" \
  --arg window "$WINDOW" \
  --arg identity "$IDENTITY" \
  --argjson cap "$CAP" '
  def days($t): if ($t | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))
      then (((($t + "T00:00:00Z") | fromdateiso8601) - (($today + "T00:00:00Z") | fromdateiso8601)) / 86400 | floor)
      else null end;
  ($open.proposals | map(.strategy)) as $held
  | [ .[]
      | . as $w
      | (($list.strategies[] | select(.slug == $w.slug)) // {}) as $s
      | {slug: $w.slug, title: ($s.title // $w.slug), status: ($s.status // ""),
         target_date: ($s.target_date // ""), days_to_target: days($s.target_date // ""),
         assignees: ($s.assignees // ""), owns: $w.owns, path: $w.path,
         feedback_refs: ($w.feedback_refs // []),
         empty_reason: ($w.empty_reason // ""),
         count: ($w.count // 0), active_count: ($w.active_count // 0),
         waiting_count: ($w.waiting_count // 0),
         landed: (($w.artifacts // []) | map(select(.changed_in_window))
                  | map({kind, title, state, attribution, last_change})),
         queued: (($w.artifacts // []) | map(select(.kind == "ticket" and .state == "queued"))
                  | map({title})),
         unreadable: ($w.unreadable // false)}
      | . + {refusal:
          (if .unreadable then "attribution_unreadable"
           elif .status != "active" then "not_active"
           elif .owns != "mine" then "not_mine"
           elif ((.days_to_target != null) and (.days_to_target < 0)) then "past_target_date"
           elif ((.feedback_refs | length) == 0) then "no_feedback_refs"
           elif ((.waiting_count // 0) > 0) then "work_waiting"
           elif ($held | index($w.slug)) then "open_proposal"
           else "" end)} ]
  | sort_by(if .days_to_target == null then 99999 else .days_to_target end)
  | (map(select(.refusal == "")) ) as $ok
  | (if $cap < 0 then $ok else $ok[0:$cap] end) as $take
  | (if $cap < 0 then [] else ($ok[$cap:] | map({slug, reason: "over_cap"})) end) as $spill
  | {ok: true, identity: $identity, window: $window, cap: $cap,
     active_count: ([.[] | select(.status == "active")] | length),
     surveyed_count: ($list.strategies | length),
     eligible: ($take | map(del(.refusal, .unreadable, .owns))),
     refused: ((map(select(.refusal != "")) | map({slug, reason: .refusal})) + $spill),
     selected: ($take | map(.slug)),
     errors: []}
  ' "${TMP}/rows"
