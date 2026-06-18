#!/bin/sh -eu
# Append a "## Deployment Evidence" block to a branch story, capturing the
# production-confirmation proof BEFORE the PR is merged. Reviewers see the
# evidence on the PR; the merged story carries it permanently.
#
# Usage: bash record-evidence.sh <branch> <target> <method> <result> <status>
#   <result> = a short, NON-SECRET observed result (status/version/hash/response).
#              Never pass credentials, tokens, or cookies — the story is public.
#   <status> = pass | fail
# Output: JSON {"recorded": bool, "story"?: path, "status"?: status, "reason"?: ...}
#
# Secret guard: the free-text inputs are scanned for common secret shapes
# (cloud keys, GitHub/Slack tokens, bearer/basic auth, PEM keys, password=/token=
# assignments). On a match the script refuses to write and exits non-zero, so a
# credential cannot leak into the version-controlled, public PR story. The scan
# deliberately does NOT flag bare hex/base64 (commit hashes, versions are legit).

set -eu

branch="$1"
target="$2"
method="$3"
result="$4"
status="$5"

# Returns 0 (match) if any argument looks like a secret.
scan_secrets() {
  printf '%s\n' "$@" | grep -Eiq \
    -e 'AKIA[0-9A-Z]{16}' \
    -e 'gh[pousr]_[A-Za-z0-9]{20,}' \
    -e 'github_pat_[A-Za-z0-9_]{20,}' \
    -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
    -e '(bearer|basic)[[:space:]]+[A-Za-z0-9._~+/=-]{16,}' \
    -e '-----BEGIN[ A-Z]*PRIVATE KEY-----' \
    -e '(password|passwd|secret|token|api[_-]?key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}'
}

if scan_secrets "$result" "$method" "$target"; then
  printf '{"recorded": false, "reason": "possible_secret"}\n'
  exit 1
fi

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
story="${root}/.workaholic/stories/${branch}.md"

if [ ! -f "$story" ]; then
  printf '{"recorded": false, "reason": "no_story"}\n'
  exit 0
fi

ts=$(date -Iseconds)

{
  printf '\n## Deployment Evidence\n\n'
  printf -- '- **When:** %s\n' "$ts"
  printf -- '- **Target:** %s\n' "$target"
  printf -- '- **Method:** %s\n' "$method"
  printf -- '- **Status:** %s\n' "$status"
  printf -- '- **Observed:** %s\n' "$result"
} >> "$story"

printf '{"recorded": true, "story": ".workaholic/stories/%s.md", "status": "%s"}\n' "$branch" "$status"
