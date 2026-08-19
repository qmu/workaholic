#!/bin/sh -eu
# Scaffold a PROPOSED mission - the proposer's mission writer (docs/
# loop-engineering-workflow.md B1/B4). Deliberately NOT mission/scripts/create.sh:
# that scaffold seeds the CREATOR as owner, and an unattended proposer has no
# business owning what it proposes. What it writes carries the OWNER the trigger
# named (see `--assignee` below) and the mission->feedback relation it grew from:
#
#   status: active, merge_policy: (empty -> review),
#   assignees: [<the triggering issue's assignee>] or [] when none was given,
#   feedback: [<record filenames>]
#
# THERE IS NO `draft` STATE ANY MORE (2026-07-31 --
# docs/loop-engineering-workflow.md K1). The batch's output is reviewed as the pull
# request it opens, and merging that pull request is the approval; a status word
# would gate the same content a second time. The script name is kept because the
# thing it writes is still a *draft in the ordinary sense* - a proposal nobody has
# accepted yet - but that state now lives in the PR, not in the file.
#
# `merge_policy` is left EMPTY, which reads as `review` (K2): this batch has no
# authority to grant unattended merging, and empty-means-review is the same rule
# tickets follow, so effective-policy.sh needs no special case.
#
# Lands in missions/active/ (in flight, not history; the area split keys archive on
# achieved|abandoned|carried only). Refuses an existing slug in either area.
# Refreshes the OKF indexes and git-stages.
#
# THE TICKET FLOOR IS NOT CHECKED HERE, deliberately (mission/SKILL.md, *Granularity ->
# The ticket floor*). Like create.sh this is a SCAFFOLD writer: it runs before the batch
# has emitted the ticket set, so it has nothing to count. The floor binds the BATCH — a
# proposal the batch cannot decompose into two or more tickets is not proposed at all,
# and silence is already a valid outcome of the run (propose/SKILL.md). Enforcing it in
# this script would refuse the mission before its tickets could exist.
#
# WHO OWNS THE PROPOSAL — `--assignee <email>` (P6, 2026-08-06). The routine that
# starts this run fires on an issue ASSIGNED TO A PERSON, so the identity is known
# at the trigger and must ride the artifacts from there rather than being
# re-derived from whatever git config each container happens to carry.
#
# Absent, the mission is written UNOWNED (`assignees: []`), which means team-owned
# and claimable by anyone. That is a real state and the right one for a proposal
# nobody was assigned — but it is the WRONG default for the routine chain, and
# leaving it as the only behaviour was a measured hole: every proposal-born
# artifact was unowned, so **every** developer's runner judged it claimable and
# raced for it, and which of them got the work was decided by whose push landed
# first. The claim protocol prevented the double-drive; it could not decide whose
# job it was, because nothing in the data said.
#
# Usage: scaffold-draft.sh "<title>" [--assignee <email>] <feedback-filename>...
# Output: JSON {created, slug, path, assignees[, reason]}

set -eu

TITLE="${1:-}"
[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }
shift

ASSIGNEE=""
REFS=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --assignee)
            ASSIGNEE="${2:-}"
            shift 2 || shift
            ;;
        *)
            if [ -n "$1" ]; then
                if [ -n "$REFS" ]; then REFS="${REFS}, $1"; else REFS="$1"; fi
            fi
            shift
            ;;
    esac
done
[ -n "$REFS" ] || { echo '{"created": false, "reason": "no_feedback_refs"}'; exit 1; }

ASSIGNEES_VALUE="[]"
if [ -n "$ASSIGNEE" ]; then
    ASSIGNEES_VALUE="[${ASSIGNEE}]"
fi

SCRIPT_DIR=$(dirname "$0")
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"
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

META=$(sh "${SCRIPT_DIR}/../../gather/scripts/ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

mkdir -p "$MISSION_DIR"
cat > "$MISSION_FILE" <<EOMISSION
---
type: Mission
title: ${TITLE}
slug: ${SLUG}
status: active
merge_policy:
created_at: ${CREATED_AT}
author: ${AUTHOR}
assignees: ${ASSIGNEES_VALUE}
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
     The proposing session fills this from the feedback records named above. -->

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

sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

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

printf '{"created": true, "slug": "%s", "path": "%s", "assignees": "%s", "size": %s}\n' \
    "$SLUG" "$MISSION_FILE" "$ASSIGNEE" "${SIZE:-null}"
