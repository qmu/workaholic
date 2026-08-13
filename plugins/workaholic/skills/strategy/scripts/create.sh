#!/bin/sh -eu
# Create one strategy: the operator's outbound, resolved direction, written to
# .workaholic/strategies/<slug>.md (flat area — a strategy is one file, never a
# directory). The Aim prose arrives on stdin; the slug rule is REUSED from
# mission/scripts/slug.sh (the single slug source) and created_at/author come from
# the gather skill, exactly as feedback/scripts/create.sh does.
#
# The three mandated parts are refused when absent, so a refusal happens HERE
# rather than at the hooks/validate-strategy.sh write floor: an empty aim, an empty
# assignee list, or a target date that is not YYYY-MM-DD. `assignees` may not be
# empty on a strategy — unlike every other artifact, where empty means team-owned —
# because an unowned direction is not a strategy (strategy/SKILL.md, The model).
#
# Usage: printf '%s\n' "<aim>" | create.sh "<title>" <YYYY-MM-DD> "<assignees>" "<schedule>" ["<feedback-refs>"] [workaholic-root]
#   assignees:     comma-separated emails, at least one
#   schedule:      the dated shape in prose (## Schedule); required, non-empty
#   feedback-refs: comma-separated feedback filenames this strategy was formed by
# Output: JSON {created, path[, reason]}

set -eu

TITLE="${1:-}"
TARGET_DATE="${2:-}"
ASSIGNEES="${3:-}"
SCHEDULE="${4:-}"
FEEDBACK="${5:-}"
ROOT="${6:-.workaholic}"

[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }

case "$TARGET_DATE" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) : ;;
    *) echo '{"created": false, "reason": "bad_target_date"}'; exit 1 ;;
esac

# Assignee: the strategy's owner. Never defaulted — an unowned direction is not a
# strategy, and inventing an owner here would put the runner's identity on a
# decision it did not make.
[ -n "$(printf '%s' "$ASSIGNEES" | tr -d '[:space:],')" ] || {
    echo '{"created": false, "reason": "no_assignees"}'; exit 1; }

[ -n "$(printf '%s' "$SCHEDULE" | tr -d '[:space:]')" ] || {
    echo '{"created": false, "reason": "empty_schedule"}'; exit 1; }

AIM=$(cat)
[ -n "$(printf '%s' "$AIM" | tr -d '[:space:]')" ] || {
    echo '{"created": false, "reason": "empty_aim"}'; exit 1; }

SCRIPT_DIR=$(dirname "$0")

META=$(sh "${SCRIPT_DIR}/../../gather/scripts/ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

SLUG=$(sh "${SCRIPT_DIR}/../../mission/scripts/slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

DIR="${ROOT}/strategies"
FILE="${DIR}/${SLUG}.md"

if [ -e "$FILE" ]; then
    printf '{"created": false, "reason": "exists", "path": "%s"}\n' "$FILE"
    exit 1
fi

# Normalize the comma-separated lists into the YAML flow sequences every reader
# already parses (`assignees: [a@x, b@y]`).
fmt_list() {
    printf '%s' "$1" | tr ',' '\n' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' \
        | grep -v '^$' | paste -sd, - | sed -e 's/,/, /g'
}
ASSIGNEE_LIST=$(fmt_list "$ASSIGNEES")
FEEDBACK_LIST=$(fmt_list "$FEEDBACK")

mkdir -p "$DIR"
{
    printf -- '---\n'
    printf 'type: Strategy\n'
    printf 'title: %s\n' "$TITLE"
    printf 'slug: %s\n' "$SLUG"
    printf 'status: active\n'
    printf 'target_date: %s\n' "$TARGET_DATE"
    printf 'assignees: [%s]\n' "$ASSIGNEE_LIST"
    printf 'feedback: [%s]\n' "$FEEDBACK_LIST"
    printf 'created_at: %s\n' "$CREATED_AT"
    printf 'author: %s\n' "$AUTHOR"
    printf -- '---\n'
    printf '\n# %s\n' "$TITLE"
    printf '\n## Aim\n\n%s\n' "$AIM"
    printf '\n## Schedule\n\nTarget: %s\n\n%s\n' "$TARGET_DATE" "$SCHEDULE"
} > "$FILE"

# Refresh the OKF bundle indexes so the registering commit ships a fresh hierarchy
# (best-effort: an index problem must not block the write).
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

printf '{"created": true, "path": "%s", "slug": "%s"}\n' "$FILE" "$SLUG"
