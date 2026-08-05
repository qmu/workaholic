#!/bin/sh -eu
# Scan a branch's changes for content that must not reach a public remote, BEFORE
# report/ship publish it. Deterministic (no model judgment) so it can gate a merge.
#
# Three checks over `git diff <base>..HEAD`:
#   secret  (severity hard)     — a known credential shape in an added line
#   size    (severity override) — too many changed files, an oversized / very
#                                 large-diff file, or a single commit whose
#                                 non-generated changed lines exceed the per-commit
#                                 cap (generated/bulk files exempted)
#   leak    (severity confirm)  — an added line contains a term from the git-ignored
#                                 .workaholic/leak-denylist. Listed terms only; absent
#                                 file means this check does nothing at all.
#
# Only ADDED lines (the diff's `+`) are scanned, so unrelated pre-existing content
# never trips the gate. Every finding cites file:line + the matched rule.
#
# Scope, stated plainly: this catches credential SHAPES and re-introduction of terms
# someone already listed. It does not detect client context — that is semantic and not
# enumerable in advance, and belongs to the crossing flow's masking confirmation. A `pass`
# verdict never means "no client context here".
#
# Usage: scan-branch-safety.sh [base-branch]
#   base defaults to gather/base-ref.sh (origin/<default>, resolved without a network
#   call so this gate stays offline). If the base cannot be resolved the scan FAILS
#   LOUDLY rather than defaulting to a stale local `main` and scanning phantom history.
# Output: {"verdict": "pass"|"block", "findings": [ {category, severity, file, line,
#          rule, evidence} ]}. verdict is "block" iff findings is non-empty.

set -eu

SCRIPT_DIR=$(dirname "$0")
. "${SCRIPT_DIR}/lib/secret-patterns.sh"
. "${SCRIPT_DIR}/lib/commit-size.sh"

# Thresholds (tune here). "override" findings are legitimate sometimes, so /ship
# lets the developer override them; the numbers are named for discoverability.
MAX_FILES=100
MAX_FILE_ADDED_LINES=3000
MAX_FILE_BYTES=524288   # 512 KB
MAX_COMMIT_CHANGED_LINES=500   # per-commit added+deleted, generated/bulk excluded

# Resolve the base from the single resolver — never re-derive a `${1:-main}` default
# here. base-ref.sh is offline (no network), so the gate's verdict cannot depend on
# connectivity, and it fails loudly instead of silently scanning against a stale `main`.
BASE="${1:-}"
if [ -z "$BASE" ]; then
    if ! BASE=$("${SCRIPT_DIR}/../../gather/scripts//base-ref.sh"); then
        echo "scan-branch-safety: could not resolve a base ref; refusing to scan against an unknown base" >&2
        exit 1
    fi
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TAB=$(printf '\t')
NL='
'

# Build the diff pathspec: base..HEAD plus :(exclude) globs from the committed,
# reviewable .workaholic/scan-allow (paths that legitimately contain secret-shaped
# or pattern-describing content — test fixtures, the scanner's own docs — NOT real
# secrets). Excluding them here keeps secret findings non-overridable at ship time
# while letting a repo pre-declare, in review, its known-safe paths.
set -- "${BASE}..HEAD" --
allowfile="${ROOT}/.workaholic/scan-allow"
if [ -f "$allowfile" ]; then
    while IFS= read -r pat; do
        case "$pat" in ''|'#'*) continue ;; esac
        set -- "$@" ":(exclude,glob)${pat}"
    done < "$allowfile"
fi

findings=""   # newline-delimited: category<TAB>severity<TAB>file<TAB>line<TAB>rule<TAB>evidence

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

add_finding() {
    entry="$1${TAB}$2${TAB}$3${TAB}$4${TAB}$5${TAB}$6"
    if [ -n "$findings" ]; then findings="${findings}${NL}${entry}"; else findings="$entry"; fi
}

# A path is "generated / bulk" — exempt from the per-commit changed-lines gate — if
# it is a lockfile, a minified/sourcemap artifact, or is declared linguist-generated
# in .gitattributes (how a repo marks its own generated trees, e.g. outputs/). This is
# what keeps the giant generated commits that motivate the per-commit tail from ever
# tripping the gate. Keep the glob list small and generic; per-repo generated dirs
# belong in .gitattributes, not hard-coded here.
is_generated_path() {
    case "$1" in
        *.lock|*-lock.json|package-lock.json|yarn.lock|pnpm-lock.yaml|Cargo.lock|poetry.lock|composer.lock|Gemfile.lock|go.sum|flake.lock) return 0 ;;
        *.min.js|*.min.css|*.map) return 0 ;;
    esac
    attr=$(git check-attr linguist-generated -- "$1" 2>/dev/null || true)
    case "$attr" in *": set") return 0 ;; esac
    return 1
}

# ---- size / count ----
numstat=$(git diff --numstat "$@" 2>/dev/null || true)
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

# ---- per-commit added lines (size / override) ----
# Standardize the commit as a reviewable unit. WHAT IS COUNTED IS DECIDED IN
# scripts/lib/commit-size.sh, which carries the rule's rationale, the five measured
# instances it was chosen against, and the rejected alternatives — read that before
# changing anything here. In short: ADDED lines only (a relocation must not be charged
# twice for moving content), excluding generated/bulk files, excluding `.workaholic/`
# artifact prose (specs and records are not implementation throughput), and skipping merge
# commits entirely (a merge authors nothing). A commit whose remaining total exceeds
# MAX_COMMIT_CHANGED_LINES yields one `too-large-commit` finding, at override severity so
# a large-but-reviewed commit can still be consciously accepted at /ship.
for sha in $(git rev-list "${BASE}..HEAD" 2>/dev/null || true); do
    # A merge commit's diff against its first parent is the whole of what it merges, and
    # that content was already measured on the commits being brought in.
    if commit_size_is_merge "$sha"; then continue; fi
    commit_total=0
    # -M so a whole-file rename reports 0/0 rather than its full length. It does not help
    # a SPLIT (content redistributed into new files) — see lib/commit-size.sh — but it
    # costs nothing and is correct for a true move.
    commit_numstat=$(git show -M --numstat --format= "$sha" 2>/dev/null || true)
    while IFS="$TAB" read -r cadded cremoved cpath; do
        [ -n "$cpath" ] || continue
        # binary rows carry '-' for both counts: generated/bulk, skip.
        case "$cadded" in ''|*[!0-9]*) continue ;; esac
        case "$cremoved" in ''|*[!0-9]*) cremoved=0 ;; esac
        if is_generated_path "$cpath"; then continue; fi
        if commit_size_is_artifact_prose "$cpath"; then continue; fi
        if [ "$cadded" -gt "$MAX_FILE_ADDED_LINES" ]; then continue; fi
        commit_total=$((commit_total + cadded))
    done <<INNER
$commit_numstat
INNER
    if [ "$commit_total" -gt "$MAX_COMMIT_CHANGED_LINES" ]; then
        short=$(git rev-parse --short "$sha" 2>/dev/null || echo "$sha")
        add_finding size override "$short" 0 "too-large-commit" "${commit_total} added lines of implementation > ${MAX_COMMIT_CHANGED_LINES}"
    fi
done

# ---- added lines, tagged file<TAB>line<TAB>content (via -U0 so only + lines) ----
# The denylist file itself is excluded — it legitimately contains the very terms
# it lists, and it is git-ignored anyway, so it should never be scanned as content.
added_lines=$(git diff -U0 "$@" 2>/dev/null | awk '
/^\+\+\+ /{ f=$2; sub(/^b\//,"",f); next }
/^@@ /{ if (match($0, /\+[0-9]+/)) ln=substr($0,RSTART+1,RLENGTH-1)+0; next }
/^\+/{ if (f != ".workaholic/leak-denylist") print f "\t" ln "\t" substr($0,2); ln++; next }
' || true)

# ---- secrets (hard) ----
# GENERATED PATHS ARE EXEMPT FROM THE SECRET RULE.
# A generated tree is a mechanical copy of reviewed source, so a credential that
# arrives there through a build also sits in that source — which this same scan reads,
# on this same branch, unexempted. For that case the exemption removes only the
# DUPLICATE of a finding the scan still makes (measured: source finding fires, copy
# is silent). `is_generated_path` is the same predicate the per-commit size rule uses,
# so "generated" means one thing in this script.
#
# THE COST, STATED PLAINLY: a credential written into a generated path BY HAND, with
# no source counterpart, is no longer reported here. That is measured, not assumed.
# What still catches it is `Outputs Freshness` CI, which rebuilds `outputs/` and fails
# on any diff — a hand-edit of a generated tree cannot reach a merge whether or not it
# holds a credential. The exemption is scoped to this rule only: the `size` and `leak`
# rules are untouched, and `.workaholic/scan-allow` remains the way to drop a path
# from the whole scan.
#
# WHY IT IS NEEDED. `git diff <base>..HEAD` reports every line of a file that arrived
# at a NEW path as added, so when build.mjs grows a bundle's closure it copies whole
# tracked files into new `outputs/` paths and every line reads as authored. Measured
# 2026-08-05: `land-unit.sh` referenced `catchup-main.sh`, which pulled
# `ship/scripts/` into two more bundles, and `record-evidence.sh:19` — a COMMENT
# documenting the secret guard, byte-identical to a line on `main` for weeks — was
# reported twice as a hard `secret` block. `commit-size.sh` had already reasoned this
# through for the size rule ("a relocation is not charged twice for moving content");
# the secret rule inherited none of it.
#
# This is the general form of a fix the allowlist already made surgically: the
# committed `.workaholic/scan-allow` carries `outputs/workflows/skills/*/release-scan/**`
# for exactly this reason. That entry stays — the allowlist drops paths from the WHOLE
# scan (leak and size too), which is strictly more than this rule does.
#
# `secret` is the one non-overridable tier, so a false positive here has no escape
# hatch by design: any future change that grows a bundle closure would inherit a
# permanent block on a branch that introduced no credential at all.
secret_scan_lines=$(
    gen_paths=$(
        printf '%s\n' "$added_lines" | cut -f1 | sort -u | while IFS= read -r gp; do
            [ -n "$gp" ] || continue
            if is_generated_path "$gp"; then printf '%s\n' "$gp"; fi
        done
    )
    printf '%s\n' "$added_lines" | awk -F"$TAB" -v gen="$gen_paths" '
BEGIN { n = split(gen, a, "\n"); for (i = 1; i <= n; i++) if (a[i] != "") g[a[i]] = 1 }
!($1 in g)
'
)

secret_hits=$(printf '%s\n' "$secret_scan_lines" | secret_grep || true)
while IFS="$TAB" read -r f l c; do
    [ -n "$f" ] || continue
    add_finding secret hard "$f" "$l" "credential" "<redacted>"
done <<EOF
$secret_hits
EOF

# ---- leak: developer-maintained denylist (confirm) ----
# Denylist-only by design. A structured internal-hostname pattern lived here and was
# removed: replayed against five real leaks it matched none of them, while matching
# `metadata.internal` — the frontmatter field every script-bearing skill must carry.
# Zero true positives, a standing false positive against our own docs. Do not
# reintroduce a pattern here: what leaks is a client's vocabulary, which is semantic
# and not enumerable in advance. That judgement belongs to a person at the crossing, not
# to a regex.
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
