#!/bin/sh -eu
# Close an active deferred concern during triage: mark its status and reason and
# move it into .workaholic/concerns/archive/ so it drops out of the active set.
# Idempotent: a concern already in archive/ (already closed) is a no-op.
#
# Usage: close-concern.sh <concern-id-or-path> <resolved|accepted> [reason]
#   resolved  — the concern is fixed / no longer applies.
#   accepted  — a deliberate, documented won't-fix (inherent trade-off).
# Output: JSON {closed, concern_id, status, path[, reason]}

set -eu

arg="${1:-}"
status="${2:-}"
reason="${3:-}"

[ -n "$arg" ] || { echo '{"closed": false, "reason": "no_concern"}'; exit 1; }
case "$status" in
  resolved|accepted) : ;;
  *) echo '{"closed": false, "reason": "bad_status"}'; exit 1 ;;
esac

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
    echo "{\"closed\": false, \"reason\": \"already_closed\", \"path\": \"${archive_dir}/${base}\"}"
    exit 0
  fi
  echo "{\"closed\": false, \"reason\": \"not_found\", \"path\": \"${file}\"}"
  exit 1
fi

closed_at=$(date -Iseconds)

concern_id=$(python3 - "$file" "$status" "$reason" "$closed_at" <<'PY'
import sys, re
path, status, reason, closed_at = sys.argv[1:5]
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

setkey('status', status)
setkey('closed_reason', reason)
setkey('closed_at', closed_at)

with open(path, 'w') as h:
    h.write('---\n' + '\n'.join(fm_lines) + '\n---\n' + body)

print(concern_id)
PY
)

dest="${archive_dir}/${base}"
git mv "$file" "$dest" 2>/dev/null || mv "$file" "$dest"
git add "$dest" >/dev/null 2>&1 || true

printf '{"closed": true, "concern_id": "%s", "status": "%s", "path": "%s", "reason": "%s"}\n' \
  "$concern_id" "$status" "$dest" "$reason"
