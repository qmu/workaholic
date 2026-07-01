#!/bin/sh -eu
# Resolve the /explain PDF export directory and whether writing there needs the
# developer's consent. All destination logic lives here so no conditional shell
# sits in the skill markdown (Shell Script Principle).
#
# Usage: resolve-export-path.sh [dest-dir]
#   dest-dir — optional explicit destination directory. When omitted, the export
#   priority is Desktop ($HOME/Desktop) first, then Home ($HOME).
#
# Output: JSON { chosen_dir, is_home, needs_permission, exists, writable }
#   is_home / needs_permission are true whenever the resolved directory is the
#   Home directory itself — writing a report there always requires consent,
#   whether Home was chosen explicitly or reached as the Desktop fallback.
#   Desktop and any other explicit destination write without a prompt.

set -eu

HOME_DIR="${HOME:-}"
[ -n "$HOME_DIR" ] || { echo 'HOME is not set' >&2; exit 1; }
HOME_DIR=${HOME_DIR%/}

DEST="${1:-}"

if [ -n "$DEST" ]; then
    CHOSEN=${DEST%/}
elif [ -d "${HOME_DIR}/Desktop" ]; then
    CHOSEN="${HOME_DIR}/Desktop"
else
    CHOSEN="${HOME_DIR}"
fi

if [ "$CHOSEN" = "$HOME_DIR" ]; then
    IS_HOME=true
    NEEDS_PERMISSION=true
else
    IS_HOME=false
    NEEDS_PERMISSION=false
fi

if [ -d "$CHOSEN" ]; then
    EXISTS=true
else
    EXISTS=false
fi

if [ -d "$CHOSEN" ] && [ -w "$CHOSEN" ]; then
    WRITABLE=true
else
    WRITABLE=false
fi

cat <<EOF
{
  "chosen_dir": "${CHOSEN}",
  "is_home": ${IS_HOME},
  "needs_permission": ${NEEDS_PERMISSION},
  "exists": ${EXISTS},
  "writable": ${WRITABLE}
}
EOF
