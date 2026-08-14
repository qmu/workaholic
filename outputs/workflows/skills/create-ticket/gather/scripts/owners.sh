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
awk '
NR == 1 { if ($0 != "---") exit; next }
/^---[ \t]*$/ { exit }
/^assignee:[ \t]*/ { sub(/^assignee:[ \t]*/, ""); sub(/[ \t]+$/, ""); if (length($0) > 0) print; exit }
' "$FILE" 2>/dev/null || true
