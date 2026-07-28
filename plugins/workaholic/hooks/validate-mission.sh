#!/bin/sh -eu
# Validates mission.md files after Write/Edit operations — the mission analogue
# of validate-ticket.sh. Exit codes: 0 = success/not a mission, 2 = validation
# failed (blocks the operation).
#
# Why: a mission stamped `drive_authorized: true` skips the per-ticket approval
# prompt, so a hand-authored mission is the one artifact that can authorize
# UNATTENDED work. Nothing validated it (validate-ticket.sh sees only tickets),
# so a mission with no assignee, no Experience, and an empty Acceptance could
# both drive unattended and stay invisible to the mission lens (the 0/0 signal
# gate hides it). This hook gives mission.md the same write-time floor tickets
# have.
#
# Scope: active/<slug>/mission.md and a legacy flat missions/<slug>/mission.md.
# archive/ is history and is never retro-blocked.
#
# One tier for the scaffold moment (which must always pass), one for the finished,
# dangerous `drive_authorized: true` state. create.sh scaffolds EMPTY sections by
# design and the Creation Interrogation fills them afterwards:
#   - always: nothing is required. Ownership is carried on the mission's own plural
#     `assignees` (2026-07-28 — returned from the 2026-07-24 strategy model; see
#     mission/SKILL.md's Ownership section), but the scaffold moment mandates no key.
#   - when the file claims `drive_authorized: true`: the mission must have an OWNER
#     (mission-owners.sh non-empty — its own assignees, else the strategy transition
#     fallback carries at least one assignee,
#     or the mission a legacy `assignee` fallback — an unattended run needs an owner), a
#     non-empty `strategy:` link, `## Experience` with non-comment content, and
#     `## Acceptance` with at least one checklist item. A 0/0 authorized mission is
#     refused at the drive seam too (drive-authorized.sh, reason no_plan) — defense in
#     depth, but this hook says it at write time, where the author can fix it.
#
# Like validate-ticket.sh this checks PRESENCE, never quality — whether the
# Experience is a good one belongs to the interrogation and the developer.

set -eu

print_skill_reference() {
  echo "See: plugins/workaholic/skills/mission/SKILL.md" >&2
}

input=$(cat)

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$file_path" ] || exit 0

# Only mission.md files under .workaholic/missions/, excluding archive/.
case "$file_path" in
  *.workaholic/missions/archive/*) exit 0 ;;
  *.workaholic/missions/*/mission.md) : ;;
  *) exit 0 ;;
esac

[ -f "$file_path" ] || exit 0

content=$(cat "$file_path")

frontmatter=$(printf '%s\n' "$content" | awk '/^---$/{if(++c==2)exit}c==1')

# Nothing is required at the scaffold moment: ownership no longer lives on the mission,
# so there is no mandatory assignee KEY any more.

stamp=$(printf '%s\n' "$frontmatter" | grep -m1 '^drive_authorized:' | sed -e 's/^drive_authorized:[ \t]*//' -e 's/[ \t]*$//' || true)
[ "$stamp" = "true" ] || exit 0

# --- drive_authorized: true — the full floor ---------------------------------

# A drive_authorized mission must link the strategy it executes. Every mission is an
# execution plan of a strategy; the link is resolved during the Creation Interrogation
# (infer / create / ask), so by the time the mission is stamped authorized it must
# carry a non-empty strategy:. An unauthorized scaffold may leave it empty (passes),
# and archive/ is never retro-blocked (handled above).
strategy=$(printf '%s\n' "$frontmatter" | grep -m1 '^strategy:' | sed -e 's/^strategy:[ \t]*//' -e 's/[ \t]*$//' -e 's/^\[//' -e 's/\]$//' -e 's/^[ \t]*//' -e 's/[ \t]*$//' || true)
if [ -z "$strategy" ]; then
  echo "Error: a drive_authorized mission must link a strategy (strategy: <slug>) — every mission executes one; resolve it in the Creation Interrogation" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

# The mission must have an OWNER. Ownership resolves through mission-owners.sh: the
# mission's own plural `assignees` first, then the strategy transition fallback, then
# the legacy singular `assignee`. An unattended run needs someone who owns it, so an
# authorized mission with no owner in any tier is refused here — seed its assignees.
owners=$(sh "$(dirname "$0")/../skills/mission/scripts/mission-owners.sh" "$file_path" 2>/dev/null || true)
if [ -z "$owners" ]; then
  echo "Error: a drive_authorized mission must have an owner — seed the mission's own assignees (or its strategy ${strategy} an assignee, or the mission a legacy assignee); unattended work needs an owner" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

# ## Experience must have non-comment content (HTML-comment-only is scaffold).
if ! printf '%s\n' "$content" | awk '
    /^## /   { in_s = ($0 ~ /^##[ \t]+Experience[ \t]*$/); next }
    in_s {
      line = $0
      gsub(/<!--.*-->/, "", line)            # strip whole inline comments
      if (line ~ /^[ \t]*<!--/) { inc = 1 }  # comment block opens
      if (inc) { if (line ~ /-->/) inc = 0; next }
      gsub(/[ \t]/, "", line)
      if (length(line) > 0) { found = 1; exit }
    }
    END { exit(found ? 0 : 1) }
  '; then
  echo "Error: a drive_authorized mission must describe the demanded behavior in ## Experience (non-comment content) — it is what /drive judges changes against" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

# ## Acceptance must hold at least one checklist item — a 0/0 mission would
# authorize unattended work with no plan and stay invisible to the lens.
if ! printf '%s\n' "$content" | awk '
    /^## / { in_s = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/); next }
    in_s && /^[ \t]*-[ \t]+\[( |x|X)\]/ { found = 1; exit }
    END { exit(found ? 0 : 1) }
  '; then
  echo "Error: a drive_authorized mission must carry at least one ## Acceptance checklist item — an empty plan cannot authorize unattended work" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

exit 0
