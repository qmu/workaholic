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
            CATEGORY="${2:-}"
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

TITLE="${1:-}"
WHY="${2:-}"
CHANGES="${3:-None}"
CONCERNS="${4:-}"
INSIGHTS="${5:-}"
VERIFY="${6:-None}"
shift 6 2>/dev/null || true

if [ -z "$TITLE" ]; then
    usage
    exit 1
fi

# Pre-flight check: verify on a branch
BRANCH=$(git branch --show-current)
if [ -z "$BRANCH" ]; then
    echo "Error: Cannot commit: not on a named branch (detached HEAD state)"
    exit 1
fi

echo "==> Pre-commit check on branch: ${BRANCH}"

# Stage files (unless --skip-staging)
if [ "$SKIP_STAGING" = "false" ]; then
    if [ $# -gt 0 ]; then
        echo "==> Staging specified files..."
        for file in "$@"; do
            if [ -e "$file" ] || git ls-files --deleted --error-unmatch "$file" >/dev/null 2>&1; then
                git add "$file"
                echo "    + $file"
            else
                echo "    ! Skipping (not found): $file"
            fi
        done
    else
        echo "==> Staging all tracked changes (git add -u)..."
        git add -u
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
