#!/bin/sh -eu
# Extract concerns from a shipped story's section 6 and persist them into the
# FEEDBACK STREAM as kind: concern records (docs/loop-engineering-workflow.md
# H2/H3 — the carry-over seam is where drive-born feedback is written), one
# immutable record per concern, keyed on the STABLE concern_id.
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
# The stream is APPEND-ONLY:
#   - a concern_id that already exists anywhere in the stream (open, closed, or
#     superseded) is SKIPPED — records are never rewritten, resurfaced, or
#     "refreshed in place"; a resolved concern that genuinely recurs is judged
#     from history by the reader, not resurrected by the writer;
#   - EVERY severity is recorded (the promotion floor retired with the concern
#     lifecycle machinery — the stream accumulates by design and curation is
#     the reader's judgment; a legacy `Keep:` field is tolerated and ignored);
#   - resolution is a SUPERSEDING record written by /report's judge seam
#     (apply-deferred-concern-verdicts.sh), never an edit here.
#
# Runs the concern-corpus living migration first, so a repo with a legacy
# concerns/ tree heals on its next ship.
#
# Usage: extract-deferred-concerns.sh <branch> <pr-number> <pr-url>
# Output: single JSON line summarizing what was extracted. `updated` and
# `story_only` are always 0 (kept for consumer stability across the merger).

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

mkdir -p .workaholic/feedbacks

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/push-outcome.sh"

# Living migration first: a legacy concerns/ corpus folds into the feedback
# stream before we index existing ids. Best-effort — never blocks extraction.
sh "${SCRIPT_DIR}/../../feedback/scripts//migrate-concerns.sh" >/dev/null 2>&1 || true

origin_commit=$(git rev-parse --short HEAD)
created_at=$(date -Iseconds)
author_email=$(git config user.email 2>/dev/null || echo "unknown@unknown.invalid")

owners_script="${SCRIPT_DIR}/../../mission/scripts//mission-owners.sh"

result=$(python3 - "$story_file" "$pr_number" "$pr_url" "$branch" "$origin_commit" "$created_at" "$author_email" "$owners_script" <<'PY'
import sys, re, os, json, glob, subprocess

story_file, pr_number, pr_url, branch, origin_commit, created_at, author_email, owners_script = sys.argv[1:9]

with open(story_file) as h:
    text = h.read()

# Story frontmatter relations (both optional): mission + tickets, inherited by
# each extracted record.
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

# Lane owner: the first owner of the first mission the story advances
# (mission-owners.sh — the mission's own assignees, legacy fallback), denormalized
# as `owner:` so list-open-concerns.sh can scope lanes without resolving missions.
def _first_slug(v):
    v = v.strip()
    if v.startswith('['):
        v = v.strip('[]').split(',')[0]
    return v.strip().strip('"').strip("'")

story_owner = ""
_slug = _first_slug(story_mission) if story_mission else ""
if _slug:
    for area in ('active', 'archive'):
        mpath = f'.workaholic/missions/{area}/{_slug}/mission.md'
        if os.path.isfile(mpath):
            try:
                _out = subprocess.run(
                    ['sh', owners_script, mpath],
                    capture_output=True, text=True, timeout=10,
                ).stdout
                _owners = [ln.strip() for ln in _out.splitlines() if ln.strip()]
                if _owners:
                    story_owner = _owners[0]
            except Exception:
                pass
            break

# Isolate section 6 (## 6. ...) up to the next top-level "## " heading.
m = re.search(r'^##\s+6\.\s.*?$(.*?)(?=^##\s+\d+\.\s|\Z)', text, re.MULTILINE | re.DOTALL)
section = m.group(1) if m else ""
blocks = re.split(r'^###\s+', section, flags=re.MULTILINE)[1:]


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


# Index every concern_id already in the stream (open, closed, superseded alike):
# the stream is append-only, so an existing id is never touched again here.
existing_ids = set()
for p in glob.glob('.workaholic/feedbacks/*.md'):
    base = os.path.basename(p)
    if base in ('README.md', 'index.md'):
        continue
    with open(p, encoding='utf-8', errors='replace') as h:
        t = h.read()
    mm = re.match(r'^---\n(.*?)\n---\n', t, re.DOTALL)
    if not mm:
        continue
    if re.search(r'^kind:[ \t]*concern[ \t]*$', mm.group(1), re.MULTILINE):
        km = re.search(r'^concern_id:[ \t]*(.*)$', mm.group(1), re.MULTILINE)
        if km and km.group(1).strip():
            existing_ids.add(km.group(1).strip())

ts = re.sub(r'[^0-9]', '', created_at)[:14] or '00000000000000'

created = []
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
    if concern_id in seen_this_run or concern_id in existing_ids:
        continue
    seen_this_run.add(concern_id)

    path = f'.workaholic/feedbacks/{ts}-{concern_id}.md'
    if os.path.exists(path):
        continue
    body = [
        '---',
        'type: Feedback',
        f'title: {strip_carried(title)}',
        'kind: concern',
        'source: development',
        f'created_at: {created_at}',
        f'author: {author_email}',
        'supersedes:',
        f'severity: {severity}',
        f'concern_id: {concern_id}',
        f'owner: {story_owner}',
        f'mission: {story_mission}',
        f'tickets: {story_tickets}',
        f'origin_pr: {pr_number}',
        f'origin_pr_url: {pr_url}',
        f'origin_branch: {branch}',
        f'origin_commit: {origin_commit}',
        f'last_seen: {created_at}',
        '---',
        '',
        f'# {strip_carried(title)}',
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

print(json.dumps({"created": created}))
PY
)

created_files=$(printf '%s' "$result" | python3 -c "import json,sys; print('\n'.join(json.load(sys.stdin)['created']))")
created_json=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['created']))")
count_created=$(printf '%s' "$result" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['created']))")

if [ "$count_created" -eq 0 ]; then
  echo "{\"status\":\"ok\",\"created\":0,\"updated\":0,\"extracted\":0,\"story_only\":0,\"pushed\":false,\"push_error\":\"not_attempted\",\"files\":[]}"
  exit 0
fi

# Mission changelog: a newly-deferred concern records a "concern deferred (stuck)"
# line on EVERY mission the story advances (idempotent). Best-effort.
story_missions=$(sh "${SCRIPT_DIR}/../../mission/scripts//read-relation.sh" "$story_file" 2>/dev/null || true)
if [ -n "$story_missions" ]; then
  printf '%s\n' "$created_files" | while IFS= read -r cfile; do
    [ -n "$cfile" ] || continue
    printf '%s\n' "$story_missions" | while IFS= read -r sm; do
      [ -n "$sm" ] || continue
      sh "${SCRIPT_DIR}/../../mission/scripts//append-changelog.sh" \
        "$sm" "concern deferred (stuck)" "$(basename "$cfile")" >/dev/null 2>&1 || true
    done
  done
fi

pushed=false
push_error="not_attempted"

if [ -z "${NO_COMMIT:-}" ]; then
  sh "${SCRIPT_DIR}/../../okf/scripts//refresh-index.sh" >/dev/null 2>&1 || true
  git add .workaholic/feedbacks/ .workaholic/missions/ >/dev/null 2>&1 || git add .workaholic/feedbacks/ >/dev/null
  git commit -m "Add deferred concerns from PR #${pr_number}" >/dev/null
  # Non-fatal by design (the PR has already merged), but never silent: the
  # outcome rides out in the JSON. See lib/push-outcome.sh.
  push_and_report
  pushed="$PUSH_OK"
  push_error="$PUSH_ERROR"
fi

echo "{\"status\":\"ok\",\"created\":${count_created},\"updated\":0,\"extracted\":${count_created},\"story_only\":0,\"pushed\":${pushed},\"push_error\":\"${push_error}\",\"files\":${created_json}}"
