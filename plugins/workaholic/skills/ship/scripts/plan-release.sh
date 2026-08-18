#!/bin/sh -eu
# AUTHOR A TARGET'S RELEASE PLAN — the judgment half of the draft release note.
#
#   plan-release.sh --target <slug> --out <dir> [base]
#
# Output (one JSON line):
#   {"ok": true, "target": "...", "planned": true, "path": "<dir>/<slug>.json",
#    "base_sha": "...", "merges": N, "groups": N}
#   {"ok": true, "target": "...", "planned": false,
#    "reason": "empty_range"|"no_planner"|"planner_failed"|"invalid_plan"|"no_renderer"}
#   {"ok": false, "reason": "usage"|"draft_failed"}
#
# WHERE THE JUDGMENT RUNS (Open Decision 1 on ticket
# `20260818202056-run-the-release-planning-judgment-and-reach-ci`, ruled here):
# **(a) — IN CI, BESIDE THE WRITER.** The three seams the proposal named were each
# measured against `workaholic:ship` §7's refusals rather than against effort:
#
#   (b) the agent runs on the `[Prepare Release]` tick and COMMITS the plan for CI
#       to read. Refused: that is exactly the class §7 refused twice — an hourly
#       unattended writer on `main` — and it contradicts the command's own contract
#       ("it writes nothing, anywhere") in three documents. A plan file is not a
#       release, but it is a commit, and for a target declaring no `paths:` the
#       commit storing it increments the very count it is about.
#   (c) the plan is authored per unit at ship/report time and accumulates. Refused
#       on two counts: it is not continuous re-arrangement (a repository whose units
#       are all `review` would refresh it rarely), and it has nowhere to put the
#       result — a per-unit plan must be committed for a later CI run to read it,
#       which is (b)'s refusal in a different costume. It would also stitch per-unit
#       judgments together rather than produce one view of the whole release.
#   (a) CHOSEN. The `Release Note Draft` workflow already holds `contents: write`
#       and a defined checkout (`fetch-depth: 0` + tags), so the judgment and the
#       write happen in one place and NOTHING crosses between them. It answers §7's
#       three refusals by name: it commits nothing to `main`, it writes no open pull
#       request's branch, and it never runs `/ship`.
#
# ITS COST IS A CREDENTIAL, AND THE COST IS PAID VISIBLY. An agent invocation in CI
# needs a key, which is the operator's act and not this repository's to perform. So
# the planner is GATED on one being present: with no planner command reachable this
# script reports `no_planner` and writes nothing, the note falls back to the derived
# list, and the fallback SAYS SO on its face (`draft-release-note.sh`, Open Decision
# 2). An unset secret is therefore a named, visible degradation rather than a broken
# job — the same discipline every other degraded read in this plugin follows.
#
# THE PLANNER COMMAND IS PLUGGABLE, WHICH IS ALSO WHAT MAKES IT TESTABLE.
# `WORKAHOLIC_PLANNER_CMD` (default `claude -p`) is run with the prompt on stdin and
# must print the plan JSON on stdout. The hermetic suite points it at a stub, so the
# whole chain — facts, prompt, validation, the renderer's arrangement — is proved
# with no network and no key.
#
# HOW OFTEN IT RUNS, STATED PLAINLY BECAUSE THE ASK SAYS "CONTINUOUSLY". It runs
# when the cadence would actually write: at most once per `Asia/Tokyo` day, plus
# whenever the release stage advances (`run-note-cadence.sh`). An idle base spends
# nothing, because the workflow asks the cadence what is due BEFORE it plans.
#
# IT VALIDATES ONLY WHAT IT MUST FIX. Parseable JSON, the right `target`, and the
# `base_sha` it planned against are stamped here; everything else about whether a
# plan APPLIES is the renderer's single definition (`render-release-plan.sh`), and a
# second validator would eventually disagree with it.

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

TARGET=""
OUT_DIR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --out) OUT_DIR="${2:-}"; shift 2 ;;
    --) shift; break ;;
    -*) echo '{"ok": false, "reason": "usage"}' >&2; exit 1 ;;
    *) break ;;
  esac
done
BASE="${1:-main}"

if [ -z "$TARGET" ] || [ -z "$OUT_DIR" ]; then
  echo '{"ok": false, "reason": "usage"}' >&2
  exit 1
fi

json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g'
}

TMP="${TMPDIR:-/tmp}/wh-plan-release.$$"
FACTS_DIR="${TMP}.facts"
PROMPT="${TMP}.prompt"
RAW="${TMP}.raw"
PLAN="${TMP}.plan"
trap 'rm -rf "$FACTS_DIR" "$PROMPT" "$RAW" "$PLAN"' EXIT INT TERM
mkdir -p "$FACTS_DIR" "$OUT_DIR"

if ! command -v python3 >/dev/null 2>&1; then
  printf '{"ok": true, "target": "%s", "planned": false, "reason": "no_renderer"}\n' "$(json_escape "$TARGET")"
  exit 0
fi

# The facts are the renderer's, never re-derived here: one derivation, two readers.
DRAFT_JSON=$(sh "${SCRIPT_DIR}/draft-release-note.sh" --target "$TARGET" \
  --facts-out "$FACTS_DIR" "$BASE" 2>/dev/null || true)
if ! printf '%s' "$DRAFT_JSON" | grep -q '"ok": true'; then
  printf '{"ok": false, "reason": "draft_failed", "target": "%s"}\n' "$(json_escape "$TARGET")"
  exit 0
fi

BASE_SHA=$(printf '%s' "$DRAFT_JSON" \
  | sed -n 's/.*"base_sha": "\([^"]*\)".*/\1/p' | head -n 1)
FACTS="${FACTS_DIR}/${TARGET}.facts"

if [ ! -s "$FACTS" ]; then
  # Nothing is waiting, so there is nothing to arrange. Not a failure, and not a
  # plan either: an empty plan would render a heading over an empty release.
  printf '{"ok": true, "target": "%s", "planned": false, "reason": "empty_range"}\n' \
    "$(json_escape "$TARGET")"
  exit 0
fi

PLANNER_CMD="${WORKAHOLIC_PLANNER_CMD:-claude -p}"
PLANNER_BIN=$(printf '%s' "$PLANNER_CMD" | awk '{print $1}')
if ! command -v "$PLANNER_BIN" >/dev/null 2>&1; then
  printf '{"ok": true, "target": "%s", "planned": false, "reason": "no_planner"}\n' \
    "$(json_escape "$TARGET")"
  exit 0
fi

MERGES=$(awk 'NF' "$FACTS" | wc -l | tr -d ' ')

# --- the prompt: the facts, the schema, and the two things a plan may never do ---
python3 - "$FACTS" "$TARGET" "$BASE_SHA" > "$PROMPT" <<'PY'
import sys

facts_path, target, base_sha = sys.argv[1:4]
US, RS = "\037", "\036"
rows = []
for raw in open(facts_path).read().split("\n"):
    if not raw.strip():
        continue
    parts = (raw.split(US) + ["", "", ""])[:3]
    chunks = parts[2].split(RS)
    rows.append((parts[0].strip(), parts[1].strip(), chunks[0].strip(),
                 [c.strip() for c in chunks[1:] if c.strip()]))

print("You are arranging a release plan for the deployment target `%s`." % target)
print("")
print("Below are the merges waiting to release, newest first, exactly as the release")
print("note renders them. Group them into a ship order a human can act on: what ships")
print("together, in what order, what is risky beside what, and what should be held back.")
print("")
for pr, branch, line, detail in rows:
    print("- #%s (%s): %s" % (pr or "?", branch or "?", line))
    for d in detail:
        print("    %s" % d)
print("")
print("Rules you may not break:")
print("- Arrange only. Never write a change's own summary — the note renders the line")
print("  above for each merge, and your `note` is one short remark about that merge IN")
print("  THIS RELEASE, or absent.")
print("- Reference merges only by the numbers listed above. Do not invent a number.")
print("- You may leave a merge out of every group; it renders as unarranged. Use")
print("  `held_back` only when the merge should NOT go out in this release, with a why.")
print("- Say less rather than guessing. An empty `why` is better than an invented one.")
print("")
print("Answer with ONE JSON object and nothing else, in this shape:")
print('{"target": "%s", "base_sha": "%s",' % (target, base_sha))
print(' "summary": "one to three sentences: what this release is",')
print(' "groups": [{"title": "...", "why": "...", "risk": "low|moderate|high",')
print('             "items": [{"pr": 123, "note": "..."}]}],')
print(' "held_back": [{"pr": 124, "why": "..."}],')
print(' "notes": ["whole-release caveats"]}')
PY

if ! $PLANNER_CMD < "$PROMPT" > "$RAW" 2>/dev/null; then
  printf '{"ok": true, "target": "%s", "planned": false, "reason": "planner_failed"}\n' \
    "$(json_escape "$TARGET")"
  exit 0
fi

# The answer is an agent's, so it is treated as untrusted text: the first balanced
# JSON object is extracted (a fenced block or a sentence around it is common), and
# the target and base_sha are STAMPED rather than trusted, because those two decide
# whether the renderer applies the plan at all.
if ! python3 - "$RAW" "$PLAN" "$TARGET" "$BASE_SHA" <<'PY'
import json, sys

raw_path, out_path, target, base_sha = sys.argv[1:5]
text = open(raw_path).read()
start = text.find("{")
if start < 0:
    sys.exit(1)
depth, end, instr, esc = 0, -1, False, False
for i in range(start, len(text)):
    ch = text[i]
    if instr:
        if esc: esc = False
        elif ch == "\\": esc = True
        elif ch == '"': instr = False
        continue
    if ch == '"': instr = True
    elif ch == "{": depth += 1
    elif ch == "}":
        depth -= 1
        if depth == 0:
            end = i + 1
            break
if end < 0:
    sys.exit(1)
try:
    plan = json.loads(text[start:end])
except ValueError:
    sys.exit(1)
if not isinstance(plan, dict) or not isinstance(plan.get("groups"), list):
    sys.exit(1)
plan["target"] = target
plan["base_sha"] = base_sha
with open(out_path, "w") as fh:
    json.dump(plan, fh, indent=2)
    fh.write("\n")
PY
then
  printf '{"ok": true, "target": "%s", "planned": false, "reason": "invalid_plan"}\n' \
    "$(json_escape "$TARGET")"
  exit 0
fi

GROUPS=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1])).get("groups") or []))' "$PLAN")
cp "$PLAN" "${OUT_DIR}/${TARGET}.json"

printf '{"ok": true, "target": "%s", "planned": true, "path": "%s", "base_sha": "%s", "merges": %s, "groups": %s}\n' \
  "$(json_escape "$TARGET")" "$(json_escape "${OUT_DIR}/${TARGET}.json")" \
  "$(json_escape "$BASE_SHA")" "$MERGES" "$GROUPS"
