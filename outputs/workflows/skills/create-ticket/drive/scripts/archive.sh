#!/bin/sh -eu
# Complete archive workflow: move ticket, commit via commit skill, update frontmatter

set -eu

TICKET="${1:-}"
COMMIT_MSG="${2:-}"
REPO_URL="${3:-}"
WHY="${4:-}"
CHANGES="${5:-None}"
CONCERNS="${6:-}"
INSIGHTS="${7:-}"
VERIFY="${8:-None}"
shift 8 2>/dev/null || true

if [ -z "$TICKET" ] || [ -z "$COMMIT_MSG" ] || [ -z "$REPO_URL" ]; then
    echo "Usage: archive.sh <ticket-path> <commit-message> <repo-url> [why] [changes] [concerns] [insights] [verify] [files...]"
    exit 1
fi

if [ ! -f "$TICKET" ]; then
    echo "Error: Ticket not found: $TICKET"
    exit 1
fi

BRANCH=$(git branch --show-current)

if [ -z "$BRANCH" ]; then
    echo "Error: Cannot archive ticket: not on a named branch."
    exit 1
fi

TICKET_DIR=$(dirname "$TICKET")
# Strip /todo, /icebox, or their per-user form /todo/<user>, /icebox/<user> to
# find the tickets root. The per-user patterns run first so a trailing user
# segment is removed before the bare-directory patterns apply.
TICKETS_ROOT=$(echo "$TICKET_DIR" | sed 's|/todo/[^/]*$||; s|/icebox/[^/]*$||; s|/todo$||; s|/icebox$||')
# Sanitize branch name: replace / with - for flat archive directory naming
# e.g. trip/my-feature -> trip-my-feature (consistent with drive-* convention)
SAFE_BRANCH=$(echo "$BRANCH" | tr '/' '-')
ARCHIVE_DIR="${TICKETS_ROOT}/archive/${SAFE_BRANCH}"
TICKET_FILENAME=$(basename "$TICKET")

CATEGORY="Changed"
case "$COMMIT_MSG" in
    Add*|Create*|Implement*|Introduce*) CATEGORY="Added" ;;
    Remove*|Delete*) CATEGORY="Removed" ;;
esac

echo "==> Archiving ticket..."
mkdir -p "$ARCHIVE_DIR"
mv "$TICKET" "$ARCHIVE_DIR/"
ARCHIVED_TICKET="${ARCHIVE_DIR}/${TICKET_FILENAME}"
echo "    ${ARCHIVED_TICKET}"

SCRIPT_DIR=$(dirname "$0")

# Roll every related mission: a ticket carrying `mission: [a, b]` appends a "ticket
# archived" changelog line and ticks its acceptance item on EACH mission it names, via
# the mission skill's shared, idempotent mutators. The relation is read by the mission
# skill's single reader, so the field's shape lives in one place.
#
# Looping is safe without dedup: append-changelog.sh keys on the (event, artifact) pair
# and tick-acceptance.sh on the artifact basename, so both no-op on a repeat and
# tick-acceptance simply finds nothing on a mission whose Acceptance does not list this
# ticket. Best-effort throughout — a mission update must never block archiving. The
# mutators git-stage the mission file, so it rides along in the archive commit's
# `git add -A` below.
MISSION_SCRIPTS="${SCRIPT_DIR}/../../mission/scripts/"
sh "${MISSION_SCRIPTS}/read-relation.sh" "$ARCHIVED_TICKET" 2>/dev/null | while IFS= read -r MISSION_SLUG; do
    [ -n "$MISSION_SLUG" ] || continue
    sh "${MISSION_SCRIPTS}/append-changelog.sh" "$MISSION_SLUG" "ticket archived" "$TICKET_FILENAME" >/dev/null 2>&1 || true
    sh "${MISSION_SCRIPTS}/tick-acceptance.sh" "$MISSION_SLUG" "$TICKET_FILENAME" >/dev/null 2>&1 || true
done

# Refresh the .workaholic OKF bundle indexes so the archive commit ships with a
# fresh hierarchy (best-effort: an index problem must not block the archive).
sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

# Stage all changes including the archived ticket
echo "==> Staging changes..."
git add -A

# Delegate to commit skill (with --skip-staging since we already staged)
SCRIPT_DIR=$(dirname "$0")
COMMIT_SCRIPT="${SCRIPT_DIR}/../../commit/scripts//commit.sh"

# Pass the same computed CATEGORY both into the commit (as a git trailer) and into
# the ticket frontmatter below, so the two surfaces can never disagree.
sh "$COMMIT_SCRIPT" --skip-staging --category "$CATEGORY" "$COMMIT_MSG" "$WHY" "$CHANGES" "$CONCERNS" "$INSIGHTS" "$VERIFY"

# NOTE: `commit_hash` is deliberately NOT stamped here. A commit cannot contain its own
# hash: writing it and amending changes the hash, so the recorded value named a pre-amend
# commit that is orphaned and never pushed — every link built from it 404s. Re-stamping
# after the amend just regresses forever (no fixed point exists). The hash is derived
# instead, from the commit that ADDED the archived ticket — see
# `report/scripts/ticket-commits.sh`, which is the single source of truth for it.
echo "==> Updating ticket frontmatter..."
UPDATE_SCRIPT="${SCRIPT_DIR}/update.sh"
sh "$UPDATE_SCRIPT" "$ARCHIVED_TICKET" "category" "$CATEGORY"

git add "$ARCHIVED_TICKET"
git commit --amend --no-edit
echo "==> Updated ticket with category"

# Read the hash only AFTER the final amend, so what we print actually exists.
COMMIT_HASH=$(git rev-parse --short HEAD)

echo ""
echo "Archive complete!"
echo "  Commit: ${COMMIT_HASH}"
echo "  Ticket: ${ARCHIVED_TICKET}"
