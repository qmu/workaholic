#!/bin/sh -eu
# Does the committed identity mapping cover the addresses this tree actually uses? Pure read.
#
#   audit-identity-coverage.sh [repo-root]
#
# Output (one JSON line):
#   {"map": {"present": true|false, "path": ".claude/git-identities"},
#    "addresses": N,
#    "covered": N,
#    "uncovered": [{"address": "...", "artifacts": N, "line": "<login>=<address>"}, ...],
#    "problems": [...]}
#
# WHY THIS EXISTS (2026-08-26). `migrate-assignee-aliases.sh` recovers the addresses the
# mapping CAN resolve. It reports the rest by name and stops, correctly — an address no
# entry covers is a person the tree knows about and the mapping does not, and inventing the
# entry is the guess the whole change refuses. That report needed a home a human reads, and
# `/workaholify` is the preparation command: it audits, then applies.
#
# EVERY UNCOVERED ADDRESS IS NAMED WITH THE LINE THAT WOULD COVER IT. A report naming a
# problem without its repair leaves an operator guessing at the format — and the format is
# exactly what they would have to guess, since the mapping's second field is new. The login
# half of the proposed line is a `<login>` PLACEHOLDER, never a name this script picked:
# which GitHub account an address belongs to is a fact only a human has.
#
# A MAPPING'S CONTENTS ARE THE OPERATOR'S, NOT THIS PLUGIN'S. This script only reads. The
# apply lives in `apply-bootstrap.sh`, takes the same single confirmation every other repair
# takes, and writes only the mapping; an unwritable mapping refuses with nothing written,
# exactly as `settings_unparseable` / `hook_source_missing` / `unwritable` already do.
#
# `assignees: []` IS NOT AN UNCOVERED ADDRESS. Team-owned work names nobody, so a repository
# whose queue is legitimately team-owned has nothing to cover and must not be reported as
# though it did.
#
# ONE CHECK, NOT TWO (the coordination this ticket owed). The queued ticket
# `install-and-audit-the-identity-mapping` asks `check-bootstrap.sh` for the mapping's
# EXISTENCE check; this asks for its COVERAGE. An operator told twice about one file, in two
# vocabularies, fixes one and assumes the other followed — so both are one named-problem set,
# emitted here and surfaced through `check-bootstrap.sh`'s own `problems[]`:
# `identity_map_missing` (the file is absent — step 0b of the web bootstrap is then a
# permanent no-op) and `identity_map_uncovered` (the file exists and does not name an address
# the tree uses). A later session driving that queued ticket should EXTEND this set rather
# than add a rival one.

set -eu

ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
IDENTITY="${SCRIPT_DIR}/../../gather/scripts//identity.sh"
READ_ASSIGNEES="${SCRIPT_DIR}/../../gather/scripts//read-assignees.sh"

MAP_REL=".claude/git-identities"
MAP="${ROOT}/${MAP_REL}"

map_present=false
[ -f "$MAP" ] && map_present=true

# Collect every `assignees:` value the tree carries, through the field's one parser. The
# three areas are the three that carry the field.
addresses=""
for area in tickets missions strategies; do
    [ -d "${ROOT}/.workaholic/${area}" ] || continue
    for file in $(find "${ROOT}/.workaholic/${area}" -name '*.md' -type f | sort); do
        owners=$(sh "$READ_ASSIGNEES" "$file" 2>/dev/null || true)
        [ -n "$owners" ] || continue
        for owner in $owners; do
            addresses="${addresses}${owner}
"
        done
    done
done

total=0
covered=0
uncovered=""
u_sep=""

for address in $(printf '%s' "$addresses" | sort -u); do
    n=$(printf '%s' "$addresses" | grep -c "^${address}\$" || true)
    [ -n "$n" ] || n=0
    total=$((total + 1))

    answer=$(sh "$IDENTITY" "$address" "$MAP" 2>/dev/null || true)
    resolved=$(printf '%s' "$answer" | sed -n 's/.*"resolved": *\([a-z]*\).*/\1/p')

    if [ "$resolved" = "true" ]; then
        covered=$((covered + 1))
    else
        # The proposed line carries a `<login>` placeholder on purpose: which account an
        # address belongs to is the operator's knowledge, not this script's.
        uncovered="${uncovered}${u_sep}{\"address\": \"${address}\", \"artifacts\": ${n}, \"line\": \"<login>=${address}\"}"
        u_sep=", "
    fi
done

problems=""
p_sep=""
if [ "$map_present" = "false" ]; then
    problems="\"identity_map_missing (${MAP_REL} does not exist; the web bootstrap's identity step is a permanent no-op)\""
    p_sep=", "
fi
if [ -n "$uncovered" ]; then
    n_unc=$(printf '%s' "$uncovered" | tr ',' '\n' | grep -c '"address"' || true)
    [ -n "$n_unc" ] || n_unc=0
    problems="${problems}${p_sep}\"identity_map_uncovered (${n_unc} address(es) this tree uses are named by no mapping entry)\""
fi

printf '{"map": {"present": %s, "path": "%s"}, "addresses": %d, "covered": %d, "uncovered": [%s], "problems": [%s]}\n' \
    "$map_present" "$MAP_REL" "$total" "$covered" "$uncovered" "$problems"
