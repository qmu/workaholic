#!/bin/sh -eu
# Step 9 — where each deployment target's draft release note stands.
#
# WHERE IT CAME FROM. The second half of the retired `[Prepare Release]` routine
# (2026-08-19), merged here for the same reason as step 8: a target whose draft
# note has gone stale is a fact about the repository's progress, which is what
# this tick is for.
#
# IT NEVER PASSES `--write`. The per-target draft release is written by the
# `Release Note Draft` GitHub workflow, which holds `contents: write` and defines
# its own checkout (`fetch-depth: 0` plus tags) rather than inheriting whatever
# refs a container happens to hold. A routine's container cannot write a release
# at all — `gh release` is refused as GraphQL, and REST answers "Creating,
# editing, or deleting releases is not permitted for this session type" — so a
# tick that tried would fail on every tick, which is exactly what the 2026-08-17
# design did until it was corrected. This step reads the cadence and reports it.
#
# IT POSTS NOTHING. Same rule as step 8: a state worth a person's attention
# becomes a question at step 10, addressed to somebody, or it stays in the log.
#
# Usage: step-note-cadence.sh --tick <id> --root <repo-root>
# Output: one JSON line {"step","status","reason","summary","needs_agent":[...],"stale":[...]}

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CADENCE="${SCRIPT_DIR}/../../ship/scripts//run-note-cadence.sh"

while [ $# -gt 0 ]; do
    case "$1" in
        --tick|--root) shift 2 ;;
        *) shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

if [ ! -f "$CADENCE" ]; then
    printf '{"step": "note-cadence", "status": "degraded", "reason": "reader_missing", "summary": "run-note-cadence.sh is not present in this checkout", "needs_agent": [], "stale": []}\n'
    exit 0
fi

# No `--write`: the flag is passed by the Release Note Draft workflow and by
# nothing else. Read-only here by construction, not by convention.
out=$(sh "$CADENCE" 2>/dev/null || true)

case "$out" in
    *'"ok": true'*) ;;
    *)
        reason=$(printf '%s' "$out" | sed 's/.*"reason": "//; s/".*//')
        [ -n "$reason" ] || reason=unreadable
        printf '{"step": "note-cadence", "status": "degraded", "reason": "%s", "summary": "the draft-note cadence could not be read this tick", "needs_agent": [], "stale": []}\n' \
            "$(json_escape "$reason")"
        exit 0
        ;;
esac

stage=$(printf '%s' "$out" | sed 's/.*"stage": "//; s/".*//')
idle=$(printf '%s' "$out" | sed 's/.*"idle": //; s/,.*//')
count=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')

due=$(printf '%s' "$out" | awk '{ gsub(/},/, "},\n"); print }' | grep '"due": true' || true)
n=$(printf '%s' "$due" | awk 'NF { n++ } END { print n + 0 }')

if [ "$n" -eq 0 ]; then
    printf '{"step": "note-cadence", "status": "ok", "reason": "", "summary": "%s target(s) at stage %s, no draft note due (idle: %s)", "needs_agent": [], "stale": []}\n' \
        "$count" "$(json_escape "$stage")" "$idle"
    exit 0
fi

slugs=$(printf '%s' "$due" | sed 's/.*"slug": "//; s/".*//' | tr '\n' ' ' | sed 's/ $//')
printf '{"step": "note-cadence", "status": "blocked", "reason": "note_due", "summary": "%s target(s) have a draft note due: %s — written by the Release Note Draft workflow, never by this tick", "needs_agent": ["note-cadence-due"], "stale": [%s], "event": "%s deployment target(s) have a release note due: %s"}\n' \
    "$n" "$(json_escape "$(printf '%s' "$slugs" | sed 's/ /, /g')")" \
    "$(printf '%s' "$slugs" | tr ' ' '\n' | awk 'NF { printf "%s\"%s\"", (n++ ? ", " : ""), $0 }')" \
    "$n" "$(json_escape "$(printf '%s' "$slugs" | sed 's/ /, /g')")"
