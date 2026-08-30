#!/bin/sh -eu
# Rewrite an `assignees:` entry that names a person's ALIAS address to that person's
# CANONICAL one — the living migration that recovers work already written under an
# address the loop cannot drive.
#
# WHY A MIGRATION AND NOT A HAND EDIT (2026-08-26). `identity.sh` teaches the tree that
# two addresses are one person, and `owns.sh` reads it — but neither rewrites what is
# already written, and the defect had been producing artifacts for five days: measured on
# this repository, two active missions and five queued tickets carried a developer's second
# address while the committed mapping named their first, so `plan-units.sh` excluded all
# seven as `owned_by_other`. A hand edit fixes one tree and leaves every other repository
# to discover the same defect on its own; registered at `/workaholify`'s converge seam,
# this reaches a consuming repository when it converges rather than when somebody
# remembers to tell it.
#
# IT TOUCHES NOTHING IT CANNOT RESOLVE, and reports every entry it left alone by name. An
# address absent from the mapping is somebody the tree knows about and the mapping does
# not — rewriting it would be exactly the guess `/specificate`'s writer-side rule refuses,
# and an address changed wrongly is silently unrecoverable while one left alone is merely
# still excluded. So: only an entry the mapping names AS AN ALIAS moves, only onto that
# entry's canonical address, and everything else is reported.
#
# THREE AREAS, because those are the three that carry `assignees:` —
# `.workaholic/tickets/`, `.workaholic/missions/` and `.workaholic/strategies/`.
#
# A STRATEGY'S `assignees:` IS THE ONE FIELD WHERE EMPTY IS A REFUSAL rather than
# team-owned (`hooks/validate-strategy.sh`). This migration rewrites an alias to a
# canonical address and never empties a field, so it cannot produce an invalid strategy —
# asserted in the suite rather than relied on, since a strategy this migration emptied
# would be rejected by its own write floor.
#
# STAGE, NEVER COMMIT, and never touch the caller's index beyond the files it rewrote:
# the existing migrations' discipline, for the reason `migrate-concerns.sh`'s header
# records — a migration that resets or sweeps an index discards whatever the caller had
# staged before calling it.
#
# IDEMPOTENT: an entry already canonical is left byte-identical, so a second consecutive
# run reports `migrated: 0` and every write seam can call it unconditionally.
#
# Usage: migrate-assignee-aliases.sh [workaholic-root]   (default .workaholic)
# Output: {"migrated": N,
#          "rewrites": [{"file": ..., "from": ..., "to": ...}, ...],
#          "unresolved": [{"file": ..., "address": ..., "reason": ...}, ...]}
#         `unresolved` names every address no mapping entry covers — the audit
#         (`workaholify/scripts/audit-identity-coverage.sh`) is where an operator is
#         offered the line that would cover it.

set -eu

SCRIPT_DIR=$(dirname "$0")
ROOT="${1:-.workaholic}"

rewrites=""
unresolved=""
count=0
rsep=""
usep=""

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

emit() {
    printf '{"migrated": %s, "rewrites": [%s], "unresolved": [%s]}\n' "$count" "$rewrites" "$unresolved"
}

if [ ! -d "$ROOT" ]; then
    emit
    exit 0
fi

for area in tickets missions strategies; do
    [ -d "${ROOT}/${area}" ] || continue

    for file in $(find "${ROOT}/${area}" -name '*.md' -type f | sort); do
        owners=$(sh "${SCRIPT_DIR}/read-assignees.sh" "$file" 2>/dev/null || true)
        [ -n "$owners" ] || continue

        changed=0
        new_owners=""
        for owner in $owners; do
            answer=$(sh "${SCRIPT_DIR}/identity.sh" "$owner" 2>/dev/null || true)
            resolved=$(printf '%s' "$answer" | sed -n 's/.*"resolved": *\([a-z]*\).*/\1/p')
            canonical=$(printf '%s' "$answer" | sed -n 's/.*"canonical": "\([^"]*\)".*/\1/p')
            reason=$(printf '%s' "$answer" | sed -n 's/.*"reason": "\([^"]*\)".*/\1/p')

            if [ "$resolved" = "true" ] && [ -n "$canonical" ] && [ "$canonical" != "$owner" ]; then
                # An alias the mapping names: the one case that moves.
                keep="$canonical"
                changed=1
                rewrites="${rewrites}${rsep}{\"file\": \"$(json_escape "$file")\", \"from\": \"$(json_escape "$owner")\", \"to\": \"$(json_escape "$canonical")\"}"
                rsep=", "
            else
                keep="$owner"
                if [ "$resolved" != "true" ]; then
                    # Somebody the tree knows about and the mapping does not. Named,
                    # never guessed at — the repair is a human's line in the mapping.
                    unresolved="${unresolved}${usep}{\"file\": \"$(json_escape "$file")\", \"address\": \"$(json_escape "$owner")\", \"reason\": \"$(json_escape "${reason:-no_entry}")\"}"
                    usep=", "
                fi
            fi

            if [ -z "$new_owners" ]; then new_owners="$keep"; else new_owners="${new_owners}, ${keep}"; fi
        done

        [ "$changed" -eq 1 ] || continue

        # Rewrite the FRONTMATTER's `assignees:` line only — the first one, in the
        # frontmatter block, exactly as read-assignees.sh reads it. A body line starting
        # `assignees:` is prose and must not move.
        tmp="${file}.migrate-assignee-aliases.$$"
        awk -v repl="assignees: [${new_owners}]" '
        NR == 1 { print; if ($0 != "---") { passthrough = 1 } ; next }
        passthrough { print; next }
        done_fm { print; next }
        /^---[ \t]*$/ { done_fm = 1; print; next }
        /^assignees:[ \t]*/ { if (!written) { print repl; written = 1; next } ; print; next }
        { print }
        ' "$file" > "$tmp"

        mv "$tmp" "$file"
        git add -- "$file" >/dev/null 2>&1 || true
        count=$((count + 1))
    done
done

emit
