#!/bin/sh -eu
# Decide whether a failed `/fb` filing falls back to writing a feedback record.
#
#   <open-issue envelope on stdin> | fb-fallback.sh in-repo | crossing
#
# Emits: {"fallback": true|false, "reason": "<why>"}
#
# WHY THIS IS A SCRIPT AND NOT A SENTENCE. `/fb`'s primary path became a network call
# (mission `register-every-fb-as-an-issue`), and a degradation whose rule lives only in
# prose is a rule each session re-derives under exactly the conditions — a refusal, a
# 503, a missing `gh` — where re-deriving it is least reliable. The decision is one
# comparison, so it is written once, here, where a hermetic case can drive it off a
# stubbed envelope with no `gh` and no network.
#
# THE FALLBACK IS THE IN-REPO PATH ONLY, and that asymmetry is the whole point of taking
# the destination as an argument rather than reading the envelope alone. A refusal from a
# DIFFERENT repository — issues disabled, no access for this identity — is that target's
# own decision about its boundary; it is reported verbatim and never worked around, and
# writing a local record about it would be a different act from the one the caller asked
# for. On the in-repo path there is no boundary and no other party: the ask is ours, the
# only question is whether we lose it.
#
# WHAT A `true` COSTS, stated here because the caller must report it: a fallback record is
# NOT discovered by `[Specificate]`, whose discovery reads open issues rather than files
# (`propose/scripts/list-inbound-issues.sh`). The ask is captured but not proposed until
# someone files it or re-runs. That is a deliberate limit, not an oversight — the
# alternative is a sweep that re-reads local records looking for something to propose,
# which is the retired `[Propose Batch]` design.
#
# A SUCCESSFUL FILING NEVER ALSO WRITES A RECORD: `ok: true` answers `false` here, so the
# fallback cannot fire on the happy path and re-introduce the `already_captured`
# self-suppression the in-repo path exists to avoid.

set -eu

emit() {
    printf '{"fallback": %s, "reason": "%s"}\n' "$1" \
        "$(printf '%s' "${2:-}" | tr -d '"\\' | tr '\n' ' ' | cut -c1-400)"
    exit 0
}

destination="${1:-}"

case "$destination" in
    in-repo|crossing) ;;
    *) emit false "destination must be in-repo or crossing, got: ${destination}" ;;
esac

envelope="$(cat)"
[ -n "$envelope" ] || emit false "no open-issue envelope given"

ok="$(printf '%s' "$envelope" | jq -r '.ok // empty' 2>/dev/null || true)"
error="$(printf '%s' "$envelope" | jq -r '.error // .reason // empty' 2>/dev/null || true)"

# An UNPARSEABLE envelope is a failure, not a success. `open-issue.sh` emits JSON on every
# outcome, so anything else means the call did not complete the way either side expects —
# treating that as "filed" is how an ask gets lost silently.
if [ -z "$ok" ]; then
    ok="false"
    [ -n "$error" ] || error="the filing reported no parseable outcome"
fi

[ "$ok" != "true" ] || emit false "the issue was filed"

if [ "$destination" = "crossing" ]; then
    emit false "a refusal from another repository is reported verbatim, never worked around: ${error}"
fi

emit true "${error:-the issue could not be opened}"
