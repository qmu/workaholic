#!/bin/sh -eu
# Step 5 — stale issues, and drift between GitHub and `.workaholic/`.
#
# THE CHEAPEST AND MOST VALUABLE OF THE FOUR. It is a pure read over two lists,
# and it catches the failure nobody watches: work that landed while its issue
# stayed open, and an issue the loop never ingested at all.
#
# THREE MECHANICAL FACTS, NO VERDICTS:
#   landed_but_open  an OPEN issue whose number an ARCHIVED ticket or a story
#                    names — the work landed, so the issue is probably closable.
#   never_ingested   an OPEN issue no feedback record names — `[Specificate]` has not
#                    taken it (it only takes issues assigned to the running
#                    identity, so an unassigned or someone else's issue lands here
#                    legitimately, which is why this is a fact and not a fault).
#   oldest           the least recently updated open issues, with their dates, for
#                    the agent to judge staleness against.
#
# IT CLOSES NOTHING AND MERGES NOTHING. An issue is somebody's words; a machine
# that closed them hourly would be deciding what the project heard. Consolidating
# two issues is a judgement, so it is proposed, never performed — and closure,
# when it happens, is a human's act with the reason recorded. "Remove" is never
# delete: the repository's history is the durable record.
#
# Usage: step-issue-triage.sh --tick <id> --root <repo-root> [--limit <n>]
# Output: one JSON line {"step","status","reason","summary","needs_agent":[...]}

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
GATHER="${SCRIPT_DIR}/../../gather/scripts"
ROOT='.'
LIMIT=30

while [ $# -gt 0 ]; do
    case "$1" in
        --limit) LIMIT="${2:-30}"; shift 2 ;;
        --root)  ROOT="${2:-}"; shift 2 ;;
        --tick)  shift 2 ;;
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
    printf '{"step": "issue-triage", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s]}\n' \
        "$1" "$2" "$(json_escape "$3")" "$4"
    exit 0
}

command -v gh >/dev/null 2>&1 || emit degraded gh_unavailable "GitHub unreadable — the drift set is unknown this tick" ""

slug=$(sh "${GATHER}/gh-rest.sh" slug 2>/dev/null || true)
[ -n "$slug" ] || emit degraded gh_unavailable "GitHub unreadable (no repository slug) — the drift set is unknown this tick" ""

rows=$(sh "${GATHER}/gh-rest.sh" api \
    "repos/${slug}/issues?state=open&sort=updated&direction=asc&per_page=${LIMIT}" \
    --jq 'map(select(.pull_request | not)) | .[] | [(.number|tostring), .html_url, .updated_at, .title] | @tsv' 2>/dev/null || true)

if [ -z "$rows" ]; then
    emit ok "" "no open issues — nothing to triage" ""
fi

ARCHIVE="$ROOT/.workaholic/tickets/archive"
STORIES="$ROOT/.workaholic/stories"
FEEDBACKS="$ROOT/.workaholic/feedbacks"

TAB=$(printf '\t')
needs=''
open_count=0
landed=0
never=0
oldest_shown=0
while IFS="$TAB" read -r number url updated title; do
    [ -n "$number" ] || continue
    open_count=$((open_count + 1))
    kinds=''

    if { [ -d "$ARCHIVE" ] && grep -rqE "/issues/${number}([^0-9]|\$)" "$ARCHIVE" 2>/dev/null; } ||
       { [ -d "$STORIES" ] && grep -rqE "/issues/${number}([^0-9]|\$)" "$STORIES" 2>/dev/null; }; then
        kinds='landed_but_open'
        landed=$((landed + 1))
    elif [ ! -d "$FEEDBACKS" ] || ! grep -rqE "/issues/${number}([^0-9]|\$)" "$FEEDBACKS" 2>/dev/null; then
        kinds='never_ingested'
        never=$((never + 1))
    elif [ "$oldest_shown" -lt 3 ]; then
        # The list is sorted oldest-updated first, so the first few carrying no
        # other signal are the staleness candidates.
        kinds='oldest'
        oldest_shown=$((oldest_shown + 1))
    fi

    [ -n "$kinds" ] || continue
    needs="${needs:+${needs}, }{\"action\": \"judge_and_file\", \"drift\": \"${kinds}\", \"issue\": ${number}, \"url\": \"$(json_escape "$url")\", \"title\": \"$(json_escape "$title")\", \"updated_at\": \"$(json_escape "$updated")\", \"bound\": \"propose, never perform: no close, no consolidation, no delete\"}"
done <<EOF
$rows
EOF

if [ -z "$needs" ]; then
    emit ok "" "${open_count} open issue(s), no drift against .workaholic/" ""
fi

emit ok "" \
    "${open_count} open issue(s): ${landed} landed but still open, ${never} never ingested, ${oldest_shown} oldest for a staleness judgement" \
    "$needs"
