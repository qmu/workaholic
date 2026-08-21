#!/bin/sh -eu
# WHAT A STORY-LESS MERGE CAN STILL BE RESOLVED TO, FROM THE BASE ALONE.
#
#   resolve-merge-substance.sh <merge-sha>
#
# Stdout: zero or more detail lines, each already a full sentence and NOT prefixed
# with a bullet — the caller owns the bullet, the indentation and the clamp. Zero
# lines is the ordinary answer for a merge that published no artifact.
#
# WHY IT EXISTS (2026-08-18, issue #512). `## Key Changes` prefers a branch story
# and falls back to the merge body's pull request title. The fallback is not rare:
# a `/propose` pull request is published through the publish tree and auto-merges
# without ever running `/report`, so it structurally never has a story. Measured on
# this repository over `v1.0.170..main`: **38 of 68 merges (56%) carry no story** —
# the majority path, rendered as one clamped title where a story is a paragraph of
# why. The substance is on the base already: the proposal's own feedback record,
# the mission it planned, the tickets it queued.
#
# IT ADDS DETAIL TO A ROW; IT SELECTS NOTHING. No merge is dropped, reordered or
# capped by this script — the renderer performs no selection and this introduces
# none (the reordering and capping readings were refused on 2026-08-18; do not
# revive them). A merge this script can say nothing about renders exactly as it did.
#
# THE LABELS ARE HONEST ON PURPOSE. A feedback record states what somebody ASKED
# FOR, which is not always what the merge DID, so its line says `Asked for:` and
# never presents itself as a summary of the change. A wrong summary is worse than a
# thin one.
#
# LOCAL READS ONLY. The paths come from the merge's own diff against its first
# parent — the files that merge brought in — and the titles are read from the base
# checkout, the same way the story rung already reads `.workaholic/stories/`. No
# network, so `--enrich` stays off by default and a CI render never depends on it,
# and the same base state renders the same detail.
#
# NEITHER RELATION IS PARSED HERE. `feedback:` and `mission:` lists have exactly one
# reader each (`propose/scripts/read-feedback-relation.sh`,
# `mission/scripts/read-relation.sh`) and this script reads neither: it discovers
# artifact PATHS from a diff and reads a `title:` field off them, so it adds no
# second parser of either field.

set -eu

SHA="${1:-}"
[ -n "$SHA" ] || exit 0

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0

# A non-merge commit publishes nothing through a pull request, and the diff below
# would then describe the commit itself rather than what a merge brought in.
git rev-parse -q --verify "${SHA}^2" >/dev/null 2>&1 || exit 0

FILES=$(git -C "$ROOT" diff --name-only "${SHA}^1" "$SHA" 2>/dev/null || true)
[ -n "$FILES" ] || exit 0

# The `title:` of an artifact as the base checkout carries it. Absent file, absent
# field, or a body-only document each answer with nothing, and the caller then
# names what it does know (the stem) rather than inventing a title.
frontmatter_title() {
  [ -f "${ROOT}/$1" ] || return 0
  awk '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && /^---[[:space:]]*$/ { exit }
    /^title:[[:space:]]*/ { sub(/^title:[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print; exit }
  ' "${ROOT}/$1"
}

FB_STEM=$(printf '%s\n' "$FILES" \
  | sed -n 's|^\.workaholic/feedbacks/\(.*\)\.md$|\1|p' | head -n 1)
MISSION_PATH=$(printf '%s\n' "$FILES" \
  | sed -n 's|^\(\.workaholic/missions/[^/]*/[^/]*/mission\.md\)$|\1|p' | head -n 1)
MISSION_SLUG=$(printf '%s\n' "$MISSION_PATH" \
  | sed -n 's|^\.workaholic/missions/[^/]*/\([^/]*\)/mission\.md$|\1|p')
TICKETS=$(printf '%s\n' "$FILES" \
  | grep -c '^\.workaholic/tickets/todo/.*\.md$' || true)
[ -n "$TICKETS" ] || TICKETS=0

if [ -n "$FB_STEM" ]; then
  fb_title=$(frontmatter_title ".workaholic/feedbacks/${FB_STEM}.md")
  if [ -n "$fb_title" ]; then
    printf 'Asked for: %s (feedback `%s`).\n' "$fb_title" "$FB_STEM"
  else
    printf 'Asked for: feedback `%s`.\n' "$FB_STEM"
  fi
fi

if [ -n "$MISSION_SLUG" ]; then
  m_title=$(frontmatter_title "$MISSION_PATH")
  [ -n "$m_title" ] || m_title="$MISSION_SLUG"
  if [ "$TICKETS" -gt 0 ]; then
    printf 'Planned as: mission "%s", %s ticket(s) queued.\n' "$m_title" "$TICKETS"
  else
    printf 'Planned as: mission "%s".\n' "$m_title"
  fi
elif [ "$TICKETS" -gt 0 ]; then
  printf 'Queued: %s ticket(s).\n' "$TICKETS"
fi
