#!/bin/sh -eu
# Durable native-host control. Never starts a process or contacts a provider.
# Usage: coordinator.sh --instance ID --input FILE
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$SCRIPT_DIR/lib/result.sh"
INSTANCE='' INPUT=''
while [ "$#" -gt 0 ]; do
    case "$1" in
        --instance) INSTANCE=${2:-}; shift 2;;
        --input) INPUT=${2:-}; shift 2;;
        *) runtime_usage "usage: coordinator.sh --instance ID --input FILE";;
    esac
done
runtime_require_json_file "$INPUT"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
attempt=0
while [ "$attempt" -lt 3 ]; do
    attempt=$((attempt+1))
    sh "$SCRIPT_DIR/state.sh" read --scope instance --id "$INSTANCE" > "$WORK/read"
    [ "$(jq -r .status "$WORK/read")" = ok ] || { cat "$WORK/read"; exit 0; }
    jq -n --slurpfile old "$WORK/read" --slurpfile input "$INPUT" \
      '{state:($old[0].data.record.data.coordinator // null),input:$input[0]}' > "$WORK/reduce"
    jq -f "$SCRIPT_DIR/lib/coordinator.jq" "$WORK/reduce" > "$WORK/plan" 2> "$WORK/error" \
        || runtime_usage "$(cat "$WORK/error")"
    if [ "$(jq -r .changed "$WORK/plan")" != true ]; then break; fi
    now=$(jq -r .now "$INPUT")
    if [ "$(jq -r .data.found "$WORK/read")" = false ]; then
        jq -n --arg now "$now" --slurpfile plan "$WORK/plan" \
          '{updated_at:$now,data:{coordinator:$plan[0].state}}' > "$WORK/write"
        sh "$SCRIPT_DIR/state.sh" create --scope instance --id "$INSTANCE" --input "$WORK/write" > "$WORK/result"
    else
        revision=$(jq -r .data.record.revision "$WORK/read")
        jq -n --arg now "$now" --slurpfile old "$WORK/read" --slurpfile plan "$WORK/plan" \
          '{updated_at:$now,data:($old[0].data.record.data + {coordinator:$plan[0].state})}' > "$WORK/write"
        sh "$SCRIPT_DIR/state.sh" update --scope instance --id "$INSTANCE" \
          --expected-revision "$revision" --input "$WORK/write" > "$WORK/result"
    fi
    [ "$(jq -r .reason "$WORK/result")" = revision_conflict ] && continue
    [ "$(jq -r .status "$WORK/result")" = ok ] || { cat "$WORK/result"; exit 0; }
    break
done
if [ -f "$WORK/result" ] && [ "$(jq -r .reason "$WORK/result")" = revision_conflict ]; then cat "$WORK/result"; exit 0; fi

# The native completion seam owns the legacy cadence log too. Replaying a finish heals
# a crash after state persistence; log-append is idempotent per completion tick + receipt.
log='null'
if [ "$(jq -r .event "$INPUT")" = finish ]; then
    id=$(jq -r .id "$INPUT")
    jq --arg id "$id" '.state.workers[$id] | select(.state == "completed")' "$WORK/plan" > "$WORK/worker"
    if [ -s "$WORK/worker" ]; then
        role=$(jq -r .role "$WORK/worker")
        stamp=$(jq -r '.finished_at | strftime("%Y%m%d-%H%M%S")' "$WORK/worker")
        suffix=$(printf '%s' "$INSTANCE:$id" | git hash-object --stdin)
        summary=$(jq -c '{executed:.result.executed,outcome:.result.outcome,reason:.result.reason}' "$WORK/worker")
        log=$(sh "$SCRIPT_DIR/../../moderate/scripts/log-append.sh" --tick "$stamp" \
          --step "loop-finish-${role}-${suffix}" --status ok --summary "$summary" 2>/dev/null || printf 'null')
        printf '%s' "$log" | jq -e . >/dev/null 2>&1 || log=null
    fi
fi
jq -c --argjson log "$log" '{protocol:"workaholic.runtime/v1",request_id:"coordinator",
  status:"ok",reason:.reason,data:(del(.state,.changed,.reason)+{completion_log:$log})}' "$WORK/plan"
