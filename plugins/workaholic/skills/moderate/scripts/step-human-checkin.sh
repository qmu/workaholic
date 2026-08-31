#!/bin/sh -eu
# Step 9 — ask the humans, at most five a tick, never late at night.
#
# WHAT THIS STEP IS. The eight steps before it keep finding things they cannot
# decide, and the loop's standing answer is to write them down and move on. This is
# the tick's way to actually ask — in **Slack**, never through `AskUserQuestion`: a
# routine-fired session has nobody watching, and the whole unattended contract turns
# on that.
#
# THE SCRIPT IS THE GATE AND THE LEDGER; THE AGENT COMPOSES AND POSTS. Which items
# are worth asking is a judgement — `rules/interaction.md`'s Recommended-label test:
# if an option could honestly be marked "(Recommended)", do not ask, decide and
# record and let the developer veto. How many may be asked, when, and whether this
# one was asked before is mechanical, and that half lives in `ask-question.sh`.
#
# THE CAP IS A CEILING, NOT A QUOTA. Five a tick is 120 a day at the ceiling, which
# is why there is a second bound the per-tick cap cannot aggregate past (default 10
# a day) — and why most ticks should ask **zero**. The bound that actually protects
# anyone's attention is the Recommended-label test, not the number.
#
# HELD IS NOT DROPPED. A question suppressed by quiet hours (or by either cap) is
# recorded by the agent as `human-checkin-held-<slug>` and handed back by THIS step
# on the next eligible tick — that is what makes the suppression a delay rather than
# a loss, and it is the reason a coarse per-tick timezone gate is affordable.
#
# AND THE ARREARS ARRIVE IN THE ORDER THEY WENT STALE (2026-08-28, mission
# `deliver-what-the-loop-already-knows-to-the-person-who-can-act`). The held set was
# collected with `sort -u` — ALPHABETICAL, an arbitrary order over a set whose only
# meaningful axis is age — and while the day cap was jammed nothing ever drained, so the
# order had never mattered. It matters the moment the cap is repaired: 22 questions were
# held when this was written (7 `undrivable-unit`, 3 `retire-blocked`, 6 `stuck`, 1
# `handoff-unit`, 1 `stalled-unit`, 1 `base-red`, 1 `direction-dormant`, 1 `direction-last`,
# 1 `release-status`), spanning five days and still growing.
#
# `held` is ordered by the day each key was FIRST held — a key held across several ticks is
# as old as its first hold, not its most recent — tie-broken on the tick id within the day
# and then on the key, so the order is total and a re-entered tick produces a byte-identical
# sequence. The day is already in the log this tick keeps (`log-read.sh` emits `day` per
# entry), so this needs NO second ledger, no cursor and no field on any artifact.
#
# AND THE READING THE ORDERING ALREADY MADE IS CARRIED, NOT THROWN AWAY (2026-08-31, mission
# `say-when-the-check-in-queue-is-stuck-and-bound-the-hold`). The first-held day per key is
# derived above for the ordering and was then discarded: only `held_count` survived, so the
# step knew how OLD its backlog was and said only how LARGE it is. `held_oldest_day` is the
# MINIMUM of that same derivation over the keys still held — no second walk of the log, no
# cursor, no store — and `held_days` is the whole-day distance from it to the tick's own day.
#
# THE TICK SUPPLIES THE DAY, NEVER THE WALL CLOCK. `ask-question.sh` derives its day from the
# tick id on exactly this axis and for exactly this reason: both sides are then ids minted by
# the same script, a re-entered tick answers the same way twice, and the arithmetic is
# testable at all. The `date` fallback covers a caller that passed no tick.
#
# NO DATE ARITHMETIC THROUGH `date`. `date -d` is GNU-only and `date -v` is BSD-only — the
# refusal `condition-age.sh` already states by name — so the whole-day distance is computed
# from the two `YYYY-MM-DD` strings by civil-day arithmetic in `awk`, portable and pure.
#
# A DEGRADED LOG READ REPORTS NULL FOR BOTH, NEVER `0`. A zero here reads as *this just
# started*, the most reassuring thing the field can say, for a reading that was never made —
# the collapse `unattributed-work.sh`'s rule forbids by name. A tick with NO holds reports
# `held_count: 0` with both fields null and is otherwise byte-identical to what this step has
# always printed.
#
# THIS STEP ORDERS; IT DOES NOT CAP AND IT DOES NOT ASK. `max_per_tick` is enforced by
# `ask-question.sh`, per candidate, exactly as before, and `held_count` counts the WHOLE held
# set rather than any prefix — the count is what tells a reader how deep the arrears are.
# The order is a PROPOSAL to the agent, not a decision: the Recommended-label test still
# applies per candidate, so an older question that is no longer worth asking is dropped by
# judgement rather than asked because it sorted first.
#
# AGE, NOT URGENCY, AND DELIBERATELY SO. A severity ranking across the step vocabularies is a
# judgement no script can make, and the verdicts call for different acts by different people
# — the reason `/moderate` refused one unified "what the loop is blocked on" report. The day
# grain is coarse (a whole day's holds sort together), which is acceptable while the arrears
# span days; the tick id is already the tie-break and carries `HHMMSS` if a finer grain is
# ever wanted.
#
# WHAT IT DELIVERED, NOT WHAT IT WAS PERMITTED TO (2026-08-28, the same mission). The summary
# read `up to 5 questions may be asked this tick; 22 held from an earlier tick`, with
# `status: ok` — a PERMISSION, and it is true on a tick that asked five and on a tick that
# asked none. Eight consecutive ticks that delivered nothing were therefore indistinguishable
# from eight healthy ones in the only record that survives the container. The step now reads
# back `delivered`, `held` and `candidates`, and names why a tick delivered nothing:
#
#   cap_spent        `max_per_day` questions were asked ON THIS DAY. The mechanism worked and
#                    the attention budget is spent; the rest are held for the next day.
#   cap_unbounded    the day count could not be bounded — the gate is missing, or answered
#                    something this step cannot interpret. THIS IS OUR OWN DEGRADATION and
#                    must never render as `cap_spent`, which is the whole point of the split:
#                    one says the budget worked, the other says the loop has stopped. It
#                    should be unreachable now that the count is bounded; it is named anyway,
#                    because a reason that exists only while a bug does is the reason that
#                    gets dropped and then silently reintroduced.
#   all_held         every candidate is refused by `quiet_hours`, `off_day` or `tick_cap`.
#   all_asked_before every key that was ever held has since been asked.
#   no_candidates    the genuinely quiet hour: nothing is waiting.
#
# WHETHER THE TICK COULD DELIVER IS ASKED OF THE GATE, NOT RE-DERIVED HERE. The step probes
# `ask-question.sh` and reads its refusal, so the day's arithmetic keeps ONE home and this
# step cannot disagree with the gate the agent is about to run. The probe writes nothing —
# recording an ask is `--record-ask`'s separate mode — so the ledger is untouched, and
# `ask-question.sh` is not modified by any of this.
#
# AND IT IS ASKED PER HELD CANDIDATE, NOT ONCE (2026-08-31, mission
# `say-when-the-check-in-queue-is-stuck-and-bound-the-hold`). The probe used a key unique to
# the tick and kept only the aggregate, so `all_held` was ONE token over four different
# refusals — `quiet_hours`, `off_day`, `tick_cap` and `day_cap` — which call for four
# different acts: wait until morning, wait until Monday, wait an hour, the budget is spent.
# Each entry of `held` now carries the gate's own word for THAT key, VERBATIM: a normalised
# or re-worded refusal sends a reader to a string no script printed. `all_held` stays the
# step's summary word — this adds the detail beneath it rather than replacing it.
#
# TWO OF THE FOUR WORDS ARE TICK-WIDE (`quiet_hours`, `off_day`) and will be identical on
# every entry. That is the true answer and is reported rather than collapsed, because the cap
# words are not tick-wide and one shape has to cover both. The cost is one local script call
# per held key, over the set the drain already orders.
#
# WHAT `delivered` HONESTLY IS. The agent asks and records under `human-checkin-ask-<slug>`
# AFTER `run.sh` returns, so on this step's own pass `delivered` counts the ask lines already
# on the tick — zero on a first pass, by construction. **There is no post-agent seam in
# `run.sh` to move the reading to**: checked while this was written, the agent's turn happens
# after the run and only `persist-log.sh` is re-invoked. So the reading is *candidates and
# holds now, delivery from the log*, and the reason words above are the ones this step can
# OBSERVE — the caps and the holds — never a prediction of the agent's judgement. The number
# is read from the log rather than assumed precisely so a second, read-only invocation after
# the agent's turn reports the real delivery.
#
# A DEGRADED READ IS NAMED, NEVER RENDERED AS A DELIVERY. When the tick log cannot be read the
# step reports `status: degraded` with the reader's own reason and makes NO `delivered` claim.
# An ABSENT log area is a readable answer — nothing has ever been held — and yields an empty
# held set: the split `step-unanswered-asks.sh` already draws.
#
# THE `event` IS SUPPLIED ONLY WHEN THE TICK REACHED NOBODY (2026-08-28, the same mission).
# The root's gate is a question and this step supplied NO `event` field at all, so a tick with
# 22 candidates and zero delivered posted nothing and total silence was byte-identical to a
# quiet hour — for eight consecutive ticks, with a red base, a 31-hour declared handoff, three
# undeletable branches and seven undrivable units all held behind it. A delivery failure IS
# the event the root exists to carry.
#
# It is supplied ONLY on the ok branch and only for `cap_spent` and `cap_unbounded` — the two
# states where the tick was eligible to ask and structurally could not. Every other case
# supplies NO event and therefore renders no line: a genuinely quiet hour, an off day and the
# quiet window are the DESIGNED hold and are already named in the log, and a tick that
# delivered questions needs no event because the questions themselves are the delivery.
# `cap_spent` is worth a line even though the budget worked, because a reader must be able to
# tell it from `cap_unbounded`, which is the loop broken. The line names no dedup key and
# carries no mention token — the root is addressed to nobody, and the questions are the
# mentioned replies inside it. It cannot restate: the root's line is a diff against the
# previous tick's SUMMARY, and this summary is a function of the reading alone — no clock, no
# timestamp, nothing that moves by construction — so two consecutive ticks with the same
# reading render one line.
#
# THE CLOCK AND THE CALENDAR ARE BOTH INJECTABLE, and both for the same reason: a step
# that reads the wall clock is a step whose tests pass or fail by the day they are run on.
# `--hour` was injectable from the start; `--weekday` was not, and the working-week gate's
# very first suite run was on a Saturday and reported `off_day` for every question the
# tests expected to be asked. A gate that cannot be pinned is a gate nobody can test.
#
# Usage: step-human-checkin.sh --tick <id> --root <repo-root> [--hour <0-23>] [--weekday <1-7>]
# Output: one JSON line
#   {"step","status","reason","summary","event","needs_agent":[...],
#    "held":[{"key":"<slug>","reason":"<the gate's own refusal word>"},...],
#    "held_count":n,"held_oldest_day":"YYYY-MM-DD"|null,"held_days":n|null,
#    "delivered":n,"candidates":n,"delivery":"<reason word>","quiet":bool}

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LOG_READ="${SCRIPT_DIR}/log-read.sh"
GATE="${SCRIPT_DIR}/ask-question.sh"
ROOT='.'
TICK=''
HOUR=''
WEEKDAY=''

while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT="${2:-}"; shift 2 ;;
        --tick) TICK="${2:-}"; shift 2 ;;
        --hour) HOUR="${2:-}"; shift 2 ;;
        --weekday) WEEKDAY="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

ZONE="${WORKAHOLIC_QUIET_TZ:-Asia/Tokyo}"
WINDOW="${WORKAHOLIC_QUIET_HOURS:-22-08}"
WORK_DAYS="${WORKAHOLIC_WORK_DAYS:-1-5}"
START=$(printf '%s' "$WINDOW" | cut -d- -f1)
END=$(printf '%s' "$WINDOW" | cut -d- -f2)
[ -n "$WEEKDAY" ] || WEEKDAY=$(TZ="$ZONE" date +%u)
case "$WEEKDAY" in ''|*[!0-9]*) WEEKDAY=1 ;; esac
DAY_START=$(printf '%s' "$WORK_DAYS" | cut -d- -f1)
DAY_END=$(printf '%s' "$WORK_DAYS" | cut -d- -f2)
offday=false
if [ "$WEEKDAY" -lt "$DAY_START" ] || [ "$WEEKDAY" -gt "$DAY_END" ]; then offday=true; fi

[ -n "$HOUR" ] || HOUR=$(TZ="$ZONE" date +%H)
HOUR=$(printf '%s' "$HOUR" | sed 's/^0//')
[ -n "$HOUR" ] || HOUR=0

# THE TICK'S OWN DAY, in `log-read.sh`'s `YYYY-MM-DD` form — the same derivation on the same
# axis `ask-question.sh` uses for its day bound, so the two sides cannot disagree about which
# day a tick belongs to. Never the wall clock where there is a tick id.
TICK_DAY=$(printf '%s' "$TICK" | sed -n 's/^\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)-.*/\1-\2-\3/p')
[ -n "$TICK_DAY" ] || TICK_DAY=$(TZ="$ZONE" date +%Y-%m-%d)

# Whole days between two `YYYY-MM-DD` strings, by civil-day arithmetic. `date -d` is GNU-only
# and `date -v` is BSD-only, so neither is reachable here.
days_between() {
    printf '%s %s\n' "$1" "$2" | awk '
        function civil(s,   y, m, d, e, yoe, doy, doe) {
            y = substr(s, 1, 4) + 0; m = substr(s, 6, 2) + 0; d = substr(s, 9, 2) + 0
            if (m <= 2) y -= 1
            e = int((y >= 0 ? y : y - 399) / 400)
            yoe = y - e * 400
            doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
            doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
            return e * 146097 + doe - 719468
        }
        { n = civil($2) - civil($1); print (n < 0 ? 0 : n) }
    '
}

quiet=false
if [ "$START" -gt "$END" ]; then
    if [ "$HOUR" -ge "$START" ] || [ "$HOUR" -lt "$END" ]; then quiet=true; fi
else
    if [ "$HOUR" -ge "$START" ] && [ "$HOUR" -lt "$END" ]; then quiet=true; fi
fi

# --- Read the log once, and say so when it could not be read -------------------------
# An ABSENT area is a readable answer (nothing has ever been held); any other refusal is our
# own degradation and is named rather than rendered as a tick that ran and found nothing.
log_reason=''
log_readable=true
held_rows=''
if [ ! -f "$LOG_READ" ]; then
    log_readable=false
    log_reason=no_reader
else
    probe_log=$(sh "$LOG_READ" --root "$ROOT" --step-prefix human-checkin-held 2>/dev/null || true)
    case "$probe_log" in
        *'"read": true'*)  held_rows="$probe_log" ;;
        *'"no_log_area"'*) held_rows='' ;;
        *)
            log_readable=false
            log_reason=$(printf '%s' "$probe_log" | sed -n 's/.*"reason": "\([a-z_]*\)".*/\1/p')
            [ -n "$log_reason" ] || log_reason=log_unreadable
            ;;
    esac
fi

if [ "$log_readable" != "true" ]; then
    heldquiet=false
    if [ "$quiet" = "true" ] || [ "$offday" = "true" ]; then heldquiet=true; fi
    printf '{"step": "human-checkin", "status": "degraded", "reason": "%s", "summary": "the tick log could not be read (%s) — no delivery is claimed and nothing is asked", "event": "", "needs_agent": [], "held": [], "held_count": 0, "held_oldest_day": null, "held_days": null, "candidates": 0, "delivery": "unreadable", "quiet": %s}\n' \
        "$(json_escape "$log_reason")" "$(json_escape "$log_reason")" "$heldquiet"
    exit 0
fi

# Questions an earlier tick held: recorded as held, never asked, OLDEST-HELD FIRST. A held
# key that has since been asked drops out — the ask is the resolution of the hold.
held=''
held_count=0
held_ever=0
held_oldest_day=''
# What the gate said, across the held set: whether anything could be asked at all, and which
# refusal it gave. Collected here rather than probed a second time below.
gate_can_ask=false
gate_day_cap=false
gate_hold=false
if [ -n "$held_rows" ]; then
    # `day tick key` per held entry, straight out of the reader's own fields — no second
    # ledger, and no notion of age this step invents for itself.
    rows=$(printf '%s' "$held_rows" |
           tr '{' '\n' |
           sed -n 's/.*"day": "\([^"]*\)", "tick": "\([^"]*\)", "step": "human-checkin-held-\([^"]*\)".*/\1 \2 \3/p' || true)
    # The EARLIEST (day, tick) per key wins: a key held across several ticks is as old as
    # its first hold. `LC_ALL=C` so the order does not move with the runner's locale.
    keys=$(printf '%s\n' "$rows" | awk '
        NF == 3 {
            k = $3; d = $1 " " $2
            if (!(k in first) || d < first[k]) first[k] = d
        }
        END { for (k in first) print first[k] " " k }
    ' | LC_ALL=C sort | awk '{ print $1 ":" $3 }')
    # `day:key`, in the drain order the sort above already produced. The day rides along
    # rather than being re-derived: it IS the value the ordering was computed from.
    for entry in $keys; do
        [ -n "$entry" ] || continue
        day=${entry%%:*}
        k=${entry#*:}
        [ -n "$k" ] || continue
        held_ever=$((held_ever + 1))
        asked=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "human-checkin-ask-${k}" 2>/dev/null | sed 's/.*"count": //; s/,.*//')
        case "$asked" in ''|*[!0-9]*) asked=0 ;; esac
        [ "$asked" -eq 0 ] || continue
        held_count=$((held_count + 1))
        # WHY THIS ONE IS HELD, in the gate's own word. The probe is read-only — recording an
        # ask is `--record-ask`'s separate mode — so nothing is written and no cap moves.
        hold_reason=''
        if [ -f "$GATE" ]; then
            gout=$(sh "$GATE" --root "$ROOT" --tick "$TICK" --key "$k" \
                     --hour "$HOUR" --weekday "$WEEKDAY" 2>/dev/null || true)
            case "$gout" in
                *'"ask": true'*) gate_can_ask=true ;;
                *) hold_reason=$(printf '%s' "$gout" | sed -n 's/.*"reason": "\([a-z_]*\)".*/\1/p' | head -1) ;;
            esac
            case "$hold_reason" in
                day_cap) gate_day_cap=true ;;
                quiet_hours|off_day|tick_cap) gate_hold=true ;;
            esac
        fi
        held="${held:+${held}, }{\"key\": \"$(json_escape "$k")\", \"reason\": \"$(json_escape "$hold_reason")\"}"
        # The MINIMUM over the keys still held — an asked key has left the arrears and must
        # not go on ageing them. `YYYY-MM-DD` compares correctly as a string.
        if [ -z "$held_oldest_day" ] || [ "$day" \< "$held_oldest_day" ]; then
            held_oldest_day="$day"
        fi
    done
fi

# Null, never `0`, when there is nothing held or the day could not be read.
held_oldest_json=null
held_days_json=null
if [ -n "$held_oldest_day" ]; then
    held_oldest_json="\"$(json_escape "$held_oldest_day")\""
    held_days_json=$(days_between "$held_oldest_day" "$TICK_DAY")
    case "$held_days_json" in ''|*[!0-9]*) held_days_json=null ;; esac
fi

# --- What this tick delivered, and why it delivered nothing ---------------------------
# `delivered` is the ask lines recorded under THIS tick's id: a read of the log, never an
# assumption. On this step's own pass it is zero by construction (the agent asks after
# `run.sh` returns); a second, read-only invocation after the agent's turn reports the real
# number, which is why it is read rather than declared.
delivered=$(sh "$LOG_READ" --root "$ROOT" --step-prefix human-checkin-ask --tick "$TICK" 2>/dev/null | sed 's/.*"count": //; s/,.*//')
case "$delivered" in ''|*[!0-9]*) delivered=0 ;; esac
candidates=$((delivered + held_count))

delivery=''
if [ "$delivered" -eq 0 ] && [ "$held_count" -eq 0 ]; then
    if [ "$held_ever" -gt 0 ]; then delivery=all_asked_before; else delivery=no_candidates; fi
fi

if [ "$offday" = "true" ]; then
    [ "$held_count" -eq 0 ] || delivery=all_held
    printf '{"step": "human-checkin", "status": "skipped", "reason": "off_day", "summary": "weekday %s is outside the %s working week (%s) — %s candidate(s): %s delivered, %s held (%s)", "event": "", "needs_agent": [], "held": [%s], "held_count": %s, "held_oldest_day": %s, "held_days": %s, "delivered": %s, "candidates": %s, "delivery": "%s", "quiet": true}\n' \
        "$WEEKDAY" "$ZONE" "$WORK_DAYS" "$candidates" "$delivered" "$held_count" "${delivery:-none}" \
        "$held" "$held_count" "$held_oldest_json" "$held_days_json" "$delivered" "$candidates" "$delivery"
    exit 0
fi

if [ "$quiet" = "true" ]; then
    [ "$held_count" -eq 0 ] || delivery=all_held
    printf '{"step": "human-checkin", "status": "skipped", "reason": "quiet_hours", "summary": "inside the %s %s quiet window — %s candidate(s): %s delivered, %s held (%s)", "event": "", "needs_agent": [], "held": [%s], "held_count": %s, "held_oldest_day": %s, "held_days": %s, "delivered": %s, "candidates": %s, "delivery": "%s", "quiet": true}\n' \
        "$WINDOW" "$ZONE" "$candidates" "$delivered" "$held_count" "${delivery:-none}" \
        "$held" "$held_count" "$held_oldest_json" "$held_days_json" "$delivered" "$candidates" "$delivery"
    exit 0
fi

# --- Could this tick deliver at all? --------------------------------------------------
# Read off the per-candidate probes above rather than asked a second time: one candidate the
# gate would allow means the tick has not failed, it has not run yet. A gate that could not be
# read leaves the day count unbounded as far as this step can tell, which is `cap_unbounded`
# and never `cap_spent` — the split exists because one says the budget worked and the other
# says the loop has stopped.
if [ "$delivered" -eq 0 ] && [ "$held_count" -gt 0 ]; then
    if   [ "$gate_can_ask" = "true" ]; then delivery=''
    elif [ "$gate_day_cap" = "true" ]; then delivery=cap_spent
    elif [ "$gate_hold" = "true" ];    then delivery=all_held
    else                                    delivery=cap_unbounded
    fi
fi

# THE EVENT: only a tick that was eligible to ask and structurally could not reach anybody.
event=''
case "$delivery" in
    cap_spent)
        event="${candidates} finding(s) waiting and none asked — the day's question budget is spent; they are held for the next working day" ;;
    cap_unbounded)
        event="${candidates} finding(s) waiting and none asked — the day's question count could not be bounded, so nothing reached anybody" ;;
esac

# The instruction is deliberately a single entry: the questions themselves come from
# the tick's own steps, which only the agent has in hand.
NEEDS="{\"action\": \"ask_if_worth_asking\", \"bound\": \"apply the Recommended-label test first: an item you could honestly mark (Recommended) is decided and recorded, never asked\", \"gate\": \"run ask-question.sh --tick ${TICK} --key <content-key> --to <email> for each; it answers ask true/false and gives the log_step to record under\", \"post\": \"render the tick's root with render-tick-post.sh; when it says post, post that root and then one reply per question INSIDE it, each addressed with a resolved <@U…> — never a bare @name, never a Claude mention token\", \"order\": \"the held list is ordered oldest-held first; take it in that order, and each entry's reason is the gate's own refusal word for that key\", \"held\": [${held}]}"

# THE SUMMARY IS A FUNCTION OF THE READING ALONE. No hour, no timestamp, nothing that moves
# by construction — so the root's hour-to-hour diff suppresses an unchanged reason rather
# than rendering it every tick, which is the property that lets the event above exist.
printf '{"step": "human-checkin", "status": "ok", "reason": "", "summary": "outside the %s %s quiet window — %s candidate(s): %s delivered, %s held (%s)", "event": "%s", "needs_agent": [%s], "held": [%s], "held_count": %s, "held_oldest_day": %s, "held_days": %s, "delivered": %s, "candidates": %s, "delivery": "%s", "quiet": false}\n' \
    "$WINDOW" "$ZONE" "$candidates" "$delivered" "$held_count" "${delivery:-none}" \
    "$(json_escape "$event")" "$NEEDS" "$held" "$held_count" "$held_oldest_json" "$held_days_json" "$delivered" "$candidates" "$delivery"
