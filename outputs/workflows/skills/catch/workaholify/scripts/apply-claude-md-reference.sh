#!/bin/sh -eu
# Apply the gateway reference `audit-claude-md.sh` checks for: make a repository's
# CLAUDE.md REFER to `workaholic:workaholify`.
#
# WHY IT EXISTS: /workaholify is the preparation command, not an audit (the
# developer's ruling, 2026-08-14, issue #445). Until this script, the CLAUDE.md
# half stopped at "conformant: false" plus an offer, so a repository that ran the
# command still left unprepared and the repair was a manual follow-up nobody
# performed. The layout half already converges; this is the same move applied to
# the wiring half.
#
# WHAT IT WRITES, and the line it will not cross. It appends a REFERENCE to the
# gateway skill — never a copy of any rule (`workaholic:development` /
# `policy-as-plugin`: rules ship in the plugin, so a repository that copied them
# would carry a second source of truth that drifts the moment the plugin updates).
# It creates CLAUDE.md when absent, and otherwise APPENDS: an existing CLAUDE.md is
# the repository's own document, so nothing here rewrites, reorders or removes a
# line of it.
#
# THE CHECK IS COMPOSED, NEVER REIMPLEMENTED. Conformance is read from
# `audit-claude-md.sh`, so "what counts as referring to the gateway" has exactly one
# definition and an apply can never disagree with the audit that motivated it.
#
# IDEMPOTENT: a conformant repository is `{"changed": false, "reason":
# "already_conformant"}` and no byte moves, so the step is safe on every run.
#
# REFUSES RATHER THAN HALF-WRITES: an unwritable CLAUDE.md (or an unwritable repo
# root, when the file must be created) is reported by name as `unwritable` with the
# file untouched — report-only is then the operator's recovery path.
#
# Usage: apply-claude-md-reference.sh [repo-root]   (default: git toplevel, else .)
# Output: JSON {file, changed, created, conformant, reason}
#   reason: applied | already_conformant | unwritable

set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

root="${1:-$(git rev-parse --show-toplevel 2>/dev/null || printf '.')}"
file="${root}/CLAUDE.md"

audit=$(sh "${SCRIPT_DIR}/audit-claude-md.sh" "$root" 2>/dev/null || printf '{"conformant": false}')
conformant=$(printf '%s' "$audit" | sed -n 's/.*"conformant": *\([a-z]*\).*/\1/p')

emit() {
  # $1 changed, $2 created, $3 conformant, $4 reason
  printf '{"file": "%s", "changed": %s, "created": %s, "conformant": %s, "reason": "%s"}\n' \
    "$file" "$1" "$2" "$3" "$4"
}

if [ "$conformant" = "true" ]; then
  emit false false true already_conformant
  exit 0
fi

created=false
if [ -f "$file" ]; then
  if [ ! -w "$file" ]; then
    emit false false false unwritable
    exit 0
  fi
else
  if [ ! -d "$root" ] || [ ! -w "$root" ]; then
    emit false false false unwritable
    exit 0
  fi
  created=true
fi

# The block is deliberately short: a doorway, not a summary. Every rule it could
# restate lives behind the gateway, and a restatement here would be the second
# source of truth this whole design exists to avoid.
{
  if [ "$created" = true ]; then
    printf '# %s\n\n' "$(basename -- "$(cd -- "$root" && pwd)")"
  else
    printf '\n'
  fi
  cat <<'EOF'
## Engineering standards

This repository works under the workaholic engineering standards. The rules are
**not** copied here — read them through the `workaholic:workaholify` gateway skill,
which reaches the pillar policies (planning / design / implementation / operation /
development / safety) and states the working-directory ground rules. Run
`/workaholify` to (re)wire this repository to them.
EOF
} >>"$file"

after=$(sh "${SCRIPT_DIR}/audit-claude-md.sh" "$root" 2>/dev/null || printf '{"conformant": false}')
now=$(printf '%s' "$after" | sed -n 's/.*"conformant": *\([a-z]*\).*/\1/p')
[ -n "$now" ] || now=false

emit true "$created" "$now" applied
