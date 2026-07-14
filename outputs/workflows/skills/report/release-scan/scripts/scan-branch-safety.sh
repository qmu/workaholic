#!/bin/sh -eu
# Scan a branch's changes for content that must not reach a public remote, BEFORE
# report/ship publish it. Deterministic (no model judgment) so it can gate a merge.
#
# Three checks over `git diff <base>..HEAD`:
#   secret  (severity hard)     — a known credential shape in an added line
#   size    (severity override) — too many changed files, or an oversized / very
#                                 large-diff file
#   leak    (severity confirm)  — an added line contains a term from the git-ignored
#                                 .workaholic/leak-denylist, or an internal-hostname
#                                 pattern (*.internal/.local/.corp)
#
# Only ADDED lines (the diff's `+`) are scanned, so unrelated pre-existing content
# never trips the gate. Every finding cites file:line + the matched rule.
#
# Usage: scan-branch-safety.sh [base-branch]
#   base defaults to gather/git-context.sh's base_branch, else main.
# Output: {"verdict": "pass"|"block", "findings": [ {category, severity, file, line,
#          rule, evidence} ]}. verdict is "block" iff findings is non-empty.

set -eu

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/secret-patterns.sh"

# Thresholds (tune here). "override" findings are legitimate sometimes, so /ship
# lets the developer override them; the numbers are named for discoverability.
MAX_FILES=100
MAX_FILE_ADDED_LINES=3000
MAX_FILE_BYTES=524288   # 512 KB

BASE="${1:-}"
if [ -z "$BASE" ]; then
    ctx=$(sh "${SCRIPT_DIR}/../../gather/scripts//git-context.sh" 2>/dev/null || true)
    BASE=$(printf '%s' "$ctx" | sed -n 's/.*"base_branch":[ ]*"\([^"]*\)".*/\1/p')
fi
[ -n "$BASE" ] || BASE=main

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TAB=$(printf '\t')
NL='
'

findings=""   # newline-delimited: category<TAB>severity<TAB>file<TAB>line<TAB>rule<TAB>evidence

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

add_finding() {
    entry="$1${TAB}$2${TAB}$3${TAB}$4${TAB}$5${TAB}$6"
    if [ -n "$findings" ]; then findings="${findings}${NL}${entry}"; else findings="$entry"; fi
}

# ---- size / count ----
numstat=$(git diff --numstat "${BASE}..HEAD" 2>/dev/null || true)
filecount=$(printf '%s\n' "$numstat" | grep -c . || true)
if [ "${filecount:-0}" -gt "$MAX_FILES" ]; then
    add_finding size override "(diff)" 0 "too-many-files" "${filecount} files > ${MAX_FILES}"
fi
while IFS="$TAB" read -r added removed path; do
    [ -n "$path" ] || continue
    case "$added" in ''|*[!0-9]*) : ;; *)
        if [ "$added" -gt "$MAX_FILE_ADDED_LINES" ]; then
            add_finding size override "$path" 0 "large-added-lines" "${added} added lines > ${MAX_FILE_ADDED_LINES}"
        fi
    ;; esac
    bytes=$(git cat-file -s "HEAD:$path" 2>/dev/null || echo 0)
    case "$bytes" in ''|*[!0-9]*) bytes=0 ;; esac
    if [ "$bytes" -gt "$MAX_FILE_BYTES" ]; then
        add_finding size override "$path" 0 "large-file" "${bytes} bytes > ${MAX_FILE_BYTES}"
    fi
done <<EOF
$numstat
EOF

# ---- added lines, tagged file<TAB>line<TAB>content (via -U0 so only + lines) ----
# The denylist file itself is excluded — it legitimately contains the very terms
# it lists, and it is git-ignored anyway, so it should never be scanned as content.
added_lines=$(git diff -U0 "${BASE}..HEAD" 2>/dev/null | awk '
/^\+\+\+ /{ f=$2; sub(/^b\//,"",f); next }
/^@@ /{ if (match($0, /\+[0-9]+/)) ln=substr($0,RSTART+1,RLENGTH-1)+0; next }
/^\+/{ if (f != ".workaholic/leak-denylist") print f "\t" ln "\t" substr($0,2); ln++; next }
' || true)

# ---- secrets (hard) ----
secret_hits=$(printf '%s\n' "$added_lines" | secret_grep || true)
while IFS="$TAB" read -r f l c; do
    [ -n "$f" ] || continue
    add_finding secret hard "$f" "$l" "credential" "<redacted>"
done <<EOF
$secret_hits
EOF

# ---- leak: internal-hostname structured pattern (confirm) ----
host_hits=$(printf '%s\n' "$added_lines" | grep -Ei '[a-z0-9_-]+\.(internal|local|corp)([^a-z0-9]|$)' || true)
while IFS="$TAB" read -r f l c; do
    [ -n "$f" ] || continue
    add_finding leak confirm "$f" "$l" "internal-hostname" "$(json_escape "$c")"
done <<EOF
$host_hits
EOF

# ---- leak: developer-maintained denylist (confirm) ----
denylist="${ROOT}/.workaholic/leak-denylist"
if [ -f "$denylist" ]; then
    while IFS= read -r term; do
        case "$term" in ''|'#'*) continue ;; esac
        term_hits=$(printf '%s\n' "$added_lines" | grep -Fi -- "$term" || true)
        while IFS="$TAB" read -r f l c; do
            [ -n "$f" ] || continue
            add_finding leak confirm "$f" "$l" "denylist:${term}" "$term"
        done <<INNER
$term_hits
INNER
    done < "$denylist"
fi

# ---- emit ----
out="["
first=1
while IFS="$TAB" read -r cat sev file line rule ev; do
    [ -n "$cat" ] || continue
    [ "$first" -eq 1 ] || out="${out},"
    first=0
    out="${out}{\"category\":\"$(json_escape "$cat")\",\"severity\":\"$(json_escape "$sev")\",\"file\":\"$(json_escape "$file")\",\"line\":${line:-0},\"rule\":\"$(json_escape "$rule")\",\"evidence\":\"$(json_escape "$ev")\"}"
done <<EOF
$findings
EOF
out="${out}]"

verdict=pass
[ -z "$findings" ] || verdict=block
printf '{"verdict": "%s", "findings": %s}\n' "$verdict" "$out"
