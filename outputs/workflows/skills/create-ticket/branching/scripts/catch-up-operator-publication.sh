#!/bin/sh -eu
# Catch up the running identity's unreviewed, non-claim publication without merging its PR.
# Usage: catch-up-operator-publication.sh PR [BASE]
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
exec sh "$SCRIPT_DIR/prepare-publication.sh" "${1:-}" "${2:-main}" --catchup-only
