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
#
# A PERSON'S SECOND ADDRESS IS THE SAME PERSON, WHEN THE MAPPING SAYS SO
# (2026-08-26). The slug rule makes one SPELLING of an address one person; it
# cannot make two different addresses one person, because nothing told it they
# were. Both sides are now resolved through `gather/scripts/identity.sh` — the one
# reader of the committed `.claude/git-identities` mapping — BEFORE the existing
# slug comparison, so a mapped alias lands on the same canonical address and the
# comparison below answers `mine` unchanged. Measured: `tamurayoshiya=a@qmu.jp` was
# committed while two active missions and five queued tickets carried that person's
# other address, so this oracle answered `other` for all seven and `plan-units.sh`
# excluded them as `owned_by_other` for five days — including the mission whose own
# job was to repair the other half of the defect.
#
# EVERY OTHER ANSWER STAYS EXACTLY WHERE IT IS, and that is the whole care here.
# An address the mapping does not name still answers `other`; `unowned` and
# `unresolved` are untouched; the tier-3 tolerance is untouched; and with NO mapping
# file present identity.sh is the identity function, so every answer is
# byte-identical to what it was before this paragraph existed. The 2026-08-14
# incident — ~10 PR-units driven out of colleagues' queues — is why `other` is
# conservative, and the loosening is bounded by the committed mapping: only
# addresses ONE ENTRY names for ONE login become one person, and a colleague's
# address appears in no entry of the runner's. A mapping entry is a claim that two
# addresses are one person, and anyone who can commit can make it — the same trust
# boundary the file already carried for `<login>=<email>`, widened in what one entry
# can say rather than in who may say it.
#
# THIS IS NOT THE CHANGE `refuse-ok-under-a-placeholder-identity` SCOPED OUT. That
# mission's `## Scope` reads "Not `owns.sh`'s comparison, which is correct", and it
# is right about its own case: a container holding `noreply@anthropic.com`, a
# PLACEHOLDER, against which no comparison should answer `mine` at all. This is a
# different case — a real identity, a present mapping entry, and a second address
# of the same person. A placeholder gains no new way to answer `mine` here, because
# a placeholder appears in no entry. A later reader finding both statements should
# read them as two cases, not as one of them being stale.

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

# Resolve an address to its person's canonical address before slugging it. With no
# mapping file, no entry, or an unparseable line, identity.sh echoes its input back —
# the identity function — so this is a no-op wherever the mapping cannot answer.
canonicalize() {
    _out=$(sh "${SCRIPT_DIR}/identity.sh" "$1" 2>/dev/null || true)
    _canon=$(printf '%s' "$_out" | sed -n 's/.*"canonical": "\([^"]*\)".*/\1/p')
    if [ -n "$_canon" ]; then printf '%s\n' "$_canon"; else printf '%s\n' "$1"; fi
}

my_canonical=$(canonicalize "$ME")
my_slug=$(sh "${SCRIPT_DIR}/user-slug.sh" "$my_canonical" 2>/dev/null || true)
[ -n "$my_slug" ] || { printf 'unresolved\n'; exit 0; }

# Word splitting is safe here: an owner is an email or a slug, and neither can
# contain whitespace. A `while read` over a pipe would run the loop in a subshell,
# so the match could not be carried back out without the fragile `grep -q` idiom
# that `set -e` turns into an abort on no-match.
found=0
for owner in $owners; do
    owner_slug=$(sh "${SCRIPT_DIR}/user-slug.sh" "$(canonicalize "$owner")" 2>/dev/null || true)
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
