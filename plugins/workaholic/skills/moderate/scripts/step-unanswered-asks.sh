#!/bin/sh -eu
# unanswered-asks — a message on the channel that nobody has answered, said to a person.
#
# WHY THIS STEP EXISTS (2026-08-26, mission `answer-what-is-waiting-and-stamp-what-was-accepted`).
# The tick's question set was bounded by what its own steps found: `step-stalled-units.sh` reads
# claims, `step-direction-health.sh` reads strategies, and nothing read the channel for a human
# message nobody has answered. So a question, request or opinion written on `#dev-<repo>` reached
# a person only if one of the tick's own readers happened to produce a row about it — and a
# message the tick *saw* in its inbound sweep and did not file produced nothing at all. That is
# the measured failure behind this mission's source record: the tick of 19:18 JST found the
# developer's message, filed nothing, deferred to the `:40` sweep, and told nobody; the developer
# asked in session why it had not been handled.
#
# NO MENTION IS REQUIRED, ANYWHERE. That is the point, and it is the same premise the inbound
# sweep was rebuilt on: a person writing in the repository's own channel is not required to
# summon a bot for what they wrote to count.
#
# THE SPLIT IS THE INBOUND SWEEP'S, AND FOR THE INBOUND SWEEP'S REASON. Slack is a **connector
# held by the session**, not by a script (`step-inbound-sweep.sh`), so this step owns the
# mechanical half — which channel, which window, and which `(channel, ts)` an earlier tick
# already asked about — and hands the judgement half back in `needs_agent`: whether a message is
# a question, a request or an opinion, and whether anything has answered it. Neither half is
# guessable from the other side.
#
# ITS EVENT IS ALWAYS EMPTY, AND THAT IS A DELIBERATE DIVERGENCE from the shape of
# `step-direction-health.sh` and `step-stalled-units.sh`, which settle their readings in the
# shell and can therefore name a repository event. This step cannot: at the moment `run.sh`
# reads its line, nobody has looked at the channel yet, so any event it supplied would be a
# claim about a reading it has not made. A step with no event renders no root line — which is
# right here, because the finding's whole delivery is the question the check-in asks, and a
# question is already a reply inside that root.
#
# THE WINDOW AND THE CHANNEL ARE THE INBOUND SWEEP'S OWN, ON PURPOSE.
# `WORKAHOLIC_INBOUND_SLACK_CHANNEL` (default `<repo_name>`) and
# `WORKAHOLIC_INBOUND_SLACK_WINDOW_HOURS` (default 26) are read here unchanged rather than
# duplicated under new names: one channel and one window mean the two readings cannot disagree
# about which messages the loop had a chance to see, and a second pair of variables is how they
# would. The cost is stated rather than hidden — a message already older than the window when
# this step first runs is never asked about, and nothing here backfills it. The asked-once
# ledger then covers every message that arrives afterwards, exactly once.
#
# THE LEDGER IS THE TICK LOG, AND THERE IS NO SECOND ONE. The refs an earlier tick already asked
# about are read out of its own `unanswered-asks-filed` lines through `log-read.sh` — the same
# `<step>-filed` convention `step-inbound-sweep.sh` uses — and handed to the agent so it does not
# spend a probe re-deriving them. It is an optimisation and not the gate: the gate is
# `ask-question.sh`'s already-asked ledger, which keys on the content key mechanically and is
# what actually guarantees "asked exactly once". Nothing here re-implements the per-tick cap,
# the daily bound, the quiet hours or the working-day hold.
#
# AN ABSENT LOG AND AN UNREADABLE ONE ARE DIFFERENT ANSWERS. `no_log_area` is a **readable**
# answer — there is definitively nothing recorded — and yields an empty already-asked set. Any
# other refusal from the reader, or a missing reader, is `degraded` with the reason named and
# **asks nothing**: filing against a ledger that could not be read is how the same person is
# asked the same question every hour.
#
# IT ASKS; IT NEVER ANSWERS, FILES OR CAPTURES. Turning a channel message into an `[FB]` issue
# is the `:40` sweep's job (`workaholic:propose`) and stays there — this step's only output is a
# question addressed to a person. The two overlap by design: the sweep runs at `:40` and this at
# `:50`, so a message captured this hour normally already has an issue. That is a reason to read
# **whether anything answered it**, not a reason to skip it — an issue nobody has replied to is
# still a person waiting.
#
# THE ASK SAID "REACTED TO". The tick's way of reacting to something is to ask a named person
# about it inside its root; a second status surface would be the line addressed to nobody this
# repository has retired twice.
#
# Usage: step-unanswered-asks.sh --tick <id> [--root <repo-root>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
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

# `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it
# (2026-08-23). This step always supplies the empty string — see the header.
emit() {
    printf '{"step": "unanswered-asks", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$(json_escape "$3")" "${4:-}" "${5:-}"
    exit 0
}

# --- The channel -------------------------------------------------------------
# Derived from the remote first: inside a claim worktree the working tree's basename is the unit
# id, not the repository, so `--show-toplevel` is the fallback and never the first answer.
CHANNEL="${WORKAHOLIC_INBOUND_SLACK_CHANNEL:-}"
if [ -z "$CHANNEL" ]; then
    remote=$( ( cd "$ROOT" && git config --get remote.origin.url ) 2>/dev/null || true)
    repo_name=""
    if [ -n "$remote" ]; then
        repo_name=$(basename "$remote" .git)
    else
        top=$( ( cd "$ROOT" && git rev-parse --show-toplevel ) 2>/dev/null || true)
        [ -n "$top" ] && repo_name=$(basename "$top")
    fi
    [ -n "$repo_name" ] || emit degraded no_channel \
        "no channel could be derived: this tree names no remote and no repository root"
    # The repository's own name, with no prefix (2026-08-28, the operator's ruling — the
    # `dev-` convention is retired; a repository whose channel still carries a prefix sets
    # WORKAHOLIC_INBOUND_SLACK_CHANNEL instead).
    CHANNEL="${repo_name}"
fi

# --- The window --------------------------------------------------------------
WINDOW="${WORKAHOLIC_INBOUND_SLACK_WINDOW_HOURS:-26}"
case "$WINDOW" in
    ''|*[!0-9]*) WINDOW=26 ;;
esac

# --- The already-asked set ---------------------------------------------------
[ -f "$LOG_READ" ] || emit degraded no_log_reader \
    "log-read.sh is not present beside this skill; what an earlier tick already asked could not be read"

ledger=$(sh "$LOG_READ" --root "$ROOT" --step unanswered-asks-filed 2>/dev/null || true)
[ -n "$ledger" ] || emit degraded ledger_unreadable \
    "log-read.sh produced no output; what an earlier tick already asked could not be read"

read_ok=$(printf '%s' "$ledger" | jq -r '.read // false' 2>/dev/null || echo unparseable)
case "$read_ok" in
    true) ;;
    false)
        reason=$(printf '%s' "$ledger" | jq -r '.reason // "unknown"' 2>/dev/null || echo unknown)
        # An ABSENT log is a readable answer: nothing has been asked. Any other refusal is not.
        [ "$reason" = "no_log_area" ] || emit degraded ledger_unreadable \
            "the tick log refused: ${reason} — what an earlier tick already asked could not be read"
        ;;
    *) emit degraded ledger_unreadable \
        "the tick log's output could not be parsed; what an earlier tick already asked could not be read" ;;
esac

# The refs an earlier tick recorded, taken from its own `<step>-filed` summaries. A summary is
# free text by contract, so the extraction matches the key shape rather than a field position.
asked=$(printf '%s' "$ledger" \
    | jq -r '.entries[]? | .summary' 2>/dev/null \
    | grep -o 'unanswered-ask:[A-Za-z0-9._:-]*' 2>/dev/null \
    | sed 's/^unanswered-ask://' \
    | sort -u || true)
asked_json=$(printf '%s' "$asked" | jq -Rsc 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')
n_asked=$(printf '%s' "$asked_json" | jq 'length' 2>/dev/null || echo 0)

summary="channel #${CHANNEL}, window ${WINDOW}h; ${n_asked} already asked about; the channel read is the agent's"

needs=$(jq -nc \
    --arg channel "$CHANNEL" \
    --arg window "$WINDOW" \
    --argjson asked "$asked_json" \
    '{action: "probe_the_channel_for_asks_nobody_has_answered",
      surface: "slack",
      channel: $channel,
      window_hours: ($window | tonumber),
      bound: "read the one designated channel over the window, as the inbound sweep does; NO mention of any bot is required for a message to count, and nothing here files, replies or captures — the only output is a question",
      judgement: "a message is a candidate when a person wrote it, it is a question, a request or an opinion, and nothing has answered it — not a reply in its thread, not a later message addressing it, not an issue with a reply on it; a post the loop itself emitted is never a candidate",
      key_shape: "unanswered-ask:<channel>:<ts>",
      compose: "one question per candidate, addressed to a named person — the message author when nobody else owns it — routed through ask-question.sh on the key above so the asked-once gate, the per-tick cap, the quiet hours and the working-day hold all apply unchanged; name what is waiting and link the message",
      already_asked: $asked,
      degradations: "name each by itself: no_slack_transport when the session holds no connector, channel_unreadable with the reason the transport gave — never report an unread channel as a channel with nothing waiting"}' \
    2>/dev/null || echo '{}')

emit ok "" "$summary" "$needs" ""
