#!/bin/sh -eu
# Check whether the Slack channel a routine will post to actually exists. Pure read.
#
#   check-slack-channel.sh <repo-name> [channel-prefix]      # prefix defaults to dev-
#
# Output (one JSON line):
#   {"channel": "dev-<repo>", "checked": true,  "exists": true|false}
#   {"channel": "dev-<repo>", "checked": false, "reason": "no_qfs"|"slack_locked"
#                                                        |"slack_not_connected"|"probe_failed", ...}
#
# ============ "CANNOT CHECK" IS NEVER REPORTED AS "DOES NOT EXIST" ============
#
# This is the entire reason the script exists rather than being an inline probe. Right
# now, on a locked credential store, BOTH an existing channel and a nonexistent one come
# back with the identical `slack_auth` error — so a naive "did the read succeed?" test
# reports every channel as missing and would send a developer to create channels that are
# already there. `checked: false` with a named reason is the honest answer; only a probe
# that actually reached Slack may set `exists`.
#
# That failure class has bitten this project twice in one day: a survey concluded "no
# routines are installed" from an empty crontab on a machine whose routines run in the
# cloud. Absence of evidence is not evidence of absence, and a script that cannot tell
# the two apart must say so.
#
# WHY THIS MATTERS BEFORE SCHEDULING. All three routine templates post to
# `dev-<repo_name>`. A routine created against a channel that does not exist is a routine
# that runs, does its work, and silently fails at the last step — the most expensive kind
# of broken, because it looks scheduled and healthy.
#
# IT IS ADVISORY, NOT A GATE. `checked: false` must not stop a developer who knows their
# setup; the command reports it and asks. Blocking on a check this environment-dependent
# would make `/workaholify` unusable on any machine without qfs.

set -eu

REPO_NAME="${1:-}"
PREFIX="${2:-dev-}"

[ -n "$REPO_NAME" ] || { echo '{"checked": false, "reason": "no_repo_name"}'; exit 1; }

CHANNEL="${PREFIX}${REPO_NAME}"
WORKSPACE="${WORKAHOLIC_SLACK_WORKSPACE:-qmu}"

if ! command -v qfs >/dev/null 2>&1; then
  printf '{"channel": "%s", "checked": false, "reason": "no_qfs", "detail": "qfs is not installed on this machine; check the channel by hand"}\n' "$CHANNEL"
  exit 0
fi

OUT=$(qfs run "/slack/${WORKSPACE}/${CHANNEL}/messages |> select text |> limit 1" --json 2>&1 || true)

case "$OUT" in
  *slack_auth*)
    printf '{"channel": "%s", "checked": false, "reason": "slack_locked", "detail": "the qfs credential store is locked or Slack needs re-consent; this says NOTHING about whether the channel exists"}\n' "$CHANNEL"
    exit 0
    ;;
  *"connect a Slack workspace"*|*slack_not_connected*)
    printf '{"channel": "%s", "checked": false, "reason": "slack_not_connected", "detail": "no Slack workspace is connected to qfs (qfs connection add slack)"}\n' "$CHANNEL"
    exit 0
    ;;
esac

# A read that came back without an error object reached Slack and found the channel.
case "$OUT" in
  *'"error"'*)
    printf '{"channel": "%s", "checked": true, "exists": false, "detail": "Slack was reachable and the channel did not resolve"}\n' "$CHANNEL"
    exit 0
    ;;
esac

printf '{"channel": "%s", "checked": true, "exists": true}\n' "$CHANNEL"
