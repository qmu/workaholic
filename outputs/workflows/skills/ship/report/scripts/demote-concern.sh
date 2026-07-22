#!/bin/sh -eu
# Demote an active deferred concern out of the tracked set during triage: mark it
# status: demoted with a reason and move it into .workaholic/concerns/archive/ so
# it drops out of the active corpus. The REVERSIBLE, evidence-recording analogue
# of close-concern.sh — but demotion is "not worth tracking", NOT resolution:
# a demoted concern is not fixed and not a won't-fix, only re-shelved, and it can
# be moved back. It is preserved in git history and still referenced by its
# branch's story. Idempotent: a concern already in archive/ is a no-op.
#
# Demotion is a DEVELOPER decision — propose-demotions.sh proposes, the /report
# triage confirms, and only then is this mutator run. It never runs unattended.
#
# Usage: demote-concern.sh <concern-id-or-path> [reason]
# Output: JSON {demoted, concern_id, status, path[, reason]}

set -eu

arg="${1:-}"
reason="${2:-}"

[ -n "$arg" ] || { echo '{"demoted": false, "reason": "no_concern"}'; exit 1; }

if [ -f "$arg" ]; then
  file="$arg"
else
  file=".workaholic/concerns/${arg}.md"
fi

archive_dir=".workaholic/concerns/archive"
mkdir -p "$archive_dir"

base=$(basename "$file")
if [ ! -f "$file" ]; then
  if [ -f "${archive_dir}/${base}" ]; then
    echo "{\"demoted\": false, \"reason\": \"already_archived\", \"path\": \"${archive_dir}/${base}\"}"
    exit 0
  fi
  echo "{\"demoted\": false, \"reason\": \"not_found\", \"path\": \"${file}\"}"
  exit 1
fi

demoted_at=$(date -Iseconds)

concern_id=$(python3 - "$file" "$reason" "$demoted_at" <<'PY'
import sys, re
path, reason, demoted_at = sys.argv[1:4]
with open(path) as h:
    text = h.read()
m = re.match(r'^---\n(.*?)\n---\n?(.*)$', text, re.DOTALL)
fm_lines = m.group(1).split('\n') if m else []
body = m.group(2) if m else text

def get(key):
    for line in fm_lines:
        km = re.match(r'^' + re.escape(key) + r':\s*(.*)$', line)
        if km:
            return km.group(1).strip()
    return ''

concern_id = get('concern_id')

def setkey(key, value):
    for i, line in enumerate(fm_lines):
        if re.match(r'^' + re.escape(key) + r':', line):
            fm_lines[i] = f'{key}: {value}'
            return
    fm_lines.append(f'{key}: {value}')

setkey('status', 'demoted')
setkey('demoted_reason', reason)
setkey('demoted_at', demoted_at)

with open(path, 'w') as h:
    h.write('---\n' + '\n'.join(fm_lines) + '\n---\n' + body)

print(concern_id)
PY
)

dest="${archive_dir}/${base}"
git mv "$file" "$dest" 2>/dev/null || mv "$file" "$dest"
git add "$dest" >/dev/null 2>&1 || true

printf '{"demoted": true, "concern_id": "%s", "status": "demoted", "path": "%s", "reason": "%s"}\n' \
  "$concern_id" "$dest" "$reason"
