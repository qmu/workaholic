#!/bin/sh -eu
# Bound reconstructable caches and diagnostics; never age out incomplete effects.
# Usage: compact-cache.sh [--log-dir DIR] [--max-log-bytes N]
LOG_DIR=""; MAX=${WORKAHOLIC_LOG_MAX_BYTES:-1048576}
while [ $# -gt 0 ]; do case "$1" in --log-dir) LOG_DIR=${2:-}; shift 2;; --max-log-bytes) MAX=${2:-}; shift 2;; *) printf '{"status":"error","reason":"bad_argument"}\n'; exit 2;; esac; done
case "$MAX" in ''|*[!0-9]*) printf '{"status":"error","reason":"bad_limit"}\n'; exit 2;; esac
COMMON=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || { printf '{"status":"error","reason":"not_repository"}\n'; exit 2; }
BASE="$COMMON/workaholic/runtime/v1"; removed=0; rotated=0
if [ -d "$BASE/snapshots" ]; then
  keep=$(find "$BASE/snapshots" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -rn | sed -n '1,2p' | cut -d' ' -f2-)
  find "$BASE/snapshots" -mindepth 1 -maxdepth 1 -type d -print | while IFS= read -r d; do printf '%s\n' "$keep" | grep -Fqx "$d" || rm -rf "$d"; done
fi
if [ -n "$LOG_DIR" ] && [ -d "$LOG_DIR" ]; then
  for f in "$LOG_DIR"/*.log; do [ -f "$f" ] || continue; size=$(wc -c < "$f" | tr -d ' '); [ "$size" -le "$MAX" ] || { tail -c "$MAX" "$f" > "$f.tmp" && mv "$f.tmp" "$f"; rotated=$((rotated+1)); }; done
fi
# Inbox/outbox/receipt records are deliberately outside both loops above.
jq -cn --argjson rotated "$rotated" '{status:"ok",reason:"",data:{snapshots_kept:2,logs_rotated:$rotated,incomplete_records_removed:0}}'
