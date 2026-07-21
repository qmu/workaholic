#!/bin/sh -eu
# Predict how long a mission will take a coding agent, deterministically, from the
# trend of ARCHIVED missions. The prediction is median(actual_hours / acceptance-item
# total) across archived missions that carry BOTH a numeric actual_hours and a non-empty
# acceptance list, multiplied by the new mission's planned item count.
#
# It is HONEST about sparse data: with no archived basis it reports basis 0 and
# predicted_hours null — never a fabricated number. Pure read; writes nothing.
#
# Usage: predict-duration.sh <planned-item-count>
# Output: JSON {predicted_hours, basis, per_item_median}
#   predicted_hours / per_item_median are null when basis is 0.

set -eu

COUNT="${1:-}"
case "$COUNT" in ''|*[!0-9]*) echo '{"error": "bad_count"}' >&2; exit 1 ;; esac

ARCHIVE=".workaholic/missions/archive"

PER_ITEMS=""
BASIS=0
if [ -d "$ARCHIVE" ]; then
    for f in "$ARCHIVE"/*/mission.md; do
        [ -f "$f" ] || continue
        ah=$(grep -m1 '^actual_hours:' "$f" 2>/dev/null | sed -e 's/^actual_hours:[ \t]*//' -e 's/[ \t]*$//' || true)
        case "$ah" in ''|*[!0-9.]*) continue ;; esac
        # Acceptance-item total (same counting rule as progress.sh; inlined so this
        # stays a pure scan with no resolver dependency).
        total=$(awk '
            /^## / { in_acc = ($0 ~ /^##[ \t]+Acceptance[ \t]*$/); next }
            in_acc && /^[ \t]*-[ \t]+\[( |x|X)\]/ { total++ }
            END { print total + 0 }
        ' "$f")
        [ "$total" -gt 0 ] 2>/dev/null || continue
        pi=$(awk -v a="$ah" -v t="$total" 'BEGIN { printf "%.6f", a / t }')
        PER_ITEMS="${PER_ITEMS}${pi}
"
        BASIS=$((BASIS + 1))
    done
fi

if [ "$BASIS" -eq 0 ]; then
    printf '{"predicted_hours": null, "basis": 0, "per_item_median": null}\n'
    exit 0
fi

MEDIAN=$(printf '%s' "$PER_ITEMS" | awk '
    /[0-9]/ { v[n++] = $1 }
    END {
        for (i = 0; i < n; i++)
            for (j = i + 1; j < n; j++)
                if (v[j] < v[i]) { t = v[i]; v[i] = v[j]; v[j] = t }
        if (n % 2) m = v[(n - 1) / 2]; else m = (v[n / 2 - 1] + v[n / 2]) / 2
        printf "%.6f", m
    }')

PRED=$(awk -v m="$MEDIAN" -v c="$COUNT" 'BEGIN { printf "%.2f", m * c }')
printf '{"predicted_hours": %s, "basis": %d, "per_item_median": %s}\n' "$PRED" "$BASIS" "$MEDIAN"
