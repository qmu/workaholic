#!/bin/sh -eu
# question-answers — read the answer a person wrote in a question's own thread.
#
# WHY THIS STEP EXISTS (2026-08-28, mission `let-an-answer-in-the-thread-turn-back-into-the-loop-s-work`).
# `record-answer.sh` has been the only writer of the answered line since 2026-08-23 and
# **nothing reached it**: its documented flow was the developer opening the session link and
# answering inside the moderator's own session, which costs a session per answer. A reply
# typed into the `🔎 Moderation` thread — where the question actually is — reached no writer
# at all: it is not a channel message, so `step-unanswered-asks.sh` never sees it, and the
# `:40` inbound sweep excludes answers to the tick's own questions by rule
# (`workaholic:propose`, *What is FB-worthy*). So the words survived in Slack and the loop
# never learned them.
#
# THE SPLIT IS `step-unanswered-asks.sh`'s, AND FOR ITS REASON. Slack is a **connector held
# by the session**, not by a script, so this step owns the mechanical half — which questions
# are outstanding and where each was posted — and hands the read back in `needs_agent`.
# Neither half is guessable from the other side.
#
# ONE THREAD READ PER OUTSTANDING QUESTION, ON A COORDINATE ALREADY IN HAND. No search, no
# channel-history read, and `workaholic:notify`'s two-query bound is untouched because **no
# query is made** — the same case-1 property the inbound sweep's receipt relies on. A later
# change must not widen this into a channel read: the coordinate is recorded at post time by
# `ask-question.sh --record-ask` precisely so it never has to be looked for.
#
# THE SET IS BOUNDED, AND THE BOUND IS NAMED. Outstanding questions accumulate — a question
# nobody ever answers stays `asked` forever — so the candidate set is capped at
# `WORKAHOLIC_ANSWER_READ_MAX` (default 10, the check-in's own daily bound rather than a new
# constant) taking the **newest first**: the thread a person is plausibly still reading. The
# number beyond the bound is reported rather than silently dropped.
#
# A CANDIDATE WITH NO COORDINATE IS COUNTED AND NAMED, NEVER SEARCHED FOR. That is an
# ordinary state — a question asked before the coordinate was recorded, or one whose post
# handed nothing back — and naming it is what keeps the alternative (find the thread by
# searching the channel) from creeping back in.
#
# ITS EVENT IS ALWAYS EMPTY, following `step-unanswered-asks.sh` deliberately: at the moment
# `run.sh` reads this step's line nobody has read any thread yet, so any event would be a
# claim about a reading not yet made. A step with no event renders no root line, which is
# right — this step's finding is delivered by what the agent then records, files and stamps.
#
# THE JUDGEMENT IS DELIBERATELY NOT HERE. Which replies are a person's answer is a model's
# call, and putting it in a script would put a judgement inside a gate; this step decides
# only *which threads to look at*.
#
# ═══ AND IT NAMES WHAT BECAME OF THE ANSWERS IT ALREADY HAS ══════════════════════════
# (2026-08-31, mission `make-the-tick-s-questions-readable-and-close-them-in-the-thread`.)
# The reaction says *received*; nothing said *acted on*, so from the thread an answer that
# became a merged mission and one that was read and dropped looked identical. A second
# candidate set rides the same pass over the ledger: a question reading `answered`, with a
# recorded coordinate, whose `answer-outcome.sh` reading is `settled:`, and with no
# `human-checkin-outcome-<slug>` line already in the log. The agent posts one `🧾 対応結果`
# reply into that question's own thread, on the coordinate already in hand.
#
# ONE PASS, TWO SETS. The answered slugs were already derived here to EXCLUDE them from the
# read candidates; naming them as their own set costs no second walk of the log and no second
# reader — which is the whole reason this step owns both halves rather than a new step owning
# one.
#
# THE OUTCOME IS A READING, NOT A GUESS. Only `settled:` posts. `pending` and
# `unreadable:<reason>` post nothing and are counted: an unread outcome rendered as a settled
# one would tell somebody their answer was acted on when nobody knows.
#
# THE HOLDS ARE THE CONFIRMATION REPLY'S, APPLIED THE SAME WAY. The off-day and quiet-hours
# holds apply and held is not dropped — stated in the bound rather than recomputed here, for
# `✅ 解消を確認`'s reason: a third copy of the clock gate is how the three start disagreeing,
# and a held candidate simply re-derives on the next eligible tick because the dedup is the
# ledger line rather than a cursor.
#
# THE ONE NETWORK READ IS THE READER'S, BOUNDED AND OFF THE FILING LINE. This step still makes
# no call of its own; `answer-outcome.sh` spends one bounded issue read per **filed** candidate
# and none for the rest, and the candidate set is capped by the same
# `WORKAHOLIC_ANSWER_READ_MAX` the thread reads use — one constant for one step, because the
# two sets grow the same way and a second bound would be a second thing to keep current.
#
# NEVER LOAD-BEARING. The recording, the filing and the stamp all happened in earlier ticks;
# a failed post is `outcome_post_failed: <reason>` and changes nothing about any of them, nor
# about the question's state or the reading.
#
# Usage: step-question-answers.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
LOG_READ="${SCRIPT_DIR}/log-read.sh"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit() {
    printf '{"step": "question-answers", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$(json_escape "$3")" "${4:-}" "${5:-}"
    exit 0
}

MAX="${WORKAHOLIC_ANSWER_READ_MAX:-10}"
case "$MAX" in ''|*[!0-9]*) MAX=10 ;; esac

[ -f "$LOG_READ" ] || emit degraded no_log_reader \
    "log-read.sh is not present beside this skill; the outstanding questions could not be read"

read_prefix() { sh "$LOG_READ" --root "$ROOT" --step-prefix "$1" 2>/dev/null || true; }

asked=$(read_prefix human-checkin-ask-)
reasked=$(read_prefix human-checkin-reasked-)
answered=$(read_prefix human-checkin-answered-)
outcomes=$(read_prefix human-checkin-outcome-)

[ -n "$asked" ] || emit degraded log_unreadable \
    "log-read.sh produced no output; the outstanding questions could not be read"

read_ok=$(printf '%s' "$asked" | jq -r '.read // false' 2>/dev/null || echo unparseable)
case "$read_ok" in
    true) ;;
    false)
        reason=$(printf '%s' "$asked" | jq -r '.reason // "unknown"' 2>/dev/null || echo unknown)
        # An ABSENT log is a readable answer: nothing has ever been asked, so nothing is
        # outstanding. Any other refusal is our own degradation and asks for no thread read.
        [ "$reason" = "no_log_area" ] || emit degraded log_unreadable \
            "the tick log refused: ${reason} — the outstanding questions could not be read"
        ;;
    *) emit degraded log_unreadable \
        "the tick log's output could not be parsed; the outstanding questions could not be read" ;;
esac

# The candidate set, derived in one pass so the ask lines and the answered lines cannot be
# read from two different snapshots. `question-state.sh` is the reader of ONE question; this
# is the same three facts over the whole ledger, which is why it composes `log-read.sh`
# directly rather than invoking that script once per key.
rows=$(printf '%s\n%s\n%s\n%s' "$asked" "$reasked" "$answered" "$outcomes" | jq -sc --argjson max "$MAX" '
    def entries(f): [ .[]? | select(.read? != null) | .entries[]? | select(.step | startswith(f)) ];
    def slug_of(f): .step | ltrimstr(f);
    def coord: (.summary // "") | [scan("posted-at:[^ ]+")] | (first // "") | ltrimstr("posted-at:");
    def keyof: (.summary // "") | [scan(" key:.*$")] | (first // "") | ltrimstr(" key:");

    . as $log
    | ( $log | entries("human-checkin-answered-")
             | map(slug_of("human-checkin-answered-")) | unique ) as $done
    # The person own words, newest line per slug: the reply carries the answer AS RECORDED.
    | ( $log | entries("human-checkin-answered-")
             | map(. + {slug: slug_of("human-checkin-answered-")})
             | group_by(.slug)
             | map((sort_by(.tick) | last) | {key: .slug, value: (.summary // "")})
             | from_entries ) as $words
    # A slug whose outcome reply an earlier tick already posted is out of the set by
    # construction: the ledger line is the dedup, and there is no cursor anywhere.
    | ( $log | entries("human-checkin-outcome-")
             | map(slug_of("human-checkin-outcome-")) | unique ) as $replied
    | ( ( $log | entries("human-checkin-ask-")     | map(. + {slug: slug_of("human-checkin-ask-")}) )
      + ( $log | entries("human-checkin-reasked-") | map(. + {slug: slug_of("human-checkin-reasked-")}) ) )
    | map(. + {coordinate: coord, key: keyof})
    | group_by(.slug)
    | map(
        ( (map(select(.coordinate != "")) | sort_by(.tick) | last)
          // (sort_by(.tick) | last) ) as $best
        | (sort_by(.tick) | last) as $newest
        | {slug: $newest.slug,
           key: ($best.key // "" | if . == "" then ($newest.key // "") else . end),
           coordinate: ($best.coordinate // ""),
           asked_tick: $newest.tick}
      )
    | sort_by(.asked_tick) | reverse
    | . as $all
    | ( $all | map(select(.slug | IN($done[]) | not)) ) as $open
    # The second set, off the same pass: answered, posted somewhere we know, not yet replied to.
    | ( $all | map(select((.slug | IN($done[])) and (.slug | IN($replied[]) | not)))
             | map(. + {answer: ($words[.slug] // "")}) ) as $settled_pool
    | {outstanding: ($open | length),
       candidates: ($open | map(select(.coordinate != "" and .key != "")) | .[0:$max]),
       beyond_bound: (($open | map(select(.coordinate != "" and .key != "")) | length) - $max | if . < 0 then 0 else . end),
       no_coordinate: ($open | map(select(.coordinate == "")) | map({slug, key, asked_tick})),
       no_key: ($open | map(select(.coordinate != "" and .key == "")) | map({slug, asked_tick})),
       outcome_pool: ($settled_pool | map(select(.coordinate != "" and .key != "")) | .[0:$max]),
       outcome_total: ($settled_pool | length),
       outcome_beyond_bound: (($settled_pool | map(select(.coordinate != "" and .key != "")) | length) - $max | if . < 0 then 0 else . end),
       outcome_no_coordinate: ($settled_pool | map(select(.coordinate == "")) | map({slug, key}))}
' 2>/dev/null || true)

[ -n "$rows" ] || emit degraded candidates_underivable \
    "the outstanding questions could not be derived from the tick log"

n_out=$(printf '%s' "$rows" | jq -r '.outstanding' 2>/dev/null || echo 0)
n_cand=$(printf '%s' "$rows" | jq -r '.candidates | length' 2>/dev/null || echo 0)
n_beyond=$(printf '%s' "$rows" | jq -r '.beyond_bound' 2>/dev/null || echo 0)
n_nocoord=$(printf '%s' "$rows" | jq -r '.no_coordinate | length' 2>/dev/null || echo 0)
n_nokey=$(printf '%s' "$rows" | jq -r '.no_key | length' 2>/dev/null || echo 0)

n_pool=$(printf '%s' "$rows" | jq -r '.outcome_pool | length' 2>/dev/null || echo 0)
n_onocoord=$(printf '%s' "$rows" | jq -r '.outcome_no_coordinate | length' 2>/dev/null || echo 0)
n_obeyond=$(printf '%s' "$rows" | jq -r '.outcome_beyond_bound' 2>/dev/null || echo 0)

# WHAT BECAME OF THE ANSWERS WE ALREADY HAVE. One `answer-outcome.sh` run per pooled candidate;
# only a `settled:` reading becomes a reply. `pending` and `unreadable:<reason>` are counted and
# post nothing — an unread outcome rendered as a settled one would tell somebody their answer was
# acted on when nobody knows.
ANSWER_OUTCOME="${SCRIPT_DIR}/answer-outcome.sh"
outcome_json='[]'
settled_n=0
opending_n=0
ounreadable_n=0
if [ -f "$ANSWER_OUTCOME" ] && [ "$n_pool" != "0" ]; then
    pool=$(printf '%s' "$rows" \
        | jq -r '.outcome_pool[] | [.slug, .key, .coordinate, (.answer | gsub("\t"; " "))] | @tsv' \
          2>/dev/null || printf '')
    TAB=$(printf '\t')
    while IFS="$TAB" read -r p_slug p_key p_coord p_answer; do
        [ -n "${p_key:-}" ] || continue
        res=$(sh "$ANSWER_OUTCOME" --key "$p_key" --root "$ROOT" 2>/dev/null || printf '')
        if [ -z "$res" ]; then ounreadable_n=$((ounreadable_n + 1)); continue; fi
        oc=$(printf '%s' "$res" | jq -r '.outcome // ""' 2>/dev/null || printf '')
        case "$oc" in
            settled:*)
                settled_n=$((settled_n + 1))
                merged=$(printf '%s' "$outcome_json" | jq -c \
                    --arg slug "$p_slug" --arg key "$p_key" --arg coordinate "$p_coord" \
                    --arg answer "${p_answer:-}" --argjson r "$res" \
                    '. + [{slug: $slug, key: $key, coordinate: $coordinate, answer: $answer,
                           outcome: $r.outcome, issue: $r.issue,
                           issue_state: $r.issue_state, issue_reason: $r.issue_reason}]' \
                    2>/dev/null || printf '')
                [ -n "$merged" ] && outcome_json="$merged"
                ;;
            pending) opending_n=$((opending_n + 1)) ;;
            *) ounreadable_n=$((ounreadable_n + 1)) ;;
        esac
    done <<POOL
$pool
POOL
fi

summary="${n_out} question(s) outstanding; ${n_cand} thread(s) to read on a recorded coordinate; ${n_nocoord} with no coordinate recorded, ${n_nokey} with no key recorded, ${n_beyond} beyond the ${MAX}-read bound; ${settled_n} answered question(s) with a settled outcome to reply, ${opending_n} not settled yet, ${ounreadable_n} unreadable, ${n_onocoord} with no coordinate recorded, ${n_obeyond} beyond the bound"

if [ "$n_cand" = "0" ] && [ "$settled_n" = "0" ]; then
    emit ok "" "$summary" "" ""
fi

needs=$(printf '%s' "$rows" | jq -c --arg tick "$TICK" --argjson settled "$outcome_json" '
    {action: "read_each_outstanding_question_thread_and_record_the_answer",
     surface: "slack",
     tick: $tick,
     bound: "one slack_read_thread per candidate, on the coordinate given — NO search, NO channel history, and no other Slack read; the coordinate was recorded when the question was posted precisely so none is needed",
     judgement: "a reply is an ANSWER when a person wrote it in that question own thread; every post this plugin emits (the tick root, its questions, its confirmations, any finish line) is excluded BY SHAPE and is never an answer; when unsure, do NOT record and say what made you unsure",
     record: "per candidate, either record-answer.sh --tick <tick> --key <key> --answer \"<their words>\", or a named not-recorded reason — a candidate handed back with no outcome is non-conformant on its face",
     then: "an answer that ASKS FOR SOMETHING becomes one [FB] issue through propose/scripts/file-inbound-ask.sh, and an answer this run recorded carries the catalog reaction on the answer message; neither is load-bearing on the recording",
     candidates: .candidates,
     no_coordinate: .no_coordinate,
     no_key: .no_key,
     degradations: "name each by itself: no_slack_transport when the session holds no connector, thread_unreadable with the reason the transport gave — never report an unread thread as a thread nobody answered",
     outcome_action: "post one 🧾 対応結果 reply per settled candidate into that question own thread, on the coordinate given — no lookup, no search, no mention token, once ever per question",
     outcome_shape: "the catalog names it (workaholic:notify, /moderate): a heading naming the question subject, then one sentence carrying the answer as recorded and what came of it",
     outcome_holds: "the off-day and quiet-hours holds apply exactly as they do to ✅ 解消を確認, and held is not dropped — a held candidate is a candidate again on the next eligible tick, because the dedup is the ledger line and not a cursor",
     outcome_record: "per candidate, one human-checkin-outcome-<slug> line through log-append.sh, then persist-log.sh --tick again — the second persist, without which the line dies with the container and the reply is posted twice",
     outcome_never: "it is never load-bearing: a failed post is outcome_post_failed: <reason> and changes nothing about the recording, the filing, the stamp, the question state or the reading",
     outcome_candidates: $settled,
     outcome_no_coordinate: .outcome_no_coordinate}' \
    2>/dev/null || echo '{}')

emit ok "" "$summary" "$needs" ""
