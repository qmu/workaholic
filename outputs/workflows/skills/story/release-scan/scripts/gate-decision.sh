#!/bin/sh -eu
# Map a scan-branch-safety.sh verdict (read on stdin) to a gate decision, so the tier
# policy is deterministic and testable rather than only prose:
#   - any finding            -> decision "block"
#   - any `hard` finding     -> overridable false (a secret is NEVER bypassable)
#   - only override/confirm  -> overridable true  (/ship may record an override)
#   - no findings            -> decision "pass"
#   - only `override`        -> override_only true (see below)
#   - NO READING AT ALL      -> decision "refuse", with the reason (see below)
#
# Usage: scan-branch-safety.sh ... | gate-decision.sh
#        gate-decision.sh < scan.json      <- a file is piped IN; see `bad_argument`
# Output: {"decision": "pass"|"block", "overridable": bool, "override_only": bool,
#          "hard": N, "confirm": N, "total": N}
#      or {"decision": "refuse", "reason": "<word>", "overridable": null,
#          "override_only": null, "hard": null, "confirm": null, "total": null}
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
# WHY A FIELD RATHER THAN EACH CONSUMER COUNTING SEVERITIES. Several consumers key on the
# tiers (`/ship`, `/drive`'s review route, the catch-up, the stranded-publication act) and
# another will. The counting is one line of `grep` each time, which is exactly how three
# copies of a rule drift into three rules; the point of this script has always been that
# the tier policy lives in one place.
#
# ---------------------------------------------------------------------------------------
# AN UNREAD SCAN REFUSES; IT NEVER PASSES (2026-09-18, ticket `20260918150931`). This
# script is the gate every merge the loop performs is read through, and its failure mode
# used to be `pass`: `decision` was gated on a TEXT-GREP count of `"category":` in the raw
# input, and every way of arriving here with no reading drove that count to zero, which is
# also what a clean branch looks like. MEASURED at `2a85aff9e`, all three answering
# `decision: "pass"`:
#
#   1. `printf '' | gate-decision.sh`                      -> pass, total 0
#   2. `gate-decision.sh <scan.json>` (a POSITIONAL path)  -> pass, total 0; the argument
#      was never read, so the caller believed its file had been judged
#   3. `{"verdict":"block","findings":[{"severity":"hard","rule":"secret"}]}` -> the
#      self-contradictory `{"hard": 1, ..., "decision": "pass", "total": 0}`
#
# and the same grep over-counted in the other direction: a `"category":` ANYWHERE in the
# input — outside `findings[]`, in a summary object, in an unescaped string from a drifted
# producer — inflated `total` into a false `block` with `override_only: true`. Measured:
# `{"verdict":"pass","findings":[],"summary":{"category":"none"}}` -> block.
#
# Both directions are removed by counting STRUCTURALLY: the findings array is parsed with
# `jq` and `decision` is derived from the SEVERITY COUNTS, never from `total`, so
# `decision: "pass"` beside a non-zero `hard` or `confirm` is unreachable by construction
# and needs no runtime self-check (a guard for an unreachable state says the derivation is
# not trusted; the suite asserts it instead).
#
# `refuse` is a THIRD WORD rather than a resolution to `block` or to `pass`. `block` means
# *findings were found*, and a `block` carrying `hard: 0, confirm: 0` satisfies the
# `override_only` rule, which is a merge licence for `/drive`'s `review` route — the
# permissive answer again, wearing the blocking word. Forcing `overridable: false` instead
# would make `/ship` report *a credential is in this diff* and send a developer hunting a
# secret that does not exist. `refuse` says the one true thing — no reading was made — and
# leaves the remedy (re-run the scan correctly) where it belongs.
#
# The counts on a refusal are `null`, NOT `0`: this repository's convention for a walk that
# could not complete (`classify-residue.sh`, `publication-age.sh`, and
# `commands/infinite-development.md`'s *readability precedes counting*). `0` reads as
# *counted, found none*, which is the very conflation this removes — and the nulls are
# load-bearing, because a consumer that reads a boolean licence cannot read a refusal as
# one.
#
# THE ONE LOAD-BEARING CHECK IS `no_scan_input`, AND THE OTHER REASONS ARE DIAGNOSTIC
# GRANULARITY, NOT SAFETY MECHANISMS. The requirement is: read ONE PARSEABLE SCAN OBJECT
# FROM STDIN, and refuse when you cannot, instead of mapping `total: 0` to `pass` before
# confirming an input existed. That single check closes BOTH entry doors on its own — a
# positional argument leaves stdin empty and therefore refuses as `no_scan_input` even with
# the argument check below removed. Do not build safety on any of the other five: each names
# *why* there was no usable reading, which is what turns a refusal a caller can act on out of
# one they have to investigate.
#
# The closed reason set, six words and no seventh:
#   no_scan_input         stdin was empty or whitespace only  <- the safety check
#   unparseable_input     stdin is not JSON
#   not_a_scan_verdict    JSON, but not one object whose `.findings` is an array
#   finding_unclassified  a `findings[]` element is not an object, or its `severity` is
#                         absent or outside the closed set `hard | confirm | override`
#   bad_argument          a positional argument was passed
#   jq_unavailable        `jq` is absent, or ran and failed
#
# `bad_argument` REFUSES A FILE PATH rather than accepting one. This script's contract is
# one stdin pipe and every call site pipes into it; accepting a path would create a second
# input route and, with both supplied, an ambiguity about which one was judged — and a gate
# with two input routes is exactly how a caller comes to believe it judged something it did
# not. The recovery costs one character: `gate-decision.sh < scan.json`. It earns its place
# by naming the mistake precisely — *your file was never read* — where `no_scan_input` would
# leave a caller holding a correct file and no explanation, which is exactly the position the
# near-miss caller below was in.
#
# THE NEAR MISS, because a permissive default that ships with a ready-made rationalisation is
# the real hazard. A caller passed a correct file positionally:
#
#   {"verdict":"block","findings":[{"rule":"too-large-commit","severity":"override",
#    "file":"d0f29157f","line":0,"detail":null}]}
#
# and got `{"decision":"pass",...,"total":0}`, exit 0. It was caught only because the same
# output block had already printed that file's one finding through `jq`, so *one finding* and
# *`total: 0`* sat side by side — and an explanation was immediately available and wrong:
# *the `override` tier is neither `hard` nor `confirm`, so of course it is not in `total`*.
# The merge outcome would have been identical; the RECORDED JUSTIFICATION would not — a false
# pass leaves a durable record saying the branch had zero findings when it had one. Piped, the
# same bytes answer `block` / `override_only: true` / `total: 1`, and passed positionally they
# now refuse. A silent wrong answer that supplies its own excuse is worse than one that looks
# wrong, which is why this is a defect in the gate and not a lesson for its callers.
#
# `decision` ALONE TELLS *READ NOTHING* FROM *READ AND FOUND NOTHING*. A refusal and a clean
# pass are never byte-identical and no consumer has to compare counts to learn which it got —
# which was the second fact the near miss established: nothing in the old output said whether
# an input had been read at all.
#
# EXIT STATUS IS 0 IN EVERY CASE, including every refusal — this repository's refusal
# convention, and every script consumer wraps the call in `|| printf ''`, so a non-zero exit
# would erase the reason word and land them on their generic empty-output path. The refusal
# object is the only way the reason survives.
#
# WHAT DID NOT MOVE, deliberately: `overridable` still keys on `hard` alone, `override_only`
# is still *findings exist and every one is `override`* (an empty finding set is `pass`, not
# `override_only`), `/ship`'s demotion doctrine is untouched, the `confirm` tier (`leak`) is
# NOT part of `override_only` — a leak is a boundary property a human rules on, not a
# granularity note — and `.findings[].category` is still emitted by the producer and read by
# `/story`, `publish-tree-pr.sh` and `land-unit.sh`; it is only no longer the axis this
# script counts on, `severity` being the correct one. `verdict` is deliberately NOT
# cross-checked against the counts: the findings array is the source of truth, and the
# producer's own summary word is not a second axis to disagree on.

set -eu

refuse() {
    printf '{"decision": "refuse", "reason": "%s", "overridable": null, "override_only": null, "hard": null, "confirm": null, "total": null}\n' "$1"
    exit 0
}

# Before reading anything: a positional argument is an input route this script does not
# have, and silently ignoring it is how a caller comes to believe its file was judged.
[ "$#" -eq 0 ] || refuse bad_argument

input=$(cat 2>/dev/null || true)

case "$(printf '%s' "$input" | tr -d '[:space:]')" in
    '') refuse no_scan_input ;;
esac

command -v jq >/dev/null 2>&1 || refuse jq_unavailable
# A jq that is present but broken is not a pass either, and proving it works here is what
# lets a parse failure below be attributed to the INPUT rather than to the tool.
printf '0' | jq -e . >/dev/null 2>&1 || refuse jq_unavailable

jq_status=0
reading=$(printf '%s' "$input" | jq -r -s 'if length != 1 then {"reason": "not_a_scan_verdict", "total": null, "hard": null, "confirm": null, "override": null}
    else .[0] as $v
        | if ($v | type) != "object" then {"reason": "not_a_scan_verdict", "total": null, "hard": null, "confirm": null, "override": null}
          elif ($v | has("findings") | not) or (($v.findings | type) != "array") then {"reason": "not_a_scan_verdict", "total": null, "hard": null, "confirm": null, "override": null}
          elif ([$v.findings[] | (type == "object") and (has("severity")) and ((.severity | type) == "string") and (.severity == "hard" or .severity == "confirm" or .severity == "override")] | any(. == false)) then {"reason": "finding_unclassified", "total": null, "hard": null, "confirm": null, "override": null}
          else {"reason": "ok",
                "total": ($v.findings | length),
                "hard": ([$v.findings[] | select(.severity == "hard")] | length),
                "confirm": ([$v.findings[] | select(.severity == "confirm")] | length),
                "override": ([$v.findings[] | select(.severity == "override")] | length)}
          end
    end
    | "\(.reason) \(.total) \(.hard) \(.confirm) \(.override)"' 2>/dev/null) || jq_status=$?

# Exit 3 is jq refusing to compile the program above — our own defect, never a statement
# about the input (`rules/shell.md`, *an embedded jq program that does not compile is our
# defect, never an empty answer*). Every other failure, and an empty answer, is the input.
[ "$jq_status" -ne 3 ] || refuse jq_unavailable
[ "$jq_status" -eq 0 ] || refuse unparseable_input
[ -n "$reading" ] || refuse unparseable_input

# Every token below comes from the closed vocabulary above, so word splitting is safe.
# shellcheck disable=SC2086
set -- $reading
reason=${1:-}
total=${2:-}
hard=${3:-}
confirm=${4:-}
override=${5:-}

[ "$reason" = ok ] || refuse "$reason"

decision=pass
overridable=true
override_only=false
# DERIVED FROM THE SEVERITY COUNTS, never from `total`: the two are read off one parsed
# array whose every severity is in the closed set, so they cannot disagree, and a `pass`
# beside a non-zero `hard` or `confirm` is unreachable rather than merely untested for.
if [ $((hard + confirm + override)) -gt 0 ]; then
    decision=block
    if [ "$hard" -gt 0 ]; then
        overridable=false
    fi
    # Findings, and every one of them the nudge tier. An empty finding set is NOT
    # `override_only` — "nothing was found" and "only granularity notes were found" are
    # different answers, and a consumer that conflated them would be making the same
    # mistake in the other direction.
    if [ "$hard" -eq 0 ] && [ "$confirm" -eq 0 ]; then
        override_only=true
    fi
fi

printf '{"decision": "%s", "overridable": %s, "override_only": %s, "hard": %s, "confirm": %s, "total": %s}\n' \
    "$decision" "$overridable" "$override_only" "$hard" "$confirm" "$total"
