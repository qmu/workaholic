#!/bin/bash
# Update version based on version type argument

VERSION_TYPE="$1"

if [ -z "$VERSION_TYPE" ]; then
  echo "Usage: $0 <patch|minor|major>" >&2
  exit 1
fi

# Read current version
MARKETPLACE_JSON=".claude-plugin/marketplace.json"
CURRENT=$(grep -o '"version": "[^"]*"' "$MARKETPLACE_JSON" | head -1 | cut -d'"' -f4)

# Parse version components
MAJOR=$(echo "$CURRENT" | cut -d. -f1)
MINOR=$(echo "$CURRENT" | cut -d. -f2)
PATCH=$(echo "$CURRENT" | cut -d. -f3)

# Calculate new version
case "$VERSION_TYPE" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Invalid version type: $VERSION_TYPE" >&2
    exit 1
    ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}"

# Update all version occurrences in marketplace.json
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/g" "$MARKETPLACE_JSON"

# Update core plugin.json
CORE_PLUGIN="plugins/core/.claude-plugin/plugin.json"
if [ -f "$CORE_PLUGIN" ]; then
  sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" "$CORE_PLUGIN"
fi

echo "$CURRENT -> $NEW"
