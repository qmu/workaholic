#!/bin/sh -eu
# Compare the live routines against the shipped templates, for ONE repository.
#
#   <RemoteTrigger list JSON> | compare-routines.sh <repo-url>
#
# Output (one JSON line):
#   {"repo","repo_name","total_live","for_this_repo","missing":[{id,name}],
#    "present":[{id,name,trigger_id,drift:[...]}], "unknown":[{name,trigger_id}]}
#
# WHY STDIN. The live routines come from the claude.ai remote-trigger API, and only the
# `RemoteTrigger` tool can reach it — a shell script cannot. So the command fetches and
# pipes the raw response here, and the comparison stays a script: the Shell Script
# Principle keeps this logic out of markdown, and a script is the only form a test can
# drive against fixtures without touching anyone's account.
#
# WHAT COUNTS AS "FOR THIS REPOSITORY". A routine belongs to this repo when its
# `job_config.ccr.session_context.sources[].git_repository.url` matches, compared after
# stripping a trailing slash and `.git`. The NAME is not the identity — names are what
# drift, and matching on them would report a renamed routine as both missing and unknown.
#
# DRIFT IS REPORTED PER FIELD, NOT AS A BOOLEAN. Measured on the live account when this
# was written: `Merged PR qmu-co-jp` and `[FB] coop-csnet` carry no `model` at all while
# every sibling pins `claude-opus-5`, and `[FB] data-platform` has one extra prompt line
# ("Speak/Write Japanese"). "This routine differs" would tell a developer nothing about
# which of those they are looking at, and the whole point of the issue behind this work is
# being able to refresh a routine from its template deliberately.
#
# `unknown` IS INFORMATION, NOT AN ERROR. A routine pointing at this repo that matches no
# template is somebody's deliberate one-off. It is listed so nothing about the repository
# is invisible, and nothing here ever proposes deleting it — the API has no delete, and
# that asymmetry is a feature: this can add and refresh, never remove.

set -eu

REPO="${1:-}"
[ -n "$REPO" ] || { echo '{"error": "no_repo_url"}' >&2; exit 1; }

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

REPO_CLEAN=$(printf '%s' "$REPO" | sed -e 's#/$##' -e 's#\.git$##')
REPO_NAME=$(printf '%s' "$REPO_CLEAN" | sed -e 's#.*/##')

LIVE=$(cat)
[ -n "$LIVE" ] || { echo '{"error": "no_live_input"}' >&2; exit 1; }

TMP=$(mktemp "${TMPDIR:-/tmp}/workaholic-routines.XXXXXX")
trap 'rm -f "$TMP"' EXIT
printf '%s' "$LIVE" > "$TMP"

TEMPLATES=$(sh "${SCRIPT_DIR}/list-routine-templates.sh")

# The comparison is JSON-shaped on both sides, so it is done in python3 rather than by
# hand-rolling a JSON reader in sed — the repo already depends on python3 in its test
# suite, and a fragile parser here would fail in the direction that hides drift.
python3 - "$TMP" "$REPO_CLEAN" "$REPO_NAME" "$SCRIPT_DIR" "$TEMPLATES" <<'PY'
import json, subprocess, sys

live_path, repo, repo_name, script_dir, templates_json = sys.argv[1:6]

def norm_url(u):
    return (u or "").rstrip("/").removesuffix(".git")

try:
    live = json.load(open(live_path))
except Exception as e:
    print(json.dumps({"error": "unparseable_live_input", "detail": str(e)}))
    sys.exit(1)

items = live.get("data", live if isinstance(live, list) else [])
templates = json.loads(templates_json)["templates"]

def sources_of(t):
    ccr = (t.get("job_config") or {}).get("ccr") or {}
    ctx = ccr.get("session_context") or {}
    return [norm_url((s.get("git_repository") or {}).get("url")) for s in ctx.get("sources") or []]

mine = [t for t in items if repo in sources_of(t)]

def render(tid):
    out = subprocess.run(["sh", f"{script_dir}/render-routine.sh", tid, repo],
                         capture_output=True, text=True)
    return json.loads(out.stdout)

def live_prompt(t):
    ccr = (t.get("job_config") or {}).get("ccr") or {}
    evs = ccr.get("events") or []
    if not evs:
        return ""
    return ((evs[0].get("data") or {}).get("message") or {}).get("content") or ""

def live_model(t):
    ccr = (t.get("job_config") or {}).get("ccr") or {}
    return ((ccr.get("session_context") or {}).get("model")) or ""

missing, present, matched_ids = [], [], set()

for tpl in templates:
    want = render(tpl["id"])
    # Identity is the rendered NAME within this repository's routines; a repo has at most
    # one of each template, so this is unambiguous even when a name has drifted in case.
    hit = next((t for t in mine if (t.get("name") or "").strip() == want["name"]), None)
    if hit is None:
        missing.append({"id": tpl["id"], "name": want["name"], "trigger": want["trigger"]})
        continue
    matched_ids.add(hit.get("id"))
    drift = []
    if live_prompt(hit).strip() != want["prompt"].strip():
        drift.append("prompt")
    if live_model(hit) != want["model"]:
        drift.append(f"model ({live_model(hit) or 'unset'} != {want['model']})")
    if (hit.get("cron_expression") or "") != want["cron_expression"]:
        drift.append(f"schedule ({hit.get('cron_expression') or 'none'} != {want['cron_expression'] or 'none'})")
    if not hit.get("enabled", True):
        drift.append("disabled")
    present.append({"id": tpl["id"], "name": want["name"],
                    "trigger_id": hit.get("id"), "drift": drift})

unknown = [{"name": t.get("name"), "trigger_id": t.get("id")}
           for t in mine if t.get("id") not in matched_ids]

print(json.dumps({
    "repo": repo, "repo_name": repo_name,
    "total_live": len(items), "for_this_repo": len(mine),
    "missing": missing, "present": present, "unknown": unknown,
}))
PY
