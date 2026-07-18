#!/bin/sh -eu
# List all deferred concern files under .workaholic/concerns/ with status: active.
# Output: JSON envelope {active_count, should_triage, concerns: [...]}, each
# concern being {path, concern_id, status, severity, first_seen, last_seen,
#                origin_pr, origin_pr_url, origin_branch, origin_commit, body}.
#
# should_triage is the machine half of report's Phase 1b count trigger:
# active_count > CONCERN_TRIAGE_THRESHOLD (default 20). The threshold lives
# HERE, not in prose, so the trigger fires from data rather than from a human
# remembering the number.
#
# The whole array is assembled in ONE python3 pass with json.dumps doing every
# escape. The previous per-field shell interpolation emitted raw values into
# the JSON stream (origin_pr unquoted and unvalidated, per-field escapes easy
# to miss), and this script ships to consumer repos via outputs/workflows —
# a corpus with a quote or backslash in any field must still parse.
#
# Used by /report to feed the deferred-concern judge (general-purpose) subagent.

set -eu

dir=".workaholic/concerns"

if [ ! -d "$dir" ]; then
  printf '{"active_count": 0, "should_triage": false, "concerns": []}\n'
  exit 0
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Living identity migration: back-fill concern_id/first_seen/last_seen and
# collapse any legacy carried-from clone chains before listing, so the judge
# sees one fresh file per concern. Best-effort — never blocks the listing.
sh "${SCRIPT_DIR}/migrate-concern-identity.sh" >/dev/null 2>&1 || true

python3 - "$dir" "${CONCERN_TRIAGE_THRESHOLD:-20}" <<'PY'
import json, os, re, sys

d, threshold = sys.argv[1], int(sys.argv[2])
concerns = []
for name in sorted(os.listdir(d)):
    if not name.endswith('.md') or name in ('README.md', 'index.md'):
        continue
    path = os.path.join(d, name)
    if not os.path.isfile(path):
        continue
    with open(path, encoding='utf-8', errors='replace') as h:
        text = h.read()
    m = re.match(r'^---\n(.*?)\n---\n?(.*)$', text, re.DOTALL)
    fm_text = m.group(1) if m else ''
    body = (m.group(2) if m else text)[:4000]

    def get(key, default=''):
        km = re.search(r'^' + re.escape(key) + r':[ \t]*(.*)$', fm_text, re.MULTILINE)
        return km.group(1).strip() if km else default

    if get('status') != 'active':
        continue
    pr = get('origin_pr')
    concerns.append({
        'path': path,
        'concern_id': get('concern_id'),
        'status': 'active',
        'severity': get('severity') or 'moderate',
        'first_seen': get('first_seen'),
        'last_seen': get('last_seen'),
        'origin_pr': int(pr) if pr.isdigit() else 0,
        'origin_pr_url': get('origin_pr_url'),
        'origin_branch': get('origin_branch'),
        'origin_commit': get('origin_commit'),
        'body': body,
    })

print(json.dumps({
    'active_count': len(concerns),
    'should_triage': len(concerns) > threshold,
    'concerns': concerns,
}))
PY
