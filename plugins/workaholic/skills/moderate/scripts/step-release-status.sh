#!/bin/sh -eu
# Step 8 — what has landed on the base and not yet reached a deployment target.
#
# WHERE IT CAME FROM. Until 2026-08-19 this was a routine of its own,
# `[Prepare Release]`, firing at `:45` and posting a `📦 Release Preparation`
# line. It was merged into this tick on the developer's instruction, because the
# question it answers — what is waiting, and on whom — is the same question the
# rest of these steps ask about the repository's progress.
#
# IT POSTS NOTHING, AND THAT IS THE POINT. Measured on `#dev-workaholic`,
# 2026-08-19: ten `📦` lines in ten consecutive hours, each restating a growing
# commit count, none answered by anyone. A status line addressed to nobody is
# noise whatever its dedup key. This step writes a log row; if the state is worth
# a person's attention it becomes a QUESTION at step 10, addressed to somebody,
# with the options named. The two gates the old routine carried (`deploy:<digest>`
# and `deploy-day:<day_token>`) are gone with the post they gated.
#
# IT READS AND NEVER WRITES. `report-deploy-status.sh` freshens the base branch
# and tags before deriving the boundary from them (bounded, best-effort) and
# reports `refs: fresh|stale|skipped`. A boundary derived from refs it could not
# freshen is `doubtful`, and this step says so instead of reporting a count it
# does not trust.
#
# Usage: step-release-status.sh --tick <id> --root <repo-root>
# Output: one JSON line {"step","status","reason","summary","needs_agent":[...],"targets":[...]}

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
REPORT="${SCRIPT_DIR}/../../ship/scripts/report-deploy-status.sh"

while [ $# -gt 0 ]; do
    case "$1" in
        --tick|--root) shift 2 ;;
        *) shift ;;
    esac
done

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

if [ ! -f "$REPORT" ]; then
    printf '{"step": "release-status", "status": "degraded", "reason": "reader_missing", "summary": "report-deploy-status.sh is not present in this checkout", "needs_agent": [], "targets": []}\n'
    exit 0
fi

out=$(sh "$REPORT" 2>/dev/null || true)

case "$out" in
    *'"ok": true'*) ;;
    *)
        reason=$(printf '%s' "$out" | sed 's/.*"reason": "//; s/".*//')
        [ -n "$reason" ] || reason=unreadable
        printf '{"step": "release-status", "status": "degraded", "reason": "%s", "summary": "the deploy state could not be read — what is waiting is unknown this tick", "needs_agent": [], "targets": []}\n' \
            "$(json_escape "$reason")"
        exit 0
        ;;
esac

actionable=$(printf '%s' "$out" | sed 's/.*"actionable": //; s/,.*//')
doubtful=$(printf '%s' "$out" | sed 's/.*"doubtful": //; s/,.*//')
refs=$(printf '%s' "$out" | sed 's/.*"refs": "//; s/".*//')
refs_reason=$(printf '%s' "$out" | sed 's/.*"refs_reason": "//; s/".*//')
count=$(printf '%s' "$out" | sed 's/.*"count": //; s/,.*//')

# A count derived from refs the reader could not freshen is withheld, never
# rendered — two containers holding different stale refs would otherwise report
# two different truths about one base.
if [ "$doubtful" = "true" ]; then
    printf '{"step": "release-status", "status": "degraded", "reason": "doubtful", "summary": "refs not freshened (%s) — the waiting count is withheld rather than guessed", "needs_agent": ["release-status-doubtful"], "targets": []}\n' \
        "$(json_escape "$refs_reason")"
    exit 0
fi

if [ "$actionable" != "true" ]; then
    printf '{"step": "release-status", "status": "ok", "reason": "", "summary": "%s deployment target(s), nothing waiting to reach production (refs: %s)", "needs_agent": [], "targets": []}\n' \
        "$count" "$(json_escape "$refs")"
    exit 0
fi

# Per target: what it is waiting for. `needs` is the reader's own word list
# (`release`, `confirmation_method`, …), carried through rather than re-derived.
waiting=$(printf '%s' "$out" | awk '{ gsub(/},/, "},\n"); print }' | grep '"needs": \[' | grep -v '"needs": \[\]' || true)
n=$(printf '%s' "$waiting" | awk 'NF { n++ } END { print n + 0 }')

if [ "$n" -eq 0 ]; then
    printf '{"step": "release-status", "status": "ok", "reason": "", "summary": "%s deployment target(s), none reporting an unmet need (refs: %s)", "needs_agent": [], "targets": []}\n' \
        "$count" "$(json_escape "$refs")"
    exit 0
fi

slugs=$(printf '%s' "$waiting" | sed 's/.*"slug": "//; s/".*//' | tr '\n' ' ' | sed 's/ $//')
summary="${n} deployment target(s) waiting: $(printf '%s' "$slugs" | sed 's/ /, /g') — a question for step 10, never a status post"

# THE REFS WORD IS TRANSPORT-DERIVED AND NO LONGER RIDES THIS COMPARED SUMMARY
# (2026-09-01, ticket `20260901122448-name-every-step-summary-carrying-transport-derived-
# volatility`). This row is `blocked`, so it enters `render-tick-post.sh`'s IMPAIRMENT diff,
# which compares `(step, status, stabilized summary)` — and `refs` reads `fresh` or `stale`
# purely by whether one bounded fetch succeeded, which flips on a slow network with the base
# and the targets unmoved. Every flip opened a root saying nothing had happened.
#
# NOTHING IS LOST. The count that a doubtful read would make untrustworthy is already
# withheld above under its own `degraded`/`doubtful` row, which is where a reader learns the
# refs were not fresh; `refs` stays on the reader's own output for any caller that wants it.
# The two `ok` rows above keep it: this step supplies no `event`, so an `ok` row renders no
# change line, and an `ok` row is not impairment — neither of them can open a root at all.
# What stays here is the repository fact: how many targets are waiting, and which.
printf '{"step": "release-status", "status": "blocked", "reason": "waiting", "summary": "%s", "needs_agent": ["release-status-waiting"], "targets": [%s]}\n' \
    "$(json_escape "$summary")" \
    "$(printf '%s' "$slugs" | tr ' ' '\n' | awk 'NF { printf "%s\"%s\"", (n++ ? ", " : ""), $0 }')"
