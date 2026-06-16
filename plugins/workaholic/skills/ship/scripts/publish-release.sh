#!/bin/bash
# Publish a GitHub Release from a generated release-note file, UNLESS the repo
# already has a GitHub Actions workflow that publishes releases (then CI owns it
# and we must not double-publish).
#
# Usage: bash publish-release.sh <branch> <merge-commit> <tag> <notes-file>
# Output: JSON {published, tag, url, reason}
#   reason: ci_publishes | no_notes_file | already_exists | created | error
#
# Hermetic note: the CI-detection branch (ci_publishes / no_notes_file) never
# touches the network. The create branch calls `gh` and requires auth.

set -euo pipefail

branch="${1:-}"
commit="${2:-}"
tag="${3:-}"
notes_file="${4:-}"

if [ -z "$branch" ] || [ -z "$tag" ] || [ -z "$notes_file" ]; then
  echo '{"error": "usage: publish-release.sh <branch> <merge-commit> <tag> <notes-file>"}' >&2
  exit 1
fi

# 1. Defer to an existing GitHub Actions release publisher, if any.
wf_dir=".github/workflows"
if [ -d "$wf_dir" ]; then
  if grep -rqlE 'gh release create|softprops/action-gh-release|actions/create-release' "$wf_dir" 2>/dev/null; then
    echo '{"published": false, "reason": "ci_publishes"}'
    exit 0
  fi
fi

# 2. No CI publisher — create the release ourselves (idempotent).
if [ ! -f "$notes_file" ]; then
  echo '{"published": false, "reason": "no_notes_file"}'
  exit 0
fi

if gh release view "$tag" >/dev/null 2>&1; then
  echo '{"published": false, "reason": "already_exists", "tag": "'"$tag"'"}'
  exit 0
fi

if [ -n "$commit" ]; then
  url=$(gh release create "$tag" --title "$tag" --notes-file "$notes_file" --latest --target "$commit")
else
  url=$(gh release create "$tag" --title "$tag" --notes-file "$notes_file" --latest)
fi

echo '{"published": true, "tag": "'"$tag"'", "url": "'"$url"'", "reason": "created"}'
