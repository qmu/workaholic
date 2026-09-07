#!/bin/sh -eu
# Produce the expensive claims observation once. Consumers project this record and
# never repeat fetch/ref enumeration for the same snapshot.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/claims.sh"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo '{"error":"not_inside_repository"}' >&2; exit 1; }
fetched=$(claims_fetch)
CLAIMS_FETCH_OK=$fetched; export CLAIMS_FETCH_OK
shallow=$(claims_shallow)
base=$(claims_base)
surveyed_sha=$(git rev-parse HEAD 2>/dev/null || printf '')
base_sha=$(git rev-parse --verify --quiet "${base}^{commit}" 2>/dev/null || printf '')
unanswered_file=$(mktemp); trap 'rm -f "$unanswered_file"' EXIT HUP INT TERM
CLAIMS_UNANSWERED_FILE=$unanswered_file; export CLAIMS_UNANSWERED_FILE
rows=$(claims_scan "$base")
unanswered=$(jq -Rn '[inputs | split("\t") | select(length>=2) | {branch:.[0],reason:.[1]}]' <"$unanswered_file")
jq -cn --argjson fetched "$fetched" --argjson shallow "$shallow" --arg base "$base" \
  --arg surveyed "$surveyed_sha" --arg base_sha "$base_sha" --arg rows "$rows" --argjson unanswered "$unanswered" \
  '{schema_version:1,fetched:$fetched,shallow:$shallow,base:$base,surveyed_sha:$surveyed,base_sha:$base_sha,rows_tsv:$rows,merged_lookup_unanswered:$unanswered}'

