#!/bin/sh -eu
# Retire a lingering .workaholic/concerns/ tree — the living migration for the
# concern->feedback merger (docs/loop-engineering-workflow.md H2, 2026-07-28).
# Modeled on the strategy retirement: nothing is deleted from KNOWLEDGE, only
# from STRUCTURE.
#
#   * each ACTIVE concerns/*.md survives as an OPEN kind: concern feedback record
#     (feedbacks/<ts-from-first_seen>-<concern_id>.md, Description / How to Fix
#     body preserved verbatim);
#   * each concerns/archive/*.md survives as a record stamped with the
#     migration-only `closed: <status>` field (resolved/accepted/demoted/
#     superseded; post-migration closures are SUPERSEDING RECORDS, never a
#     field — this stamp exists only so history does not resurface as open);
#   * then the concerns/ directory is removed (git rm when tracked).
#
# Deterministic filenames (first_seen digits + concern_id) make the migration
# idempotent; best-effort throughout so a calling seam (ship extraction, report
# listing) is never blocked. Direct/test entry here; the seams call it first.
#
# Usage: migrate-concerns.sh [workaholic-root]
#   workaholic-root defaults to this repository's .workaholic.
# Output: JSON {migrated, root}

set -eu

ROOT="${1:-}"
if [ -z "$ROOT" ]; then
    _top="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "$_top" ]; then ROOT="${_top}/.workaholic"; else ROOT=".workaholic"; fi
fi

HAD="false"
[ -d "${ROOT}/concerns" ] && HAD="true"

if [ "$HAD" = "true" ]; then
    python3 - "$ROOT" <<'PY' || true
import os, re, subprocess, sys

root = sys.argv[1]
cdir = os.path.join(root, 'concerns')
fdir = os.path.join(root, 'feedbacks')
os.makedirs(fdir, exist_ok=True)

def read_fm(path):
    with open(path, encoding='utf-8', errors='replace') as h:
        t = h.read()
    m = re.match(r'^---\n(.*?)\n---\n?(.*)$', t, re.DOTALL)
    if not m:
        return {}, t
    fm = {}
    for line in m.group(1).split('\n'):
        km = re.match(r'^([A-Za-z0-9_]+):(.*)$', line)
        if km:
            fm[km.group(1)] = km.group(2).strip()
    return fm, m.group(2)

def author_default():
    try:
        out = subprocess.run(['git', 'config', 'user.email'], capture_output=True, text=True).stdout.strip()
        return out or 'unknown@unknown.invalid'
    except Exception:
        return 'unknown@unknown.invalid'

AUTHOR = author_default()

def migrate(path, closed):
    fm, body = read_fm(path)
    cid = fm.get('concern_id') or os.path.basename(path)[:-3]
    first_seen = fm.get('first_seen') or fm.get('created_at') or ''
    ts = re.sub(r'[^0-9]', '', first_seen)[:14] or '00000000000000'
    out = os.path.join(fdir, f'{ts}-{cid}.md')
    if os.path.exists(out):
        return
    title_m = re.search(r'^# (.+)$', body, re.MULTILINE)
    title = title_m.group(1).strip() if title_m else cid
    lines = [
        '---',
        'type: Feedback',
        f'title: {title}',
        'kind: concern',
        'source: development',
        f'created_at: {first_seen}',
        f'author: {AUTHOR}',
        'supersedes:',
        f'severity: {fm.get("severity", "moderate")}',
        f'concern_id: {cid}',
        f'owner: {fm.get("owner", "")}',
        f'mission: {fm.get("mission", "")}',
        f'tickets: {fm.get("tickets", "[]")}',
        f'origin_pr: {fm.get("origin_pr", "")}',
        f'origin_pr_url: {fm.get("origin_pr_url", "")}',
        f'origin_branch: {fm.get("origin_branch", "")}',
        f'origin_commit: {fm.get("origin_commit", "")}',
        f'last_seen: {fm.get("last_seen", first_seen)}',
    ]
    if closed:
        status = fm.get('status', '')
        status = status if status in ('resolved', 'accepted', 'demoted', 'superseded') else 'resolved'
        lines.append(f'closed: {status}')
        if fm.get('resolved_by_pr'):
            lines.append(f'resolved_by_pr: {fm.get("resolved_by_pr")}')
        if fm.get('resolved_by_commit'):
            lines.append(f'resolved_by_commit: {fm.get("resolved_by_commit")}')
    lines += ['---', '', body.strip(), '']
    with open(out, 'w') as h:
        h.write('\n'.join(lines))
    subprocess.run(['git', 'add', out], capture_output=True)

for name in sorted(os.listdir(cdir)):
    p = os.path.join(cdir, name)
    if name.endswith('.md') and name not in ('README.md', 'index.md') and os.path.isfile(p):
        migrate(p, closed=False)

adir = os.path.join(cdir, 'archive')
if os.path.isdir(adir):
    for name in sorted(os.listdir(adir)):
        p = os.path.join(adir, name)
        if name.endswith('.md') and name not in ('README.md', 'index.md') and os.path.isfile(p):
            migrate(p, closed=True)
PY
    # Structure teardown: knowledge already moved; git history keeps the originals.
    if ! git rm -r -q "${ROOT}/concerns" >/dev/null 2>&1; then
        rm -rf "${ROOT}/concerns" 2>/dev/null || true
    fi
    git add -A "${ROOT}/concerns" >/dev/null 2>&1 || true
fi

printf '{"migrated": %s, "root": "%s"}\n' "$HAD" "$ROOT"
