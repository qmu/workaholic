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
# would be re-discovered by `[Propose]` every hour forever — a record written
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
    printf '{"step": "inbound-sweep", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "surfaces": {%s}, "since": "%s"}\n' \
        "$1" "$2" "$(json_escape "$3")" "$4" "$5" "$(json_escape "$SINCE")"
    exit 0
}

# The three connector surfaces are always handed to the agent, with the bound each
# is read under. Slack's is not advice: `workaholic:notify` fixes it at exact-string
# search, at most two queries, and no full-channel read at any point.
AGENT_SURFACES='{"surface": "slack", "action": "probe_connector", "bound": "exact-string search only, at most two queries, never a channel history read"}, {"surface": "gmail", "action": "probe_connector", "bound": "pointer and subject line only — never a message body"}, {"surface": "drive", "action": "probe_connector", "bound": "pointer and file title only — never file contents"}'
SURFACES='"slack": "agent_probe", "gmail": "agent_probe", "drive": "agent_probe"'

# The window: the previous sweep's tick, else this tick's day start.
if [ -z "$SINCE" ]; then
    prev=''
    if [ -f "$LOG_READ" ]; then
        prev=$(sh "$LOG_READ" --root "$ROOT" --step inbound-sweep 2>/dev/null |
               tr ',' '\n' | grep '"tick"' | sed 's/.*"tick": "//; s/".*//' |
               grep -v "^${TICK}$" | sort | tail -n 1 || true)
    fi
    if [ -n "$prev" ]; then
        SINCE=$(printf '%s' "$prev" | sed 's/^\(....\)\(..\)\(..\)-\(..\)\(..\)\(..\)$/\1-\2-\3T\4:\5:\6Z/')
    else
        SINCE=$(printf '%s' "$TICK" | sed 's/^\(....\)\(..\)\(..\)-.*$/\1-\2-\3T00:00:00Z/')
    fi
fi

if ! command -v gh >/dev/null 2>&1; then
    emit degraded gh_unavailable \
        "GitHub unreadable (gh is not on PATH); slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"gh_unavailable\", $SURFACES"
fi

slug=$(sh "${GATHER}/gh-rest.sh" slug 2>/dev/null || true)
if [ -z "$slug" ]; then
    emit degraded gh_unavailable \
        "GitHub unreadable (no repository slug); slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"gh_unavailable\", $SURFACES"
fi

# Repository-scoped, `since`-filtered, pull requests dropped: they share the issue
# numbering space and a sweep that kept them would re-file the loop's own work.
rows=$(sh "${GATHER}/gh-rest.sh" api \
    "repos/${slug}/issues?state=open&sort=updated&direction=desc&since=${SINCE}&per_page=${LIMIT}" \
    --jq 'map(select(.pull_request | not)) | .[] | [(.number|tostring), .html_url, .updated_at, .title] | @tsv' 2>/dev/null || true)

if [ -z "$rows" ]; then
    emit ok "" \
        "GitHub read since ${SINCE}: nothing updated; slack/gmail/drive left for the agent to probe" \
        "$AGENT_SURFACES" "\"github\": \"read\", $SURFACES"
fi

TAB=$(printf '\t')
candidates=''
seen=0
skipped=0
FEEDBACKS="$ROOT/.workaholic/feedbacks"
while IFS="$TAB" read -r number url updated title; do
    [ -n "$number" ] || continue
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

count=0
if [ -n "$candidates" ]; then
    count=$(printf '%s' "$candidates" | awk '{ print gsub(/"surface": "github"/, "&") }')
fi

emit ok "" \
    "GitHub read since ${SINCE}: ${seen} updated, ${skipped} already captured, ${count} to judge; slack/gmail/drive left for the agent to probe" \
    "${candidates:+${candidates}, }$AGENT_SURFACES" "\"github\": \"read\", $SURFACES"
