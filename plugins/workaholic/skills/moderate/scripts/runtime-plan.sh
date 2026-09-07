#!/bin/sh -eu
# Persist only mechanical maintenance cadence/fingerprint evidence outside the tree.
# Usage: runtime-plan.sh prepare --root ROOT --now EPOCH
#        runtime-plan.sh complete --root ROOT --now EPOCH --executed CSV

ACTION=${1:-}; shift || true
ROOT=. NOW='' EXECUTED=''
while [ $# -gt 0 ]; do
  case "$1" in --root) ROOT=${2:-}; shift 2;; --now) NOW=${2:-}; shift 2;; --executed) EXECUTED=${2:-}; shift 2;; *) printf '{"status":"error","reason":"invalid_argument"}\n'; exit 2;; esac
done
case "$ACTION" in prepare|complete) ;; *) printf '{"status":"error","reason":"invalid_input"}\n'; exit 2;; esac
case "$NOW" in ''|*[!0-9]*) printf '{"status":"error","reason":"invalid_input"}\n'; exit 2;; esac
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
STATE="${SCRIPT_DIR}/../../runtime/scripts/state.sh"
ROOT=$(CDPATH='' cd -- "$ROOT" && pwd); cd "$ROOT"
COMMON=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || { printf '{"status":"error","reason":"not_a_repository"}\n'; exit 0; }
repo_fp=$({ git rev-parse HEAD; git status --porcelain=v1 -z --untracked-files=all | od -An -tx1; } | git hash-object --stdin)
runtime_fp=$({
  for area in bindings instances publications; do
    [ ! -d "$COMMON/workaholic/runtime/v1/$area" ] || find "$COMMON/workaholic/runtime/v1/$area" -type f -name '*.json' -print
  done | LC_ALL=C sort | while IFS= read -r path; do printf '%s ' "$path"; git hash-object "$path" 2>/dev/null || true; done
} | git hash-object --stdin)
read_state=$($STATE read --scope snapshot --id moderate-steps)
found=$(printf '%s' "$read_state" | jq -r '.data.found // false')
if [ "$ACTION" = prepare ]; then
  if [ "$found" = true ]; then
    record=$(printf '%s' "$read_state" | jq -c .data.record)
    previous_repo=$(printf '%s' "$record" | jq -r '.data.repo_fingerprint // empty')
    previous_runtime=$(printf '%s' "$record" | jq -r '.data.runtime_fingerprint // empty')
    last_run=$(printf '%s' "$record" | jq -c '.data.last_run // {}')
  else previous_repo=''; previous_runtime=''; last_run='{}'; fi
  changed=$(jq -cn --arg old_repo "$previous_repo" --arg repo "$repo_fp" --arg old_runtime "$previous_runtime" --arg runtime "$runtime_fp" \
    '[if $old_repo!=$repo then "repository" else empty end,if $old_runtime!=$runtime then "runtime" else empty end]')
  jq -cn --argjson now "$NOW" --argjson changed "$changed" --argjson last "$last_run" --arg repo "$repo_fp" --arg runtime "$runtime_fp" \
    '{status:"ok",reason:"",now_epoch:$now,changed_snapshots:$changed,last_run:$last,_fingerprints:{repository:$repo,runtime:$runtime}}'
  exit 0
fi

last_run='{}'; revision=''
if [ "$found" = true ]; then
  last_run=$(printf '%s' "$read_state" | jq -c '.data.record.data.last_run // {}')
  revision=$(printf '%s' "$read_state" | jq -r .data.record.revision)
fi
updated=$(printf '%s' "$EXECUTED" | tr ',' '\n' | jq -Rsc --argjson now "$NOW" 'split("\n")|map(select(length>0))|reduce .[] as $id ({}; .[$id]=$now)')
data=$(jq -cn --arg repo "$repo_fp" --arg runtime "$runtime_fp" --argjson old "$last_run" --argjson add "$updated" '{repo_fingerprint:$repo,runtime_fingerprint:$runtime,last_run:($old+$add)}')
input=$(mktemp); trap 'rm -f "$input"' EXIT HUP INT TERM
jq -cn --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --argjson data "$data" '{updated_at:$now,data:$data}' >"$input"
if [ "$found" = true ]; then result=$($STATE update --scope snapshot --id moderate-steps --expected-revision "$revision" --input "$input")
else result=$($STATE create --scope snapshot --id moderate-steps --input "$input"); fi
case "$(printf '%s' "$result" | jq -r .status)" in ok) jq -cn '{status:"ok",reason:""}';; *) jq -cn --arg reason "$(printf '%s' "$result" | jq -r '.reason // "state_conflict"')" '{status:"deferred",reason:$reason}';; esac
