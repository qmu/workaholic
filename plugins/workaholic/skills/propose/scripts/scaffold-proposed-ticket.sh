#!/bin/sh -eu
# Scaffold a PROPOSED TICKET — the second half of a proposal. The batch fills the
# sections; this script owns the filename, the frontmatter, and the relations.
#
#   scaffold-proposed-ticket.sh "<title>" <mission-slug> [--assignee <email>]
#                               [--verification-handoff "<what cannot run here>"]
#   scaffold-proposed-ticket.sh "<title>" --loose --feedback <record>... [--assignee <email>]
#                               [--verification-handoff "<what cannot run here>"]
#
# Output: JSON {created, path, slug, assignees[, mission][, feedback][, reason]}
#   reasons: no_title | no_mission | mission_missing | no_feedback | exists
#
# TWO FORMS, BECAUSE THE WORK HAS TWO SHAPES. A direction that decomposes into two
# or more units becomes a mission with its ticket set (the mission form). A
# direction that is ATOMIC becomes ONE LOOSE BACKLOG TICKET (`--loose`): no
# mission wrapper, no `mission:` key, offered by `plan-units.sh` as ordinary
# backlog. Before this existed an atomic ask ended in a reported drop, which is
# still silence from the reporter's point of view — the mission-ticket floor had
# wired the refusal half and not the emission half.
#
# A ONE-TICKET MISSION REMAINS IMPOSSIBLE FROM THIS SEAM, and that is the point of
# having a second form rather than a lower floor: the choice is between two valid
# artifacts, so nothing is tempted to dress an atomic ask as a mission to get it
# published.
#
# A LOOSE TICKET MUST CARRY ITS `feedback:` REFS (`no_feedback` otherwise). The
# dedup set is the union of `feedback:` across missions AND tickets
# (list-proposed-refs.sh); a loose ticket has no mission to hold the relation, so
# a loose ticket without refs is a record the batch would re-propose on every
# tick, forever. The mission form may carry them too — harmless, since the set is
# a union — but does not need to: its mission already does.
#
# WHY A PROPOSAL CARRIES TICKETS AT ALL. A draft mission with a provisional
# acceptance sketch and no ticket set is not something a developer can judge —
# it is a title and a hope. `/drive`'s own survey says so mechanically: it drops
# such a mission as `no_tickets`, because acceptance items are not work. The
# proposal is only reviewable when it says what would actually be done.
#
# AND WHAT ACTUALLY HOLDS THE PROPOSAL BACK. `drive/scripts/plan-units.sh` excludes
# ANY ticket carrying a `mission:` relation from the backlog offer, with reason
# `mission_member` — a mission's tickets are driven as part of its unit or not at
# all — so a proposed ticket is never picked up loose. What gates the UNIT is no
# longer a draft status (retired 2026-07-31, K1) but the PULL REQUEST this batch
# opens: the proposal is unreachable to every runner until a human merges it, and
# merging it IS the approval. Nothing here is claimable before that merge, and
# everything here is claimable after it — which is the intended contract, not a gap.
#
# merge_policy IS LEFT EMPTY, which reads as `review`. The batch has no authority
# to grant automatic merging: an unattended proposer must not decide that its own
# output may merge unattended. Whoever reviews the proposal's pull request records
# the policy deliberately if `auto` is wanted (K2).
#
# `assignees` IS NOT THE SAME KIND OF BLANK (P6, 2026-08-06). merge_policy is empty
# because the proposer lacks the AUTHORITY to fill it; `assignees` was empty because
# nothing passed it, which is a different thing and was a measured hole. The routine
# that starts this run fires on an issue ASSIGNED TO A PERSON, so the owner is known
# at the trigger — and leaving it out meant every proposal-born artifact was
# unowned, therefore claimable by EVERY developer's runner, therefore raced for,
# with whose push landed first deciding whose job it was. The claim protocol stopped
# the double-drive; nothing could decide the ownership, because nothing in the data
# said. So `--assignee <email>` writes `assignees: [<email>]`, and its absence still
# writes an empty field — team-owned, claimable by anyone, which is the honest
# reading when no person was named.
#
# `--verification-handoff` IS A FACT ABOUT THE ENVIRONMENT, WHICH IS WHY THE
# PROPOSER MAY WRITE IT WHILE IT MAY NOT WRITE merge_policy. The two look alike and
# are not: merge_policy grants a permission the proposer does not hold, whereas this
# field records something the ask already stated — the verification needs a
# credential, device or account an unattended run does not have. Recording it makes
# `/drive` hand the finished unit to a person instead of merging it and announcing
# it verified (`workaholic:drive` §6). It is written ONLY when the ask says so; the
# batch never infers it from a Quality Gate it wrote itself, since that would let
# the loop excuse its own units from verification. Empty is the ordinary case.
#
# THE MANDATORY BODY SECTIONS ARE WRITTEN AS HEADINGS WITH PLACEHOLDER GUIDANCE,
# not omitted for the caller to remember. `hooks/validate-ticket.sh` rejects a
# ticket in the todo queue whose `## Policies` or `## Quality Gate` is absent or
# empty, and a scaffold that produced an invalid artifact would push the failure
# to whoever ran the batch instead of the person who wrote the scaffold.

set -eu

TITLE="${1:-}"
MISSION_SLUG="${2:-}"
[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }
[ -n "$MISSION_SLUG" ] || { echo '{"created": false, "reason": "no_mission"}'; exit 1; }
shift 2

LOOSE=0
if [ "$MISSION_SLUG" = "--loose" ]; then
  LOOSE=1
  MISSION_SLUG=""
fi

# What remains is --assignee <email> and, after --feedback, the record filenames.
# --feedback consumes to the end, so --assignee is read inside that loop too rather
# than being unreachable after it. Stray positionals are TOLERATED AND IGNORED: the
# retired `[type] [layer]` slot lived here until 2026-08-07 (the fields left the
# ticket frontmatter), and a stale caller passing them must not have its title
# ticket refused over two words that no longer mean anything.
FEEDBACK=""
ASSIGNEE=""
VERIFICATION_HANDOFF=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --assignee)
      ASSIGNEE="${2:-}"
      shift 2 || shift
      ;;
    --verification-handoff)
      VERIFICATION_HANDOFF="${2:-}"
      shift 2 || shift
      ;;
    --feedback)
      shift
      while [ "$#" -gt 0 ]; do
        if [ "$1" = "--assignee" ]; then
          ASSIGNEE="${2:-}"
          shift 2 || shift
          continue
        fi
        if [ "$1" = "--verification-handoff" ]; then
          VERIFICATION_HANDOFF="${2:-}"
          shift 2 || shift
          continue
        fi
        if [ -n "$1" ]; then
          FEEDBACK="${FEEDBACK}${FEEDBACK:+, }$1"
        fi
        shift
      done
      ;;
    *)
      shift
      ;;
  esac
done

# One frontmatter line, so a multi-line reason is folded rather than corrupting the
# block. Reported back in the JSON exactly as it was written.
VERIFICATION_HANDOFF=$(printf '%s' "$VERIFICATION_HANDOFF" | tr '\n' ' ')

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts"

if [ "$LOOSE" = "1" ]; then
  # A loose ticket is the only carrier of its own provenance, so refuse one that
  # would be invisible to the dedup set and re-proposed on every tick.
  [ -n "$FEEDBACK" ] || { echo '{"created": false, "reason": "no_feedback"}'; exit 1; }
else
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
fi

META=$(sh "${SCRIPT_DIR}/../../gather/scripts/ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')
STAMP=$(printf '%s\n' "$META" | grep '"filename_timestamp"' | sed -e 's/.*: *"//' -e 's/".*//')
USER_SLUG=$(printf '%s\n' "$META" | grep '"user_slug"' | sed -e 's/.*: *"//' -e 's/".*//')

SLUG=$(sh "${MISSION_SCRIPTS}/slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

# The FLAT queue since P2 (2026-08-06): a ticket's owner is its `assignees` field,
# not its directory. A proposal is deliberately UNOWNED — `/propose` emits work
# nobody has taken on yet, and an unowned artifact is claimable by anyone, which is
# the same reading its empty `merge_policy` already gets.
# Empty means team-owned; `[<email>]` names the person the trigger assigned.
ASSIGNEES_VALUE=""
if [ -n "$ASSIGNEE" ]; then
  ASSIGNEES_VALUE="[${ASSIGNEE}]"
fi

TICKET_DIR=".workaholic/tickets/todo"
TICKET_PATH="${TICKET_DIR}/${STAMP}-${SLUG}.md"

if [ -e "$TICKET_PATH" ]; then
  printf '{"created": false, "reason": "exists", "path": "%s"}\n' "$TICKET_PATH"
  exit 1
fi

# The relation lines the two forms differ by, and nothing else: a loose ticket
# writes NO `mission:` key at all (an empty one would still read as a relation to
# a mission named ""), and carries `feedback:` instead.
RELATIONS="mission: ${MISSION_SLUG}"
if [ "$LOOSE" = "1" ]; then
  RELATIONS="feedback: [${FEEDBACK}]"
elif [ -n "$FEEDBACK" ]; then
  RELATIONS="${RELATIONS}
feedback: [${FEEDBACK}]"
fi

mkdir -p "$TICKET_DIR"
cat > "$TICKET_PATH" <<EOTICKET
---
created_at: ${CREATED_AT}
author: ${AUTHOR}
assignees: ${ASSIGNEES_VALUE}
depends_on:
${RELATIONS}
merge_policy:
verification_handoff: ${VERIFICATION_HANDOFF}
---

# ${TITLE}

## Overview

<!-- PROPOSED. What this ticket would implement and why, from the feedback and
     repository state the proposal grew from. Merging the pull request this was
     published on is what turns it from a proposal into queued work. -->

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

LOOSE_JSON=false
if [ "$LOOSE" = "1" ]; then
  LOOSE_JSON=true
fi

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

printf '{"created": true, "path": "%s", "slug": "%s", "mission": "%s", "feedback": "%s", "assignees": "%s", "loose": %s, "verification_handoff": "%s"}\n' \
  "$TICKET_PATH" "$SLUG" "$MISSION_SLUG" "$FEEDBACK" "$ASSIGNEE" "$LOOSE_JSON" "$(json_escape "$VERIFICATION_HANDOFF")"
