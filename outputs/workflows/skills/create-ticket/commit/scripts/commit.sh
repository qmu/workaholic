#!/bin/sh -eu
# Safe commit workflow with multi-contributor awareness

set -eu

usage() {
    echo "Usage: commit.sh [--skip-staging] [--category <Added|Changed|Removed>] <title> <why> <changes> <concerns> <insights> <verify> [files...]"
    echo ""
    echo "Options:"
    echo "  --skip-staging        Skip staging step (use when files are already staged)"
    echo "  --category <value>    Emit a 'Category: <Added|Changed|Removed>' git trailer for /report grouping"
    echo ""
    echo "Parameters:"
    echo "  title     - Commit title (present-tense verb, 50 chars max)"
    echo "  why       - Why this change was needed: problem, trigger, approach (feeds /report Motivation; can be empty)"
    echo "  changes   - What users experience differently, before->after (or 'None')"
    echo "  concerns  - Risks, follow-ups, deferred work surfaced by this change (feeds /report Concerns; 'None' or empty to omit)"
    echo "  insights  - Non-obvious patterns or gotchas worth preserving (feeds /report Patterns; 'None' or empty to omit)"
    echo "  verify    - Verification done or needed (or 'None')"
    echo "  files...  - Optional: specific files to stage (ignored with --skip-staging)"
}

# Parse flags. Unknown -* arguments are refused rather than falling through to
# become the title: a typo'd flag (or --help itself) must never silently turn
# into a commit whose message is that flag.
SKIP_STAGING=false
CATEGORY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-staging)
            SKIP_STAGING=true
            shift
            ;;
        --category)
            if [ $# -lt 2 ]; then
                echo "Error: --category requires a value"
                echo ""
                usage
                exit 1
            fi
            CATEGORY="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 1
            ;;
        -*)
            echo "Error: unknown option: $1"
            echo ""
            usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Validate the optional change category (emitted as a git trailer). Fail-fast on
# a typo so the closed Added|Changed|Removed schema can't silently drift.
if [ -n "$CATEGORY" ]; then
    case "$CATEGORY" in
        Added|Changed|Removed) : ;;
        *)
            echo "Error: --category must be one of: Added, Changed, Removed (got: $CATEGORY)"
            exit 1
            ;;
    esac
fi

# All six positional fields are required (empty strings are fine -- optional
# sections default below). Without this floor, an under-supplied call would
# leave the unconsumed fields in "$@" and the staging loop would try to stage
# them as file paths -- the same silently-reinterpreted-input defect as a
# trailing flag.
if [ $# -lt 6 ]; then
    echo "Error: expected six positional arguments (title why changes concerns insights verify), got $#"
    echo ""
    usage
    exit 1
fi

TITLE="$1"
WHY="$2"
CHANGES="${3:-None}"
CONCERNS="$4"
INSIGHTS="$5"
VERIFY="${6:-None}"
shift 6

if [ -z "$TITLE" ]; then
    usage
    exit 1
fi

# Anything left in "$@" is the optional files list. Refuse any flag trailing
# the positional args by name: it would otherwise fall into the staging loop
# and be skipped as a missing file, silently dropping e.g. a --category.
for arg in "$@"; do
    case "$arg" in
        -*)
            echo "Error: unknown option: $arg (options must precede the positional arguments)"
            echo ""
            usage
            exit 1
            ;;
    esac
done

# Subject gate -- MUST run before the staging section below so a refused
# subject never mutates the index. commit.sh is the script-wrapped path the
# PreToolUse commit guard deliberately does not inspect, so the script runs
# the shared subject rule itself; the validator is the same-dir canonical copy
# (the git hooks reach it via the hooks/lib delegator).
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
if reason=$(sh "${SCRIPT_DIR}/check-subject.sh" "$TITLE"); then
    :
else
    echo "Error: rejected off-policy subject (${reason})."
    echo "  Subject: \"${TITLE}\""
    echo ""
    echo "Subject policy (plugins/workaholic/skills/commit/SKILL.md):"
    echo "  - present-tense, 50 characters or fewer"
    echo "  - no Conventional-Commit prefix (feat:/fix:/docs: ...)"
    echo "  - no leading [bracket] tag"
    exit 1
fi

# Pre-flight check: verify on a branch
BRANCH=$(git branch --show-current)
if [ -z "$BRANCH" ]; then
    echo "Error: Cannot commit: not on a named branch (detached HEAD state)"
    exit 1
fi

echo "==> Pre-commit check on branch: ${BRANCH}"

# Stage files (unless --skip-staging).
#
# Both staging paths once had a hole through which a file the caller meant to commit
# could vanish while the run still reported success. Both are closed here: a named path
# that cannot be staged is a fatal error, and an untracked file excluded by `git add -u`
# is named rather than silently dropped.
if [ "$SKIP_STAGING" = "false" ]; then
    if [ $# -gt 0 ]; then
        echo "==> Staging specified files..."
        # An explicitly-named path is the caller's strongest statement of intent. If ANY
        # named path cannot be staged, refuse the whole commit: report every missing path
        # and exit non-zero having staged and committed nothing. There is no reading of
        # `commit.sh foo.md` where silently committing without foo.md is what the caller
        # wanted, so this is a fatal error, not a skipped-with-a-warning. Missing paths are
        # collected in a first pass so nothing is staged before we know they all resolve.
        MISSING=""
        for file in "$@"; do
            if [ -e "$file" ] || git ls-files --deleted --error-unmatch "$file" >/dev/null 2>&1; then
                :
            else
                MISSING="${MISSING}${file}
"
            fi
        done
        if [ -n "$MISSING" ]; then
            echo "Error: refusing to commit -- named path(s) cannot be staged:" >&2
            printf '%s' "$MISSING" | sed 's/^/    ! not found: /' >&2
            echo "Nothing was staged and no commit was created. Fix the path(s) and retry." >&2
            exit 1
        fi
        for file in "$@"; do
            git add "$file"
            echo "    + $file"
        done
    else
        echo "==> Staging all tracked changes (git add -u)..."
        git add -u
        # `git add -u` stages tracked modifications ONLY -- an untracked file is left out
        # of the commit with no mention. That silent omission is the defect this guard
        # closes: a commit reported as done while a file the work depends on is missing.
        # Keep -u's safety (a stray file in a shared working tree does not ride in), but
        # make the omission impossible to miss by naming every untracked file. The caller
        # then decides whether to re-run naming it explicitly; commit.sh never drops it in
        # silence. `--exclude-standard` respects .gitignore, so ignored scratch files are
        # not noise here.
        UNTRACKED=$(git ls-files --others --exclude-standard)
        if [ -n "$UNTRACKED" ]; then
            echo ""
            echo "Warning: untracked files are NOT part of this commit (git add -u stages tracked changes only):"
            printf '%s\n' "$UNTRACKED" | sed 's/^/    ? /'
            echo "If any belongs in this commit, re-run commit.sh naming it as a trailing [files...] argument."
        fi
    fi
fi

# Check if anything is staged
STAGED=$(git diff --cached --stat)
if [ -z "$STAGED" ]; then
    echo ""
    echo "Warning: Nothing staged for commit"
    echo "Run 'git status' to see working tree state"
    exit 0
fi

echo ""
echo "==> Changes to be committed:"
git diff --cached --stat
echo ""

# Build the structured body section by section. Each present section is followed
# by a blank line. The optional sections (Why, Concerns, Insights) are omitted
# when empty or "None" so the log stays clean; Changes and Verify always render.
# Keys are chosen to feed /report: Why->Motivation, Changes->Changes/Outcome,
# Concerns->Concerns, Insights->Successful Development Patterns.
COMMIT_BODY=""

append_section() {
    COMMIT_BODY="${COMMIT_BODY}${1}: ${2}

"
}

case "$WHY" in ""|None|none) : ;; *) append_section "Why" "$WHY" ;; esac
append_section "Changes" "$CHANGES"
case "$CONCERNS" in ""|None|none) : ;; *) append_section "Concerns" "$CONCERNS" ;; esac
case "$INSIGHTS" in ""|None|none) : ;; *) append_section "Insights" "$INSIGHTS" ;; esac
append_section "Verify" "$VERIFY"

# Trailer block (last paragraph): a machine-readable Category trailer (when set)
# plus the Co-Authored-By trailer. `git log --format='%(trailers:key=Category,valueonly)'`
# can then read the Added/Changed/Removed grouping straight from the log.
TRAILERS="Co-Authored-By: Claude <noreply@anthropic.com>"
if [ -n "$CATEGORY" ]; then
    TRAILERS="Category: ${CATEGORY}
${TRAILERS}"
fi
COMMIT_BODY="${COMMIT_BODY}${TRAILERS}"

# Commit
echo "==> Committing..."
git commit -m "${TITLE}

${COMMIT_BODY}"

COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "Done! Commit: ${COMMIT_HASH}"
