#!/bin/sh -eu
# Extract concerns from a shipped story's section 6 and persist them under
# .workaholic/concerns/, one file per concern.
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

origin_commit=$(git rev-parse --short HEAD)
created_at=$(date -Iseconds)

written=$(python3 - "$story_file" "$pr_number" "$pr_url" "$branch" "$origin_commit" "$created_at" <<'PY'
import sys, re, os, json

story_file, pr_number, pr_url, branch, origin_commit, created_at = sys.argv[1:7]

with open(story_file) as h:
    text = h.read()

# Isolate section 6 (## 6. ...) up to the next top-level "## " heading.
m = re.search(r'^##\s+6\.\s.*?$(.*?)(?=^##\s+\d+\.\s|\Z)', text, re.MULTILINE | re.DOTALL)
section = m.group(1) if m else ""

# Split into concern blocks on "### " headings.
blocks = re.split(r'^###\s+', section, flags=re.MULTILINE)[1:]

def field(block, label):
    # Matches "- **Label:** value" or "**Label:** value", value runs to EOL.
    pat = re.compile(r'^\s*-?\s*\*\*' + re.escape(label) + r':\*\*\s*(.*)$', re.MULTILINE)
    mm = pat.search(block)
    return mm.group(1).strip() if mm else ""

def slugify(s):
    s = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', s)
    s = re.sub(r'`([^`]+)`', r'\1', s)
    s = s.lower()
    s = re.sub(r'[^a-z0-9 ]', ' ', s)
    words = [w for w in s.split() if w][:6]
    return '-'.join(words)[:60].strip('-')

import glob

def canon(slug):
    # Canonical concern identity: strip the leading "<pr>-" filename prefix and
    # any "carried-from-pr-<n>-" carry-chain prefix so the SAME logical concern
    # is recognized across PRs instead of re-emitted under each new prefix.
    slug = re.sub(r'^\d+-', '', slug)
    slug = re.sub(r'^carried-from-pr-\d+-', '', slug)
    return slug

# Identities already present (active OR archived) — never re-create these.
existing = set()
for p in glob.glob('.workaholic/concerns/*.md') + glob.glob('.workaholic/concerns/archive/*.md'):
    name = os.path.basename(p)[:-3]
    if name == 'README':
        continue
    existing.add(canon(name))

written = []
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

    slug = slugify(title) or f'concern'
    identity = canon(slug)
    # Dedup by canonical identity across PR prefixes (and vs archived/resolved).
    if identity in existing:
        continue
    slug_base = f'{pr_number}-{slug}'
    path = f'.workaholic/concerns/{slug_base}.md'
    if os.path.exists(path):
        continue
    existing.add(identity)

    body = []
    body.append('---')
    # `type` first: the non-empty type key is what makes the file an OKF
    # (Open Knowledge Format) concept document; the rest are extension keys.
    body.append('type: Concern')
    body.append(f'origin_pr: {pr_number}')
    body.append(f'origin_pr_url: {pr_url}')
    body.append(f'origin_branch: {branch}')
    body.append(f'origin_commit: {origin_commit}')
    body.append(f'created_at: {created_at}')
    body.append(f'severity: {severity}')
    body.append('status: active')
    body.append('resolved_by_pr:')
    body.append('resolved_by_commit:')
    body.append('---')
    body.append('')
    body.append(f'# {title}')
    body.append('')
    body.append('## Description')
    body.append('')
    body.append(description)
    body.append('')
    body.append('## How to Fix')
    body.append('')
    body.append(fix)
    body.append('')
    with open(path, 'w') as h:
        h.write('\n'.join(body))
    written.append(path)

print(json.dumps(written))
PY
)

count=$(echo "$written" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

if [ "$count" -eq 0 ]; then
  echo "{\"status\":\"ok\",\"extracted\":0,\"files\":[]}"
  exit 0
fi

if [ -z "${NO_COMMIT:-}" ]; then
  # Refresh the .workaholic OKF bundle indexes (stages them) so the new concern
  # files appear in the committed hierarchy (best-effort: never blocks the commit).
  SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  sh "${SCRIPT_DIR}/../../okf/scripts/refresh-index.sh" >/dev/null 2>&1 || true
  git add .workaholic/concerns/ >/dev/null
  git commit -m "Add deferred concerns from PR #${pr_number}" >/dev/null
fi

echo "{\"status\":\"ok\",\"extracted\":${count},\"files\":${written}}"
