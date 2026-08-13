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
# Usage: bash record-evidence.sh <branch> <target> <method> <result> <status> [<note>]
#   <result> = a short, NON-SECRET observed result (status/version/hash/response).
#              Never pass credentials, tokens, or cookies — the story is public.
#   <status> = pass | fail | not_run | bypassed
#              not_run = no check ran; the declared method cannot execute in this
#                        environment. DELIBERATELY distinct from fail: "we could
#                        not check" and "we checked and it was wrong" call for
#                        different acts, and conflating them makes an unverified
#                        deployment look like a verified one.
#              bypassed = an explicit accepted-risk merge WITHOUT a production
#                        confirmation; see /ship §1-4 override.
#   <note>   = optional path to the Release Note carrying this target's plan. Given
#              one, the same attempt is ALSO appended there as a
#              `## Deployment Verification` block, so a reader holding the plan can
#              see whether the verification it asked for ever ran.
# Output: JSON {"recorded": bool, "story"?: path, "note"?: path, "status"?: status,
#               "reason"?: ...}
#
# ONE WRITER, TWO DESTINATIONS (2026-08-13). The story's `## Deployment Evidence` is
# the branch's permanent record for reviewers; the note's `## Deployment Verification`
# is where the reader holding the deployment plan looks. Same evidence, two audiences —
# and one writer, so they cannot disagree and so the secret guard below cannot be
# routed around by a second, divergent writer with its own redaction rules.
#
# THE NOTE BLOCK IS APPEND-ONLY. A second attempt adds a block and never rewrites the
# first, matching confirm-release.sh's rule that a failed confirmation deletes nothing.
# An attempt is history; the plan above it is the draft.
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
note="${6:-}"

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

# The four states are a CLOSED set, checked here. An unrecognised word written
# into the record would be indistinguishable from a status nobody defined, and
# the whole point of `not_run` is that a reader can tell it from `fail`.
case "$status" in
  pass|fail|not_run|bypassed) ;;
  *)
    printf '{"recorded": false, "reason": "bad_status"}\n'
    exit 1
    ;;
esac

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
story="${root}/.workaholic/stories/${branch}.md"

note_path=""
if [ -n "$note" ]; then
  case "$note" in
    /*) note_path="$note" ;;
    *) note_path="${root}/${note}" ;;
  esac
  [ -f "$note_path" ] || note_path=""
fi

if [ ! -f "$story" ] && [ -z "$note_path" ]; then
  printf '{"recorded": false, "reason": "no_story"}\n'
  exit 0
fi

ts=$(date -Iseconds)
deployer=$(git config user.email 2>/dev/null || true)

story_rel=""
if [ -f "$story" ]; then
  {
    printf '\n## Deployment Evidence\n\n'
    printf -- '- **When:** %s\n' "$ts"
    printf -- '- **By:** %s\n' "$deployer"
    printf -- '- **Target:** %s\n' "$target"
    printf -- '- **Method:** %s\n' "$method"
    printf -- '- **Status:** %s\n' "$status"
    printf -- '- **Observed:** %s\n' "$result"
  } >> "$story"
  story_rel=".workaholic/stories/${branch}.md"
fi

# The note's block answers the plan drafted above it, in the same document. It is
# APPENDED under a single `## Deployment Verification` heading: the heading is
# written once, every later attempt adds another `### Attempt` beneath it.
note_rel=""
if [ -n "$note_path" ]; then
  if ! grep -q '^## Deployment Verification$' "$note_path"; then
    printf '\n## Deployment Verification\n' >> "$note_path"
  fi
  {
    printf '\n### Attempt — %s (%s)\n\n' "$target" "$status"
    printf -- '- **When:** %s\n' "$ts"
    printf -- '- **By:** %s\n' "$deployer"
    printf -- '- **Target:** %s\n' "$target"
    printf -- '- **Method declared:** %s\n' "$method"
    printf -- '- **Status:** %s\n' "$status"
    printf -- '- **Observed:** %s\n' "$result"
    printf -- '- **Answers:** the `## Deployment Plan` entry for `%s` in this note.\n' "$target"
    printf -- '- **Also recorded in:** %s\n' "${story_rel:-(no story for this branch)}"
  } >> "$note_path"
  note_rel=${note_path#"${root}/"}
fi

printf '{"recorded": true, "story": "%s", "note": "%s", "status": "%s"}\n' \
  "$story_rel" "$note_rel" "$status"
