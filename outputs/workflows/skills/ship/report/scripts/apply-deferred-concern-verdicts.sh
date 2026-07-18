#!/bin/sh -eu
# Apply deferred-concern judge verdicts to the corresponding files. Verdicts arrive
# on stdin as a JSON array of {path, verdict, resolved_by_pr?, resolved_by_commit?}.
# For "resolved" verdicts, flips status, records the resolving PR/commit, and
# moves the file into .workaholic/concerns/archive/. For "still_active"
# verdicts, leaves the file untouched.
#
# Usage: apply-deferred-concern-verdicts.sh [expected-count] < verdicts.json
#   expected-count (optional, default 0): the number of active deferred concerns
#   the caller expected the payload to cover (from list-active-deferred-concerns.sh).
#   When >0 and the payload names 0 verdicts, the script FAILS LOUD instead of
#   reporting zero — that mismatch is the signature of a stale or foreign payload
#   silently consumed at a shared path (the incident this contract exists to stop).
#
# Fail-loud contract (never mask a read failure behind exit 0):
#   - malformed / unparseable input, a non-list payload, or an object without a
#     "verdicts" key  -> non-zero exit with a message. NOT normalized to empty.
#   - expected-count >0 but the payload names 0 verdicts  -> non-zero exit.
#   - genuinely empty (empty stdin / [] / {"verdicts":[]}) with expected 0/unset
#     -> {"resolved":0,"still_active":0,"files_resolved":[]}, exit 0 (honest empty).
#
# Output: JSON summary {resolved: N, still_active: N, files_resolved: [...]}.
# The returned paths point to the new archive locations.

set -eu

EXPECTED="${1:-0}"

input=$(cat)

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# NOTE: no living migration here on purpose. Verdicts arrive from
# list-active-deferred-concerns.sh, which already migrated the tree and returned
# post-migration paths; migrating again would rename files out from under those
# paths. Apply operates on the paths it is given.

# Parse and VALIDATE the payload. Emits tab-delimited verdict lines on stdout;
# exits non-zero with a message on malformed / wrong-shape input. Empty stdin is
# valid and yields no lines. A malformed payload is NOT normalized to empty —
# reporting the empty case is the whole point; manufacturing it is the silence.
parse() {
  python3 - "$input" <<'PY'
import json, sys
raw = sys.argv[1]
if raw.strip() == "":
    sys.exit(0)  # empty stdin: no verdicts, not an error
try:
    data = json.loads(raw)
except Exception as e:
    sys.stderr.write("apply-deferred-concern-verdicts: unparseable verdicts payload: %s\n" % e)
    sys.exit(1)
# Accept the judge's {"verdicts": [...]} object or a bare [...] array. Any other
# shape fails loud — an object without "verdicts", or a non-list, is a wrong
# payload, not an empty one.
if isinstance(data, dict):
    if "verdicts" not in data:
        sys.stderr.write("apply-deferred-concern-verdicts: object payload has no 'verdicts' key\n")
        sys.exit(1)
    data = data["verdicts"]
if not isinstance(data, list):
    sys.stderr.write("apply-deferred-concern-verdicts: verdicts payload is not a JSON list\n")
    sys.exit(1)
for item in data:
    if not isinstance(item, dict):
        continue
    path = item.get("path", "")
    verdict = item.get("verdict", "still_active")
    rpr = item.get("resolved_by_pr") or ""
    rcommit = item.get("resolved_by_commit") or ""
    # Tab-delimited so paths with spaces survive; paths shouldn't have tabs.
    print(f"{path}\t{verdict}\t{rpr}\t{rcommit}")
PY
}

# A malformed / wrong-shape payload makes parse() exit non-zero; under `set -e`
# this assignment then aborts the whole script with that non-zero status, after
# parse() has already printed the reason to stderr. That is the fail-loud path.
parsed=$(parse)

# Incident-1 signature: the caller expected N>0 concerns but the payload named
# none (a stale/foreign {"verdicts":[]} silently consumed at a shared path).
# Every parsed verdict prints a non-empty line, so an empty $parsed means 0.
if [ "$EXPECTED" -gt 0 ] && [ -z "$parsed" ]; then
  echo "apply-deferred-concern-verdicts: expected ${EXPECTED} deferred concern(s) but the verdicts payload named 0 — refusing to report a count it did not compute (stale or foreign payload?)" >&2
  exit 1
fi

archive_dir=".workaholic/concerns/archive"

resolved_count=0
still_active_count=0
files_json="["
first=1

tab=$(printf '\t')

# Capture the parsed lines and iterate via a here-doc so the counters persist in
# the current shell (POSIX has no `< <(...)`; a pipe would lose them).
while IFS="$tab" read -r path verdict rpr rcommit; do
  [ -z "$path" ] && continue
  [ ! -f "$path" ] && continue

  if [ "$verdict" = "resolved" ]; then
    # Create the archive dir lazily — only when something is actually resolved,
    # so the honest-empty path stays cheap and touches nothing.
    mkdir -p "$archive_dir"

    # Read the mission relation before moving (concern frontmatter carries mission:).
    # Many-valued: a concern can have blocked more than one mission.
    concern_missions=$(sh "${SCRIPT_DIR}/../../mission/scripts//read-relation.sh" "$path" 2>/dev/null || true)
    concern_base=$(basename "$path")

    awk -v rpr="$rpr" -v rcommit="$rcommit" '
      /^---$/ { c++ }
      c==1 && /^status:/ { print "status: resolved"; next }
      c==1 && /^resolved_by_pr:/ { print "resolved_by_pr: " rpr; next }
      c==1 && /^resolved_by_commit:/ { print "resolved_by_commit: " rcommit; next }
      { print }
    ' "$path" > "${path}.tmp" && mv "${path}.tmp" "$path"

    dest="${archive_dir}/${concern_base}"
    git mv "$path" "$dest" 2>/dev/null || mv "$path" "$dest"

    # A resolved concern records a "concern resolved (unstuck)" line on EVERY mission it
    # blocked (idempotent; the mutator git-stages the mission file). Best-effort — never
    # blocks verdict application.
    printf '%s\n' "$concern_missions" | while IFS= read -r cm; do
      [ -n "$cm" ] || continue
      sh "${SCRIPT_DIR}/../../mission/scripts//append-changelog.sh" \
        "$cm" "concern resolved (unstuck)" "$concern_base" >/dev/null 2>&1 || true
    done

    resolved_count=$((resolved_count+1))
    if [ "$first" -eq 1 ]; then
      first=0
    else
      files_json="${files_json},"
    fi
    files_json="${files_json}\"${dest}\""
  else
    still_active_count=$((still_active_count+1))
  fi
done <<EOF
$parsed
EOF

files_json="${files_json}]"

echo "{\"resolved\":${resolved_count},\"still_active\":${still_active_count},\"files_resolved\":${files_json}}"
