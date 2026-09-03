#!/bin/sh -eu
# Validates mission.md files after Write/Edit operations — the mission analogue
# of validate-ticket.sh. Exit codes: 0 = success/not a mission, 2 = validation
# failed (blocks the operation).
#
# Why: a mission in the active area is the one artifact that can authorize
# UNATTENDED work — /drive's survey offers it as a claimable PR-unit and drives its
# whole ticket queue. Nothing else validates it (validate-ticket.sh sees only
# tickets), so a mission with no Experience and an empty Acceptance could drive
# unattended while rendering as an empty 0/0 board on every roadmap view.
# This hook gives mission.md the same write-time floor tickets have.
#
# Scope: active/<slug>/mission.md and a legacy flat missions/<slug>/mission.md.
# archive/ is history and is never retro-blocked.
#
# THE TWO-TICKET FLOOR IS NOT HERE, AND MUST NOT BE ADDED (2026-09-03, ticket
# `20260903053712-floor-a-mission-at-two-tickets-at-every-seam.md`). This hook fires when
# `mission.md` is WRITTEN, which is before any of its tickets exist -- the normal authoring
# order -- so counting the `mission:` relation here would refuse every legitimate mission on
# its first write. The floor belongs at the seam that publishes the mission and its ticket set
# TOGETHER, where the count is answerable; every one of those seams is enumerated in
# `workaholic:mission`, *The ticket floor*, and each reads `mission/scripts/check-floor.sh`
# rather than spelling the number. Stated here because this is where the next reader looks
# for it.
#
# THE FLOOR FIRES ON ANY ACTIVE MISSION, NOT ON A STATUS WORD (2026-07-31 --
# docs/loop-engineering-workflow.md K1/K2). It used to fire only on
# `status: approved`, letting a `draft` through with nothing required. `draft` is
# retired — merging a mission's pull request is now the approval — so "the thing
# that can be claimed" is no longer marked by a status word, and keying the floor
# on one would leave it keyed to nothing. AREA IS THE TRIGGER: a mission written
# under missions/active/ must meet the floor at that write.
#
#   - `## Experience` must carry non-comment content, and `## Acceptance` at least
#     one checklist item. A 0/0 mission is refused at the drive seam too
#     (drive-authorized.sh / plan-units.sh, reason no_plan) — defense in depth, but
#     this hook says it at write time, where the author can still fix it.
#   - OWNERSHIP IS NOT REQUIRED (K2). It used to be, because an unattended run
#     "needs an owner"; it does not — an unowned mission on `main` is claimable by
#     anyone, which is already how list.sh and summary.sh treat
#     it (`relation: unassigned`), and /specificate writes unowned proposals by design.
#     A legacy `strategy:` key from the retired strategy layer (B3) is likewise
#     tolerated and never required.
#
# CONSEQUENCE WORTH KNOWING BEFORE YOU HIT IT: an agent EDITING a mission under
# active/ must land the Experience and Acceptance content in that write, because a
# half-filled intermediate edit is exactly what this floor refuses. The scaffold
# writers are unaffected — create.sh and scaffold-draft.sh write with a shell
# heredoc, and a PostToolUse Write|Edit hook never sees those — so the scaffold
# moment still passes; it is the interrogation's fill that must arrive complete.
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

# --- the active-area floor ----------------------------------------------------
# The status word no longer selects the floor (K1); the AREA does, and the case
# statement above already established it. One escape remains: an END STATE written
# into active/ is a placement problem for close.sh to fix, not a claimable mission,
# so it is not held to a plan it will never drive. Legacy `draft`/`approved` files
# are NOT exempt — they are ordinary active missions the living migration has not
# rewritten yet, and exempting them would reopen the gap this change closes.
status=$(printf '%s\n' "$frontmatter" | grep -m1 '^status:' | sed -e 's/^status:[ \t]*//' -e 's/[ \t]*$//' || true)
case "$status" in
  achieved | abandoned | carried) exit 0 ;;
esac

# OWNERSHIP IS NOT CHECKED (K2): an unowned mission is claimable by anyone, and
# /specificate writes unowned proposals by design. (A legacy `strategy:` key from the
# retired strategy layer is tolerated and ignored here too.)

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
  echo "Error: an active mission must describe the demanded behavior in ## Experience (non-comment content) — it is what /drive judges changes against" >&2
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
  echo "Error: an active mission must carry at least one ## Acceptance checklist item — an empty plan cannot authorize unattended work" >&2
  echo "Got: $file_path" >&2
  print_skill_reference
  exit 2
fi

exit 0
