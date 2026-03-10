#!/bin/bash
# Initialize a trip directory structure under .workaholic/.trips/
# Usage: bash init-trip.sh <trip-name>
# Output: JSON with trip_path

set -euo pipefail

trip_name="${1:-}"

if [ -z "$trip_name" ]; then
  echo '{"error": "trip name is required"}' >&2
  exit 1
fi

if ! echo "$trip_name" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$'; then
  echo '{"error": "trip name must be lowercase alphanumeric with hyphens, no leading/trailing hyphens"}' >&2
  exit 1
fi

trip_path=".workaholic/.trips/${trip_name}"

if [ -d "$trip_path" ]; then
  echo '{"error": "trip directory already exists", "trip_path": "'"$trip_path"'"}' >&2
  exit 1
fi

mkdir -p "${trip_path}/directions" "${trip_path}/models" "${trip_path}/designs"

echo '{"trip_path": "'"$trip_path"'"}'
