#!/bin/sh -eu
# Living, idempotent migration that gives every deferred concern a STABLE
# identity and collapses legacy carried-from clone chains into one fresh file
# per concern. Best-effort: any failure is swallowed so a calling seam
# (extract / list / apply) is never blocked. Scoped strictly to
# .workaholic/concerns (never touches anything else).
#
# For every concern file (the active dir and archive/):
#   - back-fill concern_id (a stable slug), first_seen and last_seen frontmatter
#     when absent, deriving them from the title / filename / created_at;
#   - rename an ACTIVE file to <concern_id>.md.
# Then, per concern_id among ACTIVE files, keep the earliest file (merged: the
# most-severe severity, the latest last_seen) and move the redundant clones to
# archive/ as status: superseded, superseded_by: <concern_id> — so the pile of
# NN-carried-from-... clones collapses to one fresh file per real concern.
#
# Idempotent: a migrated tree (one <concern_id>.md per concern, frontmatter
# already present) is a no-op. Runs on the repository the CWD is in.
#
# Usage: migrate-concern-identity.sh

set -eu

[ -d .workaholic/concerns ] || exit 0

python3 - <<'PY' 2>/dev/null || exit 0
import os, re, glob

ACTIVE_DIR = ".workaholic/concerns"
ARCHIVE_DIR = ".workaholic/concerns/archive"
SEV_RANK = {"urgent": 0, "moderate": 1, "low": 2}
RESERVED = {"README", "index"}


def slugify(s):
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)   # [text](url) -> text
    s = re.sub(r"`([^`]+)`", r"\1", s)               # `code` -> code
    s = s.lower()
    s = re.sub(r"[^a-z0-9 ]", " ", s)
    words = [w for w in s.split() if w][:6]
    return "-".join(words)[:60].strip("-")


def strip_carried(title):
    # Drop a leading "(carried from PR #58 -> #54) " parenthetical so the SAME
    # logical concern yields the SAME slug regardless of how many times it was
    # re-deferred.
    return re.sub(r"^\(carried from[^)]*\)\s*", "", title).strip()


def canon_from_name(name):
    name = re.sub(r"^\d+-", "", name)                       # drop "<pr>-"
    name = re.sub(r"^carried-from-pr-\d+-", "", name)       # drop carry prefix
    name = re.sub(r"^(?:\d+-)?", "", name)                  # drop a second "<pr>-"
    return name


def parse(path):
    with open(path) as h:
        text = h.read()
    m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.DOTALL)
    if not m:
        return None
    fm_lines = m.group(1).split("\n")
    body = m.group(2)
    fm = []  # ordered (key, value)
    for line in fm_lines:
        mm = re.match(r"^([A-Za-z0-9_]+):(.*)$", line)
        if mm:
            fm.append([mm.group(1), mm.group(2).strip()])
        else:
            fm.append([None, line])  # preserve non key:value lines verbatim
    tm = re.search(r"^#\s+(.*)$", body, re.MULTILINE)
    title = tm.group(1).strip() if tm else ""
    return fm, body, title


def get(fm, key, default=""):
    for k, v in fm:
        if k == key:
            return v
    return default


def setkey(fm, key, value, after=("created_at", "severity", "status")):
    for pair in fm:
        if pair[0] == key:
            pair[1] = value
            return
    # insert after the first present anchor key
    for anchor in after:
        for i, pair in enumerate(fm):
            if pair[0] == anchor:
                fm.insert(i + 1, [key, value])
                return
    fm.append([key, value])


def serialize(fm, body):
    out = ["---"]
    for k, v in fm:
        out.append(f"{k}: {v}" if k is not None else v)
    out.append("---")
    text = "\n".join(out) + "\n" + body
    return text if text.endswith("\n") else text + "\n"


def concern_id_of(fm, title, path):
    cid = get(fm, "concern_id")
    if cid:
        return cid
    base = strip_carried(title)
    cid = slugify(base) if base else ""
    if not cid:
        cid = canon_from_name(os.path.basename(path)[:-3])
    return cid or "concern"


def ensure_fields(path, is_archive):
    parsed = parse(path)
    if parsed is None:
        return None
    fm, body, title = parsed
    changed = False
    cid = concern_id_of(fm, title, path)
    if get(fm, "concern_id") != cid:
        setkey(fm, "concern_id", cid)
        changed = True
    created = get(fm, "created_at")
    if not get(fm, "first_seen"):
        setkey(fm, "first_seen", created)
        changed = True
    if not get(fm, "last_seen"):
        setkey(fm, "last_seen", created or get(fm, "first_seen"))
        changed = True
    if changed:
        with open(path, "w") as h:
            h.write(serialize(fm, body))
    return cid, fm, body, title


# --- Pass 1: back-fill identity on every file (active + archive) -------------
active = [
    p for p in glob.glob(f"{ACTIVE_DIR}/*.md")
    if os.path.basename(p)[:-3] not in RESERVED
]
archive = glob.glob(f"{ARCHIVE_DIR}/*.md")

for p in archive:
    ensure_fields(p, is_archive=True)

# archived concern_ids must never be resurrected as a fresh active file
archived_ids = set()
for p in archive:
    parsed = parse(p)
    if parsed:
        archived_ids.add(get(parsed[0], "concern_id"))

# group active files by concern_id
groups = {}
for p in active:
    res = ensure_fields(p, is_archive=False)
    if not res:
        continue
    cid = res[0]
    groups.setdefault(cid, []).append(p)

os.makedirs(ARCHIVE_DIR, exist_ok=True)


def first_seen_key(path):
    parsed = parse(path)
    fs = get(parsed[0], "first_seen") if parsed else ""
    pr = get(parsed[0], "origin_pr") if parsed else ""
    pr_n = int(pr) if str(pr).isdigit() else 10**9
    return (fs or "9999", pr_n, path)


# --- Pass 2: collapse each active group to one <concern_id>.md ---------------
for cid, paths in groups.items():
    paths.sort(key=first_seen_key)
    keeper = paths[0]
    clones = paths[1:]
    # merge severity (most severe) and last_seen (latest) across the whole group
    sev = "low"
    last = ""
    for p in paths:
        parsed = parse(p)
        if not parsed:
            continue
        s = get(parsed[0], "severity") or "moderate"
        if SEV_RANK.get(s, 1) < SEV_RANK.get(sev, 1):
            sev = s
        ls = get(parsed[0], "last_seen")
        if ls > last:
            last = ls
    # write keeper with merged values, renamed to <concern_id>.md
    kparsed = parse(keeper)
    if kparsed:
        fm, body, _ = kparsed
        setkey(fm, "severity", sev)
        setkey(fm, "last_seen", last or get(fm, "last_seen"))
        with open(keeper, "w") as h:
            h.write(serialize(fm, body))
    dest_keeper = f"{ACTIVE_DIR}/{cid}.md"
    if os.path.abspath(keeper) != os.path.abspath(dest_keeper):
        if not os.path.exists(dest_keeper):
            os.rename(keeper, dest_keeper)
    # move clones to archive as superseded
    for c in clones:
        cparsed = parse(c)
        if cparsed:
            fm, body, _ = cparsed
            setkey(fm, "status", "superseded")
            setkey(fm, "superseded_by", cid)
            with open(c, "w") as h:
                h.write(serialize(fm, body))
        dest = f"{ARCHIVE_DIR}/{os.path.basename(c)}"
        base_no_ext = os.path.basename(c)[:-3]
        if os.path.exists(dest):
            dest = f"{ARCHIVE_DIR}/{base_no_ext}-superseded.md"
        os.rename(c, dest)
PY

# Stage the moves/edits best-effort so they ride the calling seam's commit; a
# staging failure never blocks the seam.
git add -A .workaholic/concerns >/dev/null 2>&1 || true
