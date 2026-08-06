#!/bin/sh -eu
# Answer "whose is this artifact, from where I stand" — the three-way ownership
# rule, in one place, for every artifact kind.
#
# The rule itself is not new: /drive's survey has applied it to missions since
# 2026-07-28 (mine -> claimable, unowned -> claimable, someone else's -> excluded
# as `owned_by_other`). What was new on 2026-08-06 (P2) is that a TICKET can be
# asked the same question, because its owner became a field instead of its
# directory — so the rule stopped being a mission-shaped special case and became
# the one thing every consumer reads.
#
# Usage: owns.sh <artifact-file> [identity]
#   identity defaults to `git config user.email`.
#
# Output: exactly one word on stdout.
#
#   mine        the identity is among the artifact's owners
#   unowned     the artifact names no owner — TEAM-OWNED, claimable by anyone
#   other       it is owned, and not by this identity
#   unresolved  it is owned, and this runner has no identity to compare against
#
# `unresolved` is deliberately its own answer rather than being folded into
# `other`. They imply the same conservative ACTION — do not offer the artifact —
# but they are different FACTS, and collapsing them is precisely the defect this
# whole change exists to remove: "I know this is somebody else's" and "I cannot
# tell whose this is" must never render identically to an operator reading a
# survey. A caller that only needs the action can treat them alike; a caller that
# reports must not.
#
# Comparison is by SLUG, not by string equality (gather/scripts/user-slug.sh).
# Two reasons, both load-bearing: `A@Qmu.jp` and `a@qmu.jp` are one person, and
# the living migration stamps an owner derived from a directory name, so a
# `assignees: [a-qmu-jp]` left by the migration must still match the runner's
# `a@qmu.jp`. Comparing raw strings would silently orphan every migrated ticket.

set -eu

FILE="${1:-}"
ME="${2:-}"

[ -n "$FILE" ] || { printf 'unowned\n'; exit 0; }
[ -f "$FILE" ] || { printf 'unowned\n'; exit 0; }

SCRIPT_DIR=$(dirname "$0")

owners=$(sh "${SCRIPT_DIR}/owners.sh" "$FILE" 2>/dev/null || true)
if [ -z "$owners" ]; then
    printf 'unowned\n'
    exit 0
fi

if [ -z "$ME" ]; then
    ME=$(git config user.email 2>/dev/null || true)
fi
if [ -z "$ME" ]; then
    printf 'unresolved\n'
    exit 0
fi

my_slug=$(sh "${SCRIPT_DIR}/user-slug.sh" "$ME" 2>/dev/null || true)
[ -n "$my_slug" ] || { printf 'unresolved\n'; exit 0; }

# Word splitting is safe here: an owner is an email or a slug, and neither can
# contain whitespace. A `while read` over a pipe would run the loop in a subshell,
# so the match could not be carried back out without the fragile `grep -q` idiom
# that `set -e` turns into an abort on no-match.
found=0
for owner in $owners; do
    owner_slug=$(sh "${SCRIPT_DIR}/user-slug.sh" "$owner" 2>/dev/null || true)
    if [ "$owner_slug" = "$my_slug" ]; then
        found=1
        break
    fi
done

if [ "$found" -eq 1 ]; then
    printf 'mine\n'
else
    printf 'other\n'
fi
