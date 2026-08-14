#!/bin/sh -eu
# Resolve who owns an ARTIFACT — the one ownership oracle every consumer reads through.
#
# Ownership is CARRIED ON THE ARTIFACT, as a field. A mission has said so since
# 2026-07-28 (docs/loop-engineering-workflow.md B3/B4); a **ticket** joined it on
# 2026-08-06 (P2), when its owner stopped being its directory. Before that a
# ticket's owner was encoded in its path — `.workaholic/tickets/todo/<user-slug>/` —
# which cost three things this file exists to end:
#
#   * "could not read" and "nothing queued" were the SAME OBSERVATION. With no
#     `git config user.email` there was no directory to open, so an unreadable
#     queue rendered as an empty one and an hourly runner reported a healthy idle
#     tick over a full backlog.
#   * Reassignment was a file MOVE, and following renames across the queue is
#     exactly what the claim reader's tree-to-tree map plus filename fallback were
#     built for — both added after real double-pick incidents (2026-07-30,
#     2026-08-04).
#   * TWO OWNERSHIP MODELS coexisted: a mission's plural `assignees` with an
#     unowned state meaning "claimable by anyone", against a ticket's single owner
#     with no unowned state at all. The better model already existed and was
#     proven; the queue used the worse one.
#
# So: one reader, one model, every artifact kind. `assignees` is plural (an
# artifact can be co-owned) and EMPTY MEANS TEAM-OWNED — unclaimed work, surfaced
# to everyone as claimable, never orphaned.
#
# Resolution order (first non-empty tier wins):
#
#   1. the artifact's own `assignees:` (plural), read through read-assignees.sh —
#      the single parser of the field shape (list + bare forms);
#   2. LEGACY FALLBACK: the artifact's own singular `assignee:`, so an artifact
#      predating the plural field is never orphaned.
#   3. LEGACY TOLERANCE, TICKETS ONLY: a queued ticket still sitting at
#      `.workaholic/tickets/todo/<user-slug>/<file>.md` with no field of its own
#      resolves to `<user-slug>` — the directory that WAS the ownership record.
#
# WHY TIER 3 EXISTS (2026-08-14, issue #454). P2 moved the owner into the field but
# left the old layout tolerated everywhere it is read — `list-todo.sh` surveys
# `-maxdepth 2` on purpose — so a colleague's un-migrated ticket reached this oracle
# with no `assignees:`, answered EMPTY, and `owns.sh` called it `unowned`. Unowned
# means team-owned and claimable by anyone, so `plan-units.sh` offered every
# colleague's queue to every runner: measured overnight 2026-08-13→14, ~10 PR-units
# driven and merged under one developer's identity out of other people's queues.
# The directory that used to BE the ownership record was being read as its absence,
# the exact inverse of the `owned_by_other` exclusion the survey promises.
#
# It is a TIER ON THE ORACLE, not an exclusion rule in the survey, for three
# reasons: every consumer already reads ownership from here, so one tier fixes all
# of them at once; comparison downstream is by slug (`user-slug.sh`) precisely so a
# directory-shaped owner matches an email identity; and resolving (rather than
# excluding) keeps a runner's OWN legacy tickets answering `mine` instead of
# vanishing along with everyone else's.
#
# It is a TOLERANCE, NOT A MODEL CHANGE, and it is written to be deletable: it fires
# only for the one path shape, only when both field tiers are silent, and only for
# tickets. A ticket directly in `todo/` still answers empty — genuinely team-owned —
# and no other artifact kind gains a path tier. When the legacy layout is gone (the
# archive seam now converges every queue it touches), this block goes with it.
#
# NOTE what is deliberately NOT here: a ticket's `author:`. Author is who wrote
# the spec and is immutable history; owner is who is to do it and is meant to
# change. Reading author as owner would make every ticket permanently its writer's,
# which is the reassignment cost above wearing a different field name.
#
# The strategy hop (2026-07-24 — owners derived from a linked strategy's
# `assignees`) is GONE and stays gone. It went with the 2026-07-28 strategy-layer
# retirement, whose living migration folded strategy assignees down into each
# linked active mission's own `assignees` so nothing was orphaned. The strategy
# ARTIFACT returned on 2026-08-13 (workaholic:strategy) — the HOP did not: a
# strategy owns itself and a mission owns itself, with no relation between them,
# because a second ownership resolution path is exactly what this oracle exists to
# not have (strategy/SKILL.md, Its relation to missions).
#
# Usage: owners.sh <artifact-file>
# Output: zero or more owners, one per line. Empty output means UNOWNED, which is a
#         real state and not an error. Never fails on a malformed/missing file.

set -eu

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

SCRIPT_DIR=$(dirname "$0")

# 1. The artifact's own plural `assignees:` — the primary source. read-assignees.sh
# parses the field shape (frontmatter-only, list + bare forms), so the shape lives
# in exactly one place.
own=$(sh "${SCRIPT_DIR}/read-assignees.sh" "$FILE" 2>/dev/null || true)
if [ -n "$own" ]; then
    printf '%s\n' "$own"
    exit 0
fi

# 2. Legacy fallback: the artifact's own singular `assignee:` (frontmatter only).
legacy=$(awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^assignee:[ \t]*/ { sub(/^assignee:[ \t]*/, ""); sub(/[ \t]+$/, ""); if (length($0) > 0) print; exit }
' "$FILE" 2>/dev/null || true)
if [ -n "$legacy" ]; then
    printf '%s\n' "$legacy"
    exit 0
fi

# 3. Legacy tolerance, tickets only: the per-user queue directory P2 replaced.
# The shape is matched exactly — `<...>/tickets/todo/<segment>/<file>` — so a flat
# `todo/<file>` (segment would be `todo` itself, parent `tickets`) and every other
# tree (`archive/<branch>/`, `missions/active/<slug>/`) fall through to empty.
dir=$(dirname "$FILE")
segment=$(basename "$dir")
parent=$(basename "$(dirname "$dir")")
grandparent=$(basename "$(dirname "$(dirname "$dir")")")

if [ "$parent" = "todo" ] && [ "$grandparent" = "tickets" ]; then
    printf '%s\n' "$segment"
fi
