#!/bin/sh -eu
# Apply deferred-concern judge verdicts to the FEEDBACK STREAM. Verdicts arrive
# on stdin as a JSON array of {path, verdict, resolved_by_pr?, resolved_by_commit?},
# where each path is an open kind: concern feedback record (from
# feedback/scripts/list-open-concerns.sh). For "resolved" verdicts, a
# SUPERSEDING record is appended to the stream (kind: concern, supersedes:
# <record filename>, body naming the resolving PR/commit) — the resolved record
# itself is IMMUTABLE and never edited or moved (docs/loop-engineering-workflow.md
# H2/H3: resolution is a new record, and the open set is computed as
# "not superseded"). For "still_active" verdicts, nothing is written.
#
# Usage: apply-deferred-concern-verdicts.sh [expected-count] < verdicts.json
#   expected-count (optional, default 0): the number of open concerns
#   the caller expected the payload to cover (from list-open-concerns.sh).
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
# The returned paths point to the newly written SUPERSEDING records.

set -eu

EXPECTED="${1:-0}"

input=$(cat)

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# NOTE: no living migration here on purpose. Verdicts arrive from
# feedback/scripts/list-open-concerns.sh, which already migrated the tree and
# returned post-migration paths. Apply operates on the paths it is given.

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
    # An absent field is emitted as "-", never as an empty run: tab is IFS
    # *whitespace*, so `read` collapses consecutive tabs into one delimiter and
    # a verdict carrying only resolved_by_commit would shift that hash into the
    # resolved_by_pr column -- writing "PR #<commit-hash>" into an append-only
    # record. The reader maps "-" back to empty.
    print(f"{path}\t{verdict}\t{rpr or '-'}\t{rcommit or '-'}")
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

resolved_count=0
still_active_count=0
files_json="["
first=1

tab=$(printf '\t')

created_at=$(date -Iseconds)
author_email=$(git config user.email 2>/dev/null || echo "unknown@unknown.invalid")
ts=$(printf '%s' "$created_at" | tr -dc '0-9' | cut -c1-14)

# Capture the parsed lines and iterate via a here-doc so the counters persist in
# the current shell (POSIX has no `< <(...)`; a pipe would lose them).
while IFS="$tab" read -r path verdict rpr rcommit; do
  [ -z "$path" ] && continue
  [ ! -f "$path" ] && continue

  # "-" is the absent-field sentinel the parser emits (see the note there).
  [ "$rpr" = "-" ] && rpr=""
  [ "$rcommit" = "-" ] && rcommit=""

  if [ "$verdict" = "resolved" ]; then
    concern_base=$(basename "$path")

    # Frontmatter facts of the record being superseded (title/severity/id/mission).
    fm_get() {
      awk -v key="$1" '
        NR == 1 { if ($0 != "---") exit; next }
        /^---[ \t]*$/ { exit }
        index($0, key ":") == 1 { sub("^" key ":[ \t]*", ""); sub("[ \t]+$", ""); print; exit }
      ' "$path" 2>/dev/null || true
    }
    c_title=$(fm_get title)
    [ -n "$c_title" ] || c_title="$concern_base"
    c_sev=$(fm_get severity)
    [ -n "$c_sev" ] || c_sev="moderate"
    c_id=$(fm_get concern_id)
    c_mission=$(fm_get mission)

    # Many-valued mission relation, read through the single reader for the roll.
    concern_missions=$(sh "${SCRIPT_DIR}/../../mission/scripts//read-relation.sh" "$path" 2>/dev/null || true)

    dest=".workaholic/feedbacks/${ts}-resolved-${c_id:-${concern_base%.md}}.md"
    if [ ! -e "$dest" ]; then
      {
        printf -- '---\n'
        printf 'type: Feedback\n'
        printf 'title: Resolved: %s\n' "$c_title"
        printf 'kind: concern\n'
        printf 'source: development\n'
        printf 'created_at: %s\n' "$created_at"
        printf 'author: %s\n' "$author_email"
        printf 'supersedes: %s\n' "$concern_base"
        printf 'severity: %s\n' "$c_sev"
        printf 'concern_id: %s\n' "${c_id:-}"
        printf 'mission: %s\n' "${c_mission:-}"
        printf 'resolved_by_pr: %s\n' "${rpr:-}"
        printf 'resolved_by_commit: %s\n' "${rcommit:-}"
        printf -- '---\n\n'
        printf '# Resolved: %s\n\n' "$c_title"
        printf 'Judged resolved by the /story deferred-concern judge'
        if [ -n "${rpr:-}" ]; then printf ' (PR #%s' "$rpr"; [ -n "${rcommit:-}" ] && printf ', %s' "$rcommit"; printf ')'; elif [ -n "${rcommit:-}" ]; then printf ' (%s)' "$rcommit"; fi
        printf '. Supersedes %s.\n' "$concern_base"
      } > "$dest"
      git add "$dest" >/dev/null 2>&1 || true
    fi

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
