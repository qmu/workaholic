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
#                * gather/scripts/migrate-renamed-areas.sh  every `area` row of the
#                                                           rename registry: git mv the
#                                                           directory, fix the root index
#                * gather/scripts/migrate-assignee-aliases.sh  an `assignees:` entry naming
#                                                           a person's ALIAS address ->
#                                                           that person's canonical one.
#                                                           Touches nothing the committed
#                                                           mapping cannot resolve and
#                                                           reports every address it left
#                                                           alone, because inventing an
#                                                           entry is a human's ruling.
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
#                * `rename_conversions` — the PROPOSED half of a rename. An `area` row
#                    moves a machine-owned directory and is applied above; the same
#                    rename's NAME survives in prose, in code comments and in a
#                    consuming repository's own documents, and a name is vocabulary.
#                    gather/scripts/rename-conversions.sh counts the survivors and
#                    prints the bulk conversion; the operator runs it or declines. This
#                    is the same line the `retired-area` class draws, applied to the
#                    other axis: mechanical is applied, judgment is reported.
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
#               rename_conversions: [...], legacy_strategies, changed, conforming}
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

# Cross-skill references use the ${SCRIPT_DIR}/../../<skill>/scripts/ form, which is
# the shape build.mjs detects when it computes a skill's script closure for the
# portable bundle. ${PLUGIN_ROOT}/skills/... reads the same at runtime and is
# INVISIBLE to that scan, so the bundle would ship this script without the two
# migrations it composes (verify.mjs catches it).
owners_out=$(sh "${SCRIPT_DIR}/../../gather/scripts/migrate-todo-owners.sh" "$TICKETS_ROOT" 2>/dev/null || printf '{"migrated": 0, "moves": []}')
states_out=$(sh "${SCRIPT_DIR}/../../gather/scripts/migrate-ticket-states.sh" "$TICKETS_ROOT" 2>/dev/null || printf '{"migrated": 0, "moves": []}')
# Takes the .workaholic root rather than the tickets root: it moves whole AREAS, of
# which tickets/ is one.
areas_out=$(sh "${SCRIPT_DIR}/../../gather/scripts/migrate-renamed-areas.sh" "${ROOT}/.workaholic" 2>/dev/null || printf '{"migrated": 0, "moves": [], "blocked": [], "links_updated": 0}')
# Also the .workaholic root: `assignees:` lives on three areas (tickets, missions,
# strategies), so this one is not scoped to the ticket tree either.
aliases_out=$(sh "${SCRIPT_DIR}/../../gather/scripts/migrate-assignee-aliases.sh" "${ROOT}/.workaholic" 2>/dev/null || printf '{"migrated": 0, "rewrites": [], "unresolved": []}')

APPLIED="{\"migration\": \"migrate-todo-owners\", \"result\": ${owners_out}}, {\"migration\": \"migrate-ticket-states\", \"result\": ${states_out}}, {\"migration\": \"migrate-renamed-areas\", \"result\": ${areas_out}}, {\"migration\": \"migrate-assignee-aliases\", \"result\": ${aliases_out}}"

owners_n=$(printf '%s' "$owners_out" | sed -n 's/.*"migrated": *\([0-9][0-9]*\).*/\1/p')
states_n=$(printf '%s' "$states_out" | sed -n 's/.*"migrated": *\([0-9][0-9]*\).*/\1/p')
areas_n=$(printf '%s' "$areas_out" | sed -n 's/.*"migrated": *\([0-9][0-9]*\).*/\1/p')
aliases_n=$(printf '%s' "$aliases_out" | sed -n 's/.*"migrated": *\([0-9][0-9]*\).*/\1/p')
CHANGED=$(( ${owners_n:-0} + ${states_n:-0} + ${areas_n:-0} + ${aliases_n:-0} ))

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

# --- the proposed half of every rename -----------------------------------------
# Carried through verbatim, like the decisions above: what the operator sees is the
# script's own counts and its own suggested command, not a paraphrase of them. An empty
# list means every declared rename has been converted here -- which is also the signal
# that the row can be deleted from the table (renames.tsv, *a migration record*).
CONVERSIONS=$(sh "${SCRIPT_DIR}/../../gather/scripts/rename-conversions.sh" "$ROOT" 2>/dev/null || printf '{"conversions": []}')
CONVERSIONS=$(printf '%s' "$CONVERSIONS" | sed -n 's/.*"conversions":[ ]*\[\(.*\)\][ ]*}.*/\1/p')

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

printf '{"before": %s, "applied": [%s], "after": %s, "decisions": [%s], "rename_conversions": [%s], "legacy_strategies": %s, "changed": %s, "conforming": %s}\n' \
    "$BEFORE" "$APPLIED" "$AFTER" "$DECISIONS" "$CONVERSIONS" "$LEGACY_STRATEGIES" "$CHANGED" "$CONFORMING"
