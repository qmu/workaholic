#!/bin/bash
# Validates ticket file format and location after Write/Edit operations
# Exit codes: 0 = success/not a ticket, 2 = validation failed (blocks operation)

set -e

# Print reference to authoritative skill documentation
print_skill_reference() {
  echo "See: plugins/core/skills/create-ticket/SKILL.md" >&2
}

# Read JSON from stdin
input=$(cat)

# Extract file path from tool input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Exit early if no file path or not a ticket file
if [[ -z "$file_path" ]]; then
  exit 0
fi

# Check if file is in .workaholic/tickets/ directory
if [[ ! "$file_path" =~ \.workaholic/tickets/ ]]; then
  exit 0
fi

# Extract the path after .workaholic/tickets/
tickets_path="${file_path#*.workaholic/tickets/}"

# Validate location: must be in todo/, icebox/, or archive/<branch>/
if [[ "$tickets_path" =~ ^todo/ ]]; then
  : # Valid
elif [[ "$tickets_path" =~ ^icebox/ ]]; then
  : # Valid
elif [[ "$tickets_path" =~ ^archive/[^/]+/ ]]; then
  : # Valid (archive/<branch>/)
else
  echo "Error: Ticket must be in todo/, icebox/, or archive/<branch>/ directory" >&2
  echo "Got: $tickets_path" >&2
  print_skill_reference
  exit 2
fi

# Extract filename
filename=$(basename "$file_path")

# Validate filename format: YYYYMMDDHHmmss-*.md
if [[ ! "$filename" =~ ^[0-9]{14}-.*\.md$ ]]; then
  echo "Error: Ticket filename must match YYYYMMDDHHmmss-*.md pattern" >&2
  echo "Got: $filename" >&2
  print_skill_reference
  exit 2
fi

# Check if file exists (it should after Write/Edit)
if [[ ! -f "$file_path" ]]; then
  exit 0
fi

# Read file content
content=$(cat "$file_path")

# Check for frontmatter
if [[ ! "$content" =~ ^---[[:space:]] ]]; then
  echo "Error: Ticket must start with YAML frontmatter (---)" >&2
  print_skill_reference
  exit 2
fi

# Extract frontmatter (between first two ---)
# Use awk for portability (macOS head doesn't support -n -1)
frontmatter=$(echo "$content" | awk '/^---$/{if(++c==2)exit}c==1')

# Validate required fields
validate_field() {
  local field="$1"
  local value
  value=$(echo "$frontmatter" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//" | sed 's/[[:space:]]*$//')
  echo "$value"
}

# created_at: ISO 8601 format (YYYY-MM-DDTHH:MM:SS+TZ or YYYY-MM-DDTHH:MM:SS-TZ)
created_at=$(validate_field "created_at")
if [[ -z "$created_at" ]]; then
  echo "Error: created_at field is required" >&2
  print_skill_reference
  exit 2
fi
if [[ ! "$created_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{2}:[0-9]{2}$ ]]; then
  echo "Error: created_at must be ISO 8601 format (e.g., 2026-01-29T04:19:24+09:00)" >&2
  echo "Got: $created_at" >&2
  print_skill_reference
  exit 2
fi

# author: email format
author=$(validate_field "author")
if [[ -z "$author" ]]; then
  echo "Error: author field is required" >&2
  print_skill_reference
  exit 2
fi
if [[ ! "$author" =~ ^[^@]+@[^@]+\.[^@]+$ ]]; then
  echo "Error: author must be an email address" >&2
  echo "Got: $author" >&2
  print_skill_reference
  exit 2
fi
# Reject anthropic.com emails - Claude must use actual user's git email
if [[ "$author" =~ @anthropic\.com$ ]]; then
  echo "Error: author must be your actual email from 'git config user.email'" >&2
  echo "Rejected: $author (run 'git config user.email' and use that value)" >&2
  print_skill_reference
  exit 2
fi

# type: one of enhancement, bugfix, refactoring, housekeeping
type=$(validate_field "type")
if [[ -z "$type" ]]; then
  echo "Error: type field is required" >&2
  print_skill_reference
  exit 2
fi
if [[ ! "$type" =~ ^(enhancement|bugfix|refactoring|housekeeping)$ ]]; then
  echo "Error: type must be one of: enhancement, bugfix, refactoring, housekeeping" >&2
  echo "Got: $type" >&2
  print_skill_reference
  exit 2
fi

# layer: YAML array with valid values
layer_line=$(echo "$frontmatter" | grep "^layer:")
if [[ -z "$layer_line" ]]; then
  echo "Error: layer field is required" >&2
  print_skill_reference
  exit 2
fi
# Extract array values (handles [UX, Domain] format)
layer_values=$(echo "$layer_line" | sed 's/^layer:[[:space:]]*//' | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
if [[ -z "$layer_values" ]]; then
  echo "Error: layer must contain at least one value" >&2
  print_skill_reference
  exit 2
fi
while IFS= read -r layer; do
  if [[ -n "$layer" ]] && [[ ! "$layer" =~ ^(UX|Domain|Infrastructure|DB|Config)$ ]]; then
    echo "Error: layer values must be one of: UX, Domain, Infrastructure, DB, Config" >&2
    echo "Got: $layer" >&2
    print_skill_reference
    exit 2
  fi
done <<< "$layer_values"

# effort: empty or valid format (0.1h, 0.25h, 0.5h, 1h, 2h, 4h)
effort=$(validate_field "effort")
if [[ -n "$effort" ]]; then
  if [[ ! "$effort" =~ ^(0\.1h|0\.25h|0\.5h|1h|2h|4h)$ ]]; then
    echo "Error: effort must be one of: 0.1h, 0.25h, 0.5h, 1h, 2h, 4h (or empty)" >&2
    echo "Got: $effort" >&2
    print_skill_reference
    exit 2
  fi
fi

# commit_hash: empty or short git hash format (7-40 hex chars)
commit_hash=$(validate_field "commit_hash")
if [[ -n "$commit_hash" ]]; then
  if [[ ! "$commit_hash" =~ ^[0-9a-f]{7,40}$ ]]; then
    echo "Error: commit_hash must be a valid short git hash (7-40 hex characters)" >&2
    echo "Got: $commit_hash" >&2
    print_skill_reference
    exit 2
  fi
fi

# category: empty or one of Added, Changed, Removed
category=$(validate_field "category")
if [[ -n "$category" ]]; then
  if [[ ! "$category" =~ ^(Added|Changed|Removed)$ ]]; then
    echo "Error: category must be one of: Added, Changed, Removed (or empty)" >&2
    echo "Got: $category" >&2
    print_skill_reference
    exit 2
  fi
fi

# All validations passed
exit 0
