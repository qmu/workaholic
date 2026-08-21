#!/bin/sh -eu
# The release scan's rules, applied to ONE composed body that is about to leave this
# repository as a GitHub issue.
#
# Usage: scan-outbound-body.sh <body-file>
# Output: {"verdict": "pass"|"block", "findings": [ {category, severity, file, line,
#          rule, evidence} ]} — the same envelope `scan-branch-safety.sh` emits, so a
#          caller reads one shape whichever gate it ran.
#
# WHY THIS EXISTS RATHER THAN A CALL TO scan-branch-safety.sh. That script scans
# `git diff <base>..HEAD`: it answers "what is this BRANCH about to publish". A crossing
# body is composed in the session and committed nowhere, so pointing the branch scan at
# it reports on the caller's unrelated working branch — a verdict about the wrong
# content, which is worse than no verdict because it reads as one. The rules themselves
# are shared, not copied: `secret-patterns.sh` and the `.workaholic/leak-denylist` are
# read from the release-scan skill, so the two gates cannot drift on what a credential
# or a listed term looks like.
#
# TWO OF THE THREE RULES APPLY, AND THE THIRD IS OMITTED DELIBERATELY. `secret` (hard)
# and `leak` (confirm) are properties of content and carry over unchanged. `size` is a
# property of a diff — file counts, per-file byte ceilings, per-commit changed lines —
# and none of it is meaningful for a single body a human is about to read verbatim in
# the confirmation. An empty `size` tier is honest; a fabricated one would not be.
#
# AND IT IS STILL THE SECOND LAYER, NEVER THE FIRST. A `pass` means only "nothing
# already written down was found". What actually leaks is a client's vocabulary, which
# is semantic and does not exist as a term to list until the moment it leaks — the
# feedback skill's *Crossing a repository boundary* section carries the five measured
# instances. The developer's verbatim confirmation is the control; this is underneath it.

set -eu

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd -P)"
. "${SCRIPT_DIR}/../../release-scan/scripts//lib/secret-patterns.sh"

body_file="${1:-}"
if [ -z "$body_file" ] || [ ! -f "$body_file" ]; then
    printf '{"verdict": "block", "findings": [{"category": "secret", "severity": "hard", "file": "%s", "line": 0, "rule": "no-body", "evidence": "no body file to scan"}]}\n' "$body_file"
    exit 0
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TAB=$(printf '\t')

# The same `file<TAB>line<TAB>content` shape the branch scan feeds its rules, so the
# shared library needs no second entry point. The pseudo-path is the body's basename:
# a finding must cite something a human can look at, and there is no repository path.
label="$(basename -- "$body_file")"
tagged="$(awk -v f="$label" -v t="$TAB" '{ print f t NR t $0 }' "$body_file")"

findings=""
first=1
add_finding() {
    [ "$first" -eq 1 ] || findings="${findings},"
    first=0
    findings="${findings}{\"category\": \"$1\", \"severity\": \"$2\", \"file\": \"$3\", \"line\": $4, \"rule\": \"$5\", \"evidence\": \"$6\"}"
}

# ---- secret (hard) ----
secret_hits="$(printf '%s\n' "$tagged" | secret_grep || true)"
while IFS="$TAB" read -r f l c; do
    [ -n "$f" ] || continue
    add_finding secret hard "$f" "$l" "credential" "<redacted>"
done <<EOF
$secret_hits
EOF

# ---- leak (confirm) ----
# Denylist-only, exactly as the branch scan is. Absent file means this check does
# nothing at all, which is the state of every repository where nobody wrote one.
denylist="${ROOT}/.workaholic/leak-denylist"
if [ -f "$denylist" ]; then
    while IFS= read -r term; do
        case "$term" in ''|'#'*) continue ;; esac
        term_hits="$(printf '%s\n' "$tagged" | grep -Fi -- "$term" || true)"
        while IFS="$TAB" read -r f l c; do
            [ -n "$f" ] || continue
            add_finding leak confirm "$f" "$l" "denylist:${term}" "$term"
        done <<INNER
$term_hits
INNER
    done < "$denylist"
fi

verdict=pass
[ "$first" -eq 1 ] || verdict=block
printf '{"verdict": "%s", "findings": [%s]}\n' "$verdict" "$findings"
