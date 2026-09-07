#!/bin/sh -eu
# Translate the legacy relay envelope into transport/v1 requests. This adapter
# does not extend workaholic.codex-slack-relay/v1 or reinterpret its ACK.

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/result.sh"
cmd=${1:-}; envelope=${2:-}; shift 2 2>/dev/null || transport_usage "usage: relay-v1.sh envelope FILE [--bindings FILE]"
[ "$cmd" = envelope ] || transport_usage "only envelope conversion is supported"
BINDINGS=""
while [ $# -gt 0 ]; do case "$1" in --bindings) BINDINGS=${2:-}; shift 2;; *) transport_usage "unknown relay argument";; esac; done
[ -s "$envelope" ] || transport_usage "missing relay envelope"
# The legacy script remains untouched. This conversion boundary accepts exactly
# the same closed envelope fields and operations before producing a new protocol.
jq -e '
  . as $envelope |
  .protocol=="workaholic.codex-slack-relay/v1" and
  (.tick_id|type=="string" and length>0) and (.executed|type=="boolean") and
  (.outcome=="ok" or .outcome=="pending" or .outcome=="blocked") and
  (.slack_intents|type=="array") and (([.slack_intents[].key]|length)==([$envelope.slack_intents[].key]|unique|length)) and
  all(.slack_intents[];
    (.key|type=="string" and length>0) and (.channel|type=="string" and length>0) and
    (.operation=="search_exact" or .operation=="read_thread" or .operation=="post_root" or .operation=="post_reply" or .operation=="add_reaction") and
    (if .operation=="search_exact" then (.query|type=="string" and length>0) and .private_inclusive==true
     elif .operation=="read_thread" then (.thread_ts|type=="string" and length>0)
     elif .operation=="post_root" then (.text|type=="string" and length>0)
     elif .operation=="post_reply" then (.thread_ts|type=="string" and length>0) and (.text|type=="string" and length>0)
     else (.timestamp|type=="string" and length>0) and (.emoji|type=="string" and length>0) end))
' "$envelope" >/dev/null 2>&1 || transport_usage "malformed legacy envelope"
[ -z "$BINDINGS" ] || jq -e 'type=="array"' "$BINDINGS" >/dev/null 2>&1 || transport_usage "bindings must be an array"

if [ -n "$BINDINGS" ]; then
  ambiguous=$(jq -n --slurpfile env "$envelope" --slurpfile bindings "$BINDINGS" '
    [$env[0].slack_intents[] as $i | [$bindings[0][]|select(.channel==$i.channel)|.workspace]|unique|length] | any(.>1)')
  if [ "$ambiguous" = true ]; then
    transport_result deferred ambiguous_target "$(jq -r .tick_id "$envelope")" '{"detail":"legacy channel-only target resolves in multiple workspaces"}'
    exit 0
  fi
fi
jq -cn --slurpfile env "$envelope" --slurpfile bindings "${BINDINGS:-/dev/null}" '
  $env[0] as $e |
  {protocol:"workaholic.transport/v1",request_id:$e.tick_id,status:"ok",reason:"",
   data:{requests:[$e.slack_intents[] as $i |
     ([($bindings[0]//[])[]|select(.channel==$i.channel)][0]//null) as $b |
     {protocol:"workaholic.transport/v1",request_id:($e.tick_id+"-"+$i.key),operation:$i.operation,
      repo_root:".",instance_id:$e.tick_id,input:($i + {binding:$b})} +
      (if $b==null then {} else {binding_id:$b.binding_id} end)]}}
' 2>/dev/null || transport_usage "could not convert relay envelope"
