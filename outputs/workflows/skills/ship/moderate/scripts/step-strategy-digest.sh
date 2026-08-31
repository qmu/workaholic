#!/bin/sh -eu
# Step 14 — the morning's per-strategy digest, carried by the Moderation root.
#
# WHY THIS STEP EXISTS, AND WHY THE SEPARATE ROUTINE DOES NOT (2026-08-24, the
# developer's ruling: the standup had been integrated into the moderation tick, and a
# separate [Standup] routine they had deleted was mistakenly re-created the same day).
# The per-strategy morning status belongs in the one thread the developer already reads
# — the morning Moderation root — not in a second root posted five minutes away by a
# second routine the repository's designated account has to maintain. The [Standup]
# template is retired with this step; `/standup` survives as a command a human runs on
# demand.
#
# ONCE PER Asia/Tokyo DAY, ON THE FIRST TICK AT OR AFTER 09:00. The day and hour are
# read from the TICK ID, not the wall clock, so a re-entered tick answers the same way
# twice. Before 09:00 the step reports `before_morning` and emits nothing; after the
# digest has been logged once (the tick log carries a `strategy-digest` line for this
# JST day), it reports `already_rendered`. The log is the same dedup every other step
# uses — no new store, no cursor.
#
# WHAT IT EMITS: the digest as data (`standup/scripts/digest.sh`, the same pure read
# `/standup` uses — one derivation, two consumers, never a second parser), handed to the
# agent to render at the TOP of the Moderation root in the numbered form the developer
# specified (2026-08-24): the headline is `commit_count`, each strategy is numbered with
# a bold title on its own line, and the honesty line names tickets and the window.
#
# THE DIGEST IS A SECOND GATE ON THE ROOT, beside the question gate: a morning tick
# whose digest is present posts its root even with zero questions, because the digest is
# the day's opening statement and the developer asked to find it there. Every other hour
# the question gate stands alone, unchanged.
#
# A DEGRADED READ IS NAMED, NEVER RENDERED AS A QUIET MORNING: an unreadable digest
# reports `digest_unreadable` and emits nothing.
#
# Usage: step-strategy-digest.sh --tick <id> [--root <repo-root>]
# Output: one JSON line {"step","status","reason","summary","needs_agent":[...],"event"}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/jq-guard.sh"
STANDUP_SCRIPTS="${SCRIPT_DIR}/../../standup/scripts/"

TICK=""
ROOT="."
while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

emit() {
    printf '{"step": "strategy-digest", "status": "%s", "reason": "%s", "summary": "%s", "needs_agent": [%s], "event": "%s"}\n' \
        "$1" "$2" "$3" "${4:-}" "${5:-}"
    exit 0
}

[ -n "$TICK" ] || emit degraded no_tick "step-strategy-digest.sh needs --tick"

# The tick id is UTC (YYYYMMDD-HHMMSS). Derive the JST day and hour from it.
utc_day=$(printf '%s' "$TICK" | cut -c1-8)
utc_hour=$(printf '%s' "$TICK" | cut -c10-11)
case "$utc_day" in *[!0-9]*|'') emit degraded bad_tick "tick id carries no parseable UTC day" ;; esac
case "$utc_hour" in *[!0-9]*|'') emit degraded bad_tick "tick id carries no parseable UTC hour" ;; esac
jst_epoch=$(( $(date -u -d "${utc_day} ${utc_hour}:00:00" +%s) + 9 * 3600 ))
jst_day=$(date -u -d "@${jst_epoch}" +%Y-%m-%d)
jst_hour=$(date -u -d "@${jst_epoch}" +%H)

[ "$jst_hour" -ge 9 ] || emit ok before_morning "before 09:00 JST (tick hour ${jst_hour}); the digest waits for the morning tick"

# Once per JST day: the tick log is the dedup, exactly as every other step's is.
log_dir="${ROOT}/.workaholic/moderations"
if [ -d "$log_dir" ] && grep -rqs "strategy-digest-rendered:${jst_day}" "$log_dir" 2>/dev/null; then
    emit ok already_rendered "the ${jst_day} digest is already in a Moderation root"
fi

digest=$( ( cd "$ROOT" && sh "${STANDUP_SCRIPTS}/digest.sh" "1 day ago" ) 2>/dev/null ) \
    || emit degraded digest_unreadable "standup/scripts/digest.sh failed; the morning digest could not be read"
printf '%s' "$digest" | jq -e . >/dev/null 2>&1 \
    || emit degraded digest_unreadable "digest.sh produced output this step could not parse"

noop=$(printf '%s' "$digest" | jq -r '.noop')
reason=$(printf '%s' "$digest" | jq -r '.noop_reason')
if [ "$noop" = "true" ]; then
    emit ok "digest_noop_${reason}" "the morning digest is a no-op (${reason}); nothing rides the root"
fi

commits=$(printf '%s' "$digest" | jq -r '.commit_count // 0')
count=$(printf '%s' "$digest" | jq -r '.strategy_count // 0')
needs=$(printf '%s' "$digest" | jq -c '{action: "render_the_morning_digest_at_the_top_of_the_root",
    bound: "numbered strategies, bold title on its own line, headline is commit_count, honesty line names tickets and the window; log strategy-digest-rendered:<jst-day> via log-append.sh when the root posts",
    jst_day: "'"$jst_day"'", digest: .}' 2>/dev/null || echo '{}')

emit ok "" "morning digest ready for ${jst_day}: ${count} strategies, ${commits} commits" "$needs" \
    "morning per-strategy digest (${count} strategies, ${commits} commits since yesterday)"
