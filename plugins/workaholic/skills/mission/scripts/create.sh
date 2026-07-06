#!/bin/sh -eu
# Create a new mission: scaffold .workaholic/missions/<slug>/mission.md from a title,
# stamp created_at/author from the gather skill, refresh the OKF bundle indexes, and
# git-stage. The slug is derived from the title (lowercased, every run of non-[a-z0-9]
# collapsed to a single hyphen, ends trimmed). Refuses to overwrite an existing mission.
#
# Usage: create.sh "<title>"
# Output: JSON {created, slug, path[, reason]}

set -eu

TITLE="${1:-}"
[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }

SCRIPT_DIR=$(dirname "$0")

# Slug rule (mirrors the mission SKILL.md): lowercase, non-[a-z0-9] runs -> single
# hyphen, leading/trailing hyphens trimmed.
SLUG=$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | tr -s '-' | sed -e 's/^-//' -e 's/-$//')
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

MISSION_DIR=".workaholic/missions/${SLUG}"
MISSION_FILE="${MISSION_DIR}/mission.md"

if [ -e "$MISSION_FILE" ]; then
    printf '{"created": false, "reason": "exists", "slug": "%s", "path": "%s"}\n' "$SLUG" "$MISSION_FILE"
    exit 1
fi

# created_at / author from the single canonical gather script (one line per field).
META=$(sh "${SCRIPT_DIR}/../../../../workaholic/skills/gather/scripts/ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

mkdir -p "$MISSION_DIR"
cat > "$MISSION_FILE" <<EOF
---
type: Mission
title: ${TITLE}
slug: ${SLUG}
status: active
created_at: ${CREATED_AT}
author: ${AUTHOR}
tickets: []
stories: []
concerns: []
---

# ${TITLE}

## Goal

<!-- The information-rich "why": business grounding and the outcome this mission pursues. -->

## Scope

<!-- Definition of done, plus explicit out-of-scope notes. -->

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
sh "${SCRIPT_DIR}/../../../../workaholic/skills/okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$MISSION_FILE" 2>/dev/null || true

printf '{"created": true, "slug": "%s", "path": "%s"}\n' "$SLUG" "$MISSION_FILE"
