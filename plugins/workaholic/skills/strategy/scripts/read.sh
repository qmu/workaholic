#!/bin/sh -eu
# Read one strategy: its fields plus the path to the file, so a caller can print
# the prose itself rather than have this script re-encode it. Pure read.
#
# THE ONE PLACE THE ABSENT STAGE IS RESOLVED (2026-08-29, mission
# `make-a-direction-s-lifecycle-a-declared-stage`). `stage:` is the operator's DECLARED phase
# — 進行中 | 改良中 | 観察中 — and an absent field means 進行中, the convention `merge_policy`
# (absent means review) and a ticket's `status:` (absent means queued) already use. The
# default is resolved HERE and nowhere else, so no consumer re-derives it and a strategy
# written before the field existed reads exactly as it always did.
#
# IT IS DECLARED, NEVER DERIVED. Nothing in the lifecycle layer may compute a stage: the
# readings (`pace`, `overdue`, `expiring`, `dormant`, `quiescent`) describe the evidence and
# may SUGGEST a transition, while only the operator's own announcement moves this field.
#
# Usage: read.sh <slug> [workaholic-root]
# Output: JSON {found, path, slug, title, status, stage, target_date, assignees, feedback}

set -eu

SLUG="${1:-}"
ROOT="${2:-.workaholic}"
[ -n "$SLUG" ] || { echo '{"found": false, "reason": "no_slug"}'; exit 1; }

FILE="${ROOT}/strategies/${SLUG}.md"
if [ ! -f "$FILE" ]; then
    printf '{"found": false, "reason": "not_found", "path": "%s"}\n' "$FILE"
    exit 1
fi

fm() {
    awk -v key="$1" '
        NR==1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        $0 ~ "^" key ":" { sub("^" key ":[ \t]*", ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$FILE" 2>/dev/null || true
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

STAGE=$(fm stage)
[ -n "$STAGE" ] || STAGE="進行中"

printf '{"found": true, "path": "%s", "slug": "%s", "title": "%s", "status": "%s", "stage": "%s", "target_date": "%s", "assignees": "%s", "feedback": "%s"}\n' \
    "$FILE" \
    "$(json_escape "$SLUG")" \
    "$(json_escape "$(fm title)")" \
    "$(json_escape "$(fm status)")" \
    "$(json_escape "$STAGE")" \
    "$(json_escape "$(fm target_date)")" \
    "$(json_escape "$(fm assignees | sed -e 's/^\[//' -e 's/\]$//')")" \
    "$(json_escape "$(fm feedback | sed -e 's/^\[//' -e 's/\]$//')")"
