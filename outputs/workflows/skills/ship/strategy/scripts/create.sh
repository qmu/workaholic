#!/bin/sh -eu
# Create a new strategy: scaffold .workaholic/strategies/active/<slug>/strategy.md from
# a title, stamp created_at/author from the gather skill, refresh the OKF bundle indexes,
# and git-stage. A new strategy is active by definition, so it always lands in active/.
# The slug rule is REUSED from mission/scripts/slug.sh (the single source), so a strategy
# slug follows the same derivation as a mission slug. Refuses an existing slug in either
# area (active/ or archive/).
#
# A strategy is long-lived DIRECTION with no completion conditions -- it has no worktree,
# no tickets, no acceptance checklist, no drive_authorized. It DOES carry ownership:
# `assignees` names who owns this direction (2026-07-24 -- a deliberate amendment of the
# earlier "a strategy has no assignee" rule; see strategy/SKILL.md's Terminology record).
# Ownership is not execution machinery -- worktree/tickets/acceptance/drive_authorized all
# stay on the mission -- so putting it here does NOT collapse the granularity split: a
# strategy is a direction some set of people own, and its missions DERIVE their owner from
# it (mission/scripts/mission-owners.sh). `assignees` is a LIST because a direction can be
# co-owned; it is seeded with the creator by default.
#
# Usage: create.sh "<title>" [assignee]
#   assignee defaults to the creator's git user.email (self-ownership). Pass a second
#   argument to seed a different single owner; co-owners are added by editing the list.
# Output: JSON {created, slug, path[, reason]}

set -eu

TITLE="${1:-}"
[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }
ASSIGNEE_ARG="${2:-}"

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

# Self-ownership by default: the strategy is owned by its creator unless an explicit
# owner was passed. Seeded as a one-element list (`assignees` is a list because a
# direction can be co-owned). A mission executing this strategy derives its owner(s)
# from here (mission/scripts/mission-owners.sh).
ASSIGNEE="${ASSIGNEE_ARG:-$AUTHOR}"

mkdir -p "$STRATEGY_DIR"
cat > "$STRATEGY_FILE" <<EOF
---
type: Strategy
title: ${TITLE}
slug: ${SLUG}
status: active
created_at: ${CREATED_AT}
author: ${AUTHOR}
assignees: [${ASSIGNEE}]
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
