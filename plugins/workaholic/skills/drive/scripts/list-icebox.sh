#!/bin/sh -eu
# List the iceboxed tickets, one path per line (empty output if none).
#
# Since 2026-08-13 (issue #436) the icebox is a STATE, not a directory: an
# iceboxed ticket lives in the archive carrying `status: icebox`. The retired
# `tickets/icebox/` directory is still read, indefinitely and deliberately, for
# the same reason list-todo.sh still reads `todo/<user>/`: a reader that only saw
# the new shape would turn the living migration into a gate, and a checkout that
# had not run it yet would report an empty icebox — which is worse than a slow
# convergence, because the icebox is developer-curated and its contents are
# somebody's deliberate deferrals.
#
# The icebox survives as a state rather than folding into `abandoned` because the
# two are different decisions: iceboxed is DEFERRED and promotable
# (promote-icebox.sh brings one back), abandoned is DECIDED AGAINST.

set -eu

ROOT=".workaholic/tickets"

# 1. The state: any archived ticket carrying `status: icebox`.
if [ -d "${ROOT}/archive" ]; then
    find "${ROOT}/archive" -name '*.md' -type f 2>/dev/null | sort | while IFS= read -r t; do
        [ -f "$t" ] || continue
        state=$(awk '
            NR == 1 { if ($0 != "---") exit; next }
            /^---[ \t]*$/ { exit }
            /^status:/ { sub(/^status:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
        ' "$t" 2>/dev/null || true)
        # `if`, not `&&`: the last iteration's status is the loop's status, so a
        # trailing non-match would make this script exit 1 on a healthy read.
        if [ "$state" = "icebox" ]; then printf '%s\n' "$t"; fi
    done
fi

# 2. The retired directory, until the living migration converges it.
if [ -d "${ROOT}/icebox" ]; then
    find "${ROOT}/icebox" -maxdepth 1 -name '*.md' -type f | sort
fi
