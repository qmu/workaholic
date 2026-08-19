#!/bin/sh -eu
# Measure a mission document against the SIZE NORMS, and report rather than judge.
#
#   size.sh <mission-file>
#
# Output (one JSON line):
#   {"lines": N, "bytes": N, "acceptance_items": N,
#    "max_lines": 60, "max_bytes": 2048, "max_acceptance": 3,
#    "within_lines": true|false, "within_bytes": true|false,
#    "within_acceptance": true|false, "within": true|false}
#
# WHY THE NORMS EXIST. Missions became hard to finish, and the diagnosis was not that
# the gates were too strict -- it was that NOTHING BOUNDED HOW MUCH A MISSION MAY SAY.
# An unbounded `## Acceptance` grows into an exhaustive audit list, and a mission whose
# acceptance list is an audit list can never be honestly closed. Measured at the time
# the norms were adopted: six active missions, every one of them at 0 of 3-9 criteria.
#
# THE THREE-ITEM ACCEPTANCE NORM IS THE RULE DOING THE REAL WORK. The line and byte
# ceilings are a backstop -- a mission can meet 2 KB by saying less and meaning less, so
# the ceiling shapes the artifact, not the thinking. What belongs in `## Acceptance` is
# the minimum set of conditions under which the work can be called done; coverage lists
# and future audit items belong in tickets and the feedback stream.
#
# THIS SCRIPT NEVER BLOCKS, AND THAT ASYMMETRY IS DELIBERATE (recorded 2026-08-01):
#
#   - For a HUMAN-AUTHORED mission the norms are a NORM, surfaced by the interrogation
#     and by this reader. A hard gate would fire on a legitimately larger mission, and a
#     gate that refuses good work is worse than a norm that guides it -- the author is
#     present, exercising judgment, and can be shown the measurement instead.
#   - For a /specificate DRAFT the ceiling is HARD, enforced by the batch on its own output.
#     The batch writes unattended with no judgment to exercise and no author to show a
#     measurement to, so "guidance" there is just an unenforced wish.
#
# The APPROVED FLOOR is untouched by all of this and stays where it was
# (`hooks/validate-mission.sh`: an owner, a real `## Experience`, at least one
# `## Acceptance` item). This is a CEILING, and lowering a ceiling is not loosening a
# floor -- a later reader must not mistake one for the other.

set -eu

FILE="${1:-}"
MAX_LINES="${WORKAHOLIC_MISSION_MAX_LINES:-60}"
MAX_BYTES="${WORKAHOLIC_MISSION_MAX_BYTES:-2048}"
MAX_ACCEPTANCE="${WORKAHOLIC_MISSION_MAX_ACCEPTANCE:-3}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  printf '{"error": "mission file not found", "file": "%s"}\n' "$FILE" >&2
  exit 1
fi

lines=$(wc -l < "$FILE" | tr -d ' ')
bytes=$(wc -c < "$FILE" | tr -d ' ')

# Count checklist items under ## Acceptance only — the same scoping every other mission
# reader uses, so a checklist elsewhere in the document is never counted as a criterion.
# The regexes deliberately avoid any `[[` sequence — `[[:space:]]` and `\[[ xX]\]` both
# contain one, and hooks/posix-lint.sh flags it as a shell bashism. That is a false
# positive here (this is awk's regex, not the shell's `[[ ]]`), but a lint rule you have
# to argue with at each call site is worth less than these two spellings. `\[.\]` accepts
# any single marker character, which is what every other mission reader already does.
items=$(awk '
  /^## Acceptance[ \t]*$/ { in_acc = 1; next }
  /^## /                  { in_acc = 0 }
  in_acc && /^[ \t]*-[ \t]*\[.\]/ { n++ }
  END { print n + 0 }
' "$FILE")

bool() { [ "$1" -le "$2" ] && printf 'true' || printf 'false'; }

wl=$(bool "$lines" "$MAX_LINES")
wb=$(bool "$bytes" "$MAX_BYTES")
wa=$(bool "$items" "$MAX_ACCEPTANCE")

within=false
if [ "$wl" = "true" ] && [ "$wb" = "true" ] && [ "$wa" = "true" ]; then within=true; fi

printf '{"lines": %s, "bytes": %s, "acceptance_items": %s, "max_lines": %s, "max_bytes": %s, "max_acceptance": %s, "within_lines": %s, "within_bytes": %s, "within_acceptance": %s, "within": %s}\n' \
  "$lines" "$bytes" "$items" "$MAX_LINES" "$MAX_BYTES" "$MAX_ACCEPTANCE" "$wl" "$wb" "$wa" "$within"
