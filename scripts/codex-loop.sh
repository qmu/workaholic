#!/bin/sh -eu
# Compatibility entrypoint. The published plugin owns the maintained supervisor.

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PLUGIN_LAUNCHER="${REPO_ROOT}/plugins/workaholic/skills/work/scripts/codex-loop.sh"

if [ ! -f "$PLUGIN_LAUNCHER" ]; then
    printf 'clock_wrapper_missing: %s\n' "$PLUGIN_LAUNCHER" >&2
    printf 'Update or reinstall the Workaholic plugin; its clock wrapper is missing.\n' >&2
    exit 2
fi

exec sh "$PLUGIN_LAUNCHER" "$@"
