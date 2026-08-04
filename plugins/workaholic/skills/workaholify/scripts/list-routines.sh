#!/bin/sh -eu
# List what runs against ONE repository — schedule, target, template status — or report
# honestly that it could not be checked. Pure read: this creates and changes nothing.
#
#   list-routines.sh <repo-url> [--live <file>]        # live JSON on stdin when --live is absent
#
# Output (one JSON line), and the two shapes are deliberately not interchangeable:
#   {"repo","repo_name","checked":true,"template_set_version","total_live",
#    "routines":[{"name","template","status","trigger","schedule","target_repo",
#                 "enabled","trigger_id","drift":[...]}],
#    "missing":[...], "slack_connector":{...}, "elsewhere":{"repos","drifted"}}
#   {"repo","repo_name","checked":false,"reason":"no_live_input"|"unreadable_live_input"
#                                               |"unparseable_live_input"|"api_error"
#                                               |"unrecognised_live_shape"|"comparison_failed",
#    "detail":"..."}
#
# ============ "COULD NOT CHECK" IS NEVER "NOTHING IS CONFIGURED" ============
#
# This is the reason the script exists rather than being a formatting pass over
# `compare-routines.sh`. The audience is a developer who has just joined and cannot tell a
# wrong answer from a right one: told "no routines run against this repository" they will
# believe it, and go on to build on a repository whose feedback, announcement and drive
# routines are all live. So `checked: false` carries NO `routines` key at all — there is
# nothing to misread — and only a response that actually parsed as a routines list may set
# `checked: true`. An empty account and an unreachable API are different answers.
#
# It is the same rule `check-slack-channel.sh` was fixed for, and the same rule that a
# survey once broke by concluding "no routines are installed" from an empty crontab on a
# machine whose routines run in the cloud.
#
# WHY STDIN, AGAIN. Only the `RemoteTrigger` tool can reach the routines API; a shell
# script cannot. The command fetches and pipes the raw response here, which is also what
# lets the suite drive this against fixtures without touching anyone's account.
#
# SCOPE IS PRESENTATION, NOT A NARROWER SURVEY. `compare-routines.sh` still surveys the
# whole fleet, and the fleet's drift is reported here as an `elsewhere` summary rather
# than dropped: one defect replicated across seven repositories is still one defect, and a
# reader scoped to this checkout must at least know the rest exists.

set -eu

REPO="${1:-}"
[ -n "$REPO" ] || { echo '{"checked": false, "reason": "no_repo_url"}' >&2; exit 1; }
shift

LIVE_FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --live)
      LIVE_FILE="${2:-}"
      [ -n "$LIVE_FILE" ] || { echo '{"checked": false, "reason": "no_live_file"}' >&2; exit 1; }
      shift 2
      ;;
    *)
      printf '{"checked": false, "reason": "unknown_argument", "detail": "%s"}\n' "$1" >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

REPO_CLEAN=$(printf '%s' "$REPO" | sed -e 's#/$##' -e 's#\.git$##')
REPO_NAME=$(printf '%s' "$REPO_CLEAN" | sed -e 's#.*/##')

TMP=$(mktemp "${TMPDIR:-/tmp}/workaholic-routine-list.XXXXXX")
trap 'rm -f "$TMP"' EXIT

if [ -n "$LIVE_FILE" ]; then
  if [ ! -f "$LIVE_FILE" ]; then
    # A named file that is not there means the fetch never landed — an unchecked result,
    # not an empty one. Exit 0: this is a report, not a crash.
    printf '{"repo": "%s", "repo_name": "%s", "checked": false, "reason": "unreadable_live_input", "detail": "no such file: %s"}\n' \
      "$REPO_CLEAN" "$REPO_NAME" "$LIVE_FILE"
    exit 0
  fi
  cat "$LIVE_FILE" > "$TMP"
else
  cat > "$TMP"
fi

python3 "${SCRIPT_DIR}/lib/list_routines.py" "$TMP" "$REPO_CLEAN" "$REPO_NAME" "$SCRIPT_DIR"
