#!/bin/sh -eu
# Which of a step's claimed filings actually landed — read from the artifacts, not the claim.
#
# WHY (2026-08-23). On the measured tick `persist-log.sh` reported both records `filed` and
# `persisted`, and the log reached the base — while the base carried the tick's log section
# and **not one record**. Every mechanism reported success. The next tick then read
# `inbound-sweep-filed` and `issue-triage-filed` out of the log, concluded both findings were
# already captured, and did not re-derive them. The loss compounds: the finding is neither
# published nor recoverable, and the dedup actively prevents a second chance at it.
#
# THE DEFECT WAS KEYING ON A LINE RATHER THAN ON THE ARTIFACT THE LINE CLAIMS. A
# `<step>-filed` line is a claim written before the artifact was known to have landed, and
# `log-read.sh` cannot tell a claim from a fact. This reader closes that: it takes the paths a
# line names and asks the tree whether they are there.
#
# WHY THE TREE IS THE ORACLE, AND WHY THAT IS ENOUGH. A routine's container is a fresh clone
# of the base, so a record present in the checkout is a record on the base — the same
# equivalence `persist-log.sh` relies on in the other direction. No network call, no second
# store, and it works on lines **already** on the base, which matters because the log is
# append-only and those lines cannot be corrected.
#
# IT NEVER WRITES. The log stays append-only and no line already on the base is rewritten;
# what changes is only what a line is allowed to prove.
#
# THE WRITER'S HALF OF THE CONTRACT: a `<step>-filed` summary names the repo-relative path of
# each artifact it filed. A line naming no path yields no landed filings here — it claims
# nothing this reader can check, and treating an uncheckable claim as a fact is the defect.
#
# Usage: filed-records.sh --step <step-slug> [--root <repo-root>]
# Output: one JSON line
#   {"step": "...", "landed": ["<path>", ...], "unlanded": ["<path>", ...],
#    "claims": <n>, "readable": true|false}
#
#   landed    the line named it and it is in the tree — genuinely filed, dedup it
#   unlanded  the line named it and it is NOT in the tree — treat as NOT filed, re-derive
#   readable  false when the log could not be read at all; callers must not read that as
#             "nothing was filed", which is the same conflation this script exists to end

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOG_READ="${SCRIPT_DIR}/log-read.sh"

STEP=''
ROOT='.'
while [ $# -gt 0 ]; do
    case "$1" in
        --step) STEP="${2:-}"; shift 2 ;;
        --root) ROOT="${2:-.}"; shift 2 ;;
        *) shift ;;
    esac
done

emit() {
    printf '{"step": "%s", "landed": [%s], "unlanded": [%s], "claims": %s, "readable": %s}\n' \
        "$STEP" "${1:-}" "${2:-}" "${3:-0}" "${4:-true}"
    exit 0
}

[ -n "$STEP" ] || emit '' '' 0 false
[ -f "$LOG_READ" ] || emit '' '' 0 false
# A ROOT THAT IS NOT THERE IS UNREADABLE, NOT EMPTY. `log-read.sh` returns its envelope
# either way, so without this a caller pointed at the wrong directory would be told nothing
# was ever filed — the same conflation of "could not look" with "nothing there" that this
# script exists to end. A repository that simply has no tick log yet is different and stays
# `readable: true` with zero claims.
[ -d "$ROOT" ] || emit '' '' 0 false

out=$(sh "$LOG_READ" --root "$ROOT" --step "${STEP}-filed" 2>/dev/null || true)
[ -n "$out" ] || emit '' '' 0 false
printf '%s' "$out" | jq -e . >/dev/null 2>&1 || emit '' '' 0 false

# Every `.workaholic/...` path any of those lines names. The paths are extracted rather than
# parsed out of a fixed position: a summary is prose a human also reads, and pinning a column
# in it would be the free-text dependency the already-asked gate was fixed off in the first
# place.
paths=$(printf '%s' "$out" | jq -r '[.entries[]?.summary] | join(" ")' 2>/dev/null \
    | tr ' \t,;()<>"' '\n' | sed -n 's|^\(\.workaholic/[A-Za-z0-9._/-]*\.md\)$|\1|p' | sort -u)

landed=''; unlanded=''; lsep=''; usep=''; n=0
for p in $paths; do
    [ -n "$p" ] || continue
    n=$((n + 1))
    if [ -f "${ROOT}/${p}" ]; then
        landed="${landed}${lsep}\"${p}\""; lsep=', '
    else
        unlanded="${unlanded}${usep}\"${p}\""; usep=', '
    fi
done

emit "$landed" "$unlanded" "$n" true
