#!/bin/sh -eu
# Extract concerns from a shipped story's section 6 and persist them under
# .workaholic/concerns/, one file per concern, keyed on a STABLE concern
# identity so a still-active concern is UPDATED in place rather than re-cloned.
#
# Section 6 is expected to use this structure (or "None"):
#
#   ## 6. Concerns
#
#   ### <Title>
#
#   - **Severity:** urgent | moderate | low
#   - **Description:** <text> (see [hash](url) in `path`)
#   - **How to Fix:** <text>
#
#   ### <Next Title>
#   ...
#
# A concern's identity is `concern_id` — the slug of its title with any leading
# "(carried from …)" parenthetical stripped. On extraction:
#   - if an ACTIVE concern with that id exists  -> update it in place (bump
#     last_seen, escalate severity to the most-severe, refresh text); no new file.
#   - if an ARCHIVED (resolved/superseded) one exists -> skip (never resurface).
#   - otherwise -> create a fresh <concern_id>.md (first_seen = last_seen = now).
# This kills the NN-carried-from-... accumulation at the source; freshness is the
# invariant (see also migrate-concern-identity.sh, which collapses legacy chains).
#
# Usage: extract-deferred-concerns.sh <branch> <pr-number> <pr-url>
# Output: single JSON line summarizing what was extracted.

set -eu

branch="${1:-}"
pr_number="${2:-}"
pr_url="${3:-}"

if [ -z "$branch" ] || [ -z "$pr_number" ] || [ -z "$pr_url" ]; then
  echo '{"status":"error","reason":"missing_args","extracted":0}'
  exit 1
fi

story_file=".workaholic/stories/${branch}.md"

if [ ! -f "$story_file" ]; then
  echo "{\"status\":\"skipped\",\"reason\":\"no_story_file\",\"path\":\"$story_file\",\"extracted\":0}"
  exit 0
fi

mkdir -p .workaholic/concerns

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Living identity migration first: back-fill concern_id/first_seen/last_seen and
# collapse any legacy carried-from clone chains, so the update-or-create below
# sees one file per concern. Best-effort — never blocks extraction.
sh "${SCRIPT_DIR}/../../report/scripts/migrate-concern-identity.sh" >/dev/null 2>&1 || true

origin_commit=$(git rev-parse --short HEAD)
created_at=$(date -Iseconds)

result=$(python3 - "$story_file" "$pr_number" "$pr_url" "$branch" "$origin_commit" "$created_at" <<'PY'
import sys, re, os, json, glob

story_file, pr_number, pr_url, branch, origin_commit, created_at = sys.argv[1:7]

with open(story_file) as h:
    text = h.read()

# Parse the shipped story's frontmatter for the machine-readable relations it
# carries (both optional): the mission slug and the tickets: list the story
# covers. Each extracted concern inherits them.
story_mission = ""
story_tickets = "[]"
fm = re.match(r'^---\n(.*?)\n---\n', text, re.DOTALL)
if fm:
    for line in fm.group(1).split('\n'):
        mm = re.match(r'\s*mission:\s*(.*)$', line)
        if mm and not story_mission:
            story_mission = mm.group(1).strip()
        tm = re.match(r'\s*tickets:\s*(.*)$', line)
        if tm and tm.group(1).strip():
            story_tickets = tm.group(1).strip()

# Isolate section 6 (## 6. ...) up to the next top-level "## " heading.
m = re.search(r'^##\s+6\.\s.*?$(.*?)(?=^##\s+\d+\.\s|\Z)', text, re.MULTILINE | re.DOTALL)
section = m.group(1) if m else ""
blocks = re.split(r'^###\s+', section, flags=re.MULTILINE)[1:]

SEV_RANK = {"urgent": 0, "moderate": 1, "low": 2}


def field(block, label):
    pat = re.compile(r'^\s*-?\s*\*\*' + re.escape(label) + r':\*\*\s*(.*)$', re.MULTILINE)
    mm = pat.search(block)
    return mm.group(1).strip() if mm else ""


def strip_carried(title):
    return re.sub(r'^\(carried from[^)]*\)\s*', '', title).strip()


def slugify(s):
    s = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', s)
    s = re.sub(r'`([^`]+)`', r'\1', s)
    s = s.lower()
    s = re.sub(r'[^a-z0-9 ]', ' ', s)
    words = [w for w in s.split() if w][:6]
    return '-'.join(words)[:60].strip('-')


def read_fm(path):
    with open(path) as h:
        t = h.read()
    mm = re.match(r'^---\n(.*?)\n---\n?(.*)$', t, re.DOTALL)
    if not mm:
        return None, t
    fmv = {}
    for line in mm.group(1).split('\n'):
        km = re.match(r'^([A-Za-z0-9_]+):(.*)$', line)
        if km:
            fmv[km.group(1)] = km.group(2).strip()
    return fmv, mm.group(2)


# Index existing concerns by concern_id: active (updatable) and archived (skip).
active_by_id = {}
archived_ids = set()
for p in glob.glob('.workaholic/concerns/*.md'):
    if os.path.basename(p)[:-3] in ('README', 'index'):
        continue
    fmv, _ = read_fm(p)
    if fmv and fmv.get('concern_id'):
        active_by_id[fmv['concern_id']] = p
for p in glob.glob('.workaholic/concerns/archive/*.md'):
    fmv, _ = read_fm(p)
    if fmv and fmv.get('concern_id'):
        archived_ids.add(fmv['concern_id'])

created, updated = [], []
seen_this_run = set()

for block in blocks:
    lines = block.split('\n')
    title = re.sub(r'^\d+(-\d+)?\.\s*', '', lines[0].strip())
    if not title or title.lower() == 'none':
        continue
    severity = field(block, 'Severity').lower() or 'moderate'
    if severity not in ('urgent', 'moderate', 'low'):
        severity = 'moderate'
    description = field(block, 'Description')
    fix = field(block, 'How to Fix') or field(block, 'How To Fix') or field(block, 'Fix')

    concern_id = slugify(strip_carried(title)) or 'concern'
    if concern_id in seen_this_run:
        continue
    seen_this_run.add(concern_id)

    # Archived (resolved/superseded) -> never resurface.
    if concern_id in archived_ids:
        continue

    if concern_id in active_by_id:
        # UPDATE IN PLACE: bump last_seen, escalate severity, refresh text.
        path = active_by_id[concern_id]
        fmv, _ = read_fm(path)
        existing_sev = fmv.get('severity', 'moderate')
        merged_sev = severity if SEV_RANK.get(severity, 1) < SEV_RANK.get(existing_sev, 1) else existing_sev
        with open(path) as h:
            content = h.read()
        content = re.sub(r'(?m)^last_seen:.*$', f'last_seen: {created_at}', content)
        content = re.sub(r'(?m)^severity:.*$', f'severity: {merged_sev}', content)
        if description:
            content = re.sub(r'(?s)(## Description\n\n).*?(\n\n## How to Fix)',
                             lambda mm: mm.group(1) + description + mm.group(2), content)
        if fix:
            content = re.sub(r'(?s)(## How to Fix\n\n).*?$',
                             lambda mm: mm.group(1) + fix + '\n', content)
        with open(path, 'w') as h:
            h.write(content)
        updated.append(path)
        continue

    # CREATE fresh <concern_id>.md
    path = f'.workaholic/concerns/{concern_id}.md'
    if os.path.exists(path):
        continue
    body = [
        '---',
        'type: Concern',
        f'concern_id: {concern_id}',
        f'mission: {story_mission}',
        f'tickets: {story_tickets}',
        f'origin_pr: {pr_number}',
        f'origin_pr_url: {pr_url}',
        f'origin_branch: {branch}',
        f'origin_commit: {origin_commit}',
        f'created_at: {created_at}',
        f'first_seen: {created_at}',
        f'last_seen: {created_at}',
        f'severity: {severity}',
        'status: active',
        'resolved_by_pr:',
        'resolved_by_commit:',
        '---',
        '',
        f'# {title}',
        '',
        '## Description',
        '',
        description,
        '',
        '## How to Fix',
        '',
        fix,
        '',
    ]
    with open(path, 'w') as h:
        h.write('\n'.join(body))
    created.append(path)
    active_by_id[concern_id] = path

print(json.dumps({"created": created, "updated": updated}))
PY
)

created_files=$(printf '%s' "$result" | python3 -c "import json,sys; print('\n'.join(json.load(sys.stdin)['created']))")
created_json=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['created']))")
count_created=$(printf '%s' "$result" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['created']))")
count_updated=$(printf '%s' "$result" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['updated']))")
total=$((count_created + count_updated))

# `extracted` counts NEW files only (created), so a re-extracted still-active
# concern that is merely refreshed in place reports extracted:0 — the no-clone
# invariant. `files` lists the newly-created files; `updated` counts in-place
# refreshes. The commit still fires when anything changed (created or updated).
if [ "$total" -eq 0 ]; then
  echo "{\"status\":\"ok\",\"created\":0,\"updated\":0,\"extracted\":0,\"files\":[]}"
  exit 0
fi

# Mission changelog: a NEWLY-deferred concern that advances a mission records a
# "concern deferred (stuck)" line on that mission (idempotent). Updated (already
# deferred) concerns add no new line. Best-effort — never blocks extraction.
story_mission=$(awk '
    NR == 1 { if ($0 != "---") exit; next }
    /^---[ \t]*$/ { exit }
    /^mission:[ \t]*/ { sub(/^mission:[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }
' "$story_file" 2>/dev/null || true)
if [ -n "$story_mission" ] && [ "$count_created" -gt 0 ]; then
  printf '%s\n' "$created_files" | while IFS= read -r cfile; do
    [ -n "$cfile" ] || continue
    sh "${SCRIPT_DIR}/../../mission/scripts/append-changelog.sh" \
      "$story_mission" "concern deferred (stuck)" "$(basename "$cfile")" >/dev/null 2>&1 || true
  done
fi

if [ -z "${NO_COMMIT:-}" ]; then
  sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true
  git add .workaholic/concerns/ .workaholic/missions/ >/dev/null 2>&1 || git add .workaholic/concerns/ >/dev/null
  git commit -m "Add deferred concerns from PR #${pr_number}" >/dev/null
  git push >/dev/null 2>&1 || true
fi

echo "{\"status\":\"ok\",\"created\":${count_created},\"updated\":${count_updated},\"extracted\":${count_created},\"files\":${created_json}}"
