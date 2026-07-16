#!/bin/sh -eu
# Delegator to the shared commit-subject policy validator. The canonical rule
# source moved to skills/commit/scripts/check-subject.sh so commit.sh can run
# the gate as a same-dir sibling before staging, and so the outputs/workflows
# bundle (which copies whole skill scripts/ dirs but never hooks/) carries the
# gate too. This path stays as the stable entry point for the hook layers --
# guard-git-commit.sh (PreToolUse Bash) and git/commit-msg (git-native) both
# resolve their lib relative to hooks/ -- so one rule source now drives three
# enforcement points and none can drift.
#
# Same contract as the canonical script: subject as $1 or on stdin; a short
# reason on stdout + exit 1 on violation, silent exit 0 otherwise.

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
exec sh "${SCRIPT_DIR}/../../skills/commit/scripts/check-subject.sh" "$@"
