#!/bin/sh -eu
# The proposal batch's processed-commit cursor (docs/loop-engineering-workflow.md
# C2/A3): feedback records are immutable, so "new" is exactly "added between the
# cursor and origin/main". The cursor is RUNNER-LOCAL state (decision C1 - one
# server runs the batch; multi-runner coordination is the phase-3 claim
# protocol's job), stored at .workaholic/proposal-cursor and git-ignored via the
# repo's shared info/exclude (ensured here, idempotently - no commit involved).
#
#   read              -> {"commit": "<sha>", "initialized": <bool>}
#                        Bootstraps an absent cursor to the current origin/main
#                        HEAD (falling back to local main, then HEAD) and reports
#                        initialized: true - pre-existing feedback is treated as
#                        already-seen (safe cold start; backdate the file by hand
#                        to replay a window).
#   advance <commit>  -> {"advanced": true, "commit": "<sha>"}
#                        Refuses a value that is not a known commit.
#
# Never prompts; never fails on a missing cursor (read bootstraps instead).

set -eu

MODE="${1:-read}"

TOP="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$TOP" ] || { echo '{"error": "not_a_git_repo"}'; exit 1; }
CURSOR="${TOP}/.workaholic/proposal-cursor"

# Ensure the cursor file is ignored (runner-local state, never committed).
COMMON="$(git rev-parse --git-common-dir 2>/dev/null || echo "${TOP}/.git")"
case "$COMMON" in /*) : ;; *) COMMON="${TOP}/${COMMON}" ;; esac
mkdir -p "${COMMON}/info"
EXCLUDE="${COMMON}/info/exclude"
if [ ! -f "$EXCLUDE" ] || ! grep -qxF '.workaholic/proposal-cursor' "$EXCLUDE"; then
    printf '%s\n' '.workaholic/proposal-cursor' >> "$EXCLUDE"
fi

case "$MODE" in
    read)
        if [ -f "$CURSOR" ]; then
            c=$(head -n 1 "$CURSOR" | tr -d '[:space:]')
            if git rev-parse --verify -q "${c}^{commit}" >/dev/null 2>&1; then
                printf '{"commit": "%s", "initialized": false}\n' "$c"
                exit 0
            fi
        fi
        # Bootstrap: origin/main tip when known, else local main, else HEAD.
        c=$(git rev-parse --verify -q origin/main 2>/dev/null || true)
        [ -n "$c" ] || c=$(git rev-parse --verify -q main 2>/dev/null || true)
        [ -n "$c" ] || c=$(git rev-parse HEAD)
        mkdir -p "${TOP}/.workaholic"
        printf '%s\n' "$c" > "$CURSOR"
        printf '{"commit": "%s", "initialized": true}\n' "$c"
        ;;
    advance)
        NEW="${2:-}"
        [ -n "$NEW" ] || { echo '{"advanced": false, "reason": "no_commit"}'; exit 1; }
        if ! git rev-parse --verify -q "${NEW}^{commit}" >/dev/null 2>&1; then
            printf '{"advanced": false, "reason": "unknown_commit", "commit": "%s"}\n' "$NEW"
            exit 1
        fi
        NEW=$(git rev-parse "${NEW}^{commit}")
        mkdir -p "${TOP}/.workaholic"
        printf '%s\n' "$NEW" > "$CURSOR"
        printf '{"advanced": true, "commit": "%s"}\n' "$NEW"
        ;;
    *)
        echo '{"error": "bad_mode"}' >&2
        exit 1
        ;;
esac
