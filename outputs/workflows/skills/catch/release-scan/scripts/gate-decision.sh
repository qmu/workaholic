#!/bin/sh -eu
# Map a scan-branch-safety.sh verdict (read on stdin) to a gate decision, so the tier
# policy is deterministic and testable rather than only prose:
#   - any finding            -> decision "block"
#   - any `hard` finding     -> overridable false (a secret is NEVER bypassable)
#   - only override/confirm  -> overridable true  (/ship may record an override)
#   - no findings            -> decision "pass"
#   - only `override`        -> override_only true (see below)
#
# Usage: scan-branch-safety.sh ... | gate-decision.sh
# Output: {"decision": "pass"|"block", "overridable": bool, "override_only": bool,
#          "hard": N, "confirm": N, "total": N}
#
# `override_only` EXISTS BECAUSE A CONSUMER MUST NEVER KEY ON THE BINARY VERDICT, and one
# did (2026-08-21). `workaholic:release-scan` states the rule in its own words — "the
# SEVERITY tells the consumer how hard to block, and both consumers key on it — never on
# the binary verdict alone" — and says of the size tier that it is "a granularity nudge,
# not a hard block (hence `override`)" and that "a branch whose only findings are
# `override`-tier stays releasable". `/story` obeyed that. `/drive`'s `review` route did
# not: it read `verdict == "pass"` and therefore held a merge open on a finding its own
# scan classifies as a nudge.
#
# MEASURED, on a documentation repository consuming this plugin: a `review` unit carrying
# 42 documentation pages in two languages produced three `too-large-commit` findings
# (749 / 983 / 1119 added lines against a 500 ceiling) and nothing else. No mixed concerns,
# no secret, no leak — the line count was the shape of the work. The unit sat at an open
# pull request, and the run that reported it went on to ASK a human whether to merge, which
# `/implement` may never do. Both symptoms have one cause: a tier read as a verdict.
#
# WHY A FIELD RATHER THAN EACH CONSUMER COUNTING SEVERITIES. Three consumers now key on the
# tiers (`/ship`, `/story`, `/drive`'s review route) and a fourth will. The counting is one
# line of `grep` each time, which is exactly how three copies of a rule drift into three
# rules; the point of this script has always been that the tier policy lives in one place.
#
# WHAT DID NOT MOVE, deliberately: `decision` still blocks on any finding, `overridable`
# still keys on `hard` alone, `/ship`'s demotion doctrine is untouched, and the `confirm`
# tier (`leak`) is NOT part of `override_only` — a leak is a boundary property a human
# rules on, not a granularity note.

set -eu

input=$(cat 2>/dev/null || true)

total=$(printf '%s' "$input" | grep -oE '"category":' | grep -c . || true)
hard=$(printf '%s' "$input" | grep -oE '"severity":[ ]*"hard"' | grep -c . || true)
confirm=$(printf '%s' "$input" | grep -oE '"severity":[ ]*"confirm"' | grep -c . || true)

decision=pass
overridable=true
override_only=false
if [ "${total:-0}" -gt 0 ]; then
    decision=block
    if [ "${hard:-0}" -gt 0 ]; then
        overridable=false
    fi
    # Findings, and every one of them the nudge tier. An empty finding set is NOT
    # `override_only` — "nothing was found" and "only granularity notes were found" are
    # different answers, and a consumer that conflated them would be making the same
    # mistake in the other direction.
    if [ "${hard:-0}" -eq 0 ] && [ "${confirm:-0}" -eq 0 ]; then
        override_only=true
    fi
fi

printf '{"decision": "%s", "overridable": %s, "override_only": %s, "hard": %s, "confirm": %s, "total": %s}\n' \
    "$decision" "$overridable" "$override_only" "${hard:-0}" "${confirm:-0}" "${total:-0}"
