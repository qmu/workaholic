#!/bin/sh -eu
# Re-grade one ACTIVE deferred concern's severity in place, leaving an auditable
# rationale. This is the standalone severity mutator triage was missing:
# severity used to change only as a merge-concerns.sh side effect, so an
# in-place re-grade meant a hand edit the concerns README forbids. Same
# idempotent-mutator shape as the siblings (merge-concerns.sh,
# close-concern.sh): rewrites frontmatter, appends the rationale to the body,
# git-stages its change.
#
# Usage: re-grade.sh <concern-id-or-path> <low|moderate|urgent> "<rationale>"
# Output: JSON {regraded, concern_id, severity[, previous, path, reason]}
# Idempotent: re-grading to the current severity is a no-op
# ({regraded: false, reason: "unchanged"}).

set -eu

arg="${1:-}"
severity="${2:-}"
rationale="${3:-}"

[ -n "$arg" ] || { echo '{"regraded": false, "reason": "no_concern"}'; exit 1; }
case "$severity" in
  low|moderate|urgent) : ;;
  *) echo '{"regraded": false, "reason": "bad_severity"}'; exit 1 ;;
esac
[ -n "$rationale" ] || { echo '{"regraded": false, "reason": "no_rationale"}'; exit 1; }

if [ -f "$arg" ]; then
  file="$arg"
else
  file=".workaholic/concerns/${arg}.md"
fi

if [ ! -f "$file" ]; then
  echo "{\"regraded\": false, \"reason\": \"not_found\", \"path\": \"${file}\"}"
  exit 1
fi

regraded_at=$(date -Iseconds)

result=$(python3 - "$file" "$severity" "$rationale" "$regraded_at" <<'PY'
import json, re, sys
path, severity, rationale, regraded_at = sys.argv[1:5]
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

previous = get('severity')
concern_id = get('concern_id')

if previous == severity:
    print(json.dumps({"regraded": False, "reason": "unchanged",
                      "concern_id": concern_id, "severity": severity}))
    sys.exit(0)

def setkey(key, value):
    for i, line in enumerate(fm_lines):
        if re.match(r'^' + re.escape(key) + r':', line):
            fm_lines[i] = f'{key}: {value}'
            return
    fm_lines.append(f'{key}: {value}')

setkey('severity', severity)

# The auditable trail: append the re-grade to the body, never overwrite history.
if not body.endswith('\n'):
    body += '\n'
body += (f"\n## Re-grade ({regraded_at})\n\n"
         f"- severity: {previous or '(unset)'} -> {severity}\n"
         f"- rationale: {rationale}\n")

with open(path, 'w') as h:
    h.write('---\n' + '\n'.join(fm_lines) + '\n---\n' + body)

print(json.dumps({"regraded": True, "concern_id": concern_id,
                  "severity": severity, "previous": previous, "path": path}))
PY
)

case "$result" in
  *'"regraded": true'*) git add "$file" >/dev/null 2>&1 || true ;;
esac

printf '%s\n' "$result"
