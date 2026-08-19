#!/bin/sh -eu
# Extract concerns from a shipped story's section 6 and persist them into the
# FEEDBACK STREAM as kind: concern records (docs/loop-engineering-workflow.md
# H2/H3 — the carry-over seam is where drive-born feedback is written), one
# immutable record per concern, keyed on the STABLE concern_id.
#
# The Concerns section is expected to use this structure (the section is omitted
# entirely when the branch raised no concerns):
#
#   ## 5. Concerns          <- matched BY NAME; the number varies per story
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
# Usage: extract-deferred-concerns.sh <branch> <pr-number> <pr-url> [base-branch]
# Output: single JSON line summarizing what was extracted, INCLUDING the `destination`
# branch the records were pushed to. `updated` and `story_only` are always 0 (kept for
# consumer stability across the merger).
#
# THE DESTINATION IS EXPLICIT, NEVER INFERRED. The open-concern set is computed from
# records on the BASE, so a record pushed anywhere else is invisible to /report's judge
# and to /specificate. This script used to commit and push on whatever branch it happened to
# be standing on, with a header that assumed merge-pr.sh had already checked the base
# out. On 2026-07-30 that assumption broke -- merge-pr.sh cannot check `main` out from
# inside a claim worktree -- so PR #108's four concerns were committed and pushed to the
# ALREADY-MERGED claim branch, and the script truthfully reported `pushed: true`. The
# push had worked; the destination was wrong. `pushed` alone is not an actionable signal,
# which is why `destination` now rides beside it.
#
# When this runs somewhere other than the base, the extraction happens inside a PUBLISH
# TREE (a checkout of origin/<base>; workaholic:branching) and is pushed from there --
# the same route a source uses to publish an artifact from any checkout. That also makes
# the dedup scan read the base's records rather than the branch's, which is the correct
# set to dedup against.

set -eu

branch="${1:-}"
pr_number="${2:-}"
pr_url="${3:-}"
base="${4:-main}"

if [ -z "$branch" ] || [ -z "$pr_number" ] || [ -z "$pr_url" ]; then
  echo '{"status":"error","reason":"missing_args","extracted":0}'
  exit 1
fi

story_file=".workaholic/stories/${branch}.md"
# A publish-tree re-entry (below) carries the story's ABSOLUTE path as $5, because
# the story lives in the caller's checkout and not in the base it publishes to.
# This must precede the existence check: resolving it later meant the re-entered run
# looked for the story inside the publish tree and skipped.
if [ -n "${5:-}" ]; then
  story_file="$5"
fi

if [ ! -f "$story_file" ]; then
  echo "{\"status\":\"skipped\",\"reason\":\"no_story_file\",\"path\":\"$story_file\",\"extracted\":0,\"destination\":\"${base}\"}"
  exit 0
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "${SCRIPT_DIR}/lib/push-outcome.sh"

# --- Route to the base when we are not on it ------------------------------------------
# WH_EDC_IN_PUBLISH_TREE marks the re-entered run so this never recurses. The re-entry
# carries an ABSOLUTE story path, because the story lives in the caller's checkout.
current_branch=$(git branch --show-current 2>/dev/null || true)
if [ "$current_branch" != "$base" ] && [ -z "${WH_EDC_IN_PUBLISH_TREE:-}" ] && [ -z "${NO_COMMIT:-}" ]; then
  story_abs=$(CDPATH= cd -- "$(dirname -- "$story_file")" && pwd)/$(basename -- "$story_file")
  open_out=$(sh "${SCRIPT_DIR}/../../branching/scripts//open-publish-tree.sh" "$base" 2>/dev/null || true)
  publish_path=$(printf '%s' "$open_out" | sed -n 's/.*"path": *"\([^"]*\)".*/\1/p')
  if [ -z "$publish_path" ]; then
    reason=$(printf '%s' "$open_out" | sed -n 's/.*"reason": *"\([^"]*\)".*/\1/p')
    [ -n "$reason" ] || reason="open_publish_tree_failed"
    echo "{\"status\":\"error\",\"reason\":\"${reason}\",\"extracted\":0,\"pushed\":false,\"destination\":\"${base}\"}"
    exit 1
  fi
  # The inner run receives the same base, so ITS json already carries `destination`;
  # only `pushed`/`push_error` are rewritten here (a second destination key would be
  # duplicate JSON -- tolerated by parsers, sloppy from a script whose point is honest
  # reporting).
  # Extract INSIDE the publish tree (NO_COMMIT: the publish seam owns the commit), then
  # publish the whole batch to the base in one commit and tear the tree down.
  inner=$( cd "$publish_path" && NO_COMMIT=1 WH_EDC_IN_PUBLISH_TREE=1 sh "$0" "$branch" "$pr_number" "$pr_url" "$base" "$story_abs" )
  created=$(printf '%s' "$inner" | sed -n 's/.*"created":\([0-9][0-9]*\).*/\1/p')
  [ -n "$created" ] || created=0
  if [ "$created" -eq 0 ]; then
    sh "${SCRIPT_DIR}/../../branching/scripts//close-publish-tree.sh" "$base" >/dev/null 2>&1 || true
    printf '%s\n' "$inner"
    exit 0
  fi
  pub=$(sh "${SCRIPT_DIR}/../../branching/scripts//publish-tree-commit.sh" \
    "Add deferred concerns from PR #${pr_number}" \
    "The just-merged story's section-6 concerns become kind: concern feedback records; the open set is computed from records on the base, so they are published there rather than to whatever branch the ship ran from" \
    "None -- knowledge records" "None" "None" \
    "list-open-concerns.sh sees them from a fresh clone of the base" \
    .workaholic/ 2>/dev/null || true)
  ok=$(printf '%s' "$pub" | sed -n 's/.*"ok": *\([a-z]*\).*/\1/p')
  if [ "$ok" = "true" ]; then
    sh "${SCRIPT_DIR}/../../branching/scripts//close-publish-tree.sh" "$base" >/dev/null 2>&1 || true
    printf '%s\n' "$inner" | sed 's/"pushed":false,"push_error":"[^"]*"/"pushed":true,"push_error":""/'
  else
    perr=$(printf '%s' "$pub" | sed -n 's/.*"reason": *"\([^"]*\)".*/\1/p')
    [ -n "$perr" ] || perr="publish_failed"
    printf '%s\n' "$inner" | sed "s/\"push_error\":\"[^\"]*\"/\"push_error\":\"${perr}\"/"
  fi
  exit 0
fi

mkdir -p .workaholic/feedbacks

# Living migration first: a legacy concerns/ corpus folds into the feedback
# stream before we index existing ids. Best-effort — never blocks extraction.
sh "${SCRIPT_DIR}/../../feedback/scripts//migrate-concerns.sh" >/dev/null 2>&1 || true

origin_commit=$(git rev-parse --short HEAD)
created_at=$(date -Iseconds)
author_email=$(git config user.email 2>/dev/null || echo "unknown@unknown.invalid")

owners_script="${SCRIPT_DIR}/../../gather/scripts//owners.sh"

result=$(python3 - "$story_file" "$pr_number" "$pr_url" "$branch" "$origin_commit" "$created_at" "$author_email" "$owners_script" <<'PY'
import sys, re, os, json, glob, subprocess, hashlib, unicodedata

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
# (gather/scripts/owners.sh — the artifact's own assignees, legacy fallback), denormalized
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

# Isolate the Concerns section, up to the next top-level "## " heading.
#
# MATCH THE HEADING BY NAME, NEVER BY NUMBER. Story sections are numbered
# sequentially over the sections a story actually has, and a section with nothing
# to report is omitted -- so Concerns is "## 5. Concerns" on one branch and
# "## 6. Concerns" on the next, and both are correct. Keying on a number would
# make extraction depend on which OTHER sections happened to be written, and it
# would fail SILENTLY: no heading match means an empty section, which is
# indistinguishable from a branch that raised no concerns. The optional numeric
# prefix is tolerated precisely so every story ever written still parses.
m = re.search(r'^##\s+(?:\d+[.)]\s*)?Concerns\s*$(.*?)(?=^##\s|\Z)',
              text, re.MULTILINE | re.DOTALL)
section = m.group(1) if m else ""
blocks = re.split(r'^###\s+', section, flags=re.MULTILINE)[1:]


def field(block, label):
    pat = re.compile(r'^\s*-?\s*\*\*' + re.escape(label) + r':\*\*\s*(.*)$', re.MULTILINE)
    mm = pat.search(block)
    return mm.group(1).strip() if mm else ""


def strip_carried(title):
    return re.sub(r'^\(carried from[^)]*\)\s*', '', title).strip()


def slugify(s):
    s = s.lower()
    s = re.sub(r'[^a-z0-9 ]', ' ', s)
    words = [w for w in s.split() if w][:6]
    return '-'.join(words)[:60].strip('-')


def concern_id_for(title):
    # The id is the stream's PERMANENT key, so the historical ASCII word slug
    # is kept byte-identical. A title carrying any non-ASCII character cannot
    # use it: the word slug degenerates (a Japanese title reduces to '' or to
    # its one incidental English word), collides, and the concern is then
    # silently dropped as a duplicate. Those titles — and the pathological
    # all-punctuation ASCII title that yields no words — get a stable hash id
    # instead, derived from the NFC-normalized, case- and whitespace-folded
    # title so trivial re-renderings of the same title agree on the id.
    s = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', title)
    s = re.sub(r'`([^`]+)`', r'\1', s)
    if s.isascii():
        slug = slugify(s)
        if slug:
            return slug, False
    norm = ' '.join(unicodedata.normalize('NFC', s).lower().split())
    return 'c-' + hashlib.sha1(norm.encode('utf-8')).hexdigest()[:8], True


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
fallback_ids = []
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

    concern_id, used_fallback = concern_id_for(strip_carried(title))
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
        # The loop observed this concern in its own story; no human formed it, so
        # the subject is the running agent AS an observer AI — not the git author
        # (that field already says who ran the capture) and not a person nobody
        # asked. See feedback/reference/schema.md, The subject axis.
        f'subject: observer_ai:{author_email}',
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
    if used_fallback:
        fallback_ids.append(concern_id)

print(json.dumps({"created": created, "fallback_ids": fallback_ids}))
PY
)

created_files=$(printf '%s' "$result" | python3 -c "import json,sys; print('\n'.join(json.load(sys.stdin)['created']))")
created_json=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['created']))")
count_created=$(printf '%s' "$result" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['created']))")
# Which created records used the hash-fallback id (non-ASCII or word-less title).
# Reported so a fallback id is a visible, greppable event rather than a silent
# divergence from the word-slug convention.
fallback_json=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin).get('fallback_ids', [])))")

if [ "$count_created" -eq 0 ]; then
  # `destination` rides EVERY exit, including this one: a caller reading the JSON must
  # never have to infer where records would have gone.
  echo "{\"status\":\"ok\",\"created\":0,\"updated\":0,\"extracted\":0,\"story_only\":0,\"pushed\":false,\"push_error\":\"not_attempted\",\"destination\":\"${base}\",\"fallback_ids\":[],\"files\":[]}"
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

echo "{\"status\":\"ok\",\"created\":${count_created},\"updated\":0,\"extracted\":${count_created},\"story_only\":0,\"pushed\":${pushed},\"push_error\":\"${push_error}\",\"destination\":\"${base}\",\"fallback_ids\":${fallback_json},\"files\":${created_json}}"
