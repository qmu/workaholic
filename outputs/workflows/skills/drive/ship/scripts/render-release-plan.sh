#!/bin/sh -eu
# RENDER AN AGENT-AUTHORED RELEASE PLAN OVER THE DERIVED FACTS. The arranging half
# of `draft-release-note.sh`'s `## Key Changes` section, split out so the renderer
# keeps its line-at-a-time shell shape and the arrangement gets a real parser.
#
#   render-release-plan.sh --plan <path|-> --facts <path> --target <slug> \
#                          --base-sha <sha> --status-out <path>
#
# Stdout: the markdown that goes UNDER the `## Key Changes` heading (the heading
# itself stays with the caller, which also owns the no-plan rendering).
# --status-out: one JSON line describing what the plan did, per
# `../reference/release-plan.md`:
#
#   {"present": true, "stale": false, "base_sha": "...", "groups": N,
#    "arranged": N, "held_back": N, "unarranged": N, "unknown": N,
#    "duplicates": N, "reason": ""}
#   {"present": false, "reason": "unreadable"|"malformed"|"other_target"|"no_renderer"}
#
# THE FACTS ARE THE CALLER'S AND ARE NEVER RE-DERIVED. `--facts` is one record per
# merge in the range, in chronological order, three US-separated fields:
# `<pr-number>\037<branch>\037<rendered line>` — where the line is exactly what the
# caller would have rendered without a plan (the story's Overview sentence, or the
# merge body's pull request title, already clamped). A plan supplies arrangement and
# commentary; it never supplies a change's own text, which is what keeps a planner
# from quietly rewriting history it did not read.
#
# NOTHING IS EVER DROPPED. A merge no group and no `held_back` entry names is
# rendered under *Not arranged by the plan*; a plan item naming a pull request that
# is not in this range is named under its own heading rather than fabricated; a
# repeated pull request is rendered once and counted. A silently shortened list
# reads as "nothing else happened", which is the failure the renderer's no-cap,
# no-selection rule exists to prevent.
#
# A PLAN THAT CANNOT BE APPLIED IS NOT APPLIED, AND SAYS SO. Every refusal exits 0
# with `present: false` and a named reason, so the caller falls back to the derived
# list and reports the reason instead of shipping a note that looks planned.

set -eu

PLAN=""
FACTS=""
TARGET=""
BASE_SHA=""
STATUS_OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --plan) PLAN="${2:-}"; shift 2 ;;
    --facts) FACTS="${2:-}"; shift 2 ;;
    --target) TARGET="${2:-}"; shift 2 ;;
    --base-sha) BASE_SHA="${2:-}"; shift 2 ;;
    --status-out) STATUS_OUT="${2:-}"; shift 2 ;;
    *) echo '{"present": false, "reason": "usage"}' >&2; exit 1 ;;
  esac
done

if [ -z "$PLAN" ] || [ -z "$STATUS_OUT" ]; then
  echo '{"present": false, "reason": "usage"}' >&2
  exit 1
fi

TMP="${TMPDIR:-/tmp}/wh-render-plan.$$"
trap 'rm -f "$TMP"' EXIT INT TERM

# `-` means stdin, which the python program below cannot read (its own source
# arrives there), so it is slurped to a temp file first.
if [ "$PLAN" = "-" ]; then
  cat > "$TMP"
  PLAN="$TMP"
fi

if [ ! -f "$PLAN" ]; then
  printf '{"present": false, "reason": "unreadable"}\n' > "$STATUS_OUT"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf '{"present": false, "reason": "no_renderer"}\n' > "$STATUS_OUT"
  exit 0
fi

python3 - "$PLAN" "$FACTS" "$TARGET" "$BASE_SHA" "$STATUS_OUT" <<'PY'
import json, sys, os

plan_path, facts_path, target, base_sha, status_out = sys.argv[1:6]
US = "\037"


def refuse(reason):
    with open(status_out, "w") as fh:
        fh.write(json.dumps({"present": False, "reason": reason}) + "\n")
    sys.exit(0)


try:
    with open(plan_path) as fh:
        plan = json.load(fh)
except (OSError, ValueError):
    refuse("malformed")

if not isinstance(plan, dict):
    refuse("malformed")

plan_target = str(plan.get("target") or "")
if target and plan_target and plan_target != target:
    refuse("other_target")

# The facts, in the caller's order. A merge with no pull request number is still a
# fact -- it simply cannot be addressed by a plan, so it lands unarranged.
facts = []
if facts_path and os.path.exists(facts_path):
    with open(facts_path) as fh:
        for raw in fh.read().split("\n"):
            if not raw.strip():
                continue
            parts = raw.split(US)
            while len(parts) < 3:
                parts.append("")
            facts.append({"pr": parts[0].strip(), "branch": parts[1].strip(),
                          "line": parts[2].strip()})

by_pr = {}
for fact in facts:
    if fact["pr"] and fact["pr"] not in by_pr:
        by_pr[fact["pr"]] = fact

out = []
seen = set()
unknown = []
duplicates = 0


def take(pr):
    """Resolve a plan reference to a derived fact, or None -- never a fabrication."""
    global duplicates
    key = str(pr).strip().lstrip("#")
    if key not in by_pr:
        unknown.append(key)
        return None
    if key in seen:
        duplicates += 1
        return None
    seen.add(key)
    return by_pr[key]


plan_base = str(plan.get("base_sha") or "")
# COMPARED BY PREFIX, because the two sides legitimately carry different widths: the
# caller hands over whatever `read-deploy-state.sh --base-rev` resolved (abbreviated),
# while a planner writing `git rev-parse` gives all forty. An abbreviation mismatch is
# not a stale plan, and calling it one would put a warning on every planned note.
shortest = min(len(plan_base), len(base_sha)) if (plan_base and base_sha) else 0
stale = bool(shortest and plan_base[:shortest] != base_sha[:shortest])
if stale:
    out.append("> **This plan was written for base `%s`; the base is now `%s`.** The"
               % (plan_base[:8], base_sha[:8]))
    out.append("> arrangement below is the judgment made at that base — anything that landed")
    out.append("> since it appears unarranged.")
    out.append("")

summary = str(plan.get("summary") or "").strip()
if summary:
    out.append(summary)
    out.append("")

groups = plan.get("groups")
if not isinstance(groups, list):
    groups = []

rendered_groups = 0
for index, group in enumerate(groups, start=1):
    if not isinstance(group, dict):
        continue
    title = str(group.get("title") or "").strip() or "Group %d" % index
    items = group.get("items")
    if not isinstance(items, list):
        items = []
    lines = []
    for item in items:
        if isinstance(item, dict):
            pr, note = item.get("pr"), str(item.get("note") or "").strip()
        else:
            pr, note = item, ""
        if pr is None:
            continue
        fact = take(pr)
        if fact is None:
            continue
        lines.append("- %s%s" % (fact["line"], (" — %s" % note) if note else ""))
    if not lines:
        # A group whose every item was unknown or repeated has nothing to arrange;
        # its references are still reported below rather than vanishing.
        continue
    rendered_groups += 1
    out.append("### %d. %s" % (rendered_groups, title))
    out.append("")
    why = str(group.get("why") or "").strip()
    if why:
        out.append(why)
        out.append("")
    risk = str(group.get("risk") or "").strip()
    if risk:
        out.append("**Risk:** %s" % risk)
        out.append("")
    out.extend(lines)
    out.append("")

held = plan.get("held_back")
if not isinstance(held, list):
    held = []
held_lines = []
for entry in held:
    if isinstance(entry, dict):
        pr, why = entry.get("pr"), str(entry.get("why") or "").strip()
    else:
        pr, why = entry, ""
    if pr is None:
        continue
    fact = take(pr)
    if fact is None:
        continue
    held_lines.append("- %s%s" % (fact["line"], (" — %s" % why) if why else ""))
if held_lines:
    out.append("### Held back")
    out.append("")
    out.append("Present in this range and deliberately not part of this release.")
    out.append("")
    out.extend(held_lines)
    out.append("")

unarranged = [f for f in facts if not f["pr"] or f["pr"] not in seen]
if unarranged:
    out.append("### Not arranged by the plan")
    out.append("")
    out.append("In this range, named by no group and held back by nobody.")
    out.append("")
    for fact in unarranged:
        out.append("- %s" % fact["line"])
    out.append("")

if unknown:
    out.append("### Referenced but not in this range")
    out.append("")
    for key in unknown:
        out.append("- Pull request #%s — named by the plan, not among this range's merges." % key)
    out.append("")

body = "\n".join(out).rstrip("\n")
sys.stdout.write(body + "\n" if body else "")

status = {"present": True, "stale": stale, "base_sha": plan_base,
          "groups": rendered_groups, "arranged": len(seen) - len(held_lines),
          "held_back": len(held_lines), "unarranged": len(unarranged),
          "unknown": len(unknown), "duplicates": duplicates, "reason": ""}
with open(status_out, "w") as fh:
    fh.write(json.dumps(status) + "\n")
PY
