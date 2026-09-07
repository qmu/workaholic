#!/bin/sh

publication_result() {
  _pc_ok=$1 _pc_reason=$2 _pc_data=$3
  jq -cn --argjson ok "$_pc_ok" --arg reason "$_pc_reason" --argjson data "$_pc_data" '{ok:$ok,reason:$reason}+$data'
}

publication_usage() {
  publication_result false invalid_input "$(jq -cn --arg detail "$1" '{detail:$detail}')"
  printf '%s\n' "$1" >&2
  exit 2
}

publication_context() {
  PUBLICATION_ID=$1
  case "$PUBLICATION_ID" in ''|*[!A-Za-z0-9._-]*|.|..) publication_usage "invalid transaction id";; esac
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || publication_usage "not inside a git repository"
  PUBLICATION_ROOT=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
  [ -n "$PUBLICATION_ROOT" ] || publication_usage "main worktree is unresolved"
  PUBLICATION_PATH="${PUBLICATION_ROOT}/.worktrees/publication-${PUBLICATION_ID}"
  PUBLICATION_STATE="${PUBLICATION_SCRIPT_DIR}/../../runtime/scripts/state.sh"
  [ -x "$PUBLICATION_STATE" ] || publication_usage "runtime state writer is missing"
  PUBLICATION_INSTANCE=${WORKAHOLIC_INSTANCE_ID:-}
  [ -n "$PUBLICATION_INSTANCE" ] || PUBLICATION_INSTANCE="publication-${PUBLICATION_ID}"
  PUBLICATION_NONCE=$(printf '%s' "$PUBLICATION_INSTANCE:$PUBLICATION_ID" | sha256sum | cut -c1-24)
  PUBLICATION_OWNER=$(jq -cn --arg i "$PUBLICATION_INSTANCE" --arg n "$PUBLICATION_NONCE" --arg h "publication:$PUBLICATION_ID" '{instance_id:$i,nonce:$n,harness_receipt:$h}')
}

publication_state() {
  (cd "$PUBLICATION_ROOT" && "$PUBLICATION_STATE" "$@")
}

publication_read() {
  publication_state read --scope publication --id "$PUBLICATION_ID"
}

publication_record() {
  printf '%s' "$1" | jq -c '.data.record // null'
}

publication_write_data() {
  _pc_record=$1 _pc_data=$2 _pc_now=$3
  _pc_rev=$(printf '%s' "$_pc_record" | jq -r .revision)
  _pc_input=$(mktemp)
  jq -cn --arg now "$_pc_now" --argjson data "$_pc_data" '{updated_at:$now,data:$data}' >"$_pc_input"
  _pc_written=$(publication_state update --scope publication --id "$PUBLICATION_ID" --expected-revision "$_pc_rev" --input "$_pc_input")
  rm -f "$_pc_input"
  printf '%s\n' "$_pc_written"
}
