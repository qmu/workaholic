#!/bin/bash
# Append an event entry to the trip event log.
# Usage: bash log-event.sh <trip-path> <agent> <event-type> <target> <impact>
# The event log file is created if it does not exist.

set -euo pipefail

trip_path="${1:-}"
agent="${2:-}"
event_type="${3:-}"
target="${4:-}"
impact="${5:-}"

# Validate required arguments
if [ -z "$trip_path" ] || [ -z "$agent" ] || [ -z "$event_type" ]; then
  echo '{"error": "usage: log-event.sh <trip-path> <agent> <event-type> <target> <impact>"}' >&2
  exit 1
fi

log_file="${trip_path}/event-log.md"
timestamp="$(date -Iseconds)"

# Create log file with header if it does not exist
if [ ! -f "$log_file" ]; then
  {
    echo '# Trip Event Log'
    echo ''
    echo '| Timestamp | Agent | Event | Target | Impact |'
    echo '| --------- | ----- | ----- | ------ | ------ |'
  } > "$log_file"
fi

# Append event row
echo "| ${timestamp} | ${agent} | ${event_type} | ${target} | ${impact} |" >> "$log_file"

echo '{"logged": true, "timestamp": "'"${timestamp}"'", "agent": "'"${agent}"'", "event": "'"${event_type}"'"}'
