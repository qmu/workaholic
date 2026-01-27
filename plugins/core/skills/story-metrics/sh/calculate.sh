#!/bin/sh -eu
# Calculate performance metrics for a branch
# Outputs JSON with commits, timestamps, duration, and velocity

set -eu

BASE_BRANCH="${1:-main}"

# Get commit count
COMMITS=$(git rev-list --count "${BASE_BRANCH}..HEAD")

if [ "$COMMITS" -eq 0 ]; then
    echo '{"commits":0,"started_at":null,"ended_at":null,"duration_hours":0,"duration_days":0,"velocity":0,"velocity_unit":"hour"}'
    exit 0
fi

# Get first and last commit timestamps (ISO 8601)
STARTED_AT=$(git log "${BASE_BRANCH}..HEAD" --reverse --format=%cI | head -1)
ENDED_AT=$(git log "${BASE_BRANCH}..HEAD" --format=%cI | head -1)

# Calculate duration in hours
START_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${STARTED_AT%+*}" "+%s" 2>/dev/null || date -d "${STARTED_AT}" "+%s")
END_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${ENDED_AT%+*}" "+%s" 2>/dev/null || date -d "${ENDED_AT}" "+%s")
DURATION_SECS=$((END_EPOCH - START_EPOCH))

# Minimum 1 hour for single-commit or very short sessions
if [ "$DURATION_SECS" -lt 3600 ]; then
    DURATION_SECS=3600
fi

# Calculate duration in hours (2 decimal places)
DURATION_HOURS=$(echo "scale=2; $DURATION_SECS / 3600" | bc)

# Count distinct calendar days with commits
DURATION_DAYS=$(git log "${BASE_BRANCH}..HEAD" --format=%cd --date=short | sort -u | wc -l | tr -d ' ')

# Determine velocity unit and calculate velocity
if [ "$(echo "$DURATION_HOURS < 8" | bc -l)" -eq 1 ]; then
    VELOCITY_UNIT="hour"
    VELOCITY=$(echo "scale=1; $COMMITS / $DURATION_HOURS" | bc)
else
    VELOCITY_UNIT="day"
    VELOCITY=$(echo "scale=1; $COMMITS / $DURATION_DAYS" | bc)
fi

# Output JSON
cat <<EOF
{
  "commits": ${COMMITS},
  "started_at": "${STARTED_AT}",
  "ended_at": "${ENDED_AT}",
  "duration_hours": ${DURATION_HOURS},
  "duration_days": ${DURATION_DAYS},
  "velocity": ${VELOCITY},
  "velocity_unit": "${VELOCITY_UNIT}"
}
EOF
