#!/bin/sh -eu
# Scaffold a DRAFT mission - the proposal batch's writer (docs/
# loop-engineering-workflow.md B1/B4). Deliberately NOT mission/scripts/create.sh:
# that scaffold seeds the creator as owner, and a draft predates approval, so it
# has no approver yet. A draft is unowned, unauthorized, and carries the
# mission->feedback relation the proposal grew from:
#
#   status: draft, merge_policy: (empty), assignees: [],
#   feedback: [<record filenames>]
#
# `status: draft` IS the "not yet authorized" state on the single status axis
# (2026-07-28 -- docs/loop-engineering-workflow.md I2): the retired
# `drive_authorized` key is not written at all. Only mission/scripts/approve.sh
# flips a draft to `approved`, and it is what records the merge policy.
#
# Lands in missions/active/ (a draft is in flight, not history; the area split
# keys archive on achieved|abandoned|carried only). Refuses an existing slug in
# either area. Refreshes the OKF indexes and git-stages.
#
# Usage: scaffold-draft.sh "<title>" <feedback-filename>...
# Output: JSON {created, slug, path[, reason]}

set -eu

TITLE="${1:-}"
[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }
shift
[ "$#" -ge 1 ] || { echo '{"created": false, "reason": "no_feedback_refs"}'; exit 1; }

REFS=""
for f in "$@"; do
    if [ -n "$REFS" ]; then REFS="${REFS}, ${f}"; else REFS="$f"; fi
done

SCRIPT_DIR=$(dirname "$0")
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts/"
. "${MISSION_SCRIPTS}/lib/resolve.sh"
ROOT=$(missions_root_default)
missions_migrate_layout "$ROOT"

SLUG=$(sh "${MISSION_SCRIPTS}/slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

MISSION_DIR=".workaholic/missions/active/${SLUG}"
MISSION_FILE="${MISSION_DIR}/mission.md"

EXISTING=$(mission_resolve "$ROOT" "$SLUG")
if [ -f "$EXISTING" ]; then
    printf '{"created": false, "reason": "exists", "slug": "%s", "path": "%s"}\n' "$SLUG" "$EXISTING"
    exit 1
fi

META=$(sh "${SCRIPT_DIR}/../../gather/scripts//ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

mkdir -p "$MISSION_DIR"
cat > "$MISSION_FILE" <<EOMISSION
---
type: Mission
title: ${TITLE}
slug: ${SLUG}
status: draft
merge_policy:
created_at: ${CREATED_AT}
author: ${AUTHOR}
assignees: []
assignee:
predicted_hours:
actual_hours:
feedback: [${REFS}]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# ${TITLE}

## Goal

<!-- Why this mission is proposed: the direction the source feedback asks for.
     The proposal batch fills this from the feedback records named above. -->

## Experience

<!-- The demanded behavior, observable. Provisional until a human approves;
     approval replans this to drive-ready. -->

## Acceptance

<!-- PROPOSED criteria, THREE ITEMS OR FEWER - a sketch for discussion, not a
     plan. Approval replans this mission to drive-ready; only then may it be
     authorized. -->

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
EOMISSION

sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

git add "$MISSION_FILE" 2>/dev/null || true

# THE SIZE CEILING IS HARD FOR A DRAFT, AND SOFT FOR A HUMAN (recorded 2026-08-01).
# `mission/scripts/size.sh` measures the same norms either way; what differs is who is
# holding the pen. A developer authoring a mission is present and exercising judgment,
# so a refusal there would fire on legitimately larger work — the measurement is shown
# and the norm guides. This batch writes UNATTENDED: there is no judgment to exercise
# and nobody to show a measurement to, so an unenforced ceiling here is just a wish.
# The scaffold itself is well under the ceiling, so this reports on the FILLED draft
# when a caller re-runs it — the batch is expected to check after filling the sections.
SIZE=$(sh "${MISSION_SCRIPTS}/size.sh" "$MISSION_FILE" 2>/dev/null || true)

printf '{"created": true, "slug": "%s", "path": "%s", "size": %s}\n' "$SLUG" "$MISSION_FILE" "${SIZE:-null}"
