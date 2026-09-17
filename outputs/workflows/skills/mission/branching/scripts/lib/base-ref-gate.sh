#!/bin/sh
# base-ref-gate.sh -- THE ONE READER of whether a write may reach the base ref.
#
# Sourced by every commit and push site in the plugin, or executed for a reading:
#
#   . "<skills>/branching/scripts/lib/base-ref-gate.sh"
#   base_ref_gate commit <checkout-branch>            # before `git commit`
#   base_ref_gate push   <refspec> [reviewed]         # before `git push origin <refspec>`
#       -> returns 0 (allowed) or 1 (refused); sets BASE_REF_GATE_VERDICT, BASE_REF_GATE_REASON,
#          BASE_REF_GATE_DESTINATION, BASE_REF_GATE_ROLE, BASE_REF_GATE_BASE
#   base_ref_gate_json                                 # the last verdict, one JSON line
#
#   sh base-ref-gate.sh --act commit|push (--branch <b> | --ref <refspec>) [--base <b>] [--role <r>] [--reviewed-merge]
#       -> {"verdict": "allowed"|"refused", "reason": "<word>", "act": ..., "destination": ..., "role": ..., "base": ...}
#          always exit 0: a reading is reported, never died on.
#
# WHY (2026-09-11, issue #1151, the operator's rule verbatim: *add a base-ref write gate and
# regression tests proving that Propose, Moderate, notification, and finish-log paths cannot
# commit or push directly to `main`*). The claim protocol keeps a runner off the base by
# construction -- a claim is a branch -- and the tick's records moved onto the pull-request seam
# the same day; what had never existed is a reader that says so for the writers that carry no
# claim, so the next script, or an agent-composed push, could land on `main` again unnoticed.
# Measured before it: 17 `Record the tick's feedback findings` and 2 `Add deferred concerns`
# first-parent commits on `main` through the direct seam.
#
# THE INPUTS. The base is `WORKAHOLIC_PUBLISH_BASE` or `main`. The role is `WORKAHOLIC_ROLE` --
# `propose` / `moderate` / `notify` / `finish-log` / `implement` / `ship` / `specificate` -- set
# at each unattended path's own entry (`moderate/scripts/run.sh`, `persist-log.sh`,
# `propose/scripts/open-proposal.sh`, `file-inbound-ask.sh`, `transport/scripts/perform.sh`,
# `specificate/scripts/notify-slack.sh`, `moderate/scripts/log-append.sh`, the coordinator's
# `finish`, the ship's concern extractor, and `codex-loop.sh --dispatch <role>`), never by a
# caller composing an assignment prefix. ABSENT MEANS ATTENDED: a developer's own checkout is
# byte-identical to before this existed (`allowed:attended`), and an unknown role word is still
# a role -- it gates, and is reported as it was given, because an unattended writer that names
# itself wrongly must not be granted the developer's freedom by the typo.
#
# THE VERDICTS, each its own word:
#   allowed:attended        no role -- a person's own checkout
#   allowed:reviewed_merge  a merge seam carrying a reviewed pull request said so (`land-unit.sh`'s
#                           fast-forward; the REST merge is not a push and needs no gate)
#   allowed:claim_ref       `refs/claims/*` -- the arbiter's leases and the liveness carriers
#   allowed:claim_branch    a `work-*` branch (a claim or a publication) or `release/*`
#   allowed:branch_push     any other non-base destination
#   allowed:branch_commit   a commit on a checkout that is not the base
#   refused:base_ref_write  a commit on a checkout of the base, or a push whose destination is
#                           the base (`main`, `refs/heads/main`, `x:main`, `HEAD:main`, a delete
#                           of it), under any role
#
# WHAT IT DOES NOT DO. It never runs git for the verdict (the destination is read off the
# refspec; only a bare `HEAD` is resolved through `symbolic-ref`, read-only), it writes nothing,
# it exits 0 on every reading, and it does not replace GitHub's own branch protection -- that is
# the operator's setting, reported as an advisory by `workaholify/scripts/check-repo-settings.sh`.
# The agent-level half is `hooks/guard-git-push.sh`, which denies a composed `git push` naming
# the base before it runs; this reader is the script-level half.

BASE_REF_GATE_VERDICT=''
BASE_REF_GATE_REASON=''
BASE_REF_GATE_DESTINATION=''
BASE_REF_GATE_ROLE=''
BASE_REF_GATE_BASE=''
BASE_REF_GATE_ACT=''

# base_ref_gate_destination <refspec> -> prints the destination ref name, short form.
base_ref_gate_destination() {
    _brg_spec=$1
    case "$_brg_spec" in +*) _brg_spec=${_brg_spec#+} ;; esac
    case "$_brg_spec" in
        *:*) _brg_dst=${_brg_spec##*:} ;;
        *)   _brg_dst=$_brg_spec ;;
    esac
    if [ "$_brg_dst" = HEAD ] || [ -z "$_brg_dst" ]; then
        _brg_dst=$(git symbolic-ref --short -q HEAD 2>/dev/null || printf 'HEAD')
    fi
    case "$_brg_dst" in
        refs/heads/*) _brg_dst=${_brg_dst#refs/heads/} ;;
    esac
    printf '%s' "$_brg_dst"
}

# base_ref_gate <commit|push> <branch-or-refspec> [reviewed]
base_ref_gate() {
    BASE_REF_GATE_ACT=$1
    _brg_target=${2:-}
    _brg_reviewed=${3:-}
    BASE_REF_GATE_BASE=${WORKAHOLIC_PUBLISH_BASE:-main}
    BASE_REF_GATE_ROLE=${WORKAHOLIC_ROLE:-}
    case "$BASE_REF_GATE_ACT" in
        commit) BASE_REF_GATE_DESTINATION=$_brg_target ;;
        push)   BASE_REF_GATE_DESTINATION=$(base_ref_gate_destination "$_brg_target") ;;
        *) BASE_REF_GATE_VERDICT=refused; BASE_REF_GATE_REASON=unknown_act; return 1 ;;
    esac
    if [ -z "$BASE_REF_GATE_ROLE" ]; then
        BASE_REF_GATE_VERDICT=allowed; BASE_REF_GATE_REASON=attended; return 0
    fi
    if [ "$_brg_reviewed" = reviewed ]; then
        BASE_REF_GATE_VERDICT=allowed; BASE_REF_GATE_REASON=reviewed_merge; return 0
    fi
    case "$BASE_REF_GATE_ACT" in
        push)
            case "$BASE_REF_GATE_DESTINATION" in
                refs/claims/*|claims/*)
                    BASE_REF_GATE_VERDICT=allowed; BASE_REF_GATE_REASON=claim_ref; return 0 ;;
            esac
            if [ "$BASE_REF_GATE_DESTINATION" = "$BASE_REF_GATE_BASE" ]; then
                BASE_REF_GATE_VERDICT=refused; BASE_REF_GATE_REASON=base_ref_write; return 1
            fi
            case "$BASE_REF_GATE_DESTINATION" in
                work-*|release/*) BASE_REF_GATE_VERDICT=allowed; BASE_REF_GATE_REASON=claim_branch; return 0 ;;
            esac
            BASE_REF_GATE_VERDICT=allowed; BASE_REF_GATE_REASON=branch_push; return 0 ;;
        commit)
            if [ "$BASE_REF_GATE_DESTINATION" = "$BASE_REF_GATE_BASE" ]; then
                BASE_REF_GATE_VERDICT=refused; BASE_REF_GATE_REASON=base_ref_write; return 1
            fi
            BASE_REF_GATE_VERDICT=allowed; BASE_REF_GATE_REASON=branch_commit; return 0 ;;
    esac
}

base_ref_gate_json() {
    printf '{"verdict": "%s", "reason": "%s", "act": "%s", "destination": "%s", "role": "%s", "base": "%s"}\n' \
        "$BASE_REF_GATE_VERDICT" "$BASE_REF_GATE_REASON" "$BASE_REF_GATE_ACT" \
        "$BASE_REF_GATE_DESTINATION" "$BASE_REF_GATE_ROLE" "$BASE_REF_GATE_BASE"
}

# Executed directly: a reading on the command line.
case "${0##*/}" in
    base-ref-gate.sh)
        _brg_act='' _brg_branch='' _brg_ref='' _brg_rev=''
        while [ $# -gt 0 ]; do
            case "$1" in
                --act) _brg_act=${2:-}; shift 2 ;;
                --branch) _brg_branch=${2:-}; shift 2 ;;
                --ref) _brg_ref=${2:-}; shift 2 ;;
                --base) WORKAHOLIC_PUBLISH_BASE=${2:-}; export WORKAHOLIC_PUBLISH_BASE; shift 2 ;;
                --role) WORKAHOLIC_ROLE=${2:-}; export WORKAHOLIC_ROLE; shift 2 ;;
                --reviewed-merge) _brg_rev=reviewed; shift ;;
                *) printf '{"verdict": "refused", "reason": "usage", "detail": "base-ref-gate.sh --act commit|push (--branch <b> | --ref <refspec>) [--base <b>] [--role <r>] [--reviewed-merge]"}\n'; exit 0 ;;
            esac
        done
        case "$_brg_act" in
            commit) base_ref_gate commit "$_brg_branch" "$_brg_rev" || true ;;
            push)   base_ref_gate push "$_brg_ref" "$_brg_rev" || true ;;
            *) printf '{"verdict": "refused", "reason": "usage", "detail": "--act must be commit or push"}\n'; exit 0 ;;
        esac
        base_ref_gate_json
        exit 0
        ;;
esac
