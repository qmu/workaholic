#!/bin/sh -eu
# Create a new mission: scaffold .workaholic/missions/active/<slug>/mission.md from a
# title, stamp created_at/author from the gather skill, refresh the OKF bundle indexes,
# and git-stage. A new mission is active by definition, so it always lands in the
# active/ area. The slug is derived from the title (lowercased, every run of
# non-[a-z0-9] collapsed to a single hyphen, ends trimmed). Refuses to overwrite an
# existing mission in either area (active/ or archive/).
#
# Usage: create.sh "<title>" [assignee]
#   assignee defaults to the creator's git user.email (self-assignment). Pass a
#   second argument to assign the mission to a different user id / email.
# Output: JSON {created, slug, path[, reason]}

set -eu

TITLE="${1:-}"
[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }
ASSIGNEE_ARG="${2:-}"

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
# No artifact to key off -- a mission is being created, so the root is "this repo".
ROOT=$(missions_root_default)
missions_migrate_layout "$ROOT"

# Slug rule lives in slug.sh (the single source), so the mission directory name
# and the /mission worktree directory name always agree.
SLUG=$(sh "${SCRIPT_DIR}/slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

MISSION_DIR=".workaholic/missions/active/${SLUG}"
MISSION_FILE="${MISSION_DIR}/mission.md"

EXISTING=$(mission_resolve "$ROOT" "$SLUG")
if [ -f "$EXISTING" ]; then
    printf '{"created": false, "reason": "exists", "slug": "%s", "path": "%s"}\n' "$SLUG" "$EXISTING"
    exit 1
fi

# created_at / author from the single canonical gather script (one line per field).
META=$(sh "${SCRIPT_DIR}/../../gather/scripts/ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

# Self-assignment by default: the assignee is the creator unless an explicit one
# was passed. The mission lens (hooks/mission-lens.sh) surfaces a mission only to
# the git user whose email matches this field.
ASSIGNEE="${ASSIGNEE_ARG:-$AUTHOR}"

mkdir -p "$MISSION_DIR"
cat > "$MISSION_FILE" <<EOF
---
type: Mission
title: ${TITLE}
slug: ${SLUG}
status: active
created_at: ${CREATED_AT}
author: ${AUTHOR}
assignee: ${ASSIGNEE}
drive_authorized:
tickets: []
stories: []
concerns: []
gate_type:
gate_target:
gate_assert:
---

# ${TITLE}

## Goal

<!-- The information-rich "why": business grounding and the outcome this mission pursues. -->

## Scope

<!-- Definition of done, plus explicit out-of-scope notes. -->

## Experience

<!-- The mission's substance: the user experience, the demanded behavior, and/or the overall
     structure this mission pursues. Describe what the thing DOES (## Goal is why it is worth
     doing). Keep it observable -- "the list reorders without a reload" is checkable, "feels
     fast" is not. This is what a later session reads to know what is actually demanded, and
     it is the durable content a kickoff-time quality gate could never be. -->

## Acceptance

<!-- One checklist item per criterion, each naming the ticket/story expected to satisfy it
     by filename, e.g. "criterion text (#20260101120000-some-ticket.md)". Progress toward
     achievement is checked over total, computed from this list, never a hand-set number. -->

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
EOF

# Refresh the OKF bundle indexes so the create commit ships a fresh hierarchy
# (best-effort: an index problem must not block mission creation).
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$MISSION_FILE" 2>/dev/null || true

printf '{"created": true, "slug": "%s", "path": "%s"}\n' "$SLUG" "$MISSION_FILE"
