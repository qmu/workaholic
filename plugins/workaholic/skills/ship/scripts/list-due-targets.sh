#!/bin/sh -eu
# WHICH TARGETS THE CADENCE WOULD ACTUALLY WRITE — the planner's spend gate.
#
#   list-due-targets.sh <run-note-cadence.sh --dry-run output>
#
# Stdout: one GitHub-Actions output line, `targets=<slug> <slug> …` (empty value
# when nothing is due), so a workflow step can gate on it.
#
# It exists so an idle base spends no agent budget: the CI writer asks the cadence
# what it WOULD write before it pays for a judgment about it. A target is due when
# the cadence says `"due": true` for it — the daily `Asia/Tokyo` floor and the
# release-stage advance are the cadence's rules, and this reads its answer rather
# than re-deriving them (there is exactly one place that decision is made).
#
# It is a script rather than a pipeline in the workflow's `run:` block for the same
# reason every other extraction here is: shell buried in YAML is untested shell.

set -eu

IN="${1:-}"
if [ -z "$IN" ] || [ ! -f "$IN" ]; then
  printf 'targets=\n'
  exit 0
fi

if command -v python3 >/dev/null 2>&1; then
  python3 - "$IN" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except (OSError, ValueError):
    print("targets=")
    sys.exit(0)
slugs = [t.get("slug", "") for t in (data.get("targets") or [])
         if t.get("due") and t.get("slug")]
print("targets=%s" % " ".join(slugs))
PY
  exit 0
fi

# No python3: name nothing rather than guess. A missed plan renders the derived
# list and says so, which is the honest degradation; a wrong slug would not.
printf 'targets=\n'
