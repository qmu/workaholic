#!/bin/sh -eu
# Production entry: select due maintenance work, run one complete report, persist evidence.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
ROOT=.
want_root=false
for arg in "$@"; do
  if [ "$want_root" = true ]; then ROOT=$arg; want_root=false; continue; fi
  case "$arg" in
    --root) want_root=true ;;
    --plan-input) printf '{"tick":"","error":"plan_input_owned_by_run_planned"}\n'; exit 2;;
  esac
done
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
now=$(date -u +%s)
sh "$SCRIPT_DIR/runtime-plan.sh" prepare --root "$ROOT" --now "$now" >"$tmp/plan.json"
if [ "$(jq -r '.status // "error"' "$tmp/plan.json")" != ok ]; then printf '{"tick":"","error":"runtime_plan_unreadable"}\n'; exit 1; fi
# run.sh remains the compatibility entry and owns argument validation.
sh "$SCRIPT_DIR/run.sh" "$@" --plan-input "$tmp/plan.json" >"$tmp/result.json"
executed=$(jq -r '[.steps[]|select(.reason!="cadence" and .reason!="budget" and .reason!="requested")|.step]|join(",")' "$tmp/result.json")
sh "$SCRIPT_DIR/runtime-plan.sh" complete --root "$ROOT" --now "$now" --executed "$executed" >"$tmp/complete.json" 2>/dev/null || true
jq -c --slurpfile completion "$tmp/complete.json" '. + {cadence_state:($completion[0] // {status:"deferred",reason:"state_unreadable"})}' "$tmp/result.json"
