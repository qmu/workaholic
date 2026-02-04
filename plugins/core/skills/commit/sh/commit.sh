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
MOTIVATION="${2:-}"
UX_CHANGE="${3:-None}"
ARCH_CHANGE="${4:-None}"
shift 4 2>/dev/null || true

if [ -z "$TITLE" ]; then
    echo "Usage: commit.sh [--skip-staging] <title> <motivation> <ux-change> <arch-change> [files...]"
    echo ""
    echo "Options:"
    echo "  --skip-staging  Skip staging step (use when files are already staged)"
    echo ""
    echo "Parameters:"
    echo "  title      - Commit title (present-tense verb, 50 chars max)"
    echo "  motivation - Why this change was needed (can be empty)"
    echo "  ux-change  - User-visible changes (or 'None')"
    echo "  arch-change - Architecture changes (or 'None')"
    echo "  files...   - Optional: specific files to stage (ignored with --skip-staging)"
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
if [ -n "$MOTIVATION" ]; then
    COMMIT_BODY="Motivation: ${MOTIVATION}

"
fi
COMMIT_BODY="${COMMIT_BODY}UX Change: ${UX_CHANGE}

Arch Change: ${ARCH_CHANGE}

Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit
echo "==> Committing..."
git commit -m "${TITLE}

${COMMIT_BODY}"

COMMIT_HASH=$(git rev-parse --short HEAD)
echo ""
echo "Done! Commit: ${COMMIT_HASH}"
