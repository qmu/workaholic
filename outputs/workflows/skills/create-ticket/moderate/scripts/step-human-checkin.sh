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
# `ask-question.sh` with a key unique to the tick and reads its refusal, so the day's
# arithmetic keeps ONE home and this step cannot disagree with the gate the agent is about to
# run. The probe writes nothing — recording an ask is `--record-ask`'s separate mode — so the
# ledger is untouched, and `ask-question.sh` is not modified by any of this.
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
#   {"step","status","reason","summary","event","needs_agent":[...],"held":[...],
#    "held_count":n,"delivered":n,"candidates":n,"delivery":"<reason word>","quiet":bool}

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
    printf '{"step": "human-checkin", "status": "degraded", "reason": "%s", "summary": "the tick log could not be read (%s) — no delivery is claimed and nothing is asked", "event": "", "needs_agent": [], "held": [], "held_count": 0, "candidates": 0, "delivery": "unreadable", "quiet": %s}\n' \
        "$(json_escape "$log_reason")" "$(json_escape "$log_reason")" "$heldquiet"
    exit 0
fi

# Questions an earlier tick held: recorded as held, never asked, OLDEST-HELD FIRST. A held
# key that has since been asked drops out — the ask is the resolution of the hold.
held=''
held_count=0
held_ever=0
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
    ' | LC_ALL=C sort | awk '{ print $3 }')
    for k in $keys; do
        [ -n "$k" ] || continue
        held_ever=$((held_ever + 1))
        asked=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "human-checkin-ask-${k}" 2>/dev/null | sed 's/.*"count": //; s/,.*//')
        case "$asked" in ''|*[!0-9]*) asked=0 ;; esac
        [ "$asked" -eq 0 ] || continue
        held_count=$((held_count + 1))
        held="${held:+${held}, }\"$(json_escape "$k")\""
    done
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
    printf '{"step": "human-checkin", "status": "skipped", "reason": "off_day", "summary": "weekday %s is outside the %s working week (%s) — %s candidate(s): %s delivered, %s held (%s)", "event": "", "needs_agent": [], "held": [%s], "held_count": %s, "delivered": %s, "candidates": %s, "delivery": "%s", "quiet": true}\n' \
        "$WEEKDAY" "$ZONE" "$WORK_DAYS" "$candidates" "$delivered" "$held_count" "${delivery:-none}" \
        "$held" "$held_count" "$delivered" "$candidates" "$delivery"
    exit 0
fi

if [ "$quiet" = "true" ]; then
    [ "$held_count" -eq 0 ] || delivery=all_held
    printf '{"step": "human-checkin", "status": "skipped", "reason": "quiet_hours", "summary": "inside the %s %s quiet window — %s candidate(s): %s delivered, %s held (%s)", "event": "", "needs_agent": [], "held": [%s], "held_count": %s, "delivered": %s, "candidates": %s, "delivery": "%s", "quiet": true}\n' \
        "$WINDOW" "$ZONE" "$candidates" "$delivered" "$held_count" "${delivery:-none}" \
        "$held" "$held_count" "$delivered" "$candidates" "$delivery"
    exit 0
fi

# --- Could this tick deliver at all? --------------------------------------------------
# Asked of the gate rather than re-derived here, so the day's arithmetic keeps ONE home and
# this step cannot disagree with the gate the agent is about to run. The probe key is unique
# to the tick and is never recorded, so nothing is written; a gate that cannot be read leaves
# the day count unbounded as far as this step can tell, which is `cap_unbounded` and never
# `cap_spent`.
if [ "$delivered" -eq 0 ] && [ "$held_count" -gt 0 ]; then
    probe=''
    if [ -f "$GATE" ]; then
        pout=$(sh "$GATE" --root "$ROOT" --tick "$TICK" --key "human-checkin:delivery-probe:${TICK}" \
                 --hour "$HOUR" --weekday "$WEEKDAY" 2>/dev/null || true)
        case "$pout" in
            *'"ask": true'*)             probe=can_ask ;;
            *'"reason": "day_cap"'*)     probe=day_cap ;;
            *'"reason": "tick_cap"'*)    probe=held ;;
            *'"reason": "quiet_hours"'*) probe=held ;;
            *'"reason": "off_day"'*)     probe=held ;;
        esac
    fi
    case "$probe" in
        can_ask) delivery='' ;;
        day_cap) delivery=cap_spent ;;
        held)    delivery=all_held ;;
        *)       delivery=cap_unbounded ;;
    esac
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
NEEDS="{\"action\": \"ask_if_worth_asking\", \"bound\": \"apply the Recommended-label test first: an item you could honestly mark (Recommended) is decided and recorded, never asked\", \"gate\": \"run ask-question.sh --tick ${TICK} --key <content-key> --to <email> for each; it answers ask true/false and gives the log_step to record under\", \"post\": \"render the tick's root with render-tick-post.sh; when it says post, post that root and then one reply per question INSIDE it, each addressed with a resolved <@U…> — never a bare @name, never a Claude mention token\", \"order\": \"the held list is ordered oldest-held first; take it in that order\", \"held\": [${held}]}"

# THE SUMMARY IS A FUNCTION OF THE READING ALONE. No hour, no timestamp, nothing that moves
# by construction — so the root's hour-to-hour diff suppresses an unchanged reason rather
# than rendering it every tick, which is the property that lets the event above exist.
printf '{"step": "human-checkin", "status": "ok", "reason": "", "summary": "outside the %s %s quiet window — %s candidate(s): %s delivered, %s held (%s)", "event": "%s", "needs_agent": [%s], "held": [%s], "held_count": %s, "delivered": %s, "candidates": %s, "delivery": "%s", "quiet": false}\n' \
    "$WINDOW" "$ZONE" "$candidates" "$delivered" "$held_count" "${delivery:-none}" \
    "$(json_escape "$event")" "$NEEDS" "$held" "$held_count" "$delivered" "$candidates" "$delivery"
