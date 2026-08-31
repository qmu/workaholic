#!/bin/sh -eu
# Is this repository bootstrapped for Claude Code on the web? Pure read.
#
#   check-bootstrap.sh [repo-root]
#
# Output (one JSON line):
#   {"hook":{"present","path","matches_canonical"},
#    "settings":{"registered","matcher","timeout","enabled_plugin","marketplace"},
#    "identity_map":{"present","path","addresses","covered","uncovered":[{address,artifacts,line}]},
#    "ok": true|false, "problems": [...], "advisories": [...]}
#
# `advisories` carries the identity mapping's two named problems. They do not gate `ok` —
# see the note beside where they are read.
#
# WHY THIS IS PART OF WIRING A REPOSITORY TO THE STANDARDS. A Claude Code Web routine runs
# in a fresh, ephemeral container. `enabledPlugins` in `.claude/settings.json` is not
# enough there -- the plugin is not fetched or installed automatically -- so without this
# hook every cloud routine stops at its own precondition. The [Implement] prompt says it in as
# many words: "the workaholic plugin must be loaded ... if it is not, post the failure and
# stop." An unbootstrapped repository therefore schedules its routines, fires them on
# time, and does nothing, which reads as healthy from the routines list and from git.
#
# **A configured routine and a working routine are different states**, and this check is
# the only thing that tells them apart.
#
# THE TEMPLATE IS THE PLUGIN'S, THE INSTALLATION IS THE REPOSITORY'S -- the same shape as
# the routine templates next door. `bootstrap/session-start.sh` is the canonical copy;
# `matches_canonical` compares the installed file against it byte-for-byte, so an old copy
# carrying the qmu/workaholic#126 defects (a swallowed errexit that logs OK on total
# failure, `marketplace add --scope user`, no idempotence) is reported as drift rather than
# passing because a file happens to exist at the path.
#
# THE MAPPING IS PART OF THE BOOTSTRAP, AND IT IS ONE CHECK, NOT TWO (2026-08-26). The
# hook's step 0b reads `.claude/git-identities`; a repository with the hook and without the
# mapping therefore looks configured while that step is a permanent no-op. Two questions
# about one file — does it EXIST, and does it COVER the addresses this tree uses — are
# emitted as one named-problem set by `audit-identity-coverage.sh` and carried through here:
# `identity_map_missing` and `identity_map_uncovered`. An operator told twice about one
# file, in two vocabularies, fixes one and assumes the other followed.
#
# EVERY PROBLEM IS NAMED SEPARATELY. "Not bootstrapped" could mean the hook file is
# missing, the settings entry is missing, the matcher is wrong (SessionStart also fires on
# resume/clear/compact), the timeout is too short for a network clone, or the installed
# copy is stale. Those need different fixes, and collapsing them into one boolean would
# leave the developer to re-derive which.

set -eu

ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
CANON="${SCRIPT_DIR}/../bootstrap/session-start.sh"

HOOK_REL=".claude/hooks/session-start.sh"
HOOK="${ROOT}/${HOOK_REL}"
SETTINGS="${ROOT}/.claude/settings.json"

hook_present=false
matches=false
if [ -f "$HOOK" ]; then
  hook_present=true
  if [ -f "$CANON" ] && cmp -s "$HOOK" "$CANON"; then
    matches=true
  fi
fi

# The mapping's own audit is a separate reader (it walks the tree's `assignees:` values
# through the field's one parser); its problems are carried through verbatim so the two
# checks speak one vocabulary.
IDENTITY_AUDIT=$(sh "${SCRIPT_DIR}/audit-identity-coverage.sh" "$ROOT" 2>/dev/null || printf '{"problems": []}')

# The settings side is JSON, so it is read with python3 rather than grepped: a SessionStart
# entry can be nested several ways and a grep would report a commented-out or unrelated
# match as configured.
python3 - "$SETTINGS" "$hook_present" "$matches" "$HOOK_REL" "$IDENTITY_AUDIT" <<'PY'
import json, sys, os

settings_path, hook_present, matches, hook_rel, identity_audit = sys.argv[1:6]
hook_present = hook_present == "true"
matches = matches == "true"

registered, matcher, timeout = False, "", 0
enabled_plugin, marketplace = False, False

data = {}
if os.path.isfile(settings_path):
    try:
        with open(settings_path) as fh:
            data = json.load(fh)
    except Exception:
        data = {}

for group in (data.get("hooks") or {}).get("SessionStart") or []:
    for h in group.get("hooks") or []:
        if "session-start.sh" in (h.get("command") or ""):
            registered = True
            matcher = group.get("matcher") or ""
            timeout = h.get("timeout") or 0

enabled_plugin = bool((data.get("enabledPlugins") or {}).get("workaholic@workaholic"))
marketplace = "workaholic" in (data.get("extraKnownMarketplaces") or {})

problems = []
if not hook_present:
    problems.append(f"hook_missing ({hook_rel} does not exist)")
elif not matches:
    problems.append("hook_stale (the installed hook differs from the plugin's canonical copy)")
if not registered:
    problems.append("not_registered (no SessionStart entry in .claude/settings.json runs it)")
else:
    if matcher != "startup":
        problems.append(
            f"matcher ({matcher or 'unset'} != startup; SessionStart also fires on "
            "resume/clear/compact)"
        )
    if timeout < 120:
        problems.append(
            f"timeout ({timeout or 'unset'} < 120s; a marketplace clone plus install can "
            "exceed the default)"
        )
if not enabled_plugin:
    problems.append("enabled_plugin (workaholic@workaholic is not in enabledPlugins)")
if not marketplace:
    problems.append("marketplace (workaholic is not in extraKnownMarketplaces)")

# The mapping's problems, carried through verbatim — one vocabulary for one file — but as
# ADVISORIES rather than in `problems`, so `ok` is byte-identical to what it was.
#
# WHY THEY DO NOT GATE `ok` (2026-08-26). `identity_map_uncovered` can only be settled by a
# human: which GitHub account an address belongs to is a fact this plugin does not have, so
# gating a completion signal on it makes `ok` unreachable by any machine, and
# `/workaholify`'s report-only outcome is a named refusal's recovery path rather than the
# ordinary one. Whether `identity_map_missing` should gate belongs to the queued ticket
# `install-and-audit-the-identity-mapping`, which owns the existence check — deliberately
# left to it rather than decided here, so one mission does not land another's ruling.
try:
    identity = json.loads(identity_audit)
except Exception:
    identity = {"problems": []}
advisories = list(identity.get("problems") or [])

print(json.dumps({
    "hook": {"present": hook_present, "path": hook_rel, "matches_canonical": matches},
    "settings": {
        "registered": registered, "matcher": matcher, "timeout": timeout,
        "enabled_plugin": enabled_plugin, "marketplace": marketplace,
    },
    "identity_map": {
        "present": (identity.get("map") or {}).get("present"),
        "path": (identity.get("map") or {}).get("path"),
        "addresses": identity.get("addresses"),
        "covered": identity.get("covered"),
        "uncovered": identity.get("uncovered") or [],
    },
    "ok": not problems,
    "problems": problems,
    "advisories": advisories,
}))
PY
