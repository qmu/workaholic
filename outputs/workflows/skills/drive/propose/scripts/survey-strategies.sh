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
#                empty_reason, count, active_count, waiting_count, pace, overdue, expiring,
#                dormant, quiescent, residue,
#                landed: [{kind, title, state, attribution, last_change}],
#                path}],
#    refused: [{slug, reason, pace, overdue, expiring, dormant, quiescent, residue, title,
#               assignees, days_to_target, target_date, landed_count}],
#    errors: [], selected: [<slug>...]}
#
#   residue  {readable, reason, missions: [{slug, queued}], mission_count, ticket_count} —
#            WHAT NO DIRECTION CLAIMS, read once per survey from
#            `strategy/scripts/unattributed-work.sh` and put unchanged on EVERY row. A
#            degraded read carries `readable: false` with its reason and NULL counts, never a
#            zeroed residue. It gates nothing except `quiescent` (see that block).
#   or {ok: false, reason, detail} when a gate could not be read at all.
#
# A ROW WHOSE ATTRIBUTION WALK DID NOT COMPLETE (2026-08-29): refused
# `attribution_unreadable` — the word this condition has always had, never a second one — with
# `pace: unknown`, `dormant: false`, `quiescent: false` and NULL `count` / `active_count` /
# `waiting_*`. `work_waiting` cannot stand open on it, because the refusal ladder answers
# first: a degraded walk cannot prove the brake is clear, and a gate that cannot be read is
# not a gate. The DATE terms are untouched — `days_to_target`, `overdue` and `expiring` come
# from the strategy's own `target_date` and never from the walk.
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
#   observing         the operator DECLARED this direction 観察中 — settled, the loop
#                     reactive only. It is the FIRST DECLARED gate on this list, and that is
#                     exactly what makes it safe: every other gate is derived, and a derived
#                     silence was refused by name (`pace` gates nothing, because a machine's
#                     guess must not silence the one routine that originates work). The
#                     operator's own word is not a guess.
#                     PLACED AFTER `not_active` AND `not_mine`: a closed or foreign direction
#                     is not this repository's question at all, and answering `observing` for
#                     one would send a reader to the wrong fact. PLACED BEFORE
#                     `past_target_date`: an observing direction that is also overdue should
#                     read as observing, because that is the fact a person acts on, and
#                     lateness on a settled direction is not a failure.
#                     IT STOPS ORIGINATION AND NOTHING ELSE. An inbound ask — a swept channel
#                     message, an issue somebody files, an error reported — still becomes an
#                     `[FB]` issue, still reaches `/specificate`, and still lands as work
#                     carrying this direction's refs. That asymmetry is the whole stage.
#   past_target_date  the date has passed. A dated direction that ran out of date is the
#                     operator's to re-date or close; proposing into it forever is the
#                     runaway this gate exists to stop.
#   no_feedback_refs  the strategy cites no feedback record, so `attributed-work.sh` can
#                     never attribute anything back to it — every proposal would land
#                     invisible and the loop could not close. Refused with the repair named
#                     rather than proposed into blindly. THIS IS THE ONE GATE THAT ANSWERS
#                     THE LOSSY READER: the judgment is made only where the reader can see.
#   work_waiting      a MISSION attributed to this strategy is still in flight, or an
#                     attributable ticket is still queued (2026-08-26: the grain moved to
#                     the mission, because a proposal now plans one). The previous turn of
#                     the loop has not landed, so this one does not start. Together with
#                     `open_proposal` this is "ONE MISSION PER STRATEGY IN FLIGHT AT A
#                     TIME" -- see below.
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
# holds; THAT SAME MERGE puts the mission on `main`, so `work_waiting` holds from the same
# instant -- the handoff is window-free by construction rather than by timing. It then holds
# until the mission is closed, which since 2026-08-23 the archive gate does on its own
# arithmetic when the acceptance is complete and the queue is empty. Then the strategy is
# free and the next turn begins.
#
# THE MISSION TERM IS WIDER THAN THE TICKET TERM IT SITS BESIDE, and that is the point: a
# mission whose last ticket has been claimed and archived has NO queued tickets while its
# work is still in flight at a pull request. Under the change-grain gate that gap was the
# design (the next change could start); under the mission grain it is exactly the window a
# second mission would slip through. The ticket term stays because a loose ticket emitted
# with no mission around it must still brake.
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
# PACE: THE ONE READING THAT IS NOT A BRAKE (2026-08-22). Every gate above reduces
# proposals. None asked whether the direction will ARRIVE, so a strategy could be
# perfectly gated and still reach its date with nothing built -- measured on a consuming
# repository, a platform strategy seven days from its date whose 19 attributed artifacts
# were all specification pages and whose deploy config still said the worker had no code
# of its own. Every gate was correct on every tick.
#
# THE DERIVATION NEEDS NO THRESHOLD, WHICH IS WHAT MAKES IT DEFENSIBLE. `late` means "no
# evidence of movement over a period as long as the one that remains": one window was
# looked back over, nothing landed in it, and fewer days remain than that window. Both
# terms are already justified here -- the window is the evidence the judgment is made
# against, and the remaining days are the strategy's own date. A ratio would imply an
# accuracy `landed[]` cannot support, since its own reader states attribution is
# transitive and LOSSY.
#
# IT IS EVIDENCE, NEVER A VERDICT. `unknown` is a real third answer and must not collapse
# into either other one: a degraded attribution read cannot tell a stalled direction from a
# moving one, and a strategy with no resolvable `target_date` is not late -- it is
# malformed, since the artifact requires a date.
#
# IT DOES NOT JUDGE WHAT LANDED. Whether nineteen documentation pages advance a build aim
# is `describing_move`'s question and is answered there. This reading is rate and remaining
# time only; one judgement in two places is how they drift.
#
# IT CHANGES ORDER, NEVER ELIGIBILITY. A late direction that is `work_waiting` is still
# `work_waiting`. The temptation is to let lateness LIFT a gate; that would produce two
# proposals for one direction, which is what `work_waiting` exists to prevent, and the
# answer to "the work is in flight but not moving" is not more proposals.
#
# WHY THE WINDOW IS 14 DAYS AND NOT THE STANDUP'S ONE. `landed[]` is not a changelog here;
# it is the evidence the judgment is made against — "how far has this direction actually
# got" — and a direction is not a morning. The window bounds what is SHOWN, never what is
# gated: the in-flight gates read `waiting_count`, which `attributed-work.sh` computes over
# the queue rather than the window.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STRATEGY_SCRIPTS="${SCRIPT_DIR}/../../strategy/scripts/"
GATHER_SCRIPTS="${SCRIPT_DIR}/../../gather/scripts/"

# `--open-proposals <file>` lets a caller supply the remote read it has ALREADY performed
# rather than making it twice: the run's first act is often `list-open-proposals.sh` in its
# own right, and a second call would double the network cost and could disagree with the
# first across the seconds between them. It is an input, never a bypass — a file that does
# not parse, or whose `ok` is not true, refuses the tick exactly as an unreadable inbox
# does, because a gate supplied wrong and a gate unread are the same missing gate.
OPEN_FILE=""
# THE AIM IS A JUDGMENT AND STAYS WHERE IT IS ALREADY MADE (2026-08-23). Nothing here can
# read an Aim and say whether it is to build or to document — `/propose` makes exactly that
# call for `describing_move`, so it passes the answer in rather than a second place guessing
# it. Absent, `unknown` keeps the pre-2026-08-23 gate byte-for-byte: `work_waiting` off the
# undifferentiated count.
AIM_KIND=unknown

while [ $# -gt 0 ]; do
  case "$1" in
    --open-proposals) OPEN_FILE="${2:-}"; shift 2 ;;
    --aim-kind) AIM_KIND="${2:-unknown}"; shift 2 ;;
    --) shift; break ;;
    -*) echo '{"ok": false, "reason": "usage", "detail": "unknown flag"}'; exit 0 ;;
    *) break ;;
  esac
done

WINDOW="${1:-14 days ago}"
# The window in DAYS, for the pace reading. It is derived from the same `$WINDOW` the
# evidence is gathered over rather than being a second, independently-tunable number --
# "no movement over a period as long as the one that remains" only means anything while
# the two are the same period. A window with no leading integer falls back to 14, which
# is the documented default.
WINDOW_DAYS="$(printf '%s' "$WINDOW" | sed -n 's/^\([0-9][0-9]*\).*/\1/p')"
[ -n "$WINDOW_DAYS" ] || WINDOW_DAYS=14
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

# THE RESIDUE — WHAT NO DIRECTION CLAIMS (2026-08-28, mission
# `say-what-the-direction-could-not-see-before-calling-it-arrived`). Read ONCE PER SURVEY, not
# once per row: it is a fact about the REPOSITORY, not about a direction, and reading it per
# row would spend N walks of the active area to produce N copies of one answer.
#
# It is a LOCAL read. The survey makes exactly one network call (the open-proposal gate) and
# this adds none, which is what keeps `--open-proposals`' held-read contract intact.
#
# A REFUSAL IS CARRIED, NEVER SWALLOWED. `unattributed-work.sh` always exits 0 and reports
# `readable: false` with its own reason; a missing script or a garbled answer becomes the same
# shape here rather than an empty residue, because `quiescent` reads exactly that flag and an
# unreadable residue must never be mistaken for an empty one.
RESIDUE="$(sh "${STRATEGY_SCRIPTS}/unattributed-work.sh" --root "$ROOT" 2>/dev/null || true)"
if [ -z "$RESIDUE" ] || ! printf '%s' "$RESIDUE" | jq -e . >/dev/null 2>&1; then
  RESIDUE='{"readable": false, "reason": "residue_unreadable", "missions": [], "mission_count": null, "ticket_count": null}'
fi
RESIDUE="$(printf '%s' "$RESIDUE" | jq -c '{readable: (.readable // false),
                                            reason: (.reason // ""),
                                            missions: ((.missions // []) | map({slug, queued})),
                                            mission_count: .mission_count,
                                            ticket_count: .ticket_count}')"

jq -sc \
  --argjson list "$(printf '%s' "$LIST")" \
  --argjson open "$(printf '%s' "$OPEN")" \
  --argjson residue "$(printf '%s' "$RESIDUE")" \
  --arg today "$TODAY" \
  --arg window "$WINDOW" \
  --arg identity "$IDENTITY" \
  --argjson cap "$CAP" \
  --argjson window_days "$WINDOW_DAYS" \
  --arg aim_kind "$AIM_KIND" '
  def days($t): if ($t | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))
      then (((($t + "T00:00:00Z") | fromdateiso8601) - (($today + "T00:00:00Z") | fromdateiso8601)) / 86400 | floor)
      else null end;
  ($open.proposals | map(.strategy)) as $held
  | [ .[]
      | . as $w
      | (($list.strategies[] | select(.slug == $w.slug)) // {}) as $s
      # A WALK THAT DID NOT COMPLETE IS A ROW WE COULD NOT READ (2026-08-29, mission
      # `keep-the-closing-link-readable-as-the-corpus-grows`). `attributed-work.sh` produced
      # NO OUTPUT AT ALL was already `unreadable`; since that reader learned to say so,
      # `readable: false` is the same fact reported properly instead of by silence, and it
      # joins the same term rather than getting one of its own. That is what makes every
      # derivation below correct with NO further change: `pace` reads `unknown`, `dormant`
      # and `quiescent` read `false`, and `refusal` answers `attribution_unreadable` — the
      # word this condition has always had — before `work_waiting` is ever evaluated.
      #
      # `work_waiting` MUST NOT STAND OPEN on such a row, and the ladder is what guarantees
      # it: a degraded walk cannot prove the brake is clear, and A GATE THAT CANNOT BE READ
      # IS NOT A GATE — the rule `no_feedback_refs` and `inbox_unreadable` already hold
      # themselves to. This is the failure the ask measured: a tick selecting a direction on
      # `waiting_count: 0` while two active missions and ten queued tickets cited it.
      #
      # `readable` is ABSENT on a completed walk, by the contract that reader states, so the
      # test is `== false` and NOT `(.readable // true) | not`: in jq `//` treats `false`
      # itself as empty, so `false // true` is `true` and that spelling would read every
      # degraded walk as a healthy one — silently, which is the whole failure class again.
      | (($w.unreadable // false) or ($w.readable == false)) as $blind
      | {slug: $w.slug, title: ($s.title // $w.slug), status: ($s.status // ""),
         # THE DECLARED STAGE THE OPERATOR WROTE DOWN, on every row (2026-08-29, mission
         # `make-a-direction-s-lifecycle-a-declared-stage`). It rides BESIDE the derived
         # readings and enters no derivation here: this survey gains no gate, no sort term and
         # no refusal from it in this change. It comes straight off `list.sh`, which resolves
         # the absent-means-進行中 default through `read.sh` — the ONE place that default
         # lives — so an empty string here means only that the listed row could not be matched,
         # which the sanctioned path (these slugs come from that same list) cannot produce.
         #
         # A DEGRADED ROW STILL CARRIES ITS STAGE. The stage is read off the artifact and the
         # degradation is a property of the ATTRIBUTION WALK, so `attribution_unreadable` says
         # nothing about whether the operator declared a phase — nulling it here would be the
         # collapse the null counts beside it exist to prevent, in reverse.
         stage: ($s.stage // ""),
         # Whether that value was DECLARED or defaulted. Carried for the one consumer that
         # speaks in the operator voice and must not quote a declaration nobody made; no gate,
         # sort or refusal here reads it.
         stage_declared: ($s.stage_declared // false),
         target_date: ($s.target_date // ""), days_to_target: days($s.target_date // ""),
         assignees: ($s.assignees // ""), owns: $w.owns, path: $w.path,
         feedback_refs: ($w.feedback_refs // []),
         empty_reason: ($w.empty_reason // ""),
         # NULL, NEVER ZERO, ON A ROW WE COULD NOT READ. A zero here is the whole defect one
         # layer up: a consumer skimming the counts reads *nothing is waiting* out of a walk
         # that never looked. Nothing arithmetic reaches these — every derivation below tests
         # `.unreadable` first — so the null is read by consumers and by nothing else.
         count: (if $blind then null else ($w.count // 0) end),
         active_count: (if $blind then null else ($w.active_count // 0) end),
         waiting_count: (if $blind then null else ($w.waiting_count // 0) end),
         # WHICH KIND OF WORK THE GATE SAW (2026-08-23), on every row, gated or not: a
         # strategy suppressed — or not suppressed — says why.
         waiting_kind: (if $blind then null else ($w.waiting_kind // "unknown") end),
         waiting_describing: (if $blind then null else ($w.waiting_describing // 0) end),
         waiting_advancing: (if $blind then null else ($w.waiting_advancing // $w.waiting_count // 0) end),
         # THE MISSION GRAIN (2026-08-26), reported on every row for the same reason: the
         # brake now asks whether a mission is in flight, so a reader must be able to see
         # which one held it. Named, never a bare count.
         waiting_missions: (if $blind then null else ($w.waiting_missions // 0) end),
         waiting_missions_describing: (if $blind then null else ($w.waiting_missions_describing // 0) end),
         waiting_missions_advancing: (if $blind then null else ($w.waiting_missions_advancing // $w.waiting_missions // 0) end),
         waiting_mission_slugs: (if $blind then null else ($w.waiting_mission_slugs // []) end),
         landed: (($w.artifacts // []) | map(select(.changed_in_window))
                  | map({kind, title, state, attribution, last_change})),
         queued: (($w.artifacts // []) | map(select(.kind == "ticket" and .state == "queued"))
                  | map({title})),
         # THE RESIDUE, ON EVERY ROW (2026-08-28). The same object on every one of them —
         # eligible AND refused — because a direction refused `past_target_date` is exactly
         # the one whose residue the operator must still see: that is the direction they are
         # about to be asked to re-date or close.
         #
         # IT IS ITS OWN FIELD, never folded into `pace` or any existing one. One field
         # answering two questions is how the two drift -- the reasoning `overdue` records
         # for itself -- and this answers a question about the REPOSITORY while every field
         # beside it answers one about the direction.
         residue: $residue,
         unreadable: $blind}
      | . + {pace:
          # PACE -- WILL THIS DIRECTION ARRIVE? (2026-08-22.) Every other gate here is a
          # brake. None of them asked this, so a strategy could be perfectly gated (every
          # brake correct, every tick silent for a correct reason) and reach its date with
          # nothing built. `days_to_target` was read ONLY by `past_target_date` -- it HAS
          # PASSED -- never WILL IT BE MET; `landed[]` was read only by
          # `no_citing_artifacts` and `work_waiting`. Both were already here; nothing put
          # them together. Full reasoning: SKILL.md, *Pace: the one gate that is not a brake*.
          (if .unreadable or (.days_to_target == null) then "unknown"
           elif ((.landed | length) == 0) and (.days_to_target <= $window_days) then "late"
           else "on_course" end)}
      | . + {overdue:
          # OVERDUE -- HAS THE DATE PASSED? (2026-08-26.) `pace` cannot carry this and must
          # not be asked to: `late` requires `(.landed | length) == 0`, so a direction that
          # sailed past its date WHILE PRODUCING WORK reads `on_course`, is refused
          # `past_target_date` for a correct reason, and produces no proposal and no
          # question -- forever. One field answering two questions is how the two drift:
          # `pace` answers WILL THIS ARRIVE, `overdue` answers HAS THE DATE PASSED.
          #
          # It is emitted on EVERY row, eligible and refused alike, because the refused
          # case is the whole point -- a reader that saw only `eligible` would never see a
          # direction whose date has gone. It is computed BEFORE `refusal` so that
          # expression stays byte-identical, and it changes no gate, no eligibility and no
          # sort: `past_target_date` refuses exactly what it refused before.
          #
          # A row with no resolvable `target_date` is never `overdue` -- `days_to_target`
          # is `null` there, and a malformed strategy is not a late one. `days_to_target`
          # is computed against a UTC `$today`, so a direction expiring TODAY reads `0`
          # and is not yet overdue. That is the correct boundary, stated rather than tuned.
          ((.days_to_target != null) and (.days_to_target < 0))}
      | . + {expiring:
          # EXPIRING -- IS THE DATE ABOUT TO ARRIVE? (2026-08-29.) Every reading beside this one
          # answers BACKWARDS: `late` asks whether nothing has landed, `overdue` whether the date
          # has GONE, `dormant` whether anything is answering it, `quiescent` whether its work is
          # all in. None answers *this direction is about to stop originating work*, so a live,
          # in-date, `on_course` direction one day from its date produced NO READING AND NO
          # QUESTION anywhere in the layer -- and the day after, `past_target_date` silenced
          # `/propose` with the only signal being `direction-overdue`, asked in ARREARS.
          #
          # Measured on `an-autonomous-improvement-loop-run-by-the-routines` at the hour the ask
          # was written: `days_to_target: 2`, `pace: on_course`, `overdue: false`,
          # `dormant: false` -- every reading healthy, two days from silence.
          #
          # IT INTRODUCES NO NEW THRESHOLD, which is what makes it defensible rather than tuned.
          # Both terms are already on the row and already justified there: `$window_days` is the
          # evidence window the judgment is made against (the same term `pace` is derived
          # against, out of the same `$WINDOW`), and the remaining days are the date the strategy
          # itself declares. So the reading means *less runway remains than the window the
          # judgment can see* -- precisely the point at which `pace` stops being able to tell
          # whether the direction will arrive. A fresh constant here would be a number nobody
          # could defend.
          #
          # IT IS ITS OWN FIELD, NEVER A FOURTH `pace` VALUE, for the reason `overdue` records
          # for itself one block up: one field answering two questions is how the two drift.
          #
          # THE BOUNDARIES ARE EXHAUSTIVE AND DISJOINT WITH `overdue`, and stated rather than
          # tuned. `days_to_target < 0` is the answer `overdue` gives and never this one; a
          # direction whose date is TODAY reads `0` and IS expiring, not overdue; and a row with
          # no resolvable `target_date` has a `null` `days_to_target` and is never expiring --
          # malformed is not near, exactly as malformed is not late.
          #
          # It is emitted on EVERY row, eligible and refused alike, and computed BEFORE
          # `refusal` so that expression, `pace`, `overdue`, `dormant`, `quiescent`, the sort and
          # `selected` stay byte-identical. The refused case is the point: a direction refused
          # `work_waiting` still has a date coming, and it is the one whose warning matters.
          ((.days_to_target != null) and (.days_to_target >= 0)
           and (.days_to_target <= $window_days))}
      | . + {dormant:
          # DORMANT -- A LIVE DIRECTION NOTHING IS ANSWERING (2026-08-26). `/propose` reports
          # `no_evolutionary_move` when it cannot name a move against an eligible direction --
          # the honest answer -- into a run report that on the day it matters is read by
          # nobody, and the direction stays eligible on every tick while producing nothing.
          # The state is byte-identical to a healthy idle hour, which is the whole defect.
          #
          # EVERY TERM IS ALREADY COMPUTED HERE OR BY `attributed-work.sh` BENEATH IT: no new
          # counter, no field on any artifact, and no second derivation of `pace`. It is a
          # conjunction of what the row already holds -- legible, active, owned, in date, with
          # something the reader could have seen, nothing landed in the window, nothing
          # waiting at either grain, and no proposal already open.
          #
          # IT IS NOT `pace: late`, which needs the date to be NEAR (`days_to_target <=
          # $window_days`); a direction a year out with nothing happening is dormant and not
          # late. It is not `no_citing_artifacts` either -- that reading is explicitly NOT a
          # refusal here (see the header), and this is not one: a dormant direction stays
          # eligible, which is precisely what makes its silence a FINDING rather than a gate.
          #
          # THE TWO PERIODS ARE DIFFERENT AND THAT IS INHERITED, NOT RECONCILED: `landed` is
          # bounded by `$WINDOW` while `waiting_*` is computed over the queue. The reading
          # therefore means "nothing landed in the window and nothing is waiting at all".
          (if (.unreadable or (.status != "active") or (.owns != "mine")) then false
           elif ((.days_to_target != null) and (.days_to_target < 0)) then false
           elif ((.feedback_refs | length) == 0) then false
           elif ((.landed | length) > 0) then false
           elif (((.waiting_missions // 0) + (.waiting_count // 0)) > 0) then false
           elif ($held | index($w.slug)) then false
           else true end)}
      | . + {quiescent:
          # QUIESCENT -- A DIRECTION WHOSE WORK IS ALL IN (2026-08-27). Every other reading
          # here answers IS THIS DIRECTION IN TROUBLE: `pace` asks whether it will arrive,
          # `overdue` whether its date has gone, `dormant` whether anything is answering it.
          # None asked WHETHER IT HAS ARRIVED, so a direction that produced its work and has
          # nothing left in flight is byte-identical to one still running -- and when its
          # date passes, the loop reports that SUCCESS as an hourly `direction-overdue`
          # question. Naming a success as a failure is the defect this reading removes.
          #
          # IT IS THE COMPLEMENT OF `dormant` ON ONE TERM, and only one: `landed` EMPTY (nothing
          # has answered this direction) versus `landed` NON-EMPTY (its answers are all in).
          # Every other term is shared and every term is already on the row -- no new
          # counter, no field on any artifact, no second derivation. The two are mutually
          # exclusive by construction, and nothing enforces that: deriving each from the row
          # independently is what keeps them from drifting.
          #
          # IT CARRIES NO DATE TERM AT ALL, deliberately, unlike `dormant` (which is `false`
          # once `days_to_target < 0`). ARRIVAL IS INDEPENDENT OF THE DATE -- a direction
          # that finished late has still finished -- and that independence is exactly why
          # the projected lifecycle state (`direction-state.sh`) ranks `arrived` ABOVE
          # `overdue`. Folding a date term in here would make the projection unreachable for
          # the one case it exists to serve.
          #
          # IT IS EMITTED ON EVERY ROW, eligible and refused alike, for the reason `overdue`
          # is: the refused case is the point, since a direction whose date has passed is
          # refused `past_target_date` and would otherwise never show its arrival to anyone.
          # It is computed BEFORE `refusal` so that expression, `pace`, `overdue`, `dormant`,
          # the sort and `selected` stay byte-identical.
          #
          # IT LIFTS AND CLOSES NO GATE. An arrived direction stays eligible and `/propose`
          # keeps proposing against it; the gate that eventually holds is `not_active`, after
          # A PERSON closes the direction. A reading of arrival made by a machine is not a
          # decision that the direction is done.
          #
          # AND SINCE 2026-08-28 IT REFUSES AN ARRIVAL OVER A TREE WE COULD NOT SEE (mission
          # `say-what-the-direction-could-not-see-before-calling-it-arrived`). A DEGRADED
          # residue read makes `quiescent` false: this is the `unreadable`-is-never-`dormant`
          # precedent, and the rule `no_feedback_refs` records -- a gate that cannot be read
          # is not a gate -- applied to the one reading that speaks in the vocabulary of
          # COMPLETENESS.
          #
          # THE ASYMMETRY WITH `dormant` IS THE WHOLE JUSTIFICATION, and `dormant` is
          # deliberately left alone. Claiming a direction has ARRIVED on a blind read sends
          # the operator to CLOSE it; every other reading only asks them to LOOK. Only the
          # reading whose next act is destructive is refused when the tree could not be read.
          #
          # A NON-EMPTY RESIDUE DOES NOT REFUSE THE ARRIVAL, and that restraint is
          # load-bearing. An unattributed mission is not work belonging to this direction --
          # saying it were would be exactly the inference this mission refuses -- and
          # refusing on it would let any unrelated mission in the tree suppress every
          # arrival forever, which is a different defect with the same shape. Only the
          # UNREADABLE case refuses; what a non-empty residue earns is being NAMED, wherever
          # the arrival is reported or asked about.
          (if (.unreadable or (.status != "active") or (.owns != "mine")) then false
           elif ((.residue.readable // false) | not) then false
           elif ((.feedback_refs | length) == 0) then false
           elif ((.landed | length) == 0) then false
           elif (((.waiting_missions // 0) + (.waiting_count // 0)) > 0) then false
           elif ($held | index($w.slug)) then false
           else true end)}
      | . + {refusal:
          (if .unreadable then "attribution_unreadable"
           elif .status != "active" then "not_active"
           elif .owns != "mine" then "not_mine"
           elif (.stage == "観察中") then "observing"
           elif ((.days_to_target != null) and (.days_to_target < 0)) then "past_target_date"
           elif ((.feedback_refs | length) == 0) then "no_feedback_refs"
           # WORK_WAITING AT THE MISSION GRAIN (2026-08-26). A proposal is a whole mission,
           # so the brake asks whether one is already in flight. Two terms, OR'"'"'d, and both
           # are needed: the MISSION term (an active attributed mission) is what makes the
           # gate hold while the last ticket sits at a pull request with the queue drained,
           # and the TICKET term still catches a loose ticket the run emitted with no
           # mission around it. Neither counts: `> 0` is the whole question, exactly as
           # before — the grain moved, the arithmetic did not.
           elif ((if $aim_kind == "building"
                  then (.waiting_missions_advancing // .waiting_missions // 0)
                       + (.waiting_advancing // .waiting_count // 0)
                  else (.waiting_missions // 0) + (.waiting_count // 0) end) > 0) then "work_waiting"
           elif ($held | index($w.slug)) then "open_proposal"
           else "" end)} ]
  # THE WHOLE ORDERING, STATED HERE AND NOWHERE ELSE, so no consumer re-derives it:
  #
  #   1. 改良中 FIRST, then every other stage (2026-08-29, mission
  #      `make-a-direction-s-lifecycle-a-declared-stage`).
  #   2. LATE FIRST, then
  #   3. NEAREST DATE.
  #
  # A tick that dies partway must have advanced the direction least likely to arrive, not
  # merely the one with the nearest deadline. `unknown` orders exactly where it ordered
  # before that existed: a pace that could not be read must neither promote nor demote a
  # direction on a guess.
  #
  # WHY THE STAGE LEADS, AND WHY 改良中 RATHER THAN 進行中. The operator runs several
  # directions that reference each other and improve as a blend, and 改良中 is the stage
  # they declared to mean CUT OVER AND STILL IMPROVING — the one that can absorb a proposal
  # and convert it into shipped behaviour. The counter-argument is recorded rather than
  # dismissed: work that cannot be cut over yet is the riskiest, so 進行中 might deserve
  # attention first. It lost because a blend has to put its PROPOSING energy where proposals
  # land, and a direction still building is advanced by the work already queued against it.
  # 観察中 never reaches this sort at all — it is refused `observing` one step above.
  #
  # IT IS A SORT AND NOT A GATE, which is what makes it cheap and reversible. `refused[]`,
  # every gate, the membership of `eligible[]` and `selected[]` and every reading are
  # untouched; only the ORDER moves, and only between directions of different stages. Since
  # `over_cap` was retired a tick proposes against EVERY eligible direction, so the order
  # decides only which one a tick that dies partway has advanced — which bounds the blast
  # radius of this whole change. NO weight, NO score, NO tunable constant and NO
  # cross-direction arithmetic: the key is lexicographic over fields already on the row.
  | sort_by([(if .stage == "改良中" then 0 else 1 end),
             (if .pace == "late" then 0 else 1 end),
             (if .days_to_target == null then 99999 else .days_to_target end)])
  | (map(select(.refusal == "")) ) as $ok
  | (if $cap < 0 then $ok else $ok[0:$cap] end) as $take
  | (if $cap < 0 then [] else ($ok[$cap:] | map({slug, reason: "over_cap"})) end) as $spill
  | {ok: true, identity: $identity, window: $window, cap: $cap,
     active_count: ([.[] | select(.status == "active")] | length),
     surveyed_count: ($list.strategies | length),
     eligible: ($take | map(del(.refusal, .unreadable, .owns))),
     # `refused` gains `pace`, `title`, `assignees` and `days_to_target` -- additive, so
     # every existing reader that took {slug, reason} still reads what it always did. It is
     # load-bearing for the STARVING case: a direction that will not arrive AND is gated
     # produces no proposal, so a consumer reading only `eligible` would never see it.
     # `landed_count` and `target_date` ride the refused rows too (2026-08-27), for the
     # reason `quiescent` itself does: the AN ARRIVED DIRECTION PAST ITS DATE is refused
     # `past_target_date`, so a consumer that had to say WHAT LANDED and BY WHEN would have
     # nothing to say for exactly the row that matters most. `landed_count` is a count
     # rather than the list, because the list is the evidence a proposal is judged against
     # and a refused row is not being proposed against.
     refused: ((map(select(.refusal != ""))
                | map({slug, reason: .refusal, pace, overdue, expiring, dormant, quiescent, title, assignees, stage, stage_declared,
                       days_to_target, target_date, landed_count: ((.landed // []) | length),
                       # `residue` rides the refused rows for the same reason `landed_count`
                       # and `target_date` do (2026-08-27): an ARRIVED direction past its date
                       # is refused `past_target_date`, so a consumer that had to say what was
                       # unattributed would have nothing to say for exactly the row that
                       # matters most.
                       residue,
                       # And the WAITING GRAINS ride them for the same reason again
                       # (2026-08-28): what a direction NEVER REACHED is half of what it
                       # leaves, and the one row a consumer must be able to say it for is
                       # the OVERDUE one — which is refused `past_target_date` by
                       # definition. Projections of fields already on the eligible row; no
                       # gate, no sort and no selection reads them here.
                       waiting_count, waiting_missions, waiting_mission_slugs,
                       waiting_describing, waiting_advancing}))
               + $spill),
     selected: ($take | map(.slug)),
     errors: []}
  ' "${TMP}/rows"
