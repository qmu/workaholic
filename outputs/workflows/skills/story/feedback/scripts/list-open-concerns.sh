#!/bin/sh -eu
# List the OPEN concern set from the feedback stream — the single reader every
# consumer (the /story judge flow, the proposal batch) goes through.
#
# A concern is OPEN iff:
#   * it is a kind: concern feedback record, AND
#   * no record names it in `supersedes` (resolution is a superseding record,
#     docs/loop-engineering-workflow.md H2/H3), AND
#   * it carries no migration-only `closed:` field (the one-time stamp
#     migrate-concerns.sh puts on records inherited from the retired
#     concerns/archive/).
#
# Output: JSON envelope {active_count, my_lane_count, owner_counts,
#                        should_triage, migrated, concerns: [...]}, each concern being
#                {path, concern_id, status, severity, owner, first_seen,
#                 last_seen, origin_pr, origin_pr_url, origin_branch,
#                 origin_commit, body} — the same envelope the retired
# report-side lister carried, so the /story flow reads it unchanged. should_triage is permanently false: the triage machinery
# retired with the merger (curation is the reader's judgment over the stream).
#
# Runs migrate-concerns.sh first (best-effort), so a not-yet-migrated repo
# heals on the first read.
#
# THAT MIGRATION IS A WRITE, SO THIS READER REPORTS IT. `migrated` carries how many
# records the migration wrote on this call (0 on every already-migrated repo, which
# is every call after the first). It is never staged — the migration leaves the
# caller's index alone by contract — but files did appear in the working tree, and a
# read that silently changes the tree is exactly the surprise the index defect was
# (`workaholic:implementation` / observability). The field is always present, so a
# consumer can tell "nothing happened" from "the key is missing".

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

migration=$(sh "${SCRIPT_DIR}/migrate-concerns.sh" 2>/dev/null || true)
migrated=$(printf '%s' "$migration" | sed -n 's/.*"migrated": *\([0-9][0-9]*\).*/\1/p')
[ -n "$migrated" ] || migrated=0

dir=".workaholic/feedbacks"

if [ ! -d "$dir" ]; then
  printf '{"active_count": 0, "my_lane_count": 0, "owner_counts": {}, "should_triage": false, "migrated": %s, "concerns": []}\n' "$migrated"
  exit 0
fi

actor_email=$(git config user.email 2>/dev/null || true)

python3 - "$dir" "${actor_email}" "${migrated}" <<'PY'
import json, os, re, sys

d, actor = sys.argv[1], sys.argv[2].strip()
migrated = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].isdigit() else 0

records = []      # (name, fields-dict, body)
superseded = set()
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

    fields = {}
    for line in fm_text.split('\n'):
        km = re.match(r'^([A-Za-z0-9_]+):[ \t]*(.*)$', line)
        if km:
            fields[km.group(1)] = km.group(2).strip()

    if fields.get('supersedes'):
        superseded.add(fields['supersedes'])
    records.append((name, fields, body))

concerns = []
for name, fields, body in records:
    if fields.get('kind') != 'concern':
        continue
    if fields.get('closed'):
        continue
    if fields.get('supersedes'):
        continue  # a resolution EVENT, not an open concern
    if name in superseded:
        continue
    pr = fields.get('origin_pr', '')
    concerns.append({
        'path': os.path.join(d, name),
        'concern_id': fields.get('concern_id') or name[:-3],
        'status': 'active',
        'severity': fields.get('severity') or 'moderate',
        'owner': fields.get('owner', ''),
        'first_seen': fields.get('first_seen') or fields.get('created_at', ''),
        'last_seen': fields.get('last_seen') or fields.get('created_at', ''),
        'origin_pr': int(pr) if pr.isdigit() else 0,
        'origin_pr_url': fields.get('origin_pr_url', ''),
        'origin_branch': fields.get('origin_branch', ''),
        'origin_commit': fields.get('origin_commit', ''),
        'body': body,
    })

owner_counts = {}
for c in concerns:
    key = c['owner'] or '(unowned)'
    owner_counts[key] = owner_counts.get(key, 0) + 1

if actor:
    my_lane_count = sum(1 for c in concerns if c['owner'] == actor or not c['owner'])
else:
    my_lane_count = len(concerns)

print(json.dumps({
    'active_count': len(concerns),
    'my_lane_count': my_lane_count,
    'owner_counts': owner_counts,
    'should_triage': False,
    'migrated': migrated,
    'concerns': concerns,
}))
PY
