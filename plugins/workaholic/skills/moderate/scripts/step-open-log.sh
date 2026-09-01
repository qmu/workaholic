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

DIR="$ROOT/.workaholic/moderations"
if ! mkdir -p "$DIR" 2>/dev/null || [ ! -w "$DIR" ]; then
    printf '{"step": "open-log", "status": "degraded", "reason": "unwritable", "summary": "the moderations/ log area is not writable", "needs_agent": []}\n'
    exit 0
fi

DAY=$(printf '%s' "$TICK" | cut -c1-4)-$(printf '%s' "$TICK" | cut -c5-6)-$(printf '%s' "$TICK" | cut -c7-8)

# OPENING THE LOG NOW MEANS MAKING IT READABLE HERE (2026-09-01, issue #782). The log left
# `main` for its own branch, so a fresh container's clone no longer carries it: without this,
# every reader that walks the log -- `log-read.sh`'s dedup sets, `question-state.sh`,
# `record-answer.sh`, `condition-age.sh`, `filed-records.sh`, `step-blocked-tick.sh` -- would
# answer *no earlier tick ever ran* and the whole dedup would re-fire hourly. It is the other
# half of the move, and it belongs to this step because "prepare a log storage location" is
# exactly what it always did; what a location has to contain simply grew.
#
# IT IS NEVER FATAL. A tick that could not hydrate still runs -- it has no memory of earlier
# ticks, which makes it OVER-report rather than under-report, the same asymmetry the claim scan
# keeps. The reason is carried in this step's own summary so a re-firing dedup reads as *we
# could not fetch the log* rather than as *there was nothing there*.
hy=$(sh "${SCRIPT_DIR}/hydrate-log.sh" --root "$ROOT" 2>/dev/null || true)
hy_state=$(printf '%s' "$hy" | sed -n 's/.*"state": "\([^"]*\)".*/\1/p')
hy_reason=$(printf '%s' "$hy" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')
hy_files=$(printf '%s' "$hy" | sed -n 's/.*"files": \([0-9]*\).*/\1/p')
[ -n "$hy_files" ] || hy_files=0

case "$hy_state" in
    hydrated) hy_note=", ${hy_files} day file(s) carried from the log branch" ;;
    absent)   hy_note=", no log branch history yet (${hy_reason})" ;;
    skipped)  hy_note=", not fetched (${hy_reason})" ;;
    *)
        printf '{"step": "open-log", "status": "degraded", "reason": "log_not_hydrated", "summary": "tick log open at .workaholic/moderations/%s.md, but the log branch could not be read (%s) — this tick has no memory of earlier ticks", "needs_agent": []}\n' \
            "$DAY" "${hy_reason:-unknown}"
        exit 0
        ;;
esac

printf '{"step": "open-log", "status": "ok", "reason": "", "summary": "tick log open at .workaholic/moderations/%s.md%s", "needs_agent": []}\n' "$DAY" "$hy_note"
