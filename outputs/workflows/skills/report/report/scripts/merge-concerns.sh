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
#          <target-id|-> <member-id>...
#   Flags come BEFORE the positional args. When <target-id> does not name an
#   existing active concern a NEW compound is created and --title is required;
#   pass `-` to say so explicitly.
# Output: JSON {merged, target_id, severity, superseded:[...], path}
#
# IDENTITY: a NEW compound's id is DERIVED from --title via the same slugify()
# that ship/scripts/extract-deferred-concerns.sh uses, NOT taken from the positional
# argument. That is not a convenience — it is the whole round trip. The id is what
# extract-deferred-concerns.sh looks up when the compound reappears as a `###` block in
# the next story's section 6: it computes slugify(title), finds the concern, and updates
# it IN PLACE. When the id was hand-invented by the caller, that lookup missed and the
# extractor took its CREATE branch, cloning the compound alongside itself. Measured on
# PR #86: one concern became both `commit-subject-rule-binds-on-no-path` (triage) and
# `the-commit-subject-rule-binds-on` (ship) — same title, same body, two files, repaired
# only because a human noticed. Deriving the id makes the round trip closed by
# construction. Folding into an EXISTING target still takes its id as given; that path
# was never broken.
#
# PROVENANCE: a new compound inherits origin_pr / origin_pr_url / origin_branch /
# origin_commit and first_seen from its EARLIEST-SEEN member, and stamps created_at /
# last_seen with the triage act.
#
# That split is deliberate. `origin_*` answers "where did this risk first surface", and a
# compound does not surface a new risk — it re-frames ones already on the books, so its
# origin is its earliest member's. Attributing it to the triage instead would restart the
# clock on a risk that has been open for weeks and break the audit chain back to the PR
# that raised it. `created_at` is the honest record of when THIS file was minted, which is
# a different question. The practical dividend: every field is derivable from the members,
# so this needs no --pr/--branch flags and no caller changes.
#
# Before this, a new compound was written with four EMPTY origin keys and no created_at /
# first_seen / last_seen at all — fields .workaholic/concerns/README.md documents as
# required. Two compounds in one triage carried the defect, and it is what made
# migrate-concern-identity.sh sort them dead last (its first_seen_key() falls back to
# ('9999', 10**9) on an absent first_seen), so a collapse could archive the compound and
# keep a member.

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

created_at=$(date -Iseconds)
head_commit=$(git rev-parse --short HEAD 2>/dev/null || printf '')

result=$(python3 - "$target" "$severity" "$title" "$description" "$fix" "$created_at" "$head_commit" "$@" <<'PY'
import sys, os, re, json

target_id, severity, title, description, fix, created_at, head_commit = sys.argv[1:8]
member_ids = sys.argv[8:]

ACTIVE = ".workaholic/concerns"
ARCHIVE = ".workaholic/concerns/archive"
SEV_RANK = {"urgent": 0, "moderate": 1, "low": 2}
os.makedirs(ARCHIVE, exist_ok=True)


def path_of(cid):
    return cid if cid.endswith(".md") and os.path.exists(cid) else f"{ACTIVE}/{cid}.md"


# Byte-identical to ship/scripts/extract-deferred-concerns.sh and
# report/scripts/migrate-concern-identity.sh. The three MUST agree: this one mints the id,
# the extractor looks it up, the migration renames the file to it. A drift here silently
# re-opens the cloning bug this function exists to close, and it fails quietly — the
# extractor just creates a second file. If you change one, change all three.
def slugify(s):
    s = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', s)   # [text](url) -> text
    s = re.sub(r'`([^`]+)`', r'\1', s)               # `code` -> code
    s = s.lower()
    s = re.sub(r'[^a-z0-9 ]', ' ', s)
    words = [w for w in s.split() if w][:6]
    return '-'.join(words)[:60].strip('-')


def strip_carried(title):
    return re.sub(r'^\(carried from[^)]*\)\s*', '', title).strip()


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


# Resolve the target id BEFORE anything reads it. Folding into an EXISTING active
# concern keeps its id. Otherwise this is a new compound, and its id is derived from the
# title so the next ship's extractor computes the same one and updates in place instead
# of cloning. `-` says "new compound" explicitly; any other unmatched value is treated
# the same way rather than being minted as-is.
_explicit = path_of(target_id) if target_id and target_id != "-" else ""
_is_new = not (_explicit and os.path.exists(_explicit))
if _is_new:
    if not title:
        print(json.dumps({"merged": False, "reason": "compound_needs_title"}))
        sys.exit(0)
    target_id = slugify(strip_carried(title))
    if not target_id:
        print(json.dumps({"merged": False, "reason": "title_yields_empty_id"}))
        sys.exit(0)
    # Slug collision guard: the slug is truncated (6 words / 60 chars), so two
    # DIFFERENT titles can mint the same id — without this check the second
    # compound would silently fold into the first. Same-title matches fall
    # through (that is the idempotent retry / update-in-place path); only a
    # different title behind the same slug is refused. To fold members into
    # that existing concern deliberately, pass its id instead of `-`.
    _existing = path_of(target_id)
    if os.path.exists(_existing):
        with open(_existing) as _h:
            _em = re.search(r'^#\s+(.*)$', _h.read(), re.MULTILINE)
        _etitle = strip_carried(_em.group(1).strip()) if _em else ''
        if _etitle != strip_carried(title):
            print(json.dumps({"merged": False, "reason": "id_collision",
                              "target_id": target_id, "existing_title": _etitle}))
            sys.exit(0)

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

def seen_key(path):
    """Earliest sighting of a concern, for picking which member a compound inherits from."""
    fm, _ = parse(path)
    return get(fm, "first_seen", "") or get(fm, "created_at", "") or "9999"


def inherit_provenance():
    """A compound's origin is its EARLIEST-SEEN member's — see the header. `created_at`
    and `last_seen` are the triage act's and are stamped by the caller, not here."""
    best = min(members, key=seen_key) if members else None
    if best is None:
        # No member to inherit from (every id was missing or already superseded). Say so
        # honestly with the local HEAD rather than writing blanks, which is the defect
        # this function exists to end.
        return {"origin_pr": "", "origin_pr_url": "", "origin_branch": "",
                "origin_commit": head_commit, "first_seen": created_at}
    fm, _ = parse(best)
    return {
        "origin_pr": get(fm, "origin_pr", ""),
        "origin_pr_url": get(fm, "origin_pr_url", ""),
        "origin_branch": get(fm, "origin_branch", ""),
        "origin_commit": get(fm, "origin_commit", "") or head_commit,
        "first_seen": get(fm, "first_seen", "") or get(fm, "created_at", "") or created_at,
    }


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
    # A merge is a sighting: the concern was just re-judged and re-framed. Without this
    # the target's last_seen went stale on every fold, unlike extract's update path.
    setkey(fm, "last_seen", created_at)
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
    prov = inherit_provenance()
    lines = [
        "---", "type: Concern", f"concern_id: {target_id}",
        "mission: " + ("[" + ", ".join(mission_pool) + "]" if mission_pool else ""),
        "tickets: []",
        f"origin_pr: {prov['origin_pr']}",
        f"origin_pr_url: {prov['origin_pr_url']}",
        f"origin_branch: {prov['origin_branch']}",
        f"origin_commit: {prov['origin_commit']}",
        f"created_at: {created_at}",
        f"first_seen: {prov['first_seen']}",
        f"last_seen: {created_at}",
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
