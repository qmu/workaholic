#!/bin/sh -eu
# Merge deferred concerns during triage — fold one or more member concerns into a
# target concern (an existing one, or a NEW compound created here), then archive
# each member as status: superseded, superseded_by: <target-id>. The target's
# severity is escalated to the developer-confirmed value (or, absent one, the
# most-severe among the target and its members). This is how "A + B = a bigger
# risk" collapses to one fresh compound concern that supersedes its parts.
#
# Idempotent: a member already superseded/archived is skipped; re-running the
# same merge is a no-op.
#
# Usage: merge-concerns.sh [--severity S] [--title T] [--description D] [--fix F] \
#          <target-id> <member-id>...
#   Flags come BEFORE the positional args. When <target-id> does not name an
#   existing active concern a NEW compound is created and --title is required.
# Output: JSON {merged, target_id, severity, superseded:[...], path}

set -eu

severity=""; title=""; description=""; fix=""
while [ $# -gt 0 ]; do
  case "$1" in
    --severity) severity="${2:-}"; shift 2 ;;
    --title) title="${2:-}"; shift 2 ;;
    --description) description="${2:-}"; shift 2 ;;
    --fix) fix="${2:-}"; shift 2 ;;
    --) shift; break ;;
    -?*) echo "{\"merged\": false, \"reason\": \"unknown_flag\", \"flag\": \"$1\"}"; exit 1 ;;
    *) break ;;
  esac
done

target="${1:-}"
[ -n "$target" ] || { echo '{"merged": false, "reason": "no_target"}'; exit 1; }
shift || true
[ "$#" -gt 0 ] || { echo '{"merged": false, "reason": "no_members"}'; exit 1; }

result=$(python3 - "$target" "$severity" "$title" "$description" "$fix" "$@" <<'PY'
import sys, os, re, json

target_id, severity, title, description, fix = sys.argv[1:6]
member_ids = sys.argv[6:]

ACTIVE = ".workaholic/concerns"
ARCHIVE = ".workaholic/concerns/archive"
SEV_RANK = {"urgent": 0, "moderate": 1, "low": 2}
os.makedirs(ARCHIVE, exist_ok=True)


def path_of(cid):
    return cid if cid.endswith(".md") and os.path.exists(cid) else f"{ACTIVE}/{cid}.md"


def parse(path):
    with open(path) as h:
        text = h.read()
    m = re.match(r'^---\n(.*?)\n---\n?(.*)$', text, re.DOTALL)
    if not m:
        return None, text
    fm = []
    for line in m.group(1).split('\n'):
        km = re.match(r'^([A-Za-z0-9_]+):(.*)$', line)
        fm.append([km.group(1), km.group(2).strip()] if km else [None, line])
    return fm, m.group(2)


def get(fm, key, d=""):
    for k, v in fm or []:
        if k == key:
            return v
    return d


def setkey(fm, key, value):
    for pair in fm:
        if pair[0] == key:
            pair[1] = value
            return
    fm.append([key, value])


def serialize(fm, body):
    out = ["---"]
    for k, v in fm:
        out.append(f"{k}: {v}" if k is not None else v)
    out.append("---")
    return "\n".join(out) + "\n" + (body if body.startswith("\n") else "\n" + body)


# Gather member files (active only; skip the target itself and anything missing).
members = []
for mid in member_ids:
    p = path_of(mid)
    if mid == target_id or os.path.abspath(p) == os.path.abspath(path_of(target_id)):
        continue
    if os.path.exists(p):
        members.append(p)

# Compute the merged severity: explicit flag wins, else most-severe across the set.
# Alongside it, union the mission relations: a compound concern blocks every mission its
# members blocked, so writing one (or, as this used to, writing none) would drop the rest
# from those missions' rolled-up work. Same reasoning as the story's inheritance rule —
# a relation is never discarded to fit a narrower field.
sev_pool = []
mission_pool = []

def collect_missions(fm):
    raw = get(fm, "mission", "").strip()
    if not raw:
        return
    for s in raw.strip("[]").split(","):
        s = s.strip()
        if s and s not in mission_pool:
            mission_pool.append(s)

tpath = path_of(target_id)
if os.path.exists(tpath):
    tfm, _ = parse(tpath)
    sev_pool.append(get(tfm, "severity", "moderate"))
    collect_missions(tfm)
for p in members:
    mfm, _ = parse(p)
    sev_pool.append(get(mfm, "severity", "moderate"))
    collect_missions(mfm)
if severity:
    merged_sev = severity
elif sev_pool:
    merged_sev = min(sev_pool, key=lambda s: SEV_RANK.get(s, 1))
else:
    merged_sev = "moderate"

# Materialize the target: update in place, or create a fresh compound.
if os.path.exists(tpath):
    fm, body = parse(tpath)
    setkey(fm, "severity", merged_sev)
    if title:
        body = re.sub(r'(?m)^#\s+.*$', f'# {title}', body, count=1)
    if description:
        body = re.sub(r'(?s)(## Description\n\n).*?(\n\n## How to Fix)',
                      lambda mm: mm.group(1) + description + mm.group(2), body)
    if fix:
        body = re.sub(r'(?s)(## How to Fix\n\n).*?$',
                      lambda mm: mm.group(1) + fix + '\n', body)
    with open(tpath, 'w') as h:
        h.write(serialize(fm, body))
else:
    if not title:
        print(json.dumps({"merged": False, "reason": "compound_needs_title"}))
        sys.exit(0)
    desc = description or ("Compound concern superseding: " + ", ".join(member_ids) + ".")
    fixtext = fix or "Address the combined risk described above; the superseded parts are archived."
    lines = [
        "---", "type: Concern", f"concern_id: {target_id}",
        "mission: " + ("[" + ", ".join(mission_pool) + "]" if mission_pool else ""),
        "tickets: []",
        "origin_pr: ", "origin_pr_url: ", "origin_branch: ", "origin_commit: ",
        f"severity: {merged_sev}", "status: active", "compound: true",
        "resolved_by_pr:", "resolved_by_commit:", "---", "",
        f"# {title}", "", "## Description", "", desc, "", "## How to Fix", "", fixtext, "",
    ]
    with open(tpath, 'w') as h:
        h.write("\n".join(lines))

# Supersede each member: mark + move to archive.
superseded = []
for p in members:
    fm, body = parse(p)
    setkey(fm, "status", "superseded")
    setkey(fm, "superseded_by", target_id)
    with open(p, 'w') as h:
        h.write(serialize(fm, body))
    base = os.path.basename(p)
    dest = f"{ARCHIVE}/{base}"
    if os.path.exists(dest):
        dest = f"{ARCHIVE}/{base[:-3]}-superseded.md"
    os.rename(p, dest)
    superseded.append(get(fm, "concern_id") or base[:-3])

print(json.dumps({
    "merged": True, "target_id": target_id, "severity": merged_sev,
    "superseded": superseded, "path": tpath,
}))
PY
)

git add -A .workaholic/concerns >/dev/null 2>&1 || true
printf '%s\n' "$result"
