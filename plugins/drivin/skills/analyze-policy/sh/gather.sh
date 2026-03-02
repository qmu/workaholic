#!/bin/sh -eu
# Gather context for policy-based repository analysis
# Usage: gather.sh <policy-slug> [base-branch]
# Output: Structured sections for the given policy domain

set -eu

POLICY="${1:?Usage: gather.sh <policy-slug> [base-branch]}"
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

# List existing policy files
echo "=== POLICIES ==="
find .workaholic/policies -name "*.md" -type f 2>/dev/null | sort || echo "No policies found"
echo ""

# Get diff against base
echo "=== DIFF ==="
git diff "${BASE_BRANCH}...HEAD" --stat 2>/dev/null || echo "No diff available"
echo ""

# Policy-domain-specific context gathering
echo "=== POLICY ==="
echo "$POLICY"
echo ""

echo "=== STRUCTURE ==="
case "$POLICY" in
    test)
        echo "--- Test files ---"
        find . -type f \( -name "*test*" -o -name "*spec*" -o -name "*.test.*" -o -name "*.spec.*" \) \
            -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | sort | head -30 || echo "  (none)"
        echo ""
        echo "--- Test configs ---"
        find . -maxdepth 2 -type f \( -name "jest.config*" -o -name "vitest.config*" -o -name ".mocharc*" -o -name "pytest.ini" -o -name "phpunit.xml" \) \
            -not -path "./.git/*" 2>/dev/null | sort || echo "  (none)"
        ;;
    security)
        echo "--- Auth-related files ---"
        find . -type f \( -name "*auth*" -o -name "*security*" -o -name "*permission*" -o -name "*credential*" \) \
            -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | sort | head -20 || echo "  (none)"
        echo ""
        echo "--- Secret/env files ---"
        find . -maxdepth 2 -type f \( -name ".env*" -o -name "*.pem" -o -name "*.key" -o -name ".gitignore" \) \
            -not -path "./.git/*" 2>/dev/null | sort || echo "  (none)"
        ;;
    quality)
        echo "--- Lint configs ---"
        find . -maxdepth 2 -type f \( -name ".eslintrc*" -o -name ".prettierrc*" -o -name "biome.json" -o -name ".stylelintrc*" -o -name "ruff.toml" -o -name ".flake8" \) \
            -not -path "./.git/*" 2>/dev/null | sort || echo "  (none)"
        echo ""
        echo "--- Code quality configs ---"
        find . -maxdepth 2 -type f \( -name "tsconfig*" -o -name ".editorconfig" -o -name "sonar-project.properties" \) \
            -not -path "./.git/*" 2>/dev/null | sort || echo "  (none)"
        ;;
    accessibility)
        echo "--- i18n files ---"
        find . -type f \( -name "*i18n*" -o -name "*locale*" -o -name "*translation*" -o -name "*_ja*" -o -name "*.ja.*" \) \
            -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | sort | head -20 || echo "  (none)"
        echo ""
        echo "--- Accessibility configs ---"
        find . -maxdepth 2 -type f \( -name ".axe*" -o -name "*.a11y*" \) \
            -not -path "./.git/*" 2>/dev/null | sort || echo "  (none)"
        ;;
    observability)
        echo "--- Logging/monitoring files ---"
        find . -type f \( -name "*log*" -o -name "*metric*" -o -name "*trace*" -o -name "*monitor*" \) \
            -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | sort | head -20 || echo "  (none)"
        echo ""
        echo "--- Observability configs ---"
        find . -maxdepth 2 -type f \( -name "datadog*" -o -name "newrelic*" -o -name "sentry*" -o -name "prometheus*" \) \
            -not -path "./.git/*" 2>/dev/null | sort || echo "  (none)"
        ;;
    delivery)
        echo "--- CI/CD configs ---"
        find . -maxdepth 3 -type f \( -name "*.yml" -o -name "*.yaml" \) \
            -path "*/.github/*" 2>/dev/null | sort || echo "  (none)"
        echo ""
        echo "--- Build/deploy configs ---"
        find . -maxdepth 2 -type f \( -name "Dockerfile*" -o -name "docker-compose*" -o -name "Makefile" -o -name "Procfile" -o -name "netlify.toml" -o -name "vercel.json" \) \
            -not -path "./.git/*" 2>/dev/null | sort || echo "  (none)"
        echo ""
        echo "--- Package managers ---"
        find . -maxdepth 2 -type f \( -name "package.json" -o -name "Cargo.toml" -o -name "go.mod" -o -name "pyproject.toml" -o -name "Gemfile" \) \
            -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | sort || echo "  (none)"
        ;;
    recovery)
        echo "--- Backup/recovery files ---"
        find . -type f \( -name "*backup*" -o -name "*restore*" -o -name "*disaster*" -o -name "*recovery*" \) \
            -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | sort | head -20 || echo "  (none)"
        echo ""
        echo "--- Database configs ---"
        find . -maxdepth 2 -type f \( -name "*migration*" -o -name "*seed*" -o -name "*.sql" \) \
            -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | sort | head -20 || echo "  (none)"
        ;;
    *)
        echo "Unknown policy: $POLICY"
        echo "Gathering generic structure..."
        find . -maxdepth 2 -type f -name "*.md" -not -path "./.git/*" 2>/dev/null | sort | head -30 || echo "  (none)"
        ;;
esac
