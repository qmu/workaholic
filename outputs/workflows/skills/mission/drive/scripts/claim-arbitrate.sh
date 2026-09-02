#!/bin/sh -eu
# THE ARBITER: one ref per claimed artifact, created at the remote, so a claim race is
# settled by the server rather than by two clocks.
#
#   claim-arbitrate.sh take    <artifact-rel>...   # win them all, or win none
#   claim-arbitrate.sh release <artifact-rel>...   # give them back
#   claim-arbitrate.sh refname <artifact-rel>      # the ref this artifact contends on
#   claim-arbitrate.sh reap                        # release locks no live claim stands behind
#
# Output: one JSON line, exit 0 in EVERY case including every refusal:
#   {"arbitrated": true|false, "state": "won"|"lost"|"unavailable"|"released",
#    "reason": "", "refs": [...], "held_by_ref": "", "stale_lock": false}
#
# ═══ WHY THIS EXISTS ═════════════════════════════════════════════════════════════════
# MEASURED 2026-08-30: `work-20260830-055314` and `work-20260830-055318` were both claimed
# for one unit, four seconds apart, and each drove the same four tickets for over an hour.
# `claims.md` said *the protocol settles a race by the push*, and that was true only for
# `claim.sh resume`, which contends on a branch that already exists. A FRESH claim mints
# `work-$(date +%Y%m%d-%H%M%S)`, so two runners that survey before either pushes name **two
# different refs**, both pushes succeed, and nothing anywhere says the unit was driven twice.
#
# ═══ THE REF IS DERIVED FROM THE ARTIFACTS, NOT FROM THE UNIT ID ═════════════════════
# The ticket proposed "a ref derived from the unit id". That reaches ONE grain: `claim.sh`
# mints `batch-<timestamp>` INSIDE the claim act, so two runners racing over the same tickets
# would push two different unit-keyed refs and both would still win — the defect, one layer
# down. The artifacts are what two racing runners actually share, and they are what §3's
# existing overlap refusal already keys on, so one ref per artifact settles BOTH grains:
# a mission contends on its own `mission.md`, a batch on each of its tickets.
#
# ═══ ALL OR NOTHING ══════════════════════════════════════════════════════════════════
# `take` wins every ref or releases the ones it won and reports `lost`. A partial hold would
# leave two runners each holding half a batch, which is the race with extra steps.
#
# ═══ WHERE THE TRANSPORT REFUSES, IT DEGRADES ════════════════════════════════════════
# MEASURED 2026-08-30 and again 2026-08-31 from a routine-fired container: `refs/claims/*`,
# `refs/tags/*` and `refs/notes/*` all answer `HTTP 403` over both sanctioned transports, and
# `refs/heads/*` takes a create and refuses the delete. That is a property of the CLOUD
# ROUTINE'S PROXY, not of the repository — RE-MEASURED 2026-09-02 from the developer's own
# server, where the loop now runs (`workaholic:loops`): `refs/claims/*` create, create-only
# lease, compare-and-swap and delete all succeed, confirmed by `ls-remote` each time, with no
# residue. Both readings are true of their own environment, so this script does not choose
# between them: it tries, and a refusal answers **`unavailable`**, which `claim.sh` reports
# and proceeds through exactly as it did before this mechanism existed. The Web-routine
# fallback therefore behaves byte-for-byte as it does today, and the local loop gains the
# arbitration. NOTHING HERE IS EVER A HARD STOP: a claim that cannot arbitrate is still the
# claim protocol as it stood on 2026-09-01, with `archive.sh`'s re-derivation and
# `/moderate`'s `raced-units` question as the bounded-later repair.
#
# ═══ A LOCK IS A LOCK, AND A LEAK IS REPORTED RATHER THAN TAKEN OVER ═════════════════
# `claim.sh` reaches this only after the oracle has already said nothing holds these
# artifacts, so an existing ref means one of two things: a run won the arbitration seconds
# ago and has not pushed its branch yet (the very window this closes), or a run died inside
# that window and leaked the lock. They are indistinguishable at that instant, and taking the
# lock over on the guess would reopen the race — so the ref is honoured and the answer
# carries **`stale_lock: true`** when the oracle disagrees, for a person to act on. The
# common cause is removed instead: `claim.sh` releases what it won on any later failure, and
# every path that releases a claim releases the refs (`reference/claims.md`, *What the claim
# contends for*). THE RESIDUAL COST, STATED: a process killed between winning a ref and
# pushing its branch leaves a lock somebody must release; that is seconds of exposure against
# an hour of duplicated driving.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cmd="${1:-}"
[ -n "$cmd" ] || { printf '{"arbitrated": false, "state": "unavailable", "reason": "no_command", "refs": [], "held_by_ref": "", "stale_lock": false}\n'; exit 0; }
shift 2>/dev/null || true

# The one derivation of an artifact's ref name. Git forbids a path component starting with
# `.`, so `.workaholic/...` cannot be a ref path as it stands; every character outside the
# portable set becomes `-`, the leading separators are stripped and a `.md` suffix dropped.
# It is READABLE on purpose — a person looking at `ls-remote` should see which artifact a
# lock stands for without decoding a hash.
_refname() {
    printf 'refs/claims/artifact/%s' "$(
        printf '%s' "${1%.md}" \
            | sed 's/[^A-Za-z0-9._-]/-/g; s/^[.-]*//; s/\.*$//'
    )"
}

if [ "$cmd" = "refname" ]; then
    printf '%s\n' "$(_refname "${1:-}")"
    exit 0
fi

_json_refs() { # $1 = newline-separated refs
    printf '%s' "$1" | grep . 2>/dev/null | sed 's/.*/"&"/' | paste -sd, - 2>/dev/null || printf ''
}

_emit() { # $1 state, $2 reason, $3 refs, $4 held_by_ref, $5 stale
    printf '{"arbitrated": %s, "state": "%s", "reason": "%s", "refs": [%s], "held_by_ref": "%s", "stale_lock": %s}\n' \
        "$([ "$1" = "won" ] && printf true || printf false)" \
        "$1" "$2" "$(_json_refs "$3")" "$4" "$5"
    exit 0
}

# ═══ THE REAP — WHY A LOCK CANNOT BE ETERNAL ═════════════════════════════════════════
# A ref nothing deletes makes an artifact claimable exactly once, forever — the regression the
# ticket names as worse than the race. `release-claim.sh` and `retire-claim.sh` give their
# locks back explicitly, but the THIRD release path is a **merge**, and nothing runs in the
# container at merge time: `delete_branch_on_merge` removes the branch and knows nothing about
# these refs. So the locks are also swept, on two terms that are both decidable:
#
#   1. **No live claim stands behind it** — the oracle (`lib/claims.sh`, pushed `work-*`
#      branches) is the authority on what is claimed, and a lock whose artifact no claim holds
#      is standing for nothing.
#   2. **It is older than the arbitration window** — `WORKAHOLIC_CLAIM_ARBITER_STALE_MINUTES`,
#      default 10. Between winning a lock and pushing the branch there are seconds in which
#      term 1 is true of a perfectly healthy claim; the age is what keeps the sweep from
#      eating it. The arbiter commit carries its own committer date, so no store is added.
#
# It is run by `claim.sh` before it arbitrates — the one caller that has already fetched and
# scanned, so the sweep costs one `ls-remote` and, in the ordinary case, zero deletes.
if [ "$cmd" = "reap" ]; then
    stale_minutes="${WORKAHOLIC_CLAIM_ARBITER_STALE_MINUTES:-10}"
    now=$(date +%s)
    held=""
    if [ -f "${SCRIPT_DIR}/lib/claims.sh" ]; then
        . "${SCRIPT_DIR}/lib/claims.sh"
        _rows=$(claims_scan "origin/main" 2>/dev/null || printf '')
        held=$(printf '%s\n' "$_rows" | awk -F'\t' 'NF > 1 { print $10 }' | tr ',' '\n' | grep . || printf '')
    fi
    held_refs=""
    for h in $held; do held_refs="${held_refs}$(_refname "$h")
"; done
    reaped=""
    for line in $(git ls-remote origin 'refs/claims/artifact/*' 2>/dev/null | awk '{print $2 "|" $1}' || printf ''); do
        r="${line%%|*}"; sha="${line#*|}"
        printf '%s\n' "$held_refs" | grep -qx "$r" && continue
        # A LOCK WE CANNOT DATE IS LEFT ALONE. The object may not be local, and fetching it to
        # judge an age would make a sweep the most expensive read in the protocol.
        ct=$(git log -1 --format=%ct "$sha" 2>/dev/null || printf '')
        [ -n "$ct" ] || continue
        [ $(( (now - ct) / 60 )) -ge "$stale_minutes" ] || continue
        git push origin ":${r}" >/dev/null 2>&1 || continue
        reaped="${reaped}${r}
"
    done
    _emit released reaped "$reaped" "" false
fi

[ $# -gt 0 ] || _emit unavailable no_artifacts "" "" false

base_sha=$(git rev-parse origin/main 2>/dev/null || git rev-parse HEAD 2>/dev/null || printf '')
[ -n "$base_sha" ] || _emit unavailable no_base_ref "" "" false

wanted=""
for rel in "$@"; do
    [ -n "$rel" ] || continue
    wanted="${wanted}$(_refname "$rel")
"
done
wanted=$(printf '%s' "$wanted" | grep . || printf '')
[ -n "$wanted" ] || _emit unavailable no_artifacts "" "" false

if [ "$cmd" = "release" ]; then
    released=""
    for r in $wanted; do
        git push origin ":${r}" >/dev/null 2>&1 || true
        released="${released}${r}
"
    done
    _emit released "" "$released" "" false
fi

[ "$cmd" = "take" ] || _emit unavailable "bad_command:${cmd}" "" "" false

# THE VALUE MUST BE UNIQUE PER CLAIMANT, and finding that out cost a real bug. A ref is a
# lock here, so the obvious value is the base sha — but git treats a push of the value a ref
# ALREADY HOLDS as `Everything up-to-date` and exits 0, so with a shared value the second
# claimant "wins" a lock somebody else is holding. MEASURED 2026-09-02 against this
# repository: two successive `take`s of one artifact both answered `won`. So each `take`
# mints one commit of its own (`commit-tree` over the base tree, with a message no other
# claimant can produce) and pushes THAT: the values differ, and
# `--force-with-lease=<ref>:` — an EMPTY expected value, meaning *this ref must not exist at
# the remote* — then genuinely arbitrates. Verified in the same session: the second
# create-only push is rejected `stale info` and the ref keeps the winner's value.
_uniq=$(git commit-tree "${base_sha}^{tree}" -p "$base_sha" \
    -m "Arbitrate a claim $$ $(date +%s%N) ${WORKAHOLIC_CLAIM_ARBITER_NONCE:-}" 2>/dev/null || printf '')
[ -n "$_uniq" ] || _emit unavailable no_arbiter_object "" "" false

won=""
_unwind() {
    for _u in $won; do git push origin ":${_u}" >/dev/null 2>&1 || true; done
}

for r in $wanted; do
    _out=$(git push --force-with-lease="${r}:" origin "${_uniq}:${r}" 2>&1) && {
        won="${won}${r}
"
        continue
    }
    # WHY THE REFUSAL IS CLASSIFIED RATHER THAN COUNTED. A rejected lease means somebody else
    # holds the lock — the mechanism working. A transport refusal means the mechanism is not
    # available here at all, and the caller must proceed as it did before. Reporting one as
    # the other would either strand every claim in a cloud container or hide a real race.
    _unwind
    case "$_out" in
        *"stale info"*|*"[rejected]"*|*non-fast-forward*)
            _emit lost held_by_another "" "$r" "$(
                # The oracle has already said nothing holds these artifacts, so a lock that
                # stands here is either the seconds-long window or a leak. Say which is
                # suspected; never act on the suspicion.
                printf true )" ;;
        *403*|*"not permitted"*|*"denied"*|*"cannot lock ref"*|*"pre-receive hook declined"*)
            _emit unavailable transport_refused "" "" false ;;
        *)
            _emit unavailable "push_failed" "" "" false ;;
    esac
done

_emit won "" "$won" "" false
