#!/bin/sh -eu
# THE TICKET FLOOR, AS A VERDICT A CREATION SEAM CAN ACT ON.
#
#   check-floor.sh <mission-slug> [workaholic-root]
#
# Output: {"slug", "total", "floor", "meets_floor", "ok", "reason", "alternative"}
#   exit 0 when the mission meets the floor, exit 1 when it does not -- so a seam that
#   forgets to read the JSON still fails rather than publishing a violation.
#
# THE RULE: a mission is created with two or more tickets, or it is not a mission
# (mission/SKILL.md, *Granularity -> The ticket floor*). Without it a ticketless mission
# is a feedback record on the roadmap and a one-ticket mission is a ticket with a
# progress bar -- the three artifact kinds are only distinguishable if the middle one has
# a lower bound.
#
# WHY THIS EXISTS BESIDE queue-size.sh. queue-size.sh is a pure READ: it computes
# `meets_floor` and is called by drivability checks that must not fail on a sub-floor
# mission. This is the ENFORCEMENT face of that same number -- the count is never
# recomputed here, only judged -- so the seams share one verdict AND one refusal text.
# Four inline counts would drift; four hand-written refusals would drift the same way,
# and each seam is exercised separately so neither drift would be visible.
#
# THE REFUSAL NAMES THE ALTERNATIVE, always. A refusal that states only the rule leaves
# the author retrying the same thing (implementation/observability): what they have is
# worth recording, it is just the wrong kind of artifact. A bare direction is a FEEDBACK
# RECORD; a single unit of work is a PLAIN TICKET.
#
# WHERE IT IS CALLED: the publish seam of every creation path -- the Creation
# Interrogation and /specificate -- and nowhere earlier. The tickets do not exist while the
# mission is being authored, so a check at the write of mission.md would refuse the
# normal authoring order every time; that is the same reasoning that put acceptance-link
# stamping at the emitting seam, written after 37 items across six missions were found
# unlinked. Two seams deliberately do NOT call it: `create.sh` mints the scaffold before
# any ticket exists (its header records why), and `close.sh` refuses `--successor-title`
# categorically rather than by count -- a minted successor has zero tickets by
# construction, so there is nothing to measure.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
slug="${1:-}"
root="${2:-}"

if [ -z "$slug" ]; then
  echo '{"ok": false, "reason": "slug_required"}' >&2
  exit 1
fi

qs=$(sh "${SCRIPT_DIR}/queue-size.sh" "$slug" ${root:+"$root"})

# Read the two fields off the counter's JSON rather than re-deriving either. A
# sub-floor verdict is the normal case this script exists for, so a parse failure must
# not be mistaken for one: an unreadable count is reported as its own reason.
total=$(printf '%s' "$qs" | sed -n 's/.*"total": \([0-9]*\).*/\1/p')
floor=$(printf '%s' "$qs" | sed -n 's/.*"floor": \([0-9]*\).*/\1/p')
meets=$(printf '%s' "$qs" | sed -n 's/.*"meets_floor": \([a-z]*\).*/\1/p')

if [ -z "$total" ] || [ -z "$floor" ] || [ -z "$meets" ]; then
  printf '{"ok": false, "slug": "%s", "reason": "count_unreadable"}\n' "$slug" >&2
  exit 1
fi

if [ "$meets" = "true" ]; then
  printf '{"ok": true, "slug": "%s", "total": %s, "floor": %s, "meets_floor": true}\n' \
    "$slug" "$total" "$floor"
  exit 0
fi

printf '{"ok": false, "slug": "%s", "total": %s, "floor": %s, "meets_floor": false, "reason": "below_ticket_floor", "alternative": "%s"}\n' \
  "$slug" "$total" "$floor" \
  "do not publish this as a mission: record a bare direction as a feedback record (/fb), and a single unit of work as a plain ticket (/ticket). A mission needs ${floor} or more tickets emitted with it; this one has ${total}." >&2
exit 1
