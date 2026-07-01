#!/bin/sh -eu
# Emit a short project label for AskUserQuestion headers.
# Usage: project-label.sh
# Output: JSON {"project": "<label>"}
#
# The label is the basename of the git repository root, truncated to 12
# characters so it fits the AskUserQuestion `header` chip. Commands render it in
# every interactive prompt so a developer running several Claude Code sessions
# across tmux panes can tell which repository a waiting dialog belongs to.
#
# Kept deliberately network-free and cheap: unlike git-context.sh (which runs
# `git remote show origin`), this is called at prompt time on every question, so
# it must not touch the network.

set -eu

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$ROOT" ] || { echo 'not inside a git repository; project label unavailable' >&2; exit 1; }

LABEL=$(basename "$ROOT" | cut -c1-12)

printf '{"project": "%s"}\n' "$LABEL"
