#!/bin/sh -eu
# Record one step of one `/moderate` tick in the tick log.
#
# WHY IT EXISTS (2026-08-17, issue #471). `/moderate` runs hourly and unattended.
# The only evidence such a run leaves is what it writes down, so every step says
# what it checked, what it filed, and what it could not read — into a per-day file
# under `.workaholic/housekeeping/`, the area registered for exactly this.
#
# THE LOG IS AN OPERATIONAL LOG, NOT AN OKF KNOWLEDGE ARTIFACT. Entries carry no
# `type:` and no per-area `index.md`: they are the second deliberate exception to
# the OKF floor after `tickets/`, on the same grounds. Twenty-four entries a day is
# machine scale — index-managing them would rewrite the bundle indexes on every
# tick, and an index of machine logs is not knowledge. The bundle root links the
# directory bare, exactly as it links `tickets/`.
#
# ONE FILE PER UTC DAY, AND THE WRITER NEVER PRUNES. The day is taken from the
# tick id, so a file is ~24 sections and stays greppable, and a day's log is one
# path a human can open. Pruning is the operator's act, never this script's: an
# unattended machine deleting its own audit trail is the class of act this project
# puts behind a human, and git history keeps a deleted file recoverable anyway.
#
# IDEMPOTENT PER (tick, step). A tick that re-runs a step it already recorded
# writes nothing and says so (`duplicate: true`) — so a resumed or retried tick
# produces one section with one line per step, not a doubled record. Rewriting the
# earlier line is deliberately NOT offered: the log is append-only in substance,
# and a step that ran twice with different outcomes is a fact worth keeping, which
# a caller records under a distinct step id.
#
# Usage:
#   log-append.sh --tick <YYYYMMDD-HHMMSS> --step <slug> --status <status> \
#                 --summary "<one line>" [--root <repo-root>]
#
#   status  one of: ok | filed | skipped | degraded | blocked
#           ok        ran, nothing needed doing (or it was done)
#           filed     wrote an artifact through an existing seam (ticket, feedback, comment)
#           skipped   a precondition was absent
#           degraded  a source could not be read; the step was skipped, never half-applied
#           blocked   needs a human; the tick reports it and moves on
#
# Output: one JSON line
#   {"logged": true|false, "file": "<path>", "tick": "...", "step": "...",
#    "created_file": true|false, "created_section": true|false, "duplicate": true|false}
#   {"logged": false, "reason": "<bad_tick|bad_step|bad_status|no_summary|no_workaholic_dir>"}

set -eu

TICK=''
STEP=''
STATUS=''
SUMMARY=''
ROOT='.'

while [ $# -gt 0 ]; do
    case "$1" in
        --tick)    TICK="${2:-}"; shift 2 ;;
        --step)    STEP="${2:-}"; shift 2 ;;
        --status)  STATUS="${2:-}"; shift 2 ;;
        --summary) SUMMARY="${2:-}"; shift 2 ;;
        --root)    ROOT="${2:-}"; shift 2 ;;
        *) echo "{\"logged\": false, \"reason\": \"unknown_argument\", \"argument\": \"$1\"}"; exit 1 ;;
    esac
done

case "$TICK" in
    [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
    *) echo '{"logged": false, "reason": "bad_tick"}'; exit 1 ;;
esac

# A step id is a lowercase slug so it stays greppable and safe inside a regex.
case "$STEP" in
    ''|*[!a-z0-9-]*) echo '{"logged": false, "reason": "bad_step"}'; exit 1 ;;
    -*|*-)           echo '{"logged": false, "reason": "bad_step"}'; exit 1 ;;
esac

case "$STATUS" in
    ok|filed|skipped|degraded|blocked) ;;
    *) echo '{"logged": false, "reason": "bad_status"}'; exit 1 ;;
esac

[ -n "$SUMMARY" ] || { echo '{"logged": false, "reason": "no_summary"}'; exit 1; }

[ -d "$ROOT/.workaholic" ] || { echo '{"logged": false, "reason": "no_workaholic_dir"}'; exit 1; }

# One line, whatever the caller passed: a summary that spans lines would break the
# entry shape every reader globs.
SUMMARY=$(printf '%s' "$SUMMARY" | tr '\n\r\t' '   ' | sed 's/  */ /g; s/^ //; s/ $//')

DAY=$(printf '%s' "$TICK" | cut -c1-4)-$(printf '%s' "$TICK" | cut -c5-6)-$(printf '%s' "$TICK" | cut -c7-8)
DIR="$ROOT/.workaholic/housekeeping"
FILE="$DIR/$DAY.md"

created_file=false
created_section=false

if [ ! -f "$FILE" ]; then
    mkdir -p "$DIR"
    cat > "$FILE" <<EOF
# Housekeeping log — $DAY

One section per \`/moderate\` tick, one line per step: what it checked, what it
filed, what it skipped and why. Written only by \`workaholic:moderate\`; append-only,
never pruned by a machine. This is an operational log, not an OKF knowledge
artifact — it carries no \`type:\` and is not index-managed.
EOF
    created_file=true
fi

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

LINE="- \`$STEP\`: $STATUS — $SUMMARY"

if ! grep -q "^## $TICK\$" "$FILE"; then
    printf '\n## %s\n\n%s\n' "$TICK" "$LINE" >> "$FILE"
    created_section=true
    printf '{"logged": true, "file": "%s", "tick": "%s", "step": "%s", "created_file": %s, "created_section": true, "duplicate": false}\n' \
        "$(json_escape "$FILE")" "$TICK" "$STEP" "$created_file"
    exit 0
fi

# The section exists: refuse a duplicate (tick, step), else insert at its end so a
# re-entered tick appends to its own section rather than the file's tail.
if awk -v tick="## $TICK" -v step="- \`$STEP\`:" '
    $0 == tick { inside = 1; next }
    /^## / { inside = 0 }
    inside && substr($0, 1, length(step)) == step { found = 1; exit }
    END { exit(found ? 0 : 1) }
' "$FILE"; then
    printf '{"logged": false, "file": "%s", "tick": "%s", "step": "%s", "created_file": false, "created_section": false, "duplicate": true}\n' \
        "$(json_escape "$FILE")" "$TICK" "$STEP"
    exit 0
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
# Trailing blank lines inside the section are held back so the new line lands
# against the last entry rather than after the section break.
awk -v tick="## $TICK" -v line="$LINE" '
    BEGIN { inside = 0; done = 0; held = 0 }
    function release() { for (i = 1; i <= held; i++) print hold[i]; held = 0 }
    function emit() { if (inside && !done) { print line; done = 1 } }
    {
        if ($0 == tick) { release(); print; inside = 1; next }
        if (substr($0, 1, 3) == "## ") { emit(); release(); inside = 0; print; next }
        if (inside && NF == 0) { hold[++held] = $0; next }
        release(); print
    }
    END { emit(); release() }
' "$FILE" > "$TMP"
cat "$TMP" > "$FILE"

printf '{"logged": true, "file": "%s", "tick": "%s", "step": "%s", "created_file": false, "created_section": false, "duplicate": false}\n' \
    "$(json_escape "$FILE")" "$TICK" "$STEP"
