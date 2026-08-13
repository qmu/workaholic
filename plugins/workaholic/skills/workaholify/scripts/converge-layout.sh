#!/bin/sh -eu
# Converge a repository's .workaholic/ tree onto the shape the installed plugin
# enforces — the seam issue #436 closes with ("these migrations need to be applied
# through /workaholify").
#
# WHY IT MUST EXIST: the plugin updates before the tree does. A consuming
# repository takes a new plugin version and immediately meets floors written for a
# shape it has never had — the layout gate has no env-var opt-out, so its next
# ticket write is HARD-BLOCKED with a reason describing someone else's repository.
# Convergence is the only way out, so it belongs to the command that wires a repo
# to the standards rather than to a runbook nobody reads.
#
# WHAT IT DOES, and the line it will not cross:
#
#   APPLIED  — the mechanical migrations, each already idempotent, each already
#              the single entry point for its change. This script COMPOSES them;
#              it never reimplements one, so there is one behaviour per migration.
#                * gather/scripts/migrate-todo-owners.sh    todo/<user>/ -> todo/
#                * gather/scripts/migrate-ticket-states.sh  abandoned|icebox ->
#                                                           archive/unbranched/ + status:
#
#   REPORTED — everything that needs a JUDGMENT, named with the decision it needs
#              and never guessed. Read straight out of layout-doctor.sh:
#                * `retired-area`         guides/ policies/ specs/ still present.
#                    What happens to that content is the OWNER'S call. This
#                    repository deleted its own because all 17 substantive files
#                    described an architecture retired months earlier; another
#                    repository's guides/ may be maintained and true, and nothing
#                    here may impose one repo's measurement on another.
#                * `retired-ticket-state` a legacy dir the migration could not
#                    empty (a name collision, an unwritable file) — a fact, not a
#                    retry.
#                * `undesignated` / everything else — already the doctor's
#                    "owner decision required" class.
#
#   NOT ITS BUSINESS — the feedback `subject:` floor and the revived `strategies/`
#              area need no migration at all: the floor applies to NEW writes only
#              and the stream is immutable, and a strategy is operator-authored so
#              an absent area is the correct state, not a gap. A repository holding
#              the LEGACY NESTED strategies/<area>/<slug>/strategy.md shape is
#              reported (see `legacy_strategies`) and never converted — the
#              erasing migration that used to handle it was retired with the
#              artifact's revival, deliberately.
#
# IT STAGES, IT NEVER COMMITS. The composed migrations git-stage their own moves,
# which is their existing contract; this adds nothing. /workaholify is an attended
# audit and every other step of it reports rather than writes, so committing here
# would make an audit command an author of history in a repository whose state it
# has only just learned. The blocked-write condition lifts the moment the files
# move on disk, so staging is enough to unblock; the commit is the operator's.
#
# Usage: converge-layout.sh [repo-root]
# Output: JSON {before: {...}, applied: [...], after: {...}, decisions: [...],
#               legacy_strategies, changed, conforming}
# Always exits 0 — an audit that erroring stops a session is an audit nobody runs.

set -eu

ROOT="${1:-.}"
SCRIPT_DIR=$(dirname "$0")
PLUGIN_ROOT="${SCRIPT_DIR}/../../.."

doctor() {
    sh "${PLUGIN_ROOT}/hooks/layout-doctor.sh" "$ROOT" 2>/dev/null || printf '{"conforming": null, "findings": []}'
}

# --- before -------------------------------------------------------------------
BEFORE=$(doctor)

# --- the mechanical migrations ------------------------------------------------
# Run from the repo root, because both take a tickets-root relative to the cwd.
APPLIED=""
TICKETS_ROOT="${ROOT}/.workaholic/tickets"

owners_out=$(sh "${PLUGIN_ROOT}/skills/gather/scripts/migrate-todo-owners.sh" "$TICKETS_ROOT" 2>/dev/null || printf '{"migrated": 0, "moves": []}')
states_out=$(sh "${PLUGIN_ROOT}/skills/gather/scripts/migrate-ticket-states.sh" "$TICKETS_ROOT" 2>/dev/null || printf '{"migrated": 0, "moves": []}')

APPLIED="{\"migration\": \"migrate-todo-owners\", \"result\": ${owners_out}}, {\"migration\": \"migrate-ticket-states\", \"result\": ${states_out}}"

owners_n=$(printf '%s' "$owners_out" | sed -n 's/.*"migrated": *\([0-9][0-9]*\).*/\1/p')
states_n=$(printf '%s' "$states_out" | sed -n 's/.*"migrated": *\([0-9][0-9]*\).*/\1/p')
CHANGED=$(( ${owners_n:-0} + ${states_n:-0} ))

# --- after, and the decisions still owed --------------------------------------
AFTER=$(doctor)

CONFORMING=$(printf '%s' "$AFTER" | sed -n 's/.*"conforming": *\([a-z]*\).*/\1/p')
[ -n "$CONFORMING" ] || CONFORMING="null"

# Every surviving finding is a decision a human owes, carried through verbatim so
# the reason and the remediation are the doctor's words rather than a paraphrase.
# The doctor emits `"findings": [ ... ], "advisories": [ ... ]`. Take everything
# between the first `[` after the findings key and the `]` that precedes the
# advisories key — tolerating the space after the colon, which an earlier pattern
# did not and which silently reported "no decisions owed" on a tree that owed two.
DECISIONS=$(printf '%s' "$AFTER" | sed -n 's/.*"findings":[ ]*\[\(.*\)\][ ]*,[ ]*"advisories".*/\1/p')
if [ -z "$DECISIONS" ]; then
    DECISIONS=$(printf '%s' "$AFTER" | sed -n 's/.*"findings":[ ]*\[\(.*\)\].*/\1/p')
fi

# --- the one shape nothing converts -------------------------------------------
# The legacy nested strategy tree. Its migration was RETIRED with the artifact's
# revival (a living migration and a live artifact area cannot share a directory),
# so this is reported and left alone, permanently.
LEGACY_STRATEGIES="false"
if [ -d "${ROOT}/.workaholic/strategies" ]; then
    if find "${ROOT}/.workaholic/strategies" -mindepth 2 -name 'strategy.md' -type f 2>/dev/null | grep -q .; then
        LEGACY_STRATEGIES="true"
    fi
fi

printf '{"before": %s, "applied": [%s], "after": %s, "decisions": [%s], "legacy_strategies": %s, "changed": %s, "conforming": %s}\n' \
    "$BEFORE" "$APPLIED" "$AFTER" "$DECISIONS" "$LEGACY_STRATEGIES" "$CHANGED" "$CONFORMING"
