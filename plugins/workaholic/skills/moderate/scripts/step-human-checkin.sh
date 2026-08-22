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
# THE CLOCK AND THE CALENDAR ARE BOTH INJECTABLE, and both for the same reason: a step
# that reads the wall clock is a step whose tests pass or fail by the day they are run on.
# `--hour` was injectable from the start; `--weekday` was not, and the working-week gate's
# very first suite run was on a Saturday and reported `off_day` for every question the
# tests expected to be asked. A gate that cannot be pinned is a gate nobody can test.
#
# Usage: step-human-checkin.sh --tick <id> --root <repo-root> [--hour <0-23>] [--weekday <1-7>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"held":[...],"quiet":bool}

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LOG_READ="${SCRIPT_DIR}/log-read.sh"
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

# Questions an earlier tick held: recorded as held, never asked. A held key that has
# since been asked drops out — the ask is the resolution of the hold.
held=''
held_count=0
if [ -f "$LOG_READ" ]; then
    keys=$(sh "$LOG_READ" --root "$ROOT" --step-prefix human-checkin-held 2>/dev/null |
           awk '{ gsub(/}, \{/, "}\n{"); print }' | grep '"step"' |
           sed 's/.*"step": "human-checkin-held-//; s/".*//' | sort -u || true)
    for k in $keys; do
        [ -n "$k" ] || continue
        asked=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "human-checkin-ask-${k}" 2>/dev/null | sed 's/.*"count": //; s/,.*//')
        case "$asked" in ''|*[!0-9]*) asked=0 ;; esac
        [ "$asked" -eq 0 ] || continue
        held_count=$((held_count + 1))
        held="${held:+${held}, }\"$(json_escape "$k")\""
    done
fi

if [ "$offday" = "true" ]; then
    printf '{"step": "human-checkin", "status": "skipped", "reason": "off_day", "summary": "weekday %s is outside the %s working week (%s) — nothing asked; %s question(s) held for the next working day", "needs_agent": [], "held": [%s], "quiet": true}\n' \
        "$WEEKDAY" "$ZONE" "$WORK_DAYS" "$held_count" "$held"
    exit 0
fi

if [ "$quiet" = "true" ]; then
    printf '{"step": "human-checkin", "status": "skipped", "reason": "quiet_hours", "summary": "%s local (%s) is inside the %s quiet window — nothing asked; %s question(s) held for the next eligible tick", "needs_agent": [], "held": [%s], "quiet": true}\n' \
        "${HOUR}:00" "$ZONE" "$WINDOW" "$held_count" "$held"
    exit 0
fi

# The instruction is deliberately a single entry: the questions themselves come from
# the tick's own steps, which only the agent has in hand.
NEEDS="{\"action\": \"ask_if_worth_asking\", \"bound\": \"apply the Recommended-label test first: an item you could honestly mark (Recommended) is decided and recorded, never asked\", \"gate\": \"run ask-question.sh --tick ${TICK} --key <content-key> --to <email> for each; it answers ask true/false and gives the log_step to record under\", \"post\": \"render the tick's root with render-tick-post.sh; when it says post, post that root and then one reply per question INSIDE it, each addressed with a resolved <@U…> — never a bare @name, never a Claude mention token\", \"held\": [${held}]}"

printf '{"step": "human-checkin", "status": "ok", "reason": "", "summary": "%s local (%s) is outside the %s quiet window — up to 5 questions may be asked this tick; %s held from an earlier tick", "needs_agent": [%s], "held": [%s], "quiet": false}\n' \
    "${HOUR}:00" "$ZONE" "$WINDOW" "$held_count" "$NEEDS" "$held"
