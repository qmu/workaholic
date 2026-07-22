#!/bin/sh -eu
# Propose active deferred concerns for demotion — READ-ONLY, mutates nothing.
# The companion to the promotion floor (extract-deferred-concerns.sh): the floor
# stops the tracked corpus from growing; this lists the already-tracked concerns
# at or below the demotion floor so a developer can confirm re-shelving them out
# of the active set. Demotion is a developer decision (demote-concern.sh applies
# it, only on confirmation); this script only PROPOSES.
#
# "At or below the floor" is by severity rank (urgent < moderate < low): with the
# default floor `low`, only `low` concerns are proposed; floor `moderate` proposes
# moderate and low. A concern is never proposed above the floor.
#
# Usage: propose-demotions.sh [floor]        (floor: low | moderate | urgent; default low)
# Output: JSON array [{concern_id, severity, last_seen, path}], sorted by slug,
#         of active concerns at or below the floor. [] when none.

set -eu

dir=".workaholic/concerns"
floor="${1:-low}"

if [ ! -d "$dir" ]; then
  echo '[]'
  exit 0
fi

python3 - "$dir" "$floor" <<'PY'
import json, os, re, sys

d, floor = sys.argv[1], sys.argv[2]
SEV_RANK = {"urgent": 0, "moderate": 1, "low": 2}
floor_rank = SEV_RANK.get(floor, 2)

out = []
for name in sorted(os.listdir(d)):
    if not name.endswith('.md') or name in ('README.md', 'index.md'):
        continue
    path = os.path.join(d, name)
    if not os.path.isfile(path):
        continue
    with open(path, encoding='utf-8', errors='replace') as h:
        text = h.read()
    m = re.match(r'^---\n(.*?)\n---', text, re.DOTALL)
    fm = m.group(1) if m else ''

    def get(key, default=''):
        km = re.search(r'^' + re.escape(key) + r':[ \t]*(.*)$', fm, re.MULTILINE)
        return km.group(1).strip() if km else default

    if get('status') != 'active':
        continue
    severity = get('severity') or 'moderate'
    # At or below the floor: a less-severe (higher rank) or equal concern.
    if SEV_RANK.get(severity, 1) < floor_rank:
        continue
    out.append({
        'concern_id': get('concern_id'),
        'severity': severity,
        'last_seen': get('last_seen'),
        'path': path,
    })

print(json.dumps(out))
PY
