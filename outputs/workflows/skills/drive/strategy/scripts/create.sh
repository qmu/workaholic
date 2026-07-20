#!/bin/sh -eu
# Create a new strategy: scaffold .workaholic/strategies/active/<slug>/strategy.md from
# a title, stamp created_at/author from the gather skill, refresh the OKF bundle indexes,
# and git-stage. A new strategy is active by definition, so it always lands in active/.
# The slug rule is REUSED from mission/scripts/slug.sh (the single source), so a strategy
# slug follows the same derivation as a mission slug. Refuses an existing slug in either
# area (active/ or archive/).
#
# A strategy is long-lived DIRECTION with no completion conditions -- it has no worktree,
# no tickets, no assignee, no acceptance checklist, no drive_authorized. Adding execution
# machinery here would collapse the granularity split this artifact exists to create.
#
# Usage: create.sh "<title>"
# Output: JSON {created, slug, path[, reason]}

set -eu

TITLE="${1:-}"
[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
# No artifact to key off -- a strategy is being created, so the root is "this repo".
ROOT=$(strategies_root_default)

# Slug rule lives in mission/scripts/slug.sh (the single source), reused verbatim.
SLUG=$(sh "${SCRIPT_DIR}/../../mission/scripts//slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

STRATEGY_DIR=".workaholic/strategies/active/${SLUG}"
STRATEGY_FILE="${STRATEGY_DIR}/strategy.md"

EXISTING=$(strategy_resolve "$ROOT" "$SLUG")
if [ -f "$EXISTING" ]; then
    printf '{"created": false, "reason": "exists", "slug": "%s", "path": "%s"}\n' "$SLUG" "$EXISTING"
    exit 1
fi

# created_at / author from the single canonical gather script (one line per field).
META=$(sh "${SCRIPT_DIR}/../../gather/scripts//ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

mkdir -p "$STRATEGY_DIR"
cat > "$STRATEGY_FILE" <<EOF
---
type: Strategy
title: ${TITLE}
slug: ${SLUG}
status: active
created_at: ${CREATED_AT}
author: ${AUTHOR}
---

# ${TITLE}

## Direction

<!-- The strategy's substance: the prose statement of WHERE this is heading and WHY.
     Long-lived direction, one level more general than any mission. Observable
     consequences are welcome; completion conditions are deliberately ABSENT -- a
     strategy is direction, not work, and outlives every mission that executes it.
     Missions are this strategy's execution plans; the mission->strategy link lives on
     the mission (read via read-strategy-relation.sh), so there is no ## Missions
     section here -- per-strategy rollups are computed by list.sh, never stored. -->

## Changelog

<!-- Append-only, dated timeline. One line per event ("- YYYY-MM-DD — event — filename");
     never rewrite past lines. Retirement (rare) is a recorded transition, not a deletion. -->
EOF

# Refresh the OKF bundle indexes so the create commit ships a fresh hierarchy
# (best-effort: an index problem must not block strategy creation).
sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

git add "$STRATEGY_FILE" 2>/dev/null || true

printf '{"created": true, "slug": "%s", "path": "%s"}\n' "$SLUG" "$STRATEGY_FILE"
