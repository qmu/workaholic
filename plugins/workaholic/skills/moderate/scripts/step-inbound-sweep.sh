#!/bin/sh -eu
# Step 2 — sweep the inbound surfaces for what the repository should know.
#
# WHAT IT ACTUALLY DOES, AND WHAT IT CANNOT. Of the four surfaces the ask names,
# exactly one is reachable from a shell: GitHub, through the sanctioned REST
# transport. Slack, Gmail and Drive are **connectors held by the session**, not by
# this script — so this step settles GitHub itself and hands the other three back
# in `needs_agent` for the agent to probe with the tools it has. Every surface is
# named either way: `no_surface: gmail` and "gmail had nothing" are different
# answers, and a tick that renders the first as the second is claiming coverage it
# never had.
#
# THE WINDOW IS THE LAST SWEEP, NOT A CLOCK. `--since` defaults to the previous
# tick that recorded an `inbound-sweep` line, read out of the tick log; with no
# such tick it is this tick's own UTC day start. Deliberate: deriving "an hour ago"
# needs `date -d` (GNU) or `date -v` (BSD), and a window that differs between the
# developer's laptop and the routine's container is worse than one anchored to a
# fact both can read. The tick id is already `YYYYMMDD-HHMMSS`, so the conversion
# is string surgery and nothing else.
#
# IT FILES NOTHING ITSELF (the ticket's first Open Decision, resolved 2026-08-17).
# Candidates come back in `needs_agent`; the agent applies the materiality bar and
# writes a **feedback record** through `feedback/scripts/create.sh`. It does NOT
# open a GitHub issue here: the crossing flow is gated on a verbatim human
# confirmation an unattended tick cannot give, and a self-filed assigned issue
# would be re-discovered by `[Specificate]` every hour forever — a record written
# before the issue can never name it, which is the measured reason issue #443's
# auto-file option was refused on 2026-08-14.
#
# QUOTING RULE (the ticket's second Open Decision, resolved 2026-08-17):
# POINTER AND SUBJECT LINE ONLY. A candidate carries its surface, a stable
# identifier or permalink, and the title/subject as written — never a message body,
# an attachment, or a Drive file's contents. `.workaholic/` history is durable and
# the leak scan matches only a hand-maintained denylist, so a `pass` there never
# means "no sensitive content"; a pointer leaves the content behind its own access
# controls, where the person who can read it decides what to quote.
#
# Usage: inbound-sweep.sh --tick <id> --root <repo-root> [--since <ISO8601>] [--limit <n>]
# Output: one JSON line
#   {"step","status","reason","summary","needs_agent":[...],"surfaces":{...},"since":"..."}

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
# One derivation of a tick id's timestamp, shared with `step-doc-drift.sh`: two copies of
# the same unvalidated substitution is how one poisoned log entry blinded both steps.
. "${SCRIPT_DIR}/lib/tick-iso.sh"
GATHER="${SCRIPT_DIR}/../../gather/scripts"
LOG_READ="${SCRIPT_DIR}/log-read.sh"

TICK=''
ROOT='.'
SINCE=''
LIMIT=30

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)  TICK="${2:-}"; shift 2 ;;
        --root)  ROOT="${2:-}"; shift 2 ;;
        --since) SINCE="${2:-}"; shift 2 ;;
        --limit) LIMIT="${2:-30}"; shift 2 ;;
        *) shift ;;
    esac
done

case "$LIMIT" in
    ''|*[!0-9]*) LIMIT=30 ;;
esac

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

emit() {
    # $1 status  $2 reason  $3 summary  $4 needs_agent body  $5 surfaces body
    # `event` is the POST-facing phrase, beside the LOG-facing `summary` and never instead of it
# (2026-08-23). Two audiences: the log is an audit trail a maintainer reads when the tick
# misbehaves and keeps every counter; the root is read by a person scanning a channel, who
# needs the repository's event. This step supplies it because it knows what its finding means.
# **Empty means nothing happened here** — the renderer then emits no line at all, independently
# of the change diff.
printf '{"step": "inbound-sweep", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "surfaces": {%s}, "since": "%s", "event": "%s"}\n' \
        "$1" "$2" "$(json_escape "$3")" "$4" "$5" "$(json_escape "$SINCE")" "$(json_escape "${6:-}")"
    exit 0
}

# The three connector surfaces are always handed to the agent, with the bound each
# is read under. Slack's is not advice: `workaholic:notify` fixes it at exact-string
# search, at most two queries, and no full-channel read at any point.
AGENT_SURFACES='{"surface": "slack", "action": "probe_connector", "bound": "exact-string search only, at most two queries, never a channel history read"}, {"surface": "gmail", "action": "probe_connector", "bound": "pointer and subject line only — never a message body"}, {"surface": "drive", "action": "probe_connector", "bound": "pointer and file title only — never file contents"}'
SURFACES='"slack": "agent_probe", "gmail": "agent_probe", "drive": "agent_probe"'

# The window: the previous sweep's tick, else this tick's day start. The conversion is
# `lib/tick-iso.sh`'s and it VALIDATES — the log is append-only and carries whatever any
# tick ever wrote, so a sentinel id in it (measured: `20260819-999999`, which sorts last
# and therefore won every window for seven days) must cost one wide window and a named
# reason, never a malformed `since` GitHub rejects while this step reports itself healthy.
WINDOW_REASON=''
if [ -z "$SINCE" ]; then
    prev=''
    if [ -f "$LOG_READ" ]; then
        prev=$(sh "$LOG_READ" --root "$ROOT" --step inbound-sweep 2>/dev/null |
               tr ',' '\n' | grep '"tick"' | sed 's/.*"tick": "//; s/".*//' |
               grep -v "^${TICK}$" | sort | tail -n 1 || true)
    fi
    if [ -n "$prev" ]; then
        SINCE=$(tick_to_iso "$prev")
        [ -n "$SINCE" ] || WINDOW_REASON="previous tick id ${prev} is not a timestamp — widened to this tick's day start"
    fi
    [ -n "$SINCE" ] || SINCE=$(tick_day_iso "$TICK")
fi
if [ -z "$SINCE" ]; then
    emit degraded bad_window \
        "no readable window: neither the previous sweep's tick nor ${TICK} is a timestamp; slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"bad_window\", $SURFACES"
fi

if ! command -v gh >/dev/null 2>&1; then
    emit degraded gh_unavailable \
        "GitHub unreadable (gh is not on PATH)${WINDOW_REASON:+; ${WINDOW_REASON}}; slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"gh_unavailable\", $SURFACES"
fi

slug=$(sh "${GATHER}/gh-rest.sh" slug 2>/dev/null || true)
if [ -z "$slug" ]; then
    emit degraded gh_unavailable \
        "GitHub unreadable (no repository slug)${WINDOW_REASON:+; ${WINDOW_REASON}}; slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"gh_unavailable\", $SURFACES"
fi

# Repository-scoped, `since`-filtered, pull requests dropped: they share the issue
# numbering space and a sweep that kept them would re-file the loop's own work.
# A FAILED READ IS NOT AN EMPTY ONE, and it is not a finding either (2026-08-26). The
# `|| true` swallowed the transport's exit status, and an error body reaching stdout was
# then parsed as a row — measured, GitHub's `422 The since parameter needs to be in ISO
# 8601 format` was handed to the agent as an inbound ask "to judge", with the error
# document as its reference. Both halves are guarded: the status decides whether the read
# happened, and a row whose number is not a number means the response was not the shape
# this step reads, which is a degraded read by any other name.
rows=$(sh "${GATHER}/gh-rest.sh" api \
    "repos/${slug}/issues?state=open&sort=updated&direction=desc&since=${SINCE}&per_page=${LIMIT}" \
    --jq 'map(select(.pull_request | not)) | .[] | [(.number|tostring), .html_url, .updated_at, .title] | @tsv' 2>/dev/null) || rows='__read_failed__'

if [ "$rows" = '__read_failed__' ]; then
    emit degraded gh_read_failed \
        "GitHub read since ${SINCE} failed — the issues endpoint did not answer${WINDOW_REASON:+ (${WINDOW_REASON})}; slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"gh_read_failed\", $SURFACES"
fi

if [ -z "$rows" ]; then
    emit ok "" \
        "GitHub read since ${SINCE}: nothing updated${WINDOW_REASON:+; ${WINDOW_REASON}}; slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"read\", $SURFACES"
fi

TAB=$(printf '\t')
candidates=''
seen=0
skipped=0
FEEDBACKS="$ROOT/.workaholic/feedbacks"
malformed=0
while IFS="$TAB" read -r number url updated title; do
    [ -n "$number" ] || continue
    # An issue number is digits. Anything else is a response this step does not read —
    # an error document, an HTML interstitial — and manufacturing a candidate from it is
    # what turned a 422 into a week of "1 new inbound ask arrived on GitHub".
    case "$number" in
        *[!0-9]*) malformed=$((malformed + 1)); continue ;;
    esac
    seen=$((seen + 1))
    # Already captured: a feedback record naming this issue means the loop has it.
    if [ -d "$FEEDBACKS" ] && grep -rqE "/issues/${number}([^0-9]|\$)" "$FEEDBACKS" 2>/dev/null; then
        skipped=$((skipped + 1))
        continue
    fi
    # Already swept: an earlier tick that filed this one must not file it again.
    if [ -f "$LOG_READ" ] && [ "$(sh "$LOG_READ" --root "$ROOT" --step inbound-sweep-filed --contains "#${number}" 2>/dev/null | sed 's/.*"count": //; s/,.*//')" != "0" ]; then
        skipped=$((skipped + 1))
        continue
    fi
    candidates="${candidates:+${candidates}, }{\"surface\": \"github\", \"action\": \"judge_and_file\", \"ref\": \"#${number}\", \"url\": \"$(json_escape "$url")\", \"title\": \"$(json_escape "$title")\", \"updated_at\": \"$(json_escape "$updated")\"}"
done <<EOF
$rows
EOF

if [ "$seen" -eq 0 ] && [ "$malformed" -gt 0 ]; then
    emit degraded gh_read_failed \
        "GitHub read since ${SINCE} returned ${malformed} unreadable row(s) and no issue — the response was not the issues list${WINDOW_REASON:+ (${WINDOW_REASON})}; slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"gh_read_failed\", $SURFACES"
fi

count=0
if [ -n "$candidates" ]; then
    count=$(printf '%s' "$candidates" | awk '{ print gsub(/"surface": "github"/, "&") }')
fi

# The event names only what ARRIVED. `seen`, `skipped` and the surfaces left to probe are
# the tick's own bookkeeping and stay in the log; an hour with nothing new to judge leaves
# the event empty and renders no line.
INBOUND_EVENT=""
[ "${count:-0}" -gt 0 ] && INBOUND_EVENT="${count} new inbound ask(s) arrived on GitHub"
emit ok "" \
    "GitHub read since ${SINCE}: ${seen} updated, ${skipped} already captured, ${count} to judge${WINDOW_REASON:+; ${WINDOW_REASON}}; slack/gmail/drive left for the agent to probe" \
    "${candidates:+${candidates}, }$AGENT_SURFACES" "\"github\": \"read\", $SURFACES" "$INBOUND_EVENT"
