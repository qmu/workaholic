#!/bin/sh
# WHOSE RUNNER IS THIS, WHERE THERE IS NO CONFIGURED IDENTITY (2026-08-29, mission
# `make-the-two-executors-agree-about-a-proved-empty-claim`).
#
# `lib/claims.sh` resolves the runner once, as `git config user.email`, and gates the whole
# verdict on it **first**: an empty value answers `identity_unresolved` for every claim, before
# ancestry, liveness or `superseded` is ever consulted. That is right in a container, where an
# absent identity means a takeover cannot be attributed and must not be attempted.
#
# It is wrong for the OTHER executor. `actions/checkout@v4` configures no `user.email`, so
# `claim-retirement.yml` read `identity_unresolved` for every claim, `superseded` was never
# reached, and `list-retirable-claims.sh` answered `ok: true` with `count: 0` — **byte-identical
# to a healthy, empty turn**. Measured 2026-08-29 on this repository: three proved-`superseded`
# branches standing since 2026-08-21 while `Claim Retirement` was green on every run. Reproduced
# offline by unsetting `user.email` alone: the container's own candidate count moves **3 → 0**.
#
# ═══ WHAT THIS DOES, AND THE THREE THINGS IT REFUSES TO DO ═══════════════════════════
# It answers one question — *which identity may this executor legitimately scan as, for this
# claim's author?* — and it answers it ONLY when there is no configured identity at all.
#
#   1. IT DOES NOT REORDER THE SHARED PRECEDENCE. `lib/claims.sh`'s gate order is untouched.
#      Consulting `superseded` before the identity gate would make a FOREIGN superseded claim
#      retirable, and the identity gate exists to protect exactly that.
#   2. IT DOES NOT MAKE CI SEE EVERY CLAIM AS ITS OWN. An author the committed
#      `.claude/git-identities` mapping does not name is refused — that address is somebody the
#      tree does not know, and impersonating it is the guess the mapping exists to remove
#      (`gather/scripts/identity.sh`, the one reader, answers `resolved: false`).
#   3. IT DOES NOT TOUCH A LIVE CLAIM. Identity is only the FIRST gate; `claim_active` still
#      outranks `superseded` in the shared precedence, so a claim whose tip is inside the
#      heartbeat window reads `claim_active` under any identity and stays untouchable.
#
# ═══ IT CHANGES NOTHING WHERE AN IDENTITY EXISTS ═════════════════════════════════════
# With `git config user.email` set — every container, every developer's checkout — this returns
# that value unchanged and the caller's behaviour is byte-for-byte what it was. The whole
# mechanism is reachable only from the state CI is in and no other.
#
# Sourced, never executed. Callers pass the resolved value to `lib/claims.sh` through
# `WORKAHOLIC_CLAIM_IDENTITY`, which defaults to `git config user.email` when unset.

# The identity this executor may scan as for a claim authored by $1, or empty when it may not
# scan as anybody. Never prints an address the mapping does not name.
runner_identity_for_author() {
    _rifa_author="${1:-}"

    _rifa_configured=$(git config user.email 2>/dev/null || true)
    if [ -n "$_rifa_configured" ]; then
        printf '%s' "$_rifa_configured"
        return 0
    fi

    [ -n "$_rifa_author" ] || return 0

    # `CLAIMS_LIB_DIR` is `drive/scripts/lib`, so the gather skill is three levels up — the
    # same hop `${SCRIPT_DIR}/../../gather/scripts` makes from `drive/scripts`, one deeper.
    _rifa_reader="${RUNNER_IDENTITY_READER:-${CLAIMS_LIB_DIR:-}/../../../gather/scripts/identity.sh}"
    [ -f "$_rifa_reader" ] || return 0

    _rifa_out=$(sh "$_rifa_reader" "$_rifa_author" 2>/dev/null || true)
    [ -n "$_rifa_out" ] || return 0
    printf '%s' "$_rifa_out" | jq -e '.resolved // false' >/dev/null 2>&1 || return 0

    printf '%s' "$_rifa_author"
}

# True when this executor has no configured identity of its own — the state that makes the
# resolution above reachable at all. Kept as a predicate so a caller never re-reads the config.
runner_identity_absent() {
    [ -z "$(git config user.email 2>/dev/null || true)" ]
}
