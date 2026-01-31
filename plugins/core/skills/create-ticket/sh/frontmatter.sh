#!/bin/bash
# Generate valid ticket frontmatter
# Usage: frontmatter.sh <type> <layer>
# Example: frontmatter.sh enhancement "Config"
# Example: frontmatter.sh bugfix "UX, Domain"

TYPE="${1:-enhancement}"
LAYER="${2:-Config}"

# Validate type
case "$TYPE" in
  enhancement|bugfix|refactoring|housekeeping) ;;
  *)
    echo "Error: type must be: enhancement, bugfix, refactoring, housekeeping" >&2
    exit 1
    ;;
esac

# Generate frontmatter with actual values
cat << EOF
---
created_at: $(date -Iseconds)
author: $(git config user.email)
type: $TYPE
layer: [$LAYER]
effort:
commit_hash:
category:
---
EOF
