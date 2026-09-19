#!/bin/sh -eu
# Select registered maintenance steps from snapshot changes and explicit due times.
#
# A REGISTRY ROW WHOSE SHAPE THE PROGRAM CANNOT READ IS REFUSED BY NAME, NEVER PLANNED
# AROUND AND NEVER ANSWERED EMPTY (2026-09-19, ticket `20260919141500`). jq's `or` and
# its `if` both short-circuit, and `.trigger.seconds` is reached only on the arm where
# the step has ALREADY run -- so a cold tick never evaluates it at all. A row whose
# `trigger` is a string therefore plans cleanly on the first tick of an hour and aborts
# the whole program on the second, mid-array, printing `Cannot index string with string
# "seconds"` on stderr with NOTHING on stdout; through a pipe the pipeline then exits 0,
# so every caller reads the abort as *no steps selected* -- the one direction of this
# error that is dangerous, because the reading exists to stop a step running twice inside
# its hour. `run.sh` refuses `step_plan_unreadable` on it but discards the cause (`2>/dev/null`),
# so the condition was legible nowhere.
#
# THE REGISTRY'S SIZE IS NOT A TERM. The ticket recorded two signals and suspected a
# 1024-byte boundary; measured on the tree at 36, 40, 60, 100, 200 and 400 steps, the
# planner answers a parseable result at every one of them, and the fault reproduces at a
# 1066-byte input whose JSON is intact. The shape of one row is the whole cause, and the
# clean-but-failing input the ticket saw is what a valid input carrying a malformed row
# looks like.
[ "${1:-}" = --input ] || { printf '{"status":"error","reason":"input_required"}\n'; exit 2; }
INPUT=${2:-}; SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REGISTRY="${SCRIPT_DIR}/steps.json"
jq -e '(.now_epoch|type=="number") and (.changed_snapshots|type=="array") and (.last_run|type=="object")' "$INPUT" >/dev/null 2>&1 || { printf '{"status":"error","reason":"invalid_input"}\n'; exit 2; }
jq -e '.steps|type=="array"' "$REGISTRY" >/dev/null 2>&1 || { printf '{"status":"error","reason":"registry_unreadable"}\n'; exit 2; }
# Every field the program below indexes, asserted here where the failure is legible, and
# named by the row it belongs to. `seconds` and `depends_on_snapshot` are optional (`// 3600`,
# `[]?`), so an ABSENT one passes and only a present one of the wrong type is refused --
# `has()` rather than a `//` default, because `false` and `null` are one value to jq
# (`rules/shell.md`).
malformed=$(jq -r '[.steps[]
  | select((.id|type!="string") or (.script|type!="string") or (.trigger|type!="object")
           or ((.trigger|has("seconds")) and (.trigger.seconds|type!="number"))
           or ((has("depends_on_snapshot")) and (.depends_on_snapshot|type!="array")))
  | (.id|tostring)] | join(",")' "$REGISTRY" 2>/dev/null) || { printf '{"status":"error","reason":"registry_unreadable"}\n'; exit 2; }
[ -z "$malformed" ] || { printf '{"status":"error","reason":"invalid_registry_step","steps":"%s"}\n' "$malformed"; exit 2; }
# The program's own failure is a named refusal too, never empty stdout: a reader that
# aborts must say so at the site of the defect.
plan=$(jq -cn --slurpfile registry "$REGISTRY" --slurpfile input "$INPUT" '
  $input[0] as $i | [$registry[0].steps[]
    | . as $s | ($i.last_run | has($s.id)) as $has_last | ($i.last_run[$s.id] // 0) as $last
    | select(($has_last | not)
             or ([$s.depends_on_snapshot[]?] - ($i.changed_snapshots // [] ) | length) < ([$s.depends_on_snapshot[]?]|length)
             or ($last + ($s.trigger.seconds // 3600)) <= $i.now_epoch)
    | {id,script,reason:(if ($has_last | not) then "first_run" elif ($last + (.trigger.seconds // 3600)) <= $i.now_epoch then "due" else "snapshot_changed" end)}]
  | {protocol:"workaholic.runtime/v1",request_id:"plan-steps",status:"ok",reason:"",data:{steps:.,count:length}}') \
  || { printf '{"status":"error","reason":"plan_failed"}\n'; exit 2; }
printf '%s\n' "$plan"
