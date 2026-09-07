#!/bin/sh -eu
# Select registered maintenance steps from snapshot changes and explicit due times.
[ "${1:-}" = --input ] || { printf '{"status":"error","reason":"input_required"}\n'; exit 2; }
INPUT=${2:-}; SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
jq -e '(.now_epoch|type=="number") and (.changed_snapshots|type=="array") and (.last_run|type=="object")' "$INPUT" >/dev/null 2>&1 || { printf '{"status":"error","reason":"invalid_input"}\n'; exit 2; }
jq -cn --slurpfile registry "$SCRIPT_DIR/steps.json" --slurpfile input "$INPUT" '
  $input[0] as $i | [$registry[0].steps[]
    | . as $s | ($i.last_run | has($s.id)) as $has_last | ($i.last_run[$s.id] // 0) as $last
    | select(($has_last | not)
             or ([$s.depends_on_snapshot[]?] - ($i.changed_snapshots // [] ) | length) < ([$s.depends_on_snapshot[]?]|length)
             or ($last + ($s.trigger.seconds // 3600)) <= $i.now_epoch)
    | {id,script,reason:(if ($has_last | not) then "first_run" elif ($last + (.trigger.seconds // 3600)) <= $i.now_epoch then "due" else "snapshot_changed" end)}]
  | {protocol:"workaholic.runtime/v1",request_id:"plan-steps",status:"ok",reason:"",data:{steps:.,count:length}}'
