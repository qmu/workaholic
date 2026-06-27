#!/bin/sh -eu
# Backfill .workaholic/concerns/ from every story file in .workaholic/stories/.
# Matches each story's branch to a merged PR via the GitHub CLI, then runs
# extract-carryover.sh per story with commits suppressed. Stages and commits
# everything in one batch at the end.
#
# Usage: backfill-carryover.sh
#
# Output: JSON summary {processed: N, skipped: N, files_total: N}.

set -eu

stories_dir=".workaholic/stories"

if [ ! -d "$stories_dir" ]; then
  echo '{"status":"error","reason":"no_stories_dir"}'
  exit 1
fi

# Fetch all merged PRs targeting main so we can map branch -> PR.
pr_json=$(gh pr list --state merged --base main --limit 500 --json number,headRefName,url 2>/dev/null || echo "[]")

# Resolve branch -> {number, url} via python. ($1 = branch)
lookup() {
  python3 - "$pr_json" "$1" <<'PY' 2>/dev/null
import json, sys
prs = json.loads(sys.argv[1])
target = sys.argv[2]
for pr in prs:
    if pr.get("headRefName") == target:
        print(f"{pr['number']}\t{pr['url']}")
        sys.exit(0)
sys.exit(1)
PY
}

processed=0
skipped=0
not_found=""

script_dir="$(cd "$(dirname "$0")" && pwd)"

for story in "$stories_dir"/*.md; do
  [ -e "$story" ] || continue
  base=$(basename "$story" .md)
  [ "$base" = "README" ] && continue

  # Trip stories like "trip-trip-20260319-squashed" need branch normalization;
  # the gh PR list uses the actual ref name (e.g. "trip/trip-20260319-squashed").
  branch="$base"
  case "$base" in
    trip-trip-*) branch="trip/${base#trip-}" ;;
  esac

  if pr_info=$(lookup "$branch"); then
    pr_number=$(printf '%s' "$pr_info" | cut -f1)
    pr_url=$(printf '%s' "$pr_info" | cut -f2)
    NO_COMMIT=1 sh "$script_dir/extract-carryover.sh" "$branch" "$pr_number" "$pr_url" > /dev/null || true
    processed=$((processed+1))
  else
    skipped=$((skipped+1))
    not_found="${not_found}${branch}
"
  fi
done

# Count files written.
files_total=$(find .workaholic/concerns -maxdepth 1 -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')

if [ "$processed" -gt 0 ]; then
  git add .workaholic/concerns/ >/dev/null
  if ! git diff --cached --quiet; then
    git commit -m "Backfill carry-over concerns from historical stories" >/dev/null
  fi
fi

# Build skipped list JSON from the newline-delimited not_found accumulator.
skipped_json=$(printf '%s\n' "$not_found" | grep -v '^$' | jq -R . | jq -s -c . 2>/dev/null || echo '[]')

echo "{\"status\":\"ok\",\"processed\":${processed},\"skipped\":${skipped},\"files_total\":${files_total},\"unmatched_branches\":${skipped_json}}"
