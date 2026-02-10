#!/bin/sh -eu
# Safe commit workflow with multi-contributor awareness

set -eu

# Parse flags
SKIP_STAGING=false
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-staging)
            SKIP_STAGING=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

TITLE="${1:-}"
DESCRIPTION="${2:-}"
CHANGES="${3:-None}"
TEST_PLAN="${4:-None}"
RELEASE_PREP="${5:-None}"
shift 5 2>/dev/null || true

if [ -z "$TITLE" ]; then
    echo "Usage: commit.sh [--skip-staging] <title> <description> <changes> <test-plan> <release-prep> [files...]"
    echo ""
    echo "Options:"
    echo "  --skip-staging  Skip staging step (use when files are already staged)"
    echo ""
    echo "Parameters:"
    echo "  title        - Commit title (present-tense verb, 50 chars max)"
    echo "  description  - Why this change was needed, with motivation and rationale (can be empty)"
    echo "  changes      - User-visible changes (or 'None')"
    echo "  test-plan    - Verification done or needed (or 'None')"
    echo "  release-prep - Ship and support requirements (or 'None')"
    echo "  files...     - Optional: specific files to stage (ignored with --skip-staging)"
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

# Build commit message
COMMIT_BODY=""
if [ -n "$DESCRIPTION" ]; then
    COMMIT_BODY="Description: ${DESCRIPTION}

"
fi
COMMIT_BODY="${COMMIT_BODY}Changes: ${CHANGES}

Test Planning: ${TEST_PLAN}

Release Preparation: ${RELEASE_PREP}

Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit
echo "==> Committing..."
git commit -m "${TITLE}

${COMMIT_BODY}"

COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "Done! Commit: ${COMMIT_HASH}"
