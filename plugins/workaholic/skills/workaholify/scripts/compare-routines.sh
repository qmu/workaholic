#!/bin/sh -eu
# Compare the live routines against the shipped templates — across EVERY repository that
# already carries a workaholic routine, not only this one.
#
#   <RemoteTrigger list JSON> | compare-routines.sh <repo-url>
#
# Output (one JSON line):
#   {"repo","repo_name","total_live","drifted_total",
#    "slack_connector":{"present",...},
#    "this_repo":{"missing":[...], "present":[{id,name,trigger_id,drift:[...]}], "unknown":[...]},
#    "other_repos":[{"repo","repo_name","present":[{id,name,trigger_id,drift:[...]}]}]}
#
# WHY STDIN. The live routines come from the claude.ai remote-trigger API, and only the
# `RemoteTrigger` tool can reach it — a shell script cannot. So the command fetches and
# pipes the raw response here, and the comparison stays a script: the Shell Script
# Principle keeps this logic out of markdown, and a script is the only form a test can
# drive against fixtures without touching anyone's account.
#
# IT REPORTS DRIFT ACROSS THE WHOLE FLEET. The templates are one set applied to many
# repositories, so drift is a property of the fleet rather than of a checkout: `Merged PR
# qmu-co-jp` losing its `model` is the same defect whichever repository you happen to be
# standing in, and a survey scoped to the current repo would need somebody to visit seven
# checkouts to find seven instances of one problem.
#
# THE ASYMMETRY BETWEEN `this_repo` AND `other_repos` IS DELIBERATE:
#   this_repo    — missing AND drifted. You are here; adopting a template is in scope.
#   other_repos  — drifted ONLY, over routines that already exist. A repository with no
#                  `[Drive]` routine has not necessarily failed to install one — that
#                  template is still a pilot, and "every repo should have all three" is
#                  not established. Proposing to create routines in repositories nobody
#                  is working in would be inventing policy out of a survey.
#
# WHAT COUNTS AS "FOR THIS REPOSITORY". A routine belongs to a repo when its
# `job_config.ccr.session_context.sources[].git_repository.url` matches, compared after
# stripping a trailing slash and `.git`. The NAME is not the identity — names are what
# drift, and matching on them would report a renamed routine as both missing and unknown.
#
# DRIFT IS REPORTED PER FIELD, NOT AS A BOOLEAN. Measured on the live account when this
# was written: `Merged PR qmu-co-jp` and `[FB] coop-csnet` carry no `model` while every
# sibling pins `claude-opus-5`, and `[FB] data-platform` has one extra prompt line. "This
# routine differs" would not tell a developer which of those they are looking at.
#
# A MISSING SLACK CONNECTOR IS DRIFT. Every template posts to `dev-<repo>`; a routine
# without the connector runs, does its work, and fails silently at the last step — which
# is the most expensive kind of broken, because it looks scheduled and healthy.
#
# `unknown` IS INFORMATION, NOT AN ERROR. A routine pointing at this repo that matches no
# template is somebody's deliberate one-off. It is listed so nothing is invisible, and
# nothing here ever proposes deleting it — the API has no delete, and that asymmetry is a
# feature: this can add and refresh, never remove.

set -eu

REPO="${1:-}"
[ -n "$REPO" ] || { echo '{"error": "no_repo_url"}' >&2; exit 1; }

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

REPO_CLEAN=$(printf '%s' "$REPO" | sed -e 's#/$##' -e 's#\.git$##')
REPO_NAME=$(printf '%s' "$REPO_CLEAN" | sed -e 's#.*/##')

LIVE=$(cat)
[ -n "$LIVE" ] || { echo '{"error": "no_live_input"}' >&2; exit 1; }

TMP=$(mktemp "${TMPDIR:-/tmp}/workaholic-routines.XXXXXX")
trap 'rm -f "$TMP"' EXIT
printf '%s' "$LIVE" > "$TMP"

TEMPLATES=$(sh "${SCRIPT_DIR}/list-routine-templates.sh")

# The comparison is JSON-shaped on both sides, so it is done in python3 rather than by
# hand-rolling a JSON reader in sed — the repo already depends on python3 in its test
# suite, and a fragile parser here would fail in the direction that hides drift.
python3 "${SCRIPT_DIR}/lib/compare_routines.py" "$TMP" "$REPO_CLEAN" "$REPO_NAME" "$SCRIPT_DIR" "$TEMPLATES"
