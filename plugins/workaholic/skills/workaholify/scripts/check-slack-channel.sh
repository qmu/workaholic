#!/bin/sh -eu
# Check whether the Slack channel a routine will post to actually exists. Pure read.
#
#   check-slack-channel.sh <repo-name> [channel-prefix]      # prefix defaults to empty
#
# The channel probed is WORKAHOLIC_INBOUND_SLACK_CHANNEL when set — the same variable every
# reader of the channel honours — else `<prefix><repo-name>`. The `dev-` prefix convention
# was retired on 2026-08-28 (the operator's ruling): the default channel is the repository's
# own name, and nothing here expects or requires a prefix any more; a repository whose
# channel still carries one passes it as the second argument or sets the variable.
#
# Output (one JSON line):
#   {"channel": "<repo>", "checked": true,  "exists": true}
#   {"channel": "<repo>", "checked": false, "reason": "no_qfs"|"slack_locked"
#                                                        |"slack_not_connected"
#                                                        |"channel_not_visible"|"probe_failed", ...}
#
# `exists` is only ever `true`. There is no reliable negative: Slack answers "not found"
# for a channel the calling token cannot see, so an absent channel and an invisible one are
# the same response.
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
# WHY THIS MATTERS BEFORE SCHEDULING. The routine templates post to the repository's
# channel. A routine created against a channel that does not exist is a routine
# that runs, does its work, and silently fails at the last step — the most expensive kind
# of broken, because it looks scheduled and healthy.
#
# IT IS ADVISORY, NOT A GATE. `checked: false` must not stop a developer who knows their
# setup; the command reports it and asks. Blocking on a check this environment-dependent
# would make `/workaholify` unusable on any machine without qfs.

set -eu

REPO_NAME="${1:-}"
PREFIX="${2:-}"

[ -n "$REPO_NAME" ] || { echo '{"checked": false, "reason": "no_repo_name"}'; exit 1; }

CHANNEL="${WORKAHOLIC_INBOUND_SLACK_CHANNEL:-${PREFIX}${REPO_NAME}}"
WORKSPACE="${WORKAHOLIC_SLACK_WORKSPACE:-qmu}"

if ! command -v qfs >/dev/null 2>&1; then
  printf '{"channel": "%s", "checked": false, "reason": "no_qfs", "detail": "qfs is not installed on this machine; check the channel by hand"}\n' "$CHANNEL"
  exit 0
fi

OUT=$(qfs run "/slack/${WORKSPACE}/${CHANNEL}/messages |> select text |> limit 1" --json 2>&1 || true)

case "$OUT" in
  *slack_missing_scope*|*slack_channel_name_not_found*)
    # NEITHER OF THESE MEANS "THE CHANNEL DOES NOT EXIST", and treating them that way was
    # this script's own bug -- caught on 2026-08-01 against `dev-workaholic`, a channel the
    # routines demonstrably post to, which this reported as `exists: false`.
    #
    # Slack answers "not found" for a channel the calling token cannot SEE, which is
    # indistinguishable from one that is not there: a private channel the token has not
    # joined, or a workspace scope it was never granted, both look like absence. So the
    # honest report is "could not check", and the caller is told which.
    #
    # THERE IS NO RELIABLE NEGATIVE HERE. `exists: true` is the only claim this script can
    # make; a missing channel and an invisible one cannot be separated by a read. That is a
    # stronger form of the rule this file was written for, learned the hard way by shipping
    # the weaker one.
    printf '{"channel": "%s", "checked": false, "reason": "channel_not_visible", "detail": "Slack answered not-found or missing-scope; the channel may exist and be invisible to this token (private, unjoined, or out of scope). This is NOT evidence that it is absent."}\n' "$CHANNEL"
    exit 0
    ;;
  *slack_auth*)
    printf '{"channel": "%s", "checked": false, "reason": "slack_locked", "detail": "the qfs credential store is locked or Slack needs re-consent; this says NOTHING about whether the channel exists"}\n' "$CHANNEL"
    exit 0
    ;;
  *"connect a Slack workspace"*|*slack_not_connected*)
    printf '{"channel": "%s", "checked": false, "reason": "slack_not_connected", "detail": "no Slack workspace is connected to qfs (qfs connection add slack)"}\n' "$CHANNEL"
    exit 0
    ;;
esac

# Any other error is an unrecognised failure, and an unrecognised failure is not a verdict.
case "$OUT" in
  *'"error"'*)
    printf '{"channel": "%s", "checked": false, "reason": "probe_failed", "detail": "the read failed for a reason this script does not recognise; treat the channel as unverified"}\n' "$CHANNEL"
    exit 0
    ;;
esac

printf '{"channel": "%s", "checked": true, "exists": true}\n' "$CHANNEL"
