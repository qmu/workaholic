#!/bin/sh -eu
# Append a "## Deployment Evidence" block to a branch story, capturing the
# production-confirmation proof (or, for status=bypassed, the explicit record of
# an accepted-risk merge WITHOUT confirmation) BEFORE the PR is merged. Reviewers
# see the evidence on the PR; the merged story carries it permanently.
#
# The block records the deployer explicitly (`By:` = the configured git
# user.email at ship time) so /catch attributes the deployment to a stated
# fact instead of inferring it from whoever last touched the story file.
#
# Usage: bash record-evidence.sh <branch> <target> <method> <result> <status>
#   <result> = a short, NON-SECRET observed result (status/version/hash/response).
#              Never pass credentials, tokens, or cookies — the story is public.
#   <status> = pass | fail | bypassed   (bypassed = an explicit accepted-risk
#              merge WITHOUT a production confirmation; see /ship §1-4 override)
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

# The credential KEY GROUP (_SP_KEY) and the pass-1 unmistakable shapes
# (secret_pass1_grep) come from the branch scanner's shared rule source, so the
# two guards cannot drift — the previous inline copy silently lacked the
# suffixed keywords (SECRET_KEY, aws_secret_access_key, ...) the scanner had
# gained. Pass 2's value judgment (secret_grep) is deliberately NOT used here:
# this guard reads a few lines of free-text deploy evidence bound for a PUBLIC
# story, where a false positive costs a rephrase and a false negative publishes
# a credential, so a generic assignment is flagged on the key name alone,
# whatever its right-hand side looks like.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/../../release-scan/scripts//lib/secret-patterns.sh"

# Returns 0 (match) if any argument looks like a secret.
scan_secrets() {
  _re_in=$(printf '%s\n' "$@")
  if printf '%s\n' "$_re_in" | secret_pass1_grep >/dev/null 2>&1; then
    return 0
  fi
  printf '%s\n' "$_re_in" | grep -Eiq "${_SP_KEY}[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}"
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
deployer=$(git config user.email 2>/dev/null || true)

{
  printf '\n## Deployment Evidence\n\n'
  printf -- '- **When:** %s\n' "$ts"
  printf -- '- **By:** %s\n' "$deployer"
  printf -- '- **Target:** %s\n' "$target"
  printf -- '- **Method:** %s\n' "$method"
  printf -- '- **Status:** %s\n' "$status"
  printf -- '- **Observed:** %s\n' "$result"
} >> "$story"

printf '{"recorded": true, "story": ".workaholic/stories/%s.md", "status": "%s"}\n' "$branch" "$status"
