#!/bin/sh -eu
# THE ONE READER OF THE CONTEXT PROPAGATION POLICY (2026-09-19, ticket `20260919095618`).
#
# Three dials existed and none of them was the one the operator needed: cadence in `polling`,
# worker count in `WORKAHOLIC_MAX_WORKERS`, and nothing at all for what a child INHERITS. So an
# operator whose objection was the per-child context copy had exactly one lever -- turning
# delegation off -- and pulling it stopped the coordinator receiving role ticks.
#
# This script answers what a child is launched under and whether the harness can honour it. It
# reads `read-config.sh` and NOTHING else: the policy is declared configuration, never inferred
# from a harness flag, an environment variable or the shape of a prompt.
#
#   policy          the declared policy, or null
#   declared        whether the repository declared one at all
#   harness         the harness the caller named (`--harness`), `unknown` when it named none
#   supported       whether that harness can honour `policy`; null when nothing is declared
#   effective       the policy that will actually govern the child; null when it cannot be known
#   support_reason  the named reason when `supported` is not true
#   mapping         the harness capability the policy maps onto, or ""
#
# `fork_turns` is a HARNESS capability, not a workaholic one, so it appears only as a mapping.
# A harness this script cannot vouch for answers `supported: false` with `harness_unknown` and
# `effective: null` -- an absence of a reading is never a supported policy, and the caller
# reports *unsupported* rather than dispatching silently under a policy nobody chose.
#
# It changes no count and no cadence: `WORKAHOLIC_MAX_WORKERS`, the implement fanout and every
# polling value are untouched by this reading.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"

ROOT="" HARNESS="unknown"
while [ $# -gt 0 ]; do
    case "$1" in
        --root) ROOT=${2:-}; shift 2 ;;
        --harness) HARNESS=${2:-}; shift 2 ;;
        *) runtime_usage "usage: dispatch-policy.sh --root REPO [--harness ID]" ;;
    esac
done
[ -n "$ROOT" ] && [ -d "$ROOT" ] || runtime_usage "--root must be a directory"
[ -n "$HARNESS" ] || HARNESS=unknown

# An invalid declared value is `read-config.sh`'s own refusal and is passed through verbatim:
# one word for one fact, and nothing is dispatched under a guessed policy.
if CONFIG=$(sh "${SCRIPT_DIR}/read-config.sh" --root "$ROOT" 2>/dev/null); then
    :
else
    printf '%s\n' "$CONFIG"
    exit 2
fi

jq -cn --arg harness "$HARNESS" --argjson config "$CONFIG" '
  ($config.data.config.dispatch.context_policy) as $policy
  | (if $policy == null then
       {supported:null,effective:null,support_reason:"not_declared",mapping:""}
     elif $harness == "claude_code" then
       (if $policy == "bounded_task"
        then {supported:true,effective:$policy,support_reason:"",mapping:"fork_turns=none"}
        else {supported:true,effective:$policy,support_reason:"",mapping:""} end)
     elif $harness == "codex" then
       # A detached `codex exec` worker inherits no conversation at all, so the bounded policy
       # is what that harness already does and the full one cannot be honoured there.
       (if $policy == "bounded_task"
        then {supported:true,effective:$policy,support_reason:"",mapping:"detached_worker"}
        else {supported:false,effective:"bounded_task",
              support_reason:"detached_worker_inherits_no_conversation",mapping:"detached_worker"} end)
     else
       {supported:false,effective:null,support_reason:"harness_unknown",mapping:""}
     end) as $verdict
  | {protocol:"workaholic.runtime/v1",request_id:"dispatch-policy",status:"ok",reason:"",
     data:({policy:$policy,declared:($policy != null),harness:$harness} + $verdict)}'
