#!/bin/sh -eu
# Opt-in installer for the git-native commit-subject gate (hooks/git/commit-msg).
#
# Points the repo's git at the plugin's hooks directory via core.hooksPath so the
# commit-msg subject gate runs on every commit -- including a developer's own
# terminal `git commit`, which the PreToolUse Bash gate cannot see.
#
# The plugin must NOT silently mutate a consumer repo, so this is run deliberately
# by the repo owner. It REFUSES to clobber an existing core.hooksPath or to shadow
# classic .git/hooks without --force, printing manual-merge guidance instead.
#
# Usage: sh install-git-hooks.sh [--force]

set -eu

FORCE=0
case "${1:-}" in
  --force) FORCE=1 ;;
  "") : ;;
  *) echo "Usage: install-git-hooks.sh [--force]" >&2; exit 1 ;;
esac

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
HOOKS_DIR="${SCRIPT_DIR}/git"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 1
fi

if [ ! -x "${HOOKS_DIR}/commit-msg" ]; then
  echo "Error: ${HOOKS_DIR}/commit-msg is missing or not executable." >&2
  exit 1
fi

current=$(git config --get core.hooksPath || true)

# Already pointing at us -> idempotent success.
if [ "$current" = "$HOOKS_DIR" ]; then
  echo "Already installed: core.hooksPath -> ${HOOKS_DIR}"
  exit 0
fi

# A different core.hooksPath is set -> refuse without --force.
if [ -n "$current" ] && [ "$FORCE" -ne 1 ]; then
  echo "Error: core.hooksPath is already set to: ${current}" >&2
  echo "Refusing to overwrite it. Either:" >&2
  echo "  - re-run with --force to replace it, or" >&2
  echo "  - merge manually: have ${current}/commit-msg also exec ${HOOKS_DIR}/commit-msg." >&2
  exit 1
fi

# No core.hooksPath, but classic .git/hooks exist that core.hooksPath would
# disable -> refuse without --force (setting core.hooksPath is exclusive).
if [ -z "$current" ] && [ "$FORCE" -ne 1 ]; then
  git_dir=$(git rev-parse --git-dir)
  existing=$(find "${git_dir}/hooks" -maxdepth 1 -type f ! -name '*.sample' 2>/dev/null || true)
  if [ -n "$existing" ]; then
    echo "Error: this repo has classic .git/hooks that core.hooksPath would disable:" >&2
    printf '%s\n' "$existing" | sed 's|^|  |' >&2
    echo "Setting core.hooksPath is exclusive (it disables .git/hooks/*)." >&2
    echo "Re-run with --force to set it anyway, or copy ${HOOKS_DIR}/commit-msg" >&2
    echo "into ${git_dir}/hooks/ manually to keep both." >&2
    exit 1
  fi
fi

git config core.hooksPath "$HOOKS_DIR"
echo "Installed: core.hooksPath -> ${HOOKS_DIR}"
echo "The commit-msg subject gate now runs on every git commit in this repo."
echo "Undo with:        git config --unset core.hooksPath"
echo "Bypass one commit: git commit --no-verify"
echo "If the plugin's install path changes, re-run this installer."
