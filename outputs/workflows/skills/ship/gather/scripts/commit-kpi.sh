#!/bin/sh -eu
# Compute the commit-count orchestration-throughput KPI from git history, on demand.
#
# This is NOT a KPI of human developer performance — it measures how well a fleet of
# coding agents is orchestrated and kept running: how many agents, for how long,
# producing how much reviewable change. The unit is meaningful only because per-commit
# size is normalized by the release-scan changed-lines gate (ticket 20260721020759);
# this script is the MEASUREMENT, that gate is the NORMALIZATION. Their only coupling is
# the threshold constant, read here from the single source.
#
# No dashboard, no stored metrics files — derived from git history, identical for any
# caller (human or AI). POSIX; git log / --numstat / awk only; no network.
#
# Two policy guards belong to this KPI and are documented with it (see catch SKILL.md):
#   - quota consumed only to raise the number is worthless (`development/weekly-quota`);
#   - history is never reshaped for the number — no squash/rebase grooming; the KPI
#     reads history, it never motivates rewriting it (`development/commit-change-history`).
#
# Usage: commit-kpi.sh [window]   (window is `git log --since` syntax; default "1 week")
# Output: JSON {window, total_commits, agent_commits, agent_share, median_changed_lines,
#               p90_changed_lines, oversize_commits}
#   agent_commits: commits bearing an Anthropic `Co-Authored-By` trailer (the same
#     identification the ~8,600-commit study used). agent_share: agent/total (0..1).
#   *_changed_lines: added+deleted per commit over non-binary rows (lockfiles/minified
#     excluded). oversize_commits: commits over MAX_COMMIT_CHANGED_LINES, or null while
#     that gate constant does not exist yet.

set -eu

WINDOW="${1:-1 week}"

SCRIPT_DIR=$(dirname "$0")
# The single source of the per-commit threshold is the release-scan gate. The path is
# overridable via COMMIT_KPI_SCAN only so tests can exercise the pre-gate null case
# (a scan script without the constant); production never sets it.
SCAN="${COMMIT_KPI_SCAN:-${SCRIPT_DIR}/../../release-scan/scripts//scan-branch-safety.sh}"

# Single-source the per-commit threshold from the release-scan gate. Absent -> null
# oversize (the gate has not landed in this checkout), never a fabricated count.
THRESH=$(grep -m1 '^MAX_COMMIT_CHANGED_LINES=' "$SCAN" 2>/dev/null | sed -e 's/^MAX_COMMIT_CHANGED_LINES=//' -e 's/[ \t].*//' || true)
case "$THRESH" in ''|*[!0-9]*) THRESH="" ;; esac

SHAS=$(git log --since="$WINDOW" --pretty=format:'%H' 2>/dev/null || true)

TOTAL=0
AGENT=0
OVERSIZE=0
LINES=""

for sha in $SHAS; do
    [ -n "$sha" ] || continue
    TOTAL=$((TOTAL + 1))
    if git log -1 --pretty=format:'%B' "$sha" 2>/dev/null | grep -qi 'co-authored-by:.*anthropic'; then
        AGENT=$((AGENT + 1))
    fi
    cl=$(git show --numstat --format= "$sha" 2>/dev/null | awk '
        { a = $1; d = $2; p = $3 }
        a ~ /^[0-9]+$/ && d ~ /^[0-9]+$/ {
            if (p ~ /\.lock$/ || p ~ /-lock\.json$/ || p ~ /\.min\.(js|css)$/ || p ~ /\.map$/) next
            s += a + d
        }
        END { print s + 0 }
    ')
    LINES="${LINES}${cl}
"
    if [ -n "$THRESH" ] && [ "$cl" -gt "$THRESH" ]; then
        OVERSIZE=$((OVERSIZE + 1))
    fi
done

# median + p90 over the per-commit changed-line list.
STATS=$(printf '%s' "$LINES" | awk '
    /[0-9]/ { v[n++] = $1 }
    END {
        if (n == 0) { print "0 0"; exit }
        for (i = 0; i < n; i++)
            for (j = i + 1; j < n; j++)
                if (v[j] < v[i]) { t = v[i]; v[i] = v[j]; v[j] = t }
        med = (n % 2) ? v[int((n - 1) / 2)] : (v[n / 2 - 1] + v[n / 2]) / 2
        idx = int(0.9 * n + 0.999999); if (idx > n) idx = n; if (idx < 1) idx = 1
        printf "%g %g", med, v[idx - 1]
    }')
MED=${STATS% *}
P90=${STATS#* }

if [ "$TOTAL" -gt 0 ]; then
    SHARE=$(awk -v a="$AGENT" -v t="$TOTAL" 'BEGIN { printf "%.2f", a / t }')
else
    SHARE="0.00"
fi

if [ -n "$THRESH" ]; then
    OVER_JSON="$OVERSIZE"
else
    OVER_JSON="null"
fi

WINDOW_ESC=$(printf '%s' "$WINDOW" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')

printf '{"window": "%s", "total_commits": %d, "agent_commits": %d, "agent_share": %s, "median_changed_lines": %s, "p90_changed_lines": %s, "oversize_commits": %s}\n' \
    "$WINDOW_ESC" "$TOTAL" "$AGENT" "$SHARE" "$MED" "$P90" "$OVER_JSON"
