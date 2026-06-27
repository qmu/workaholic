#!/bin/sh -eu
# POSIX-sh conformance linter for Workaholic shell scripts.
#
# Flags any *.sh whose shebang is not #!/bin/sh, or that contains a bash-only
# construct: [[ ]] tests, the =~ regex operator, <<< here-strings,
# ${BASH_SOURCE}/BASH_REMATCH, `declare`, a statement-position `local`, or array
# expansion (${x[@]} / ${x[*]}). It is a token grep, not a full parser — the
# patterns are chosen to avoid false positives on POSIX character classes
# ([[:space:]] etc.) and on the words "local"/"declare" appearing in prose.
#
# This is the standing guard that keeps rules/shell.md from regressing: the
# conversion (PRs that flip scripts to POSIX) is point-in-time; this lint is what
# fails CI the next time a #!/bin/bash script or a bashism is introduced.
#
# Usage: sh posix-lint.sh [target-dir]
#   Default target: the plugin directory this hook lives in (plugins/workaholic).
# Output: JSON {conforming, count, findings:[{path,line,kind,snippet}]} on stdout,
#         a human summary on stderr. Exit 0 iff conforming, 1 if any finding.
#
# Lives in hooks/ (beside layout-doctor.sh) so it stays out of the generated
# outputs/ bundle and needs no rebuild. Read-only.

set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
# hooks/ is at plugins/workaholic/hooks, so the default scan root is the plugin dir.
target_in="${1:-${SCRIPT_DIR}/..}"

if [ ! -d "$target_in" ]; then
  echo '{"conforming": true, "count": 0, "findings": [], "reason": "target_absent"}'
  exit 0
fi

# Normalize away any ".." so reported paths read cleanly.
target="$(cd -- "$target_in" && pwd)"

tab=$(printf '\t')
findings=""   # newline-delimited "path<TAB>line<TAB>kind<TAB>snippet"

add_finding() {
  findings="${findings}${1}${tab}${2}${tab}${3}${tab}${4}
"
}

# Body bashism patterns (ERE). "\[\[[[:space:]]" matches a bash `[[ ` test but
# NOT the POSIX class "[[:space:]]" (which is "[[:" — no space). The local/declare
# patterns are anchored to statement start so prose ("# delete local branch") and
# embedded languages ("perl -e '... local $/ ...'") do not trip them.
bashism_re='\[\[[[:space:]]|[[:space:]]=~[[:space:]]|<<<|BASH_SOURCE|BASH_REMATCH|^[[:space:]]*declare[[:space:]]|^[[:space:]]*local[[:space:]]|\[@\]|\[\*\]'

# Skip this linter itself: its own documentation and the bashism_re definition
# necessarily contain the very tokens it scans for. It is POSIX by construction.
self="${SCRIPT_DIR}/posix-lint.sh"

# Iterate every *.sh under the target. find -print0 is not POSIX; rely on
# newline-free paths (true for this repo).
for f in $(find "$target" -name '*.sh' -type f | sort); do
  [ "$f" = "$self" ] && continue

  shebang=$(head -n 1 "$f")
  case "$shebang" in
    '#!/bin/sh'*) : ;;
    *) add_finding "$f" 1 "shebang" "$shebang" ;;
  esac

  # grep -nE prints "line:content" per hit; capture and emit one finding each.
  # Drop full-line comments ("<n>:   # ...") so a token mentioned in prose does
  # not count as a bashism — only executable lines matter.
  matches=$(grep -nE "$bashism_re" "$f" | grep -vE '^[0-9]+:[[:space:]]*#' || true)
  while IFS= read -r ml; do
    [ -n "$ml" ] || continue
    ln=${ml%%:*}
    snip=${ml#*:}
    add_finding "$f" "$ln" "bashism" "$snip"
  done <<EOF
$matches
EOF
done

count=$(printf '%s' "$findings" | grep -c . || true)

if [ "$count" -eq 0 ]; then
  echo '{"conforming": true, "count": 0, "findings": []}'
  exit 0
fi

# Serialize findings to JSON via jq (handles escaping of snippets).
findings_json=$(printf '%s' "$findings" | grep -v '^$' | jq -R -s --arg t "$tab" '
  split("\n")
  | map(select(length > 0))
  | map(split($t))
  | map({path: .[0], line: (.[1] | tonumber? // .[1]), kind: .[2], snippet: .[3]})')

echo "{\"conforming\": false, \"count\": ${count}, \"findings\": ${findings_json}}"

# Human-readable summary on stderr.
printf 'POSIX-sh lint: %s non-conformance(s) found (see rules/shell.md):\n' "$count" >&2
printf '%s' "$findings" | grep -v '^$' | while IFS="$tab" read -r p l k s; do
  printf '  %s:%s [%s] %s\n' "$p" "$l" "$k" "$s" >&2
done

exit 1
