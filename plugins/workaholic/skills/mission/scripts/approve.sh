#!/bin/sh -eu
# Approve a mission: flip `status: draft` to `status: approved`, record the
# merge policy the approval decides, seed the approver as owner when the mission
# is unowned, and append the transition to the ## Changelog. This is the ONLY
# sanctioned approver -- never hand-edit `status:` (close.sh owns the other end
# of the lifecycle, and nothing else writes the field).
#
# WHY THIS IS A SCRIPT. Approval is what lets a mission's queue drive without a
# per-ticket human prompt, so the floor it must clear has to be reproducible and
# testable rather than a prose promise. It is the same floor hooks/validate-mission.sh
# enforces at write time (an owner, a non-comment ## Experience, at least one
# ## Acceptance item), asserted here at the moment the authority is actually granted.
#
# ONE AXIS. `status: approved` REPLACES the retired `drive_authorized: true` stamp
# (2026-07-28 -- docs/loop-engineering-workflow.md I2): "approved" is exactly what the
# stamp asserted, and one concept keeps one word (workaholic:planning / terminology).
# A legacy stamp is migrated away by lib/resolve.sh, never written here.
#
# MERGE POLICY IS THE ONE GENUINELY HUMAN RULING THIS FLOW OWNS (decision G5): may
# this mission's completed units merge automatically, or must a human review the PR?
# It is REQUIRED -- there is no default, because defaulting it to `auto` would grant
# unattended merging nobody asked for, and defaulting it to `review` would silently
# discard the question the approval exists to ask.
#
# Usage: approve.sh <mission-slug-or-file> <auto|review> [date]
#   date defaults to today (YYYY-MM-DD); pass it explicitly for deterministic tests.
# Output: JSON {approved, slug, status, merge_policy, owners, path[, reason]}
#   reason: ""                     newly approved
#           "already_approved"     no-op success (same status and merge policy)
#           "missing_args"         no slug, or no merge policy
#           "invalid_merge_policy" the policy is not auto|review
#           "not_found"            no such mission
#           "not_in_flight"        the mission has ended (archived); history is immutable
#           "no_owner"             unowned, and no git identity to seed the approver from
#           "no_experience"        ## Experience is absent or comment-only
#           "no_plan"              ## Acceptance holds no checklist item
#           "no_changelog_section" the approval could not be recorded as history

set -eu

ARG="${1:-}"
POLICY="${2:-}"
DATE="${3:-}"

if [ -z "$ARG" ] || [ -z "$POLICY" ]; then
    echo '{"approved": false, "reason": "missing_args"}' >&2
    exit 1
fi
case "$POLICY" in
    auto|review) : ;;
    *)
        printf '{"approved": false, "reason": "invalid_merge_policy", "merge_policy": "%s"}\n' "$POLICY" >&2
        exit 1
        ;;
esac

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"
ROOT=$(missions_root_for_arg "$ARG")
missions_migrate_layout "$ROOT"
FILE=$(mission_resolve "$ROOT" "$ARG")
[ -f "$FILE" ] || { printf '{"approved": false, "reason": "not_found", "path": "%s"}\n' "$FILE" >&2; exit 1; }

MISSION_DIR=$(dirname "$FILE")
SLUG=$(basename "$MISSION_DIR")

fm() {
    awk -v key="$1" '
        NR==1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        index($0, key ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
    ' "$FILE" 2>/dev/null || true
}

STATUS=$(fm status)
CURRENT_POLICY=$(fm merge_policy)

# Only an in-flight mission can be approved. An ended one is history (design /
# history-structures): re-approving it would rewrite the record rather than add to it.
case "$STATUS" in
    draft|approved) : ;;
    *)
        printf '{"approved": false, "reason": "not_in_flight", "slug": "%s", "status": "%s", "path": "%s"}\n' \
            "$SLUG" "$STATUS" "$FILE" >&2
        exit 1
        ;;
esac

# Already approved with the same policy: a no-op success. (Re-approving with a
# DIFFERENT policy is a real change and falls through -- it rewrites the field and
# records its own changelog line, because the event id carries the policy.)
if [ "$STATUS" = "approved" ] && [ "$CURRENT_POLICY" = "$POLICY" ]; then
    OWNERS=$(sh "${SCRIPT_DIR}/mission-owners.sh" "$FILE" 2>/dev/null || true)
    OWNERS_JSON=""
    for o in $OWNERS; do
        if [ -n "$OWNERS_JSON" ]; then OWNERS_JSON="${OWNERS_JSON}, \"${o}\""; else OWNERS_JSON="\"${o}\""; fi
    done
    printf '{"approved": true, "slug": "%s", "status": "approved", "merge_policy": "%s", "owners": [%s], "path": "%s", "reason": "already_approved"}\n' \
        "$SLUG" "$POLICY" "$OWNERS_JSON" "$FILE"
    exit 0
fi

# --- the floor, checked BEFORE anything is written ---------------------------
# A refusal must leave the mission exactly as it was: a half-approved mission is
# worse than an unapproved one, because the status is what every executor reads.

# ## Experience must carry non-comment content -- it is what /drive judges changes
# against, and a comment-only section is the untouched scaffold.
if ! awk '
    /^## /   { in_s = ($0 ~ /^##[ \t]+Experience[ \t]*$/); next }
    in_s {
      line = $0
      gsub(/<!--.*-->/, "", line)
      if (line ~ /^[ \t]*<!--/) { inc = 1 }
      if (inc) { if (line ~ /-->/) inc = 0; next }
      gsub(/[ \t]/, "", line)
      if (length(line) > 0) { found = 1; exit }
    }
    END { exit(found ? 0 : 1) }
  ' "$FILE"; then
    printf '{"approved": false, "reason": "no_experience", "slug": "%s", "path": "%s"}\n' "$SLUG" "$FILE" >&2
    exit 1
fi

# ## Acceptance must hold at least one checklist item -- an approved mission with no
# plan would authorize unattended work against no bar at all.
if ! awk '
    /^## / { in_s = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/); next }
    in_s && /^[ \t]*-[ \t]+\[( |x|X)\]/ { found = 1; exit }
    END { exit(found ? 0 : 1) }
  ' "$FILE"; then
    printf '{"approved": false, "reason": "no_plan", "slug": "%s", "path": "%s"}\n' "$SLUG" "$FILE" >&2
    exit 1
fi

# The approver is the default owner (decision B4). Ownership is read through the
# single oracle, never parsed here; an unowned mission is seeded with the approver's
# git identity, and with no identity to seed there is nobody to answer for the
# unattended run -- so it is refused rather than approved ownerless.
OWNERS=$(sh "${SCRIPT_DIR}/mission-owners.sh" "$FILE" 2>/dev/null || true)
SEED=""
if [ -z "$OWNERS" ]; then
    SEED=$(git config user.email 2>/dev/null || true)
    if [ -z "$SEED" ]; then
        printf '{"approved": false, "reason": "no_owner", "slug": "%s", "path": "%s"}\n' "$SLUG" "$FILE" >&2
        exit 1
    fi
    OWNERS="$SEED"
fi

# --- apply --------------------------------------------------------------------
# History FIRST, state second. The approval becomes history, not just state
# (workaholic:design / history-structures), and appending before the flip is what
# keeps a mission that cannot record its own approval (no ## Changelog section)
# from ending up approved with no trace: nothing has been mutated yet when this
# refuses. The policy rides in the event id, so re-approving with the same policy
# appends nothing while a genuine policy change records its own line.
CL_EVENT="mission approved — merge_policy: ${POLICY}"
if [ -n "$DATE" ]; then
    sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "$CL_EVENT" "mission.md" "$DATE" >/dev/null 2>&1 || CL_FAILED=1
else
    sh "${SCRIPT_DIR}/append-changelog.sh" "$FILE" "$CL_EVENT" "mission.md" >/dev/null 2>&1 || CL_FAILED=1
fi
if [ "${CL_FAILED:-0}" = "1" ]; then
    printf '{"approved": false, "reason": "no_changelog_section", "slug": "%s", "path": "%s"}\n' "$SLUG" "$FILE" >&2
    exit 1
fi

# One pass over the frontmatter: set status, set-or-insert merge_policy, seed
# assignees when the mission was unowned, and drop any legacy drive_authorized key
# still present (the migration normally removed it already).
TMP="${FILE}.$$.tmp"
awk -v seed="$SEED" -v policy="$POLICY" '
    NR == 1 && $0 == "---" { in_fm = 1; print; next }
    in_fm && /^---[ \t]*$/ {
        if (!mp_done) { print "merge_policy: " policy; mp_done = 1 }
        if (seed != "" && !as_done) { print "assignees: [" seed "]"; as_done = 1 }
        in_fm = 0; print; next
    }
    in_fm && /^status:/ { print "status: approved"; next }
    in_fm && /^merge_policy:/ { print "merge_policy: " policy; mp_done = 1; next }
    in_fm && /^drive_authorized:/ { next }
    in_fm && /^assignees:/ {
        if (seed != "" && !as_done) { print "assignees: [" seed "]"; as_done = 1; next }
        print; next
    }
    { print }
' "$FILE" > "$TMP"
mv "$TMP" "$FILE"

# Refresh the OKF bundle indexes so the approving commit ships a fresh hierarchy
# (best-effort: an index problem must not block an approval).
sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" 2>/dev/null || true

OWNERS_JSON=""
for o in $OWNERS; do
    if [ -n "$OWNERS_JSON" ]; then OWNERS_JSON="${OWNERS_JSON}, \"${o}\""; else OWNERS_JSON="\"${o}\""; fi
done

printf '{"approved": true, "slug": "%s", "status": "approved", "merge_policy": "%s", "owners": [%s], "path": "%s", "reason": ""}\n' \
    "$SLUG" "$POLICY" "$OWNERS_JSON" "$FILE"
