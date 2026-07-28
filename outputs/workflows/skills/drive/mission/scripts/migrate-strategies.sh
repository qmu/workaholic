#!/bin/sh -eu
# Retire a lingering .workaholic/strategies/ tree — the direct/test entry to the
# living migration that every mission script also runs through lib/resolve.sh's
# missions_migrate_layout seam (the logic lives THERE, in
# missions_migrate_strategies, so the two entries cannot drift).
#
# Each strategy document survives verbatim as a feedback record (kind: insight,
# source: discussion), its assignees fold down into linked active missions with
# empty assignees, and the strategies/ directory is removed. Idempotent and
# best-effort; see the function's comment for the full contract.
#
# Usage: migrate-strategies.sh [workaholic-root]
#   workaholic-root defaults to this repository's .workaholic (missions_root_default).
# Output: JSON {migrated, root}

set -eu

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/resolve.sh"

ROOT="${1:-$(missions_root_default)}"

HAD="false"
[ -d "${ROOT}/strategies" ] && HAD="true"

missions_migrate_strategies "$ROOT"

printf '{"migrated": %s, "root": "%s"}\n' "$HAD" "$ROOT"
