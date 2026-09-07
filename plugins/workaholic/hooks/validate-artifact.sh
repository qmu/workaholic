#!/bin/sh -eu
# Hook adapter only. Each artifact validator owns its floor; this forwards one event.
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
input=$(cat); tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT HUP INT TERM
printf '%s' "$input" > "$tmp"
for validator in validate-ticket validate-mission validate-story validate-trip validate-feedback validate-strategy; do
  [ -x "$SCRIPT_DIR/${validator}.sh" ] || continue
  set +e; "$SCRIPT_DIR/${validator}.sh" < "$tmp"; code=$?; set -e
  [ "$code" -eq 0 ] || exit "$code"
done
