#!/bin/sh -eu
# The gate one check-in question must pass before a human's attention is spent.
#
# WHY A SCRIPT DECIDES AND THE AGENT COMPOSES. Whether something is worth asking is
# a judgement (`rules/interaction.md`'s Recommended-label test: if an option could
# honestly be marked "(Recommended)", do not ask — decide, record, let the
# developer veto). Whether it may be asked *now*, *again*, or *at all this tick* is
# mechanical, and mechanical is what a five-questions-an-hour ceiling needs, because
# a model asked to police its own volume will do it inconsistently.
#
# FOUR GATES, EACH ITS OWN REFUSAL:
#   quiet_hours   inside the configured window; the question is HELD, never dropped
#   answered      a person answered it in the moderator session; never asked again
#   already_asked this exact question key was asked in an earlier tick, unanswered; the
#                 refusal carries `liveness` (live | settled | unknown) when the caller
#                 passed --run and --asked-step, and `unknown` otherwise
#   tick_cap      five per tick, the ask's own ceiling
#   day_cap       the bound the per-tick cap must not aggregate past (default 10)
#
# WHICH DAY `day_cap` COUNTS, AND WHY IT HAD TO BE SAID (2026-08-28, mission
# `deliver-what-the-loop-already-knows-to-the-person-who-can-act`). It counts the
# `human-checkin-ask` lines on **the current `WORKAHOLIC_QUIET_TZ` day** — the same day the
# `quiet_hours` and working-day gates above are read in, derived ONCE below and passed to
# `log-read.sh`'s existing `--since`. A spent cap **holds** the question rather than dropping
# it, and a held question is **re-offered on the next eligible tick, oldest-held first**
# (`step-human-checkin.sh`).
#
# It counted every day the log had ever held. `asked_today` was `count_log_prefix
# human-checkin-ask ""` — the reader with no day bound — and the log is append-only and
# never pruned by a machine, so the count only ever grew: once the ALL-TIME total crossed
# `max_per_day`, every question was refused `day_cap` forever. Measured on the live tree:
# `count: 12, days: 5` against a cap of 10, a fresh key on a working weekday at 14:00
# refused `day_cap` with `asked_today: 12`, and the same reader bounded to the current
# `Asia/Tokyo` day answering `count: 0`. Eight consecutive ticks reported `ok` and posted
# nothing while a red base, a 31-hour declared handoff, three undeletable branches and seven
# undrivable units sat held behind it.
#
# THE REPAIR IS A BOUND PASSED TO A READER THAT ALREADY ACCEPTED ONE, and deliberately NOT:
# a raised cap (the cap is kept; only its arithmetic was wrong), a second reader, a stored
# cursor, or a second notion of a day.
#
# THE DAY BOUNDARY MOVES IN `WORKAHOLIC_QUIET_TZ` WHILE THE LOG'S FILES ARE KEYED BY UTC DAY.
# Near the boundary a `--since` of the local day can therefore include a UTC file whose later
# entries belong to the local next day. That OVER-counts rather than under-counts — it holds
# a question rather than asking a duplicate — which is the safe direction; it is stated here
# rather than repaired with per-entry timestamp filtering, so a later reader does not "fix"
# it the other way.
#
# QUIET HOURS ARE ONE GATE PER TICK, IN THE WORKSPACE'S TIMEZONE (resolved
# 2026-08-17, the ticket's first Open Decision). Default `Asia/Tokyo`, 22:00–08:00,
# both overridable — `WORKAHOLIC_QUIET_TZ`, `WORKAHOLIC_QUIET_HOURS=<start>-<end>`.
# The per-recipient alternative (each addressee's Slack profile timezone) is more
# precise and was not taken: it costs a profile read per person per tick against a
# surface this project keeps to exact-string queries, and it buys little, because a
# suppressed question is HELD rather than dropped — the cost of a coarse gate is a
# few hours of delay, not a lost question. The gate stays swappable: it is one
# function reading one zone.
#
# SILENCE IS NOT CONSENT, AND IT IS NOT A REASON TO ASK AGAIN (resolved 2026-08-17,
# the second Open Decision). An unanswered question is never re-posted: the
# red-alert `↳ still failing` precedent covers a machine-observable state that
# persists, whereas a question is a demand on a person's attention, and repeating it
# hourly converts asking into nagging. The unanswered set stays visible where humans
# already look — the tick log and the run report — and the post itself is still
# sitting in its thread.
#
# THE SCRIPT IS THE GATE **AND THE LEDGER** (2026-08-28, mission
# `let-an-answer-in-the-thread-turn-back-into-the-loop-s-work`). `--record-ask` is the second
# mode: after the agent has posted, it hands back the `(channel, ts)` it posted at and this
# writes the `human-checkin-ask-<slug>` line — the line the gate reads — through
# `log-append.sh`. Recording the ask was already the caller's job; what moves here is the
# LINE'S SHAPE, so the coordinate and the content key have one writer and one reader
# (`lib/question-coordinate.sh`, `question-state.sh`) instead of a free-text summary a later
# tick would have to guess at.
#
# THE GATE IS UNTOUCHED BY IT. `--record-ask` returns before any gate runs and writes only a
# log line; the questions asked, the caps, the holds and every refusal are byte-identical, and
# a caller that logs the ask itself as before still works — such a line reads a NAMED ABSENCE
# of a coordinate rather than an error. A coordinate is never load-bearing: a question posted
# without one recorded is still asked and still gated; only the return path is unavailable
# for it, which is a state the reader names.
#
# Usage:
#   ask-question.sh --tick <id> --key <content-key> [--root <repo-root>]
#                   [--to <email>] [--hour <0-23>] [--weekday <1-7>]
#                   [--max-per-tick 5] [--max-per-day 10]
#                   [--run <run-report.json>] [--asked-step <owning-step-id>]
#   ask-question.sh --record-ask --tick <id> --key <content-key>
#                   [--log-step <the step the gate returned>]
#                   [--coordinate <channel>:<ts>] [--summary "<prose>"] [--root <repo-root>]
#
# Output: one JSON line
#   {"ask": true, "key": "...", "log_step": "human-checkin-ask-<slug>",
#    ...} — or, for the one bounded re-ask of a still-`live` question first asked on an
#    earlier day, `reason: "outstanding"` with `log_step: human-checkin-reasked-<slug>`
#    and `first_asked`, so the composer can put the age in the question
#    "mention_email": "...", "asked_this_tick": n, "asked_today": n}
#   {"ask": false, "reason": "answered|off_day|quiet_hours|already_asked|tick_cap|day_cap|no_key",
#    "hold": true|false, "window": "22-08 Asia/Tokyo", ...}
#   --record-ask:
#   {"recorded": true, "key": "...", "log_step": "...", "coordinate": "<channel>:<ts>|"}
#   {"recorded": false, "reason": "no_key|no_writer|bad_coordinate|log_refused"}
#
# `mention_email` is what the CALLER resolves to a `<@U…>` mention: a bare `@name`
# pings nobody, and a Claude mention token on a routine's own post re-triggers the
# app and is prohibited (`workaholic:notify`).

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
LOG_READ="${SCRIPT_DIR}/log-read.sh"
. "${SCRIPT_DIR}/lib/question-id.sh"
. "${SCRIPT_DIR}/lib/question-coordinate.sh"
QUESTION_STATE="${SCRIPT_DIR}/question-state.sh"
LIVENESS="${SCRIPT_DIR}/question-liveness.sh"
LOG_APPEND="${SCRIPT_DIR}/log-append.sh"

TICK=''
KEY=''
ROOT='.'
TO=''
HOUR=''
WEEKDAY=''
RUN_REPORT=''
ASKED_STEP=''
MAX_TICK=5
MAX_DAY=10
RECORD_ASK=0
COORDINATE=''
LOG_STEP_IN=''
SUMMARY_IN=''

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)         TICK="${2:-}"; shift 2 ;;
        --key)          KEY="${2:-}"; shift 2 ;;
        --root)         ROOT="${2:-}"; shift 2 ;;
        --to)           TO="${2:-}"; shift 2 ;;
        --record-ask)   RECORD_ASK=1; shift ;;
        --coordinate)   COORDINATE="${2:-}"; shift 2 ;;
        --log-step)     LOG_STEP_IN="${2:-}"; shift 2 ;;
        --summary)      SUMMARY_IN="${2:-}"; shift 2 ;;
        --run)  RUN_REPORT="${2:-}"; shift 2 ;;
        --asked-step) ASKED_STEP="${2:-}"; shift 2 ;;
        --hour)         HOUR="${2:-}"; shift 2 ;;
        --weekday)      WEEKDAY="${2:-}"; shift 2 ;;
        --max-per-tick) MAX_TICK="${2:-5}"; shift 2 ;;
        --max-per-day)  MAX_DAY="${2:-10}"; shift 2 ;;
        *) shift ;;
    esac
done

if [ "$RECORD_ASK" -eq 1 ]; then
    # --- The ledger half: record the ask, and where it was posted -------------
    # It returns BEFORE every gate below, so nothing about which questions are asked, how
    # often, or under what holds can be reached from here.
    record_refuse() { printf '{"recorded": false, "reason": "%s"}\n' "$1"; exit 0; }
    [ -n "$KEY" ] || record_refuse no_key
    [ -f "$LOG_APPEND" ] || record_refuse no_writer
    # A COORDINATE IS ACCEPTED OR NAMED, NEVER GUESSED. Absent is an ordinary state (the
    # post succeeded, nothing handed one back); malformed is a refusal, because a bad
    # coordinate recorded here reads a tick later as a thread with nothing in it, which is
    # indistinguishable from a question nobody answered.
    if [ -n "$COORDINATE" ] && ! qc_valid "$COORDINATE"; then
        record_refuse bad_coordinate
    fi
    RECORD_STEP="$LOG_STEP_IN"
    [ -n "$RECORD_STEP" ] || RECORD_STEP="human-checkin-ask-$(question_slug "$KEY")"
    RECORD_SUMMARY=$(qc_line "$SUMMARY_IN" "$COORDINATE" "$KEY")
    out=$(sh "$LOG_APPEND" --root "$ROOT" --tick "$TICK" --step "$RECORD_STEP" \
            --status filed --summary "$RECORD_SUMMARY" 2>/dev/null || true)
    case "$out" in
        *'"logged": true'*|*'"duplicate": true'*) ;;
        *) record_refuse log_refused ;;
    esac
    printf '{"recorded": true, "key": "%s", "log_step": "%s", "coordinate": "%s"}\n' \
        "$KEY" "$RECORD_STEP" "$COORDINATE"
    exit 0
fi

[ -n "$KEY" ] || { echo '{"ask": false, "reason": "no_key", "hold": false}'; exit 1; }

# WORKING TIME IS A DAY AND AN HOUR, NOT AN HOUR ALONE (2026-08-21, the developer's
# instruction). The gate only ever checked the clock, so a question found at 10:00 on a
# Sunday was posted into a channel nobody was reading, and its `already_asked` gate then
# ensured it was never posted again on a day somebody was. Held is not dropped, so a
# weekend finding waits for Monday and is asked then. `WORKAHOLIC_WORK_DAYS` is a
# `%u` range (1 = Monday), so `1-5` is the working week and `1-7` opts the gate out.
ZONE="${WORKAHOLIC_QUIET_TZ:-Asia/Tokyo}"
WINDOW="${WORKAHOLIC_QUIET_HOURS:-22-08}"
WORK_DAYS="${WORKAHOLIC_WORK_DAYS:-1-5}"
START=$(printf '%s' "$WINDOW" | cut -d- -f1)
END=$(printf '%s' "$WINDOW" | cut -d- -f2)

if [ -z "$HOUR" ]; then
    HOUR=$(TZ="$ZONE" date +%H)
fi
HOUR=$(printf '%s' "$HOUR" | sed 's/^0//')
[ -n "$HOUR" ] || HOUR=0

DAY_START=$(printf '%s' "$WORK_DAYS" | cut -d- -f1)
DAY_END=$(printf '%s' "$WORK_DAYS" | cut -d- -f2)
if [ -z "$WEEKDAY" ]; then
    WEEKDAY=$(TZ="$ZONE" date +%u)
fi
case "$WEEKDAY" in ''|*[!0-9]*) WEEKDAY=1 ;; esac

offday=false
if [ "$WEEKDAY" -lt "$DAY_START" ] || [ "$WEEKDAY" -gt "$DAY_END" ]; then offday=true; fi

# THE DAY, DERIVED ONCE, BESIDE THE GATES THAT ALREADY DERIVE THE HOUR AND THE WEEKDAY. It
# is the bound `day_cap` counts within, in `log-read.sh`'s own `YYYY-MM-DD` form.
#
# THE TICK ID SUPPLIES IT WHERE THERE IS ONE, exactly as the `outstanding` branch below
# already reads its day from the tick, and for the same stated reason: both sides are then
# ids minted by the same script on the same axis, a re-entered tick answers the same way
# twice, and the arithmetic is testable at all — reading the wall clock made a tick dated
# yesterday answer for today. The `date` fallback covers a caller that passed no tick.
TODAY=$(printf '%s' "$TICK" | sed -n 's/^\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)-.*/\1-\2-\3/p')
[ -n "$TODAY" ] || TODAY=$(TZ="$ZONE" date +%Y-%m-%d)

quiet=false
if [ "$START" -gt "$END" ]; then
    # The window crosses midnight, which is the normal case for "late night".
    if [ "$HOUR" -ge "$START" ] || [ "$HOUR" -lt "$END" ]; then quiet=true; fi
else
    if [ "$HOUR" -ge "$START" ] && [ "$HOUR" -lt "$END" ]; then quiet=true; fi
fi

count_log_prefix() {
    # $1 step-id prefix, $2 needle ("" for all), $3 --since day ("" for no day bound)
    # -> count, 0 when the log is unreadable
    #
    # THE BOUND IS A PARAMETER, NOT A GLOBAL, so each call site stays explicit about
    # whether it is asking about a day or about all time.
    if [ ! -f "$LOG_READ" ]; then printf '0'; return 0; fi
    set -- "$1" "${2:-}" "${3:-}"
    if [ -n "$2" ] && [ -n "$3" ]; then
        out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" --contains "$2" --since "$3" 2>/dev/null || true)
    elif [ -n "$2" ]; then
        out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" --contains "$2" 2>/dev/null || true)
    elif [ -n "$3" ]; then
        out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" --since "$3" 2>/dev/null || true)
    else
        out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" 2>/dev/null || true)
    fi
    n=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf '%s' "$n"
}

count_log_tick() {
    # $1 step-id prefix, bounded to THIS tick -> count, 0 when the log is unreadable
    # Lifted out of the inline block below so the `outstanding` branch can report the tick
    # count without re-deriving it: the two values it prints were the same unbounded number.
    if [ ! -f "$LOG_READ" ]; then printf '0'; return 0; fi
    out=$(sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" --tick "$TICK" 2>/dev/null || true)
    n=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf '%s' "$n"
}

count_log_step() {
    # $1 exact step id -> count, 0 when the log is unreadable
    if [ ! -f "$LOG_READ" ]; then printf '0'; return 0; fi
    out=$(sh "$LOG_READ" --root "$ROOT" --step "$1" 2>/dev/null || true)
    n=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')
    case "$n" in ''|*[!0-9]*) n=0 ;; esac
    printf '%s' "$n"
}

# One step id per question, because the log is idempotent per (tick, step): five
# questions in a tick are five ids, and the count is a prefix query.
#
# THE ID IS INJECTIVE ON THE KEY, which the slug alone was not: it lowercases, collapses
# every non-alphanumeric run and truncates to 32 characters, so two long keys sharing a
# prefix produced one id — and once the gate reads the id (above), a collision silently
# SUPPRESSES a question rather than merely miscounting one. A short digest of the whole
# key is appended so that cannot happen. The ids therefore changed shape on 2026-08-21:
# a question asked under the old id is asked once more, which is the one-off cost of
# making the gate mechanical.
# THE DERIVATION MOVED TO A LIBRARY on 2026-08-23 and did not change: three scripts key on
# this identity now (this gate, `record-answer.sh`, `question-state.sh`), and a question
# whose id differed between them would silently be a different question — an answer filed
# under one id would never clear a gate reading another.
LOG_STEP="human-checkin-ask-$(question_slug "$KEY")"

# THE GATE MATCHES THE STEP ID, NEVER THE SUMMARY TEXT (2026-08-21, ticket
# `20260819062058`). It used to ask the log for a line whose SUMMARY contained the raw
# key — but nothing ever required the writer to put the key in the summary, and the log's
# own identity for a question is the step id derived here. So the gate depended on an
# agent having written free text a contract never asked for, and measurably did not hold:
# tick `20260819-045108` asked `ask:issue-524-unassigned-never-ingested`, and an hour
# later the same key answered `{"ask": true}` with the question still unanswered in the
# channel. Reading the id makes the gate mechanical, which is what a ceiling needs.
# ANSWERED IS ITS OWN REFUSAL, NOT A KIND OF `already_asked` (2026-08-23, issue #584). Both
# refuse and neither holds, so the volume behaviour is identical — but the caller, the run
# report and the tick log can now tell "a person resolved this" from "nobody ever will",
# which is the whole distinction the loop was missing.
if [ -f "$QUESTION_STATE" ]; then
    qs=$(sh "$QUESTION_STATE" --root "$ROOT" --key "$KEY" 2>/dev/null || true)
    case "$qs" in
        *'"state": "answered"'*)
            printf '{"ask": false, "reason": "answered", "hold": false, "key": "%s", "answer": %s}\n' \
                "$KEY" "$(printf '%s' "$qs" | jq -c '.answer' 2>/dev/null || printf '""')"
            exit 0 ;;
    esac
fi

# WHETHER THE SUBJECT IS STILL LIVE RIDES THE REFUSAL, AND CHANGES NOTHING YET
# (2026-08-23). The refusal itself is unmoved — an already-asked question is still refused,
# still not held, still asked exactly once. What is added is the second axis the gate could
# not express: `live` (the owning step raised it again this tick), `settled` (the step ran
# and did not), `unknown` (nobody could look). It is re-derived from the tick's own run
# report by `question-liveness.sh`, so no state is stored and the log gains no field; a
# caller that passes no `--run`/`--asked-step` gets `unknown` and the byte-identical
# behaviour it had before.
already=$(count_log_step "$LOG_STEP")
if [ "$already" != "0" ]; then
    liveness=unknown
    if [ -n "$RUN_REPORT" ] && [ -n "$ASKED_STEP" ] && [ -f "$LIVENESS" ]; then
        lv=$(sh "$LIVENESS" --key "$KEY" --step "$ASKED_STEP" --run "$RUN_REPORT" 2>/dev/null || true)
        parsed=$(printf '%s' "$lv" | sed -n 's/.*"liveness": "\([a-z]*\)".*/\1/p')
        [ -n "$parsed" ] && liveness="$parsed"
    fi

    # ONE RE-ASK, AT THE NEXT WORKING DAY, THEN NEVER (2026-08-23; the ticket's Open
    # Decision, ruled while driving it). The fork was (a) re-ask on persistence, bounded,
    # versus (b) never re-ask and carry a standing `N outstanding, oldest <age>` line on the
    # root. **(a).** The one property both retired status roots lacked is being ADDRESSED TO
    # A PERSON, and (b) reproduces exactly that lack — a count addressed to nobody is the
    # shape this repository has retired twice, and putting an age on it does not change who
    # it reaches. The measured harm was a question unanswered for twenty hours across twenty
    # ticks with nothing carrying it; only a mentioned reply reaches anybody.
    #
    # THE INTERVAL IS THE SMALLEST THAT ANSWERS THE MEASUREMENT. Ticket `20260819061902`
    # removed UNBOUNDED re-asking — the same key re-asked every hour with the question still
    # open — and that removal stands: this is at most ONE extra ask, ever, and it is logged
    # under its own step id so a third is impossible by construction. The boundary is the
    # working day the quiet-hours gate already owns (`WORKAHOLIC_QUIET_TZ`), so no constant
    # is invented, exactly as the alert cool-down was fixed the same day.
    #
    # ONLY WHEN THE SUBJECT IS STILL `live`. `settled` needs nobody, and `unknown` is a
    # reading we could not make — spending a person's attention on our own degradation is the
    # rule `strategy-pace` already applies to its own `unknown`.
    #
    # IT ADDS NO POSTING RULE. A re-ask is a question, so it rides the tick's existing "post
    # when there is at least one question" gate; an hour with nothing to ask stays silent by
    # construction, and the `🙋` shape does not move.
    REASK_STEP="human-checkin-reasked-$(question_slug "$KEY")"
    if [ "$liveness" = "live" ] && [ "$(count_log_step "$REASK_STEP")" = "0" ]; then
        asked_day=''
        if [ -f "$QUESTION_STATE" ]; then
            asked_day=$(printf '%s' "${qs:-}" | sed -n 's/.*"asked_tick": "\([0-9]\{8\}\)-.*/\1/p')
        fi
        # THE DAY COMES FROM THE TICK, NOT THE WALL CLOCK. Both sides are then tick ids
        # minted by the same script on the same axis, a re-entered tick answers the same way
        # twice, and the comparison is testable at all — reading `date` here made a tick
        # dated yesterday re-ask itself on its own first run.
        today=$(printf '%s' "$TICK" | sed -n 's/^\([0-9]\{8\}\)-.*/\1/p')
        [ -n "$today" ] || today=$(TZ="$ZONE" date +%Y%m%d)
        # THE HOLD GATES COME FIRST, as they do for a first ask. `already_asked` returns
        # before the off-day and quiet-hours checks, so a re-ask decided here would post at
        # 03:00 on a Sunday — the exact failure `WORKAHOLIC_WORK_DAYS` exists to prevent.
        # Held is not dropped: the re-ask is logged only when it is actually asked, so it
        # waits for the next eligible tick and is still bounded to one.
        if [ "$offday" != "true" ] && [ "$quiet" != "true" ] \
           && [ -n "$asked_day" ] && [ "$asked_day" -lt "$today" ] 2>/dev/null; then
            # TWO DIFFERENT NUMBERS, WHICH THEY WERE NOT (2026-08-28). Both fields printed
            # the same unbounded prefix count, so `asked_this_tick` reported an all-time
            # total and `asked_today` reported it a second time — the day-cap defect twice
            # in one `printf`. They are now the tick count and the day-bounded count.
            printf '{"ask": true, "reason": "outstanding", "key": "%s", "log_step": "%s", "mention_email": "%s", "liveness": "live", "first_asked": "%s", "asked_this_tick": %s, "asked_today": %s, "window": "%s %s"}\n' \
                "$KEY" "$REASK_STEP" "$TO" "$asked_day" "$(count_log_tick human-checkin-ask)" "$(count_log_prefix human-checkin-ask "" "$TODAY")" "$WINDOW" "$ZONE"
            exit 0
        fi
    fi

    printf '{"ask": false, "reason": "already_asked", "hold": false, "key": "%s", "liveness": "%s"}\n' \
        "$KEY" "$liveness"
    exit 0
fi

asked_today=$(count_log_prefix human-checkin-ask "" "$TODAY")
asked_tick=$(count_log_tick human-checkin-ask)

if [ "$offday" = "true" ]; then
    printf '{"ask": false, "reason": "off_day", "hold": true, "key": "%s", "work_days": "%s", "weekday": %s, "tz": "%s"}\n' \
        "$KEY" "$WORK_DAYS" "$WEEKDAY" "$ZONE"
    exit 0
fi

if [ "$quiet" = "true" ]; then
    printf '{"ask": false, "reason": "quiet_hours", "hold": true, "key": "%s", "window": "%s %s", "hour": %s}\n' \
        "$KEY" "$WINDOW" "$ZONE" "$HOUR"
    exit 0
fi

if [ "$asked_tick" -ge "$MAX_TICK" ]; then
    printf '{"ask": false, "reason": "tick_cap", "hold": true, "key": "%s", "asked_this_tick": %s, "max_per_tick": %s}\n' \
        "$KEY" "$asked_tick" "$MAX_TICK"
    exit 0
fi

if [ "$asked_today" -ge "$MAX_DAY" ]; then
    printf '{"ask": false, "reason": "day_cap", "hold": true, "key": "%s", "asked_today": %s, "max_per_day": %s}\n' \
        "$KEY" "$asked_today" "$MAX_DAY"
    exit 0
fi

printf '{"ask": true, "key": "%s", "log_step": "%s", "mention_email": "%s", "asked_this_tick": %s, "asked_today": %s, "window": "%s %s"}\n' \
    "$KEY" "$LOG_STEP" "$TO" "$asked_tick" "$asked_today" "$WINDOW" "$ZONE"
