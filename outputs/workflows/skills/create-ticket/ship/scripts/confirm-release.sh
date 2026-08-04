#!/bin/sh -eu
# Record a confirmation attempt against a release/* branch's ship record (decision L3).
#
# This closes the record's other half: the cut said what the release carries, this says
# whether it reached production and when. It is the SECOND confirmation in the model — the
# per-unit one (ship/SKILL.md §5 step 4) proves one branch before it lands; this proves a
# batch already on the base. It never defers or weakens the first.
#
# A FAILED CONFIRMATION IS RECORDED, NOT ERASED, and the release branch is NOT deleted:
# the branch is the rollback boundary and the record is the evidence of the attempt. The
# next attempt cuts a FRESH release branch with its own record, because a release branch's
# identity is "the commits confirmed, or not, at that moment" — re-pointing or force-pushing
# one destroys the only account of what was tried.
#
# Body entries are APPEND-ONLY (several attempts against one branch each leave a block);
# the frontmatter carries the latest verdict, which is what a reader greps for.
#
# Usage: confirm-release.sh <release-branch> <method> <result> <status> [tag] [base]
#   <method>  the confirmation method executed (browser | server-batch | db-query |
#             api-probe | other), matching the .workaholic/deployments/ contract
#   <result>  a short, NON-SECRET observed result. Never a credential — the record is
#             version-controlled and public.
#   <status>  pass | fail
#   [tag]     the release tag this promotion published, when there is one
# Output: JSON {ok, path, release_branch, status, confirmed_at, committed, pushed,
#               push_error} or {ok:false, reason}
#   reason: usage | bad_status | possible_secret | no_record | not_on_base
#         | dirty_workspace | commit_failed

set -eu

BRANCH="${1:-}"
METHOD="${2:-}"
RESULT="${3:-}"
STATUS="${4:-}"
TAG="${5:-}"
BASE="${6:-main}"

fail() {
  printf '{"ok": false, "reason": "%s"}\n' "$1"
  exit 0
}

if [ -z "$BRANCH" ] || [ -z "$METHOD" ] || [ -z "$RESULT" ] || [ -z "$STATUS" ]; then
  echo '{"ok": false, "reason": "usage"}' >&2
  exit 1
fi

case "$STATUS" in
  pass|fail) : ;;
  *) fail bad_status ;;
esac

if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  echo '{"ok": false, "reason": "not_a_git_repo"}' >&2
  exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Same secret guard record-evidence.sh applies, from the same shared rule source, for the
# same reason: this is a few lines of free-text deploy evidence bound for a public,
# version-controlled record, where a false positive costs a rephrase and a false negative
# publishes a credential.
. "${SCRIPT_DIR}/../../release-scan/scripts//lib/secret-patterns.sh"

scan_secrets() {
  _re_in=$(printf '%s\n' "$@")
  if printf '%s\n' "$_re_in" | secret_pass1_grep >/dev/null 2>&1; then
    return 0
  fi
  printf '%s\n' "$_re_in" | grep -Eiq "${_SP_KEY}[[:space:]]*[:=][[:space:]]*[^[:space:]]{6,}"
}

if scan_secrets "$RESULT" "$METHOD" "$TAG"; then
  printf '{"ok": false, "reason": "possible_secret"}\n'
  exit 1
fi

SLUG=$(printf '%s' "$BRANCH" | tr '/' '-')
FILE="${ROOT}/.workaholic/releases/${SLUG}.md"
[ -f "$FILE" ] || fail no_record

CURRENT=$(git branch --show-current 2>/dev/null || true)
[ "$CURRENT" = "$BASE" ] || fail not_on_base
[ -z "$(git status --porcelain 2>/dev/null)" ] || fail dirty_workspace

TS=$(date -Iseconds)
CONFIRMER=$(git config user.email 2>/dev/null || true)
if [ "$STATUS" = pass ]; then
  RECORD_STATUS=confirmed
else
  RECORD_STATUS=failed
fi

# Rewrite the frontmatter's verdict keys in place. Only the block between the first two
# `---` lines is touched, so a `status:` written in the body is never mistaken for the
# record's own.
TMP="${FILE}.tmp.$$"
awk -v st="$RECORD_STATUS" -v at="$TS" -v m="$METHOD" -v cs="$STATUS" -v tg="$TAG" -v mod="$TS" '
  NR == 1 && $0 == "---" { infm = 1; print; next }
  infm && /^---[ \t]*$/ { infm = 0; print; next }
  infm && /^status:/              { print "status: " st; next }
  infm && /^confirmed_at:/        { print "confirmed_at: " at; next }
  infm && /^confirmation_method:/ { print "confirmation_method: " m; next }
  infm && /^confirmation_status:/ { print "confirmation_status: " cs; next }
  infm && /^tag:/                 { print "tag: " tg; next }
  infm && /^modified_at:/         { print "modified_at: " mod; next }
  { print }
' "$FILE" > "$TMP"
mv "$TMP" "$FILE"

{
  printf -- '\n### %s — %s\n\n' "$TS" "$STATUS"
  printf -- '- **When:** %s\n' "$TS"
  printf -- '- **By:** %s\n' "$CONFIRMER"
  printf -- '- **Method:** %s\n' "$METHOD"
  printf -- '- **Status:** %s\n' "$STATUS"
  printf -- '- **Observed:** %s\n' "$RESULT"
  if [ -n "$TAG" ]; then
    printf -- '- **Tag:** %s\n' "$TAG"
  fi
  if [ "$STATUS" = fail ]; then
    printf -- '\nThe release branch is kept: it is the rollback boundary, and `%s` is unaffected\n' "$BASE"
    printf -- 'because its units are already merged there. The next attempt cuts a fresh release\n'
    printf -- 'branch with its own record.\n'
  fi
} >> "$FILE"

sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true

git add "$FILE" >/dev/null 2>&1 || true
git add "${ROOT}/.workaholic/index.md" "${ROOT}/.workaholic/releases/index.md" >/dev/null 2>&1 || true

if ! sh "${SCRIPT_DIR}/../../commit/scripts//commit.sh" --skip-staging \
  "Record release confirmation" \
  "A release record is only durable if its outcome is written where the cut was." \
  "Records the ${STATUS} confirmation of ${BRANCH} against ${BASE}." \
  "" "" "Confirmation executed before this was written." >/dev/null 2>&1; then
  fail commit_failed
fi

. "${SCRIPT_DIR}/lib/push-outcome.sh"
push_and_report

printf '{"ok": true, "path": ".workaholic/releases/%s.md", "release_branch": "%s", "status": "%s", "confirmed_at": "%s", "committed": true, "pushed": %s, "push_error": "%s"}\n' \
  "$SLUG" "$BRANCH" "$RECORD_STATUS" "$TS" "$PUSH_OK" "$PUSH_ERROR"
