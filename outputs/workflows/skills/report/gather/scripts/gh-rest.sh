#!/bin/sh -eu
# The one GitHub transport every workflow script reaches GitHub through: REST only,
# never GraphQL.
#
#   gh-rest.sh slug [remote]        -> "owner/repo" for the given remote (default origin)
#   gh-rest.sh api <gh api args...> -> the `gh api` call, verbatim
#   gh-rest.sh available            -> {"ok": bool, "reason": "..."} — is REST usable here
#
# WHY THIS EXISTS (2026-08-12, feedback 20260812172522). `gh issue list`, `gh pr list`,
# `gh pr create`, `gh pr merge` and `gh pr view` are backed by GraphQL, and a Claude Code
# Web session is NOT guaranteed to serve that surface. Measured 2026-08-12 17:19 UTC in
# this repository's own `[Specificate]` tick:
#
#   HTTP 403: This GraphQL query is not enabled for this session — only the pinned set
#   of PR-review operations is served. Use REST via `gh api repos/{owner}/{repo}/...`
#   instead.
#
# A run 80 minutes earlier used the same code paths successfully, so the capability is a
# property of the SESSION, not of the repository or the credential. The scripts treated it
# as static, so a restricted session did not degrade — it stopped: discovery reported
# `list_failed` and ingested nothing, and a publish pushed its branch and then died at
# `pr_failed`, leaving work pushed but unpublished for a human to finish by hand.
#
# REST answers in both kinds of session, which is why this is a conversion rather than a
# fallback: a REST-after-GraphQL ladder would keep the slow path, keep two behaviors to
# reason about, and still fail whenever the 403 arrives in a shape the ladder did not
# expect. One transport, always available, is simpler than two and cannot drift.
#
# WHY IT LIVES IN `gather` (the Open Decision recorded on ticket
# 20260812172713-read-the-inbound-issue-inbox-through-rest, resolved when driving it).
# Six skills reach GitHub — propose, branching, ship, report, mission, feedback — so a
# `lib/` beside each consumer would be six copies of one transport, and the drift between
# them would be invisible exactly the way this defect was. `gather` is the documented home
# of common operations (CLAUDE.md, *Design principles*), which is what this is.
#
# The stated objection to `gather` — its scripts are read-only context gatherers, and the
# PR seams need writes — is answered by the shape rather than by the address: this script
# performs no operation of its own. It resolves a slug and forwards a call whose method
# the CALLER chooses, so the write stays the caller's act and `gather` gains a transport,
# not a mutator. The alternative homes were weighed and rejected: `branching` owns the
# publish seam only, and would be a strange home for `/fb`'s issue crossing or `/ship`'s
# merge confirmation.
#
# WHY IT IS INVOKED, NOT SOURCED. Every existing cross-skill call in this plugin runs
# another skill's script with `sh` (`plan-units.sh` -> `read-relation.sh`), and the build's
# closure detection is tuned for exactly that form (`${SCRIPT_DIR}/../../<skill>/scripts/`,
# checked by verify.mjs). Sourcing across skills has no precedent here and would be
# invisible to the bundle build, so the closure would ship incomplete.

set -eu

CMD="${1:-}"
[ -n "$CMD" ] || { echo '{"ok": false, "reason": "usage", "detail": "gh-rest.sh slug|api|available"}' >&2; exit 2; }
shift

# Resolve owner/repo from a remote URL. `gh api` needs a resolvable {owner}/{repo} and
# deriving it is a STEP, not an assumption -- `gh pr create` used to resolve the base
# repository itself, and that resolution disappears with the subcommand. Handles both
# clone forms and an optional trailing `.git`.
repo_slug() {
    _remote="${1:-origin}"
    _url="$(git config --get "remote.${_remote}.url" 2>/dev/null || true)"
    [ -n "$_url" ] || return 1
    printf '%s' "$_url" \
        | sed -e 's#\.git$##' -e 's#^.*[:/]\([^/][^/]*\)/\([^/][^/]*\)$#\1/\2#'
}

case "$CMD" in
    slug)
        slug="$(repo_slug "${1:-origin}")" || {
            echo '{"ok": false, "reason": "no_remote"}' >&2
            exit 1
        }
        case "$slug" in
            */*) printf '%s\n' "$slug" ;;
            *) echo '{"ok": false, "reason": "unparsable_remote"}' >&2; exit 1 ;;
        esac
        ;;
    api)
        # Verbatim passthrough. No wrapping of stderr or exit status: every caller here
        # already has its own error vocabulary (`list_failed`, `pr_failed`, ...) and
        # swallowing the underlying message is what made the measured incident
        # undiagnosable in the first place.
        command -v gh >/dev/null 2>&1 || {
            echo "gh is not on PATH" >&2
            exit 127
        }
        exec gh api "$@"
        ;;
    available)
        if ! command -v gh >/dev/null 2>&1; then
            printf '{"ok": false, "reason": "gh_unavailable"}\n'
            exit 0
        fi
        if out="$(gh api user --jq .login 2>&1)" && [ -n "$out" ]; then
            printf '{"ok": true, "login": "%s"}\n' "$(printf '%s' "$out" | tr -d '"\\')"
            exit 0
        fi
        printf '{"ok": false, "reason": "rest_unreachable", "detail": "%s"}\n' \
            "$(printf '%s' "$out" | tr -d '"\\' | tr '\n' ' ' | cut -c1-200)"
        ;;
    *)
        echo '{"ok": false, "reason": "usage", "detail": "gh-rest.sh slug|api|available"}' >&2
        exit 2
        ;;
esac
