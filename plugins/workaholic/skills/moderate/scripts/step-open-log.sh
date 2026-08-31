#!/bin/sh -eu
# Step 1 — open the tick's log.
#
# The ask's first step is "prepare a log storage location under `.workaholic/`".
# The location is registered once, in the closed layout (ticket
# `20260817113749`); what remains per tick is the check that it is actually
# writable HERE, before eight steps' worth of findings have nowhere to land.
#
# It is a probe, not a mkdir: the layout gate hard-blocks a write into an
# unregistered `.workaholic/` directory, and a step that created the directory
# itself would be routing around the gate rather than reporting it. A repository
# whose plugin is older than the registration therefore reports `degraded` with
# `area_unregistered` and the tick continues — every later step still runs and
# still reports; only its log line is lost, which the report says out loud.
#
# Usage: open-log.sh --tick <id> --root <repo-root>
# Output: one JSON line {"step","status","reason","summary","needs_agent":[]}

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
ROOT='.'
TICK=''

while [ $# -gt 0 ]; do
    case "$1" in
        --tick) TICK="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

ALLOWLIST="${SCRIPT_DIR}/../../hooks/workaholic-layout-allowlist.txt"

if [ ! -d "$ROOT/.workaholic" ]; then
    printf '{"step": "open-log", "status": "degraded", "reason": "no_workaholic_dir", "summary": "no .workaholic/ tree here — nothing this tick reads or writes exists", "needs_agent": []}\n'
    exit 0
fi

if [ -f "$ALLOWLIST" ] && ! grep -q '^moderations$' "$ALLOWLIST"; then
    printf '{"step": "open-log", "status": "degraded", "reason": "area_unregistered", "summary": "moderations/ is not in this plugin'"'"'s layout allowlist — the tick runs, its log does not", "needs_agent": []}\n'
    exit 0
fi

# THE LOCATION RESOLVES THROUGH `log-read.sh` (2026-08-31, mission
# `take-the-moderation-tick-s-log-off-main`), which is the one resolver; this step composed
# the path itself and would have gone on opening a directory nothing else read.
LOG_READ="${SCRIPT_DIR}/log-read.sh"
DIR=$(sh "$LOG_READ" --root "$ROOT" --log-dir 2>/dev/null \
    | sed -n 's/.*"log_dir": "\([^"]*\)".*/\1/p')
if [ -z "$DIR" ]; then
    printf '{"step": "open-log", "status": "degraded", "reason": "no_log_reader", "summary": "the log location could not be resolved", "needs_agent": []}\n'
    exit 0
fi
if ! mkdir -p "$DIR" 2>/dev/null || [ ! -w "$DIR" ]; then
    printf '{"step": "open-log", "status": "degraded", "reason": "unwritable", "summary": "the moderations/ log area is not writable", "needs_agent": []}\n'
    exit 0
fi

# THE ONE FETCH OF THE LOG REF, ONCE PER TICK AND HERE ONLY. Every later reader composes
# `log-read.sh` without `--refresh`, so no dedup in the tick pays for a network call. A
# fetch that could not reach the ref is recorded and answered by NAME at every read --
# never as an empty log, which would make every dedup in the tick re-fire.
refresh=$(sh "$LOG_READ" --root "$ROOT" --refresh --list-days 2>/dev/null || true)
DAY=$(printf '%s' "$TICK" | cut -c1-4)-$(printf '%s' "$TICK" | cut -c5-6)-$(printf '%s' "$TICK" | cut -c7-8)
case "$refresh" in
    *'"reason": "log_ref_unreachable"'*)
        printf '{"step": "open-log", "status": "degraded", "reason": "log_ref_unreachable", "summary": "the tick log ref could not be fetched; earlier ticks are not readable in this container", "needs_agent": []}\n'
        exit 0
        ;;
esac
printf '{"step": "open-log", "status": "ok", "reason": "", "summary": "tick log open at .workaholic/moderations/%s.md", "needs_agent": []}\n' "$DAY"
