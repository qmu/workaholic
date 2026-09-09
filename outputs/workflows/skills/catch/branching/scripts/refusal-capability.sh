#!/bin/sh -eu
# WHICH CAPABILITY REFUSED A DELIVERY, and whether an authorized route was left untried.
# Derived in ONE place, beside `merge-reason.sh` — which answers *what the refusal was*, where
# this answers *what the refusal says about this session*. Two different questions, and folding
# them into one word is exactly how the first became a statement about the second.
#
#   refusal-capability.sh <reason> [route]   -> one JSON line on stdout
#
# `<route>` is the route the refusal happened on; it defaults to `github_rest`, the only route a
# script ever merges through. Pass `github_connector` when classifying the retry's own refusal.
#
# WHY IT EXISTS (2026-09-09, mission `report-a-native-tick-from-reconciled-evidence-not-from-a-
# worker-s-word`). A 2026-09-08 native `/work` retrospective reported two runners stopping on
# `merge_refused: session_type_cannot_merge`, after which an operator-authorized squash merge
# succeeded on the same pull request. **One refused REST call had become a statement about the
# whole session**, and the route that was actually available was never tried. Two concrete
# defects were found in the tree rather than inferred from the report:
#
#   1. `gather/scripts/merge-pull.sh` rendered a LITERAL `retry_authorized:false` on every
#      refusal it classified — including `session_type_cannot_merge`, the one refusal
#      `rules/shell.md` explicitly authorizes a retry for. The field said the opposite of the
#      rule. Nothing read it, so nothing behaved on it; what it did was make the honest answer
#      unavailable to any caller that wanted one.
#   2. `commands/infinite-development.md` — the native coordinator, which delivers directly
#      through `drive/scripts/deliver-unit.sh` and `ship/scripts/merge-pr.sh` — carried NO
#      connector-retry step at all. `commands/implement.md` carries it, and a coordinator that
#      merges for itself never reaches that body. So the retrospective's claim was half right:
#      the WORKER's path reaches the retry (its prompt executes `implement.md` end to end); the
#      COORDINATOR's own path did not.
#
# THE FOUR WORDS, and each is a different next action — the reason they are not collapsed:
#
#   no_capability   The tool or route is absent HERE. The change is fine, the identity is fine,
#                   and a different caller merges the same pull request unchanged.
#   call_errored    Transport, 5xx, an unreadable response. Nothing was established; look again.
#   not_permitted   An authorization denial. A person must change something outside the pull
#                   request. **Nothing routes around this one** — see below.
#   none            NO capability refused it. The route worked, the identity was permitted, the
#                   call did not error, and GitHub declined the merge on the pull request's own
#                   state (a conflict, a required check, a moved head). Naming this `none` rather
#                   than forcing it into one of the three is the point: a named empty stays
#                   honest, and reporting a 405 as *this session cannot deliver* is the very
#                   error the classification exists to stop.
#
#   unclassified    A word this reader does not know. Deliberately NOT a guess: a new refusal
#                   word must be classified here on purpose, and `test-workflow-scripts.mjs`
#                   fails when `merge-reason.sh` emits a word this script leaves unclassified.
#
# `authorized_route` IS THE WHOLE OF ITEM 4, AND IT IS DELIBERATELY NARROW. It is non-empty for
# exactly one input — `session_type_cannot_merge` arriving on `github_rest` — and names
# `mcp__github__merge_pull_request`, which is `rules/shell.md`'s *one qualification* verbatim and
# is not widened here. Two bounds fall out of the derivation rather than being restated in prose:
#
#   * A `not_permitted` refusal NEVER carries one. An authorization denial stays a refusal; no
#     alternate spelling, no parent delegation, no second account. The ask was explicit that
#     these must not become a way around a permission refusal, and the way to keep that true is
#     that the reader which licenses a retry cannot produce one for a denial.
#   * The connector's OWN refusal carries none either (`route=github_connector`), which is the
#     "one attempt, one tool" bound expressed as arithmetic instead of as a sentence.
#
# NO NETWORK, NO GIT, NO STATE — a pure function over two strings, for `merge-reason.sh`'s own
# stated reason: a ladder that can only be exercised by making a real merge fail is a ladder
# asserted by reading the source rather than by running it.

set -eu

reason=${1:-}
route=${2:-github_rest}
[ -n "$reason" ] || {
    printf '{"reason":"","capability":"unclassified","route":"","authorized_route":"","retry_authorized":false}\n'
    exit 0
}

case "$reason" in
    # The tool or the route is absent here. A different caller merges this unchanged.
    session_type_cannot_merge|gh_unavailable) capability=no_capability ;;
    # An authorization denial. Nothing routes around it.
    merge_forbidden)                          capability=not_permitted ;;
    # Nothing was established; the call itself did not complete honestly.
    merge_failed|rest_unreachable|merge_effect_unconfirmed|pr_unreadable|repo_unresolved)
                                              capability=call_errored ;;
    # No capability refused it — the pull request's own state did.
    merge_not_allowed|head_moved|head_changed|pull_not_open)
                                              capability=none ;;
    *)                                        capability=unclassified ;;
esac

authorized_route=""
if [ "$reason" = session_type_cannot_merge ] && [ "$route" = github_rest ]; then
    authorized_route=mcp__github__merge_pull_request
fi

jq -cn --arg reason "$reason" --arg capability "$capability" --arg route "$route" \
    --arg authorized_route "$authorized_route" \
    '{reason:$reason,capability:$capability,route:$route,authorized_route:$authorized_route,
      retry_authorized:($authorized_route|length>0)}'
