#!/bin/sh -eu
# Scaffold a PROPOSED TICKET under a draft mission — the second half of a
# proposal. The batch fills the sections; this script owns the filename, the
# frontmatter, and the mission relation.
#
#   scaffold-proposed-ticket.sh "<title>" <mission-slug> [type] [layer]
#
# Output: JSON {created, path, slug[, reason]}
#   reasons: no_title | no_mission | mission_missing | exists
#
# WHY A PROPOSAL CARRIES TICKETS AT ALL. A draft mission with a provisional
# acceptance sketch and no ticket set is not something a developer can judge —
# it is a title and a hope. `/drive`'s own survey says so mechanically: it drops
# such a mission as `no_tickets`, because acceptance items are not work. The
# proposal is only reviewable when it says what would actually be done.
#
# AND WHY THAT IS SAFE WITHOUT A NEW GATE. `drive/scripts/plan-units.sh` excludes
# ANY ticket carrying a `mission:` relation from the backlog offer, with reason
# `mission_member`, REGARDLESS of the mission's status — a mission's tickets are
# driven as part of its unit or not at all. So a ticket proposed under a draft
# mission is unclaimable by construction: the draft gate that already protects
# the mission protects its tickets too, and no second mechanism is needed. This
# is the property that makes ticket emission a small change rather than a
# dangerous one, and it must be re-checked if that exclusion is ever narrowed.
#
# merge_policy IS LEFT EMPTY, which reads as `review`. The batch has no authority
# to grant automatic merging: that ruling belongs to `/mission approve`, in the
# same act that authorizes the mission at all.
#
# THE MANDATORY BODY SECTIONS ARE WRITTEN AS HEADINGS WITH PLACEHOLDER GUIDANCE,
# not omitted for the caller to remember. `hooks/validate-ticket.sh` rejects a
# ticket in `todo/<user>/` whose `## Policies` or `## Quality Gate` is absent or
# empty, and a scaffold that produced an invalid artifact would push the failure
# to whoever ran the batch instead of the person who wrote the scaffold.

set -eu

TITLE="${1:-}"
MISSION_SLUG="${2:-}"
TYPE="${3:-enhancement}"
LAYER="${4:-Config}"

[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }
[ -n "$MISSION_SLUG" ] || { echo '{"created": false, "reason": "no_mission"}'; exit 1; }

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts/"

# The mission must exist before a ticket claims to belong to it: a dangling
# relation is exactly what validate-ticket.sh refuses, and a scaffold that
# created one would be writing a known-invalid artifact.
. "${MISSION_SCRIPTS}/lib/resolve.sh"
ROOT=$(missions_root_default)
MISSION_FILE=$(mission_resolve "$ROOT" "$MISSION_SLUG")
if [ ! -f "$MISSION_FILE" ]; then
  printf '{"created": false, "reason": "mission_missing", "slug": "%s"}\n' "$MISSION_SLUG"
  exit 1
fi

META=$(sh "${SCRIPT_DIR}/../../gather/scripts//ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')
STAMP=$(printf '%s\n' "$META" | grep '"filename_timestamp"' | sed -e 's/.*: *"//' -e 's/".*//')
USER_SLUG=$(printf '%s\n' "$META" | grep '"user_slug"' | sed -e 's/.*: *"//' -e 's/".*//')

SLUG=$(sh "${MISSION_SCRIPTS}/slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

TICKET_DIR=".workaholic/tickets/todo/${USER_SLUG}"
TICKET_PATH="${TICKET_DIR}/${STAMP}-${SLUG}.md"

if [ -e "$TICKET_PATH" ]; then
  printf '{"created": false, "reason": "exists", "path": "%s"}\n' "$TICKET_PATH"
  exit 1
fi

mkdir -p "$TICKET_DIR"
cat > "$TICKET_PATH" <<EOTICKET
---
created_at: ${CREATED_AT}
author: ${AUTHOR}
type: ${TYPE}
layer: [${LAYER}]
effort:
commit_hash:
category:
depends_on:
mission: ${MISSION_SLUG}
merge_policy:
---

# ${TITLE}

## Overview

<!-- PROPOSED. What this ticket would implement and why, from the feedback and
     repository state the proposal grew from. Approval of the mission is what
     turns this from a proposal into work. -->

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- \`workaholic:implementation\` / \`policies/directory-structure.md\` — conventional project layout
- \`workaholic:implementation\` / \`policies/coding-standards.md\` — style and structure conventions

## Key Files

<!-- The files this ticket would touch, each with why it is relevant. -->

## Implementation Steps

<!-- The ordered steps. A proposal is judged on these, so they are the point. -->

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- <proposed>

**Verification method** — the commands/tests/probes that prove them:

- <proposed>

**Gate** — what must pass before approval:

- <proposed>

## Considerations

<!-- Risks and open questions the proposal already sees. -->
EOTICKET

git add "$TICKET_PATH" 2>/dev/null || true

printf '{"created": true, "path": "%s", "slug": "%s", "mission": "%s"}\n' "$TICKET_PATH" "$SLUG" "$MISSION_SLUG"
