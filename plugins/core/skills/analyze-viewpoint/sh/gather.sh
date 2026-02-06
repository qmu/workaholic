#!/bin/sh -eu
# Gather context for viewpoint-based architecture analysis
# Usage: gather.sh <viewpoint-slug> [base-branch]
# Output: Structured sections for the given viewpoint

set -eu

VIEWPOINT="${1:?Usage: gather.sh <viewpoint-slug> [base-branch]}"
BASE_BRANCH="${2:-main}"

# Get current branch
BRANCH=$(git branch --show-current)
echo "=== BRANCH ==="
echo "$BRANCH"
echo ""

# Get current commit hash
echo "=== COMMIT ==="
git rev-parse --short HEAD
echo ""

# List archived tickets
ARCHIVE_DIR=".workaholic/tickets/archive/${BRANCH}"
echo "=== TICKETS ==="
if [ -d "$ARCHIVE_DIR" ]; then
    ls -1 "$ARCHIVE_DIR"/*.md 2>/dev/null || echo "No archived tickets"
else
    echo "No archived tickets"
fi
echo ""

# Get diff against base
echo "=== DIFF ==="
git diff "${BASE_BRANCH}...HEAD" --stat 2>/dev/null || echo "No diff available"
echo ""

# List existing specs
echo "=== SPECS ==="
find .workaholic/specs -name "*.md" -type f 2>/dev/null | sort || echo "No specs found"
echo ""

# Viewpoint-specific context gathering
echo "=== VIEWPOINT ==="
echo "$VIEWPOINT"
echo ""

echo "=== STRUCTURE ==="
case "$VIEWPOINT" in
    stakeholder)
        echo "--- Commands (user entry points) ---"
        ls -1 plugins/core/commands/*.md 2>/dev/null || echo "  (none)"
        echo ""
        echo "--- README files ---"
        find . -name "README.md" -maxdepth 3 -not -path "./.git/*" 2>/dev/null | sort || echo "  (none)"
        ;;
    model)
        echo "--- Frontmatter schemas (tickets) ---"
        find .workaholic/tickets -name "*.md" -type f 2>/dev/null | head -3 | while read -r f; do
            echo "  $f"
        done
        echo ""
        echo "--- Frontmatter schemas (specs) ---"
        find .workaholic/specs -name "*.md" -not -name "README*" -type f 2>/dev/null | head -3 | while read -r f; do
            echo "  $f"
        done
        echo ""
        echo "--- Frontmatter schemas (terms) ---"
        find .workaholic/terms -name "*.md" -not -name "README*" -type f 2>/dev/null | head -3 | while read -r f; do
            echo "  $f"
        done
        ;;
    usecase)
        echo "--- Commands ---"
        ls -1 plugins/core/commands/*.md 2>/dev/null || echo "  (none)"
        echo ""
        echo "--- Skills ---"
        ls -1d plugins/core/skills/*/ 2>/dev/null | while read -r d; do
            basename "$d"
        done
        ;;
    infrastructure)
        echo "--- Root files ---"
        ls -1 *.md *.json .claude-plugin/*.json 2>/dev/null || echo "  (none)"
        echo ""
        echo "--- Plugin config ---"
        find plugins -name "*.json" -type f 2>/dev/null | sort || echo "  (none)"
        echo ""
        echo "--- Directory tree (depth 2) ---"
        find . -maxdepth 2 -type d -not -path "./.git*" 2>/dev/null | sort
        ;;
    application)
        echo "--- Agents ---"
        ls -1 plugins/core/agents/*.md 2>/dev/null || echo "  (none)"
        echo ""
        echo "--- Commands ---"
        ls -1 plugins/core/commands/*.md 2>/dev/null || echo "  (none)"
        ;;
    component)
        echo "--- Agents ---"
        ls -1 plugins/core/agents/*.md 2>/dev/null || echo "  (none)"
        echo ""
        echo "--- Commands ---"
        ls -1 plugins/core/commands/*.md 2>/dev/null || echo "  (none)"
        echo ""
        echo "--- Rules ---"
        ls -1 plugins/core/rules/*.md 2>/dev/null || echo "  (none)"
        echo ""
        echo "--- Skills ---"
        for skill_dir in plugins/core/skills/*/; do
            skill_name=$(basename "$skill_dir")
            echo "  ${skill_name}/"
            if [ -d "${skill_dir}sh" ]; then
                ls -1 "${skill_dir}sh/"*.sh 2>/dev/null | while read -r f; do
                    echo "    $(basename "$f")"
                done
            fi
        done
        ;;
    data)
        echo "--- Ticket examples ---"
        find .workaholic/tickets -name "*.md" -type f 2>/dev/null | head -5 || echo "  (none)"
        echo ""
        echo "--- Spec files ---"
        find .workaholic/specs -name "*.md" -type f 2>/dev/null | sort || echo "  (none)"
        echo ""
        echo "--- Term files ---"
        find .workaholic/terms -name "*.md" -type f 2>/dev/null | sort || echo "  (none)"
        echo ""
        echo "--- JSON configs ---"
        find . -name "*.json" -not -path "./.git/*" -not -path "./node_modules/*" -type f 2>/dev/null | sort || echo "  (none)"
        ;;
    feature)
        echo "--- Commands ---"
        ls -1 plugins/core/commands/*.md 2>/dev/null || echo "  (none)"
        echo ""
        echo "--- Skills ---"
        ls -1d plugins/core/skills/*/ 2>/dev/null | while read -r d; do
            basename "$d"
        done
        echo ""
        echo "--- Agents ---"
        ls -1 plugins/core/agents/*.md 2>/dev/null || echo "  (none)"
        ;;
    *)
        echo "Unknown viewpoint: $VIEWPOINT"
        echo "Gathering generic structure..."
        echo "--- All plugin files ---"
        find plugins/core -name "*.md" -type f 2>/dev/null | sort || echo "  (none)"
        ;;
esac
