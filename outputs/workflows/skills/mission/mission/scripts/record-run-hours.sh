#!/bin/sh -eu
# Accumulate a /monitor run's agent-hours into a mission's actual_hours, idempotently
# per run-id. A run's leaf-time (dispatch→completion wall-clock, summed across waves) is
# added into the mission's running actual_hours, and the increment is carried in a
# ## Changelog line so the sum reconstructs from history — actual_hours is never a bare
# mutable counter alone (`workaholic:design` / `history-structures`).
#
# THE RECORDER IS THE ONLY WRITER of actual_hours — same doctrine as tick-acceptance.sh:
# the field is never hand-edited.
#
# Idempotent per RUN-ID: a run already recorded (its changelog line present) adds nothing,
# so a crash-recovery re-run is safe even if its measured hours differ slightly.
#
# Usage: record-run-hours.sh <mission-slug-or-file> <hours> <run-id>
# Output: JSON {recorded, actual_hours, run_id, path[, reason]}

set -eu

ARG="${1:-}"
HOURS="${2:-}"
RUNID="${3:-}"
if [ -z "$ARG" ] || [ -z "$HOURS" ] || [ -z "$RUNID" ]; then
    echo '{"recorded": false, "reason": "missing_args"}' >&2
    exit 1
fi
case "$HOURS" in ''|*[!0-9.]*) echo '{"recorded": false, "reason": "bad_hours"}' >&2; exit 1 ;; esac

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"recorded": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

# Idempotent per run-id: a run already recorded (its changelog line ends with the
# run-id) adds nothing. This gate — not the hours — is the identity of a run.
if grep -q "run recorded.*${RUNID}\$" "$FILE" 2>/dev/null; then
    printf '{"recorded": false, "reason": "duplicate", "run_id": "%s", "path": "%s"}\n' "$RUNID" "$FILE"
    exit 0
fi

# Add HOURS into actual_hours (float add). An empty/absent field starts at 0.
CURR=$(grep -m1 '^actual_hours:' "$FILE" 2>/dev/null | sed -e 's/^actual_hours:[ \t]*//' -e 's/[ \t]*$//' || true)
case "$CURR" in ''|*[!0-9.]*) CURR=0 ;; esac
NEW=$(awk -v a="$CURR" -v b="$HOURS" 'BEGIN { printf "%g", a + b }')

# Write actual_hours in the frontmatter block only; insert the key if a legacy mission
# lacks it (before the closing ---).
TMP="${FILE}.$$.tmp"
awk -v v="$NEW" '
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm && /^---[ \t]*$/ { if (!done) { print "actual_hours: " v; done = 1 } in_fm = 0; print; next }
    in_fm && /^actual_hours:/ { print "actual_hours: " v; done = 1; next }
    { print }
' "$FILE" > "$TMP"
mv "$TMP" "$FILE"

# Record the run in the changelog, increment carried in the event phrase so the sum
# reconstructs from lines. Idempotency is already gated on run-id above.
sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "run recorded (+${HOURS}h)" "${RUNID}" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true
printf '{"recorded": true, "actual_hours": %s, "run_id": "%s", "path": "%s"}\n' "$NEW" "$RUNID" "$FILE"
