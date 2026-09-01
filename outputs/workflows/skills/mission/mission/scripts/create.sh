#!/bin/sh -eu
# Create a new mission: scaffold .workaholic/missions/active/<slug>/mission.md from a
# title, stamp created_at/author from the gather skill, refresh the OKF bundle indexes,
# and git-stage. The slug is derived from the title (lowercased, every run of
# non-[a-z0-9] collapsed to a single hyphen, ends trimmed). Refuses to overwrite an
# existing mission in either area (active/ or archive/).
#
# THE MISSION IS BORN `status: active` — there is no draft state (2026-07-31,
# docs/loop-engineering-workflow.md K1). Every mission now reaches `main` behind a
# pull request (J4), and MERGING THAT PULL REQUEST IS THE APPROVAL; a `draft` word
# would gate the same content a second time and require a manual command to undo the
# first gate. The scaffold still lands unfinished — the Creation Interrogation fills
# ## Experience and ## Acceptance before the publish commit — but "unfinished" is a
# property of the working tree, not a status a reader has to interpret.
#
# THE TICKET FLOOR IS DELIBERATELY NOT CHECKED HERE, and this absence is a decision
# rather than an oversight (mission/SKILL.md, *Granularity -> The ticket floor*). The
# floor is "two or more tickets, or it is not a mission", counted at the PUBLISH seam —
# the commit where the mission and its ticket set become one artifact. This script mints
# the scaffold, which by construction runs BEFORE the interrogation has emitted anything,
# so a floor here would refuse the normal authoring order every single time. Same
# argument as the acceptance-link contract: a check placed where its data does not yet
# exist does not enforce the rule, it blocks the workflow.
#
# Usage: create.sh "<title>" [assignee] [merge_policy]
#   Ownership is CARRIED ON THE MISSION as the plural `assignees` list (2026-07-28 —
#   returned from the 2026-07-24 strategy-layer model; see mission/reference/schema.md Ownership
#   and gather/scripts/owners.sh). The scaffold seeds `assignees` with the CREATOR — the
#   interactive creator is the mission's default owner. The optional second argument
#   seeds a different single owner instead; co-owners are added by editing the list.
#   The singular `assignee:` key stays emitted but EMPTY (legacy readers only).
#   Batch writers that need an UNOWNED mission write their own scaffold
#   (specificate/scripts/scaffold-draft.sh) — passing "" here is not supported.
#
#   MERGE POLICY IS RECORDED AT CREATION (K2), adopting the ticket rule exactly: the
#   optional third argument is `auto` or `review`, and ABSENT MEANS `review` — the
#   conservative default, so a mission that arrives with no policy routes to a PR.
#   It used to be recorded at approval, which no longer exists. An unrecognized value
#   is refused rather than silently written, because `effective-policy.sh` reads this
#   field to decide whether an unattended run may merge.
# Output: JSON {created, slug, path[, reason]}

set -eu

TITLE="${1:-}"
[ -n "$TITLE" ] || { echo '{"created": false, "reason": "no_title"}'; exit 1; }
ASSIGNEE_ARG="${2:-}"
# Absent reads as `review` and is written as an EMPTY field, exactly as a ticket
# records it -- one rule, one spelling, so effective-policy.sh needs no special case.
MERGE_POLICY_ARG="${3:-}"
case "$MERGE_POLICY_ARG" in
    auto | review | "") : ;;
    *)
        printf '{"created": false, "reason": "bad_merge_policy", "got": "%s"}\n' "$MERGE_POLICY_ARG"
        exit 1
        ;;
esac

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
# No artifact to key off -- a mission is being created, so the root is "this repo".
ROOT=$(missions_root_default)
missions_migrate_layout "$ROOT"

# Slug rule lives in slug.sh (the single source), so the mission directory name
# and the /mission worktree directory name always agree.
SLUG=$(sh "${SCRIPT_DIR}/slug.sh" "$TITLE")
[ -n "$SLUG" ] || { echo '{"created": false, "reason": "empty_slug"}'; exit 1; }

MISSION_DIR=".workaholic/missions/active/${SLUG}"
MISSION_FILE="${MISSION_DIR}/mission.md"

EXISTING=$(mission_resolve "$ROOT" "$SLUG")
if [ -f "$EXISTING" ]; then
    printf '{"created": false, "reason": "exists", "slug": "%s", "path": "%s"}\n' "$SLUG" "$EXISTING"
    exit 1
fi

# ═══ AND THE CHECK ABOVE READS THE TREE IT IS WRITING INTO ═══════════════════════════
# (2026-09-01, ticket `20260901072600`.) That tree is a publish tree cut from the base, so
# the check is correct when the tree is BUILT and arbitrarily stale by the time it MERGES.
# MEASURED on this repository: two records with the slug `say-when-the-loop-has-run-out-of-
# direction` are both on `main`. Record A was created 2026-08-26 07:19:28 and record B
# 2026-08-26 08:19:15, each in its own publish tree, and the check above was RIGHT both
# times — the base carried no such mission at either moment. Record B merged at 08:25:18;
# record A merged six days later (PR #625, 2026-09-01 06:22:15) and landed a second record
# beside the first. Git raised no conflict because B had been archived by then, so the two
# occupy different paths and nothing collided.
#
# NEITHER `create.sh`'s AREA COVERAGE NOR `close.sh` IS THE DEFECT, and both were read in
# full before this was written: the check above already covers `active/` and `archive/`
# (that is what `mission_resolve` does), and `close.sh` already answers
# `archive_slug_conflict` and leaves the mission where it is. The seam is the staleness.
#
# SO THE SECOND READING IS THE UNMERGED BRANCHES — the same oracle the claim protocol rests
# on, through the one walk `/specificate` already uses. No API call, no auth, nothing new
# derived.
#
# AN AMBIGUOUS OR DEGRADED WALK REPORTS AND PROCEEDS, NEVER REFUSES. The walk over-reads on
# every ambiguity BY DESIGN, which is right for a dedup and wrong for a gate: an over-read
# here would refuse to create a legitimate mission. A shallow clone cannot reduce
# `rev-list --count` across a graft and so counts long-merged branches as ahead, so shallow
# is treated as degraded even when it finds a hit. Only a walk that completed may refuse.
#
# THE REPORT GOES TO STDERR, so stdout stays exactly the machine-readable line every caller
# parses — the walk's own convention, and the reason a degraded read here can never be
# mistaken for a refusal.
BRANCH_TAKEN_REF=""
BRANCH_CHECK_DEGRADED=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    UNMERGED_BRANCHES_LABEL="mission/create.sh"
    . "${SCRIPT_DIR}/../../specificate/scripts//lib/unmerged-branches.sh"
    SLUG_CHECK_BASE=$(unmerged_branches_base)
    if [ -z "$SLUG_CHECK_BASE" ]; then
        BRANCH_CHECK_DEGRADED="no_base_ref"
    else
        [ "$(git rev-parse --is-shallow-repository 2>/dev/null || echo false)" = "true" ] \
            && BRANCH_CHECK_DEGRADED="shallow"
        # ONE pathspec covers both areas, because a git pathspec's `*` crosses `/`. It is
        # not the cost that matters: measured over 302 remote branches here, two pathspecs
        # took 11s and this one 10s — the branch COUNT dominates, exactly as the walk's own
        # header records. What one pathspec buys is that the two areas cannot drift apart.
        BRANCH_TAKEN_REF=$(unmerged_branches_added_paths "$SLUG_CHECK_BASE" \
            ".workaholic/missions/*/${SLUG}/mission.md" \
            2>/dev/null | head -n 1 | cut -f1 || true)
    fi
else
    BRANCH_CHECK_DEGRADED="not_a_git_repository"
fi

if [ -n "$BRANCH_TAKEN_REF" ] && [ -z "$BRANCH_CHECK_DEGRADED" ]; then
    printf '{"created": false, "reason": "exists_on_branch", "slug": "%s", "ref": "%s"}\n' \
        "$SLUG" "${BRANCH_TAKEN_REF#refs/remotes/}"
    exit 1
fi
if [ -n "$BRANCH_CHECK_DEGRADED" ]; then
    if [ -n "$BRANCH_TAKEN_REF" ]; then
        echo "mission/create.sh: slug ${SLUG} is already taken on unmerged ${BRANCH_TAKEN_REF#refs/remotes/}, but the branch walk was ${BRANCH_CHECK_DEGRADED} — creating anyway rather than refusing on a reading we could not complete" >&2
    else
        echo "mission/create.sh: the unmerged-branch slug check was ${BRANCH_CHECK_DEGRADED}; a slug taken only on an open publication would not be seen" >&2
    fi
fi

# created_at / author from the single canonical gather script (one line per field).
META=$(sh "${SCRIPT_DIR}/../../gather/scripts//ticket-metadata.sh")
CREATED_AT=$(printf '%s\n' "$META" | grep '"created_at"' | sed -e 's/.*: *"//' -e 's/".*//')
AUTHOR=$(printf '%s\n' "$META" | grep '"author"' | sed -e 's/.*: *"//' -e 's/".*//')

# Self-ownership by default: whoever creates a mission interactively owns it
# (docs/loop-engineering-workflow.md decision B4). The optional second argument seeds
# a different single owner. Ownership is NOT a gate — an unowned mission is claimable
# by anyone (K2) — so this is a convenience, not a floor.
ASSIGNEE="${ASSIGNEE_ARG:-$AUTHOR}"

mkdir -p "$MISSION_DIR"
cat > "$MISSION_FILE" <<EOF
---
type: Mission
title: ${TITLE}
slug: ${SLUG}
status: active
merge_policy: ${MERGE_POLICY_ARG}
created_at: ${CREATED_AT}
author: ${AUTHOR}
assignees: [${ASSIGNEE}]
assignee:
predicted_hours:
actual_hours:
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
---

# ${TITLE}

## Goal

<!-- The information-rich "why": business grounding and the outcome this mission pursues. -->

## Experience

<!-- The mission's substance: the user experience, the demanded behavior, and/or the overall
     structure this mission pursues. Describe what the thing DOES (## Goal is why it is worth
     doing). Keep it observable -- "the list reorders without a reload" is checkable, "feels
     fast" is not. This is what a later session reads to know what is actually demanded, and
     it is the durable content a kickoff-time quality gate could never be. -->

## Acceptance

<!-- THREE ITEMS OR FEWER. Write only the minimum conditions under which this mission can
     be called done -- not an exhaustive coverage list, and not future audit items. An
     acceptance list sized like an audit list never gets ticked, and a mission whose list
     is never ticked can never be honestly closed.
     One checklist item per criterion, each naming the ticket/story expected to satisfy it
     by filename, e.g. "criterion text (#20260101120000-some-ticket.md)". Progress toward
     achievement is checked over total, computed from this list, never a hand-set number. -->

## Changelog

<!-- Append-only, dated timeline relating this mission's tickets and reports over time.
     One line per event ("- YYYY-MM-DD — event — filename"); never rewrite past lines. -->
EOF

# Refresh the OKF bundle indexes so the create commit ships a fresh hierarchy
# (best-effort: an index problem must not block mission creation).
sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

git add "$MISSION_FILE" 2>/dev/null || true

printf '{"created": true, "slug": "%s", "path": "%s"}\n' "$SLUG" "$MISSION_FILE"
