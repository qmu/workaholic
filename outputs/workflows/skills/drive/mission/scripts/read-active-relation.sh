#!/bin/sh -eu
# Which of an artifact's named missions are STILL ACTIVE -- one slug per line.
#
# Usage: read-active-relation.sh <artifact-file>
# Output: zero or more slugs, one per line. Nothing at all when the artifact names no
#         mission, or when every mission it names has closed. Never fails on a malformed
#         file, a dangling slug, or a missing mission tree.
#
# THIS IS A SECOND READER, NOT A WIDENING OF THE FIRST. `read-relation.sh` answers
# *which missions does this artifact name* and four seams depend on that exact contract,
# so the liveness question is answered here instead of being bolted onto it. It is also
# not re-derived per caller: "is this mission alive" is a question about the mission
# tree's layout, and a caller that answered it inline would be a second definition of the
# area rule (`lib/resolve.sh`) free to drift from it.
#
# WHY IT EXISTS (2026-08-12, qmu/workaholic#382). `drive/scripts/plan-units.sh` dropped
# every ticket carrying a `mission:` relation as `mission_member`, on the premise that the
# ticket would be offered inside its mission's unit instead. Only `missions/active/` is
# scanned for units, so once every mission a ticket named had closed, the premise stopped
# holding: the ticket was offered by NEITHER path and no survey proposed it again. It sat
# in `todo/` while the queue read as drained, not as broken -- six tickets unreachable for
# weeks in one repository, five of them genuinely open work.
#
# THE AREA IS THE AUTHORITY, NOT A STATUS WORD (K1, docs/loop-engineering-workflow.md).
# A mission is alive iff it sits under `<root>/missions/active/`. This deliberately does
# not read `status`: a mission reaches `active/` on `main` only by merging its pull
# request, and `close.sh` -- the only writer of an end state -- is what moves it out. A
# `status: draft` mission still in `active/` is therefore ALIVE here, which is what keeps
# `/specificate`'s safety property intact: a ticket proposed under a not-yet-driven mission
# stays unclaimable, because its mission is in the active area whatever word it carries.
#
# IT IS A PURE READER. `plan-units.sh` calls it, and that script must stay side-effect
# free (it runs inside claim worktrees too), so this never invokes the living layout
# migration `missions_migrate_layout` -- which does `git mv`/`git add` -- even though it
# borrows that function's area keying for the legacy flat layout below.
#
# A DANGLING SLUG READS AS CLOSED, on purpose: a mission that resolves nowhere in this
# tree cannot offer the ticket a unit either, so treating it as alive would strand the
# ticket for exactly the reason this reader exists to remove.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

FILE="${1:-}"
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0

# shellcheck source=lib/resolve.sh
. "${SCRIPT_DIR}/lib/resolve.sh"

# The tree that OWNS this artifact, derived from the artifact's own path -- never from
# the process cwd, so a ticket read from inside a claim worktree resolves against that
# worktree's own missions and not a sibling's same-slug mission.
ROOT=$(missions_root_from_artifact "$FILE")

sh "${SCRIPT_DIR}/read-relation.sh" "$FILE" 2>/dev/null | while IFS= read -r slug; do
    [ -n "$slug" ] || continue

    if [ -f "${ROOT}/missions/active/${slug}/mission.md" ]; then
        printf '%s\n' "$slug"
        continue
    fi

    # Legacy flat layout (`<root>/missions/<slug>/mission.md`, pre-area split): no area
    # to read, so fall back to the same status keying `missions_migrate_layout` would
    # use when it relocates the directory -- without relocating anything here.
    flat="${ROOT}/missions/${slug}/mission.md"
    if [ -f "$flat" ]; then
        status=$(awk '
            NR == 1 { if ($0 != "---") exit; next }
            /^---[ \t]*$/ { exit }
            /^status:[ \t]*/ { sub(/^status:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
        ' "$flat" 2>/dev/null || true)
        case "$status" in
            achieved | abandoned | carried) : ;;
            *) printf '%s\n' "$slug" ;;
        esac
    fi
done
