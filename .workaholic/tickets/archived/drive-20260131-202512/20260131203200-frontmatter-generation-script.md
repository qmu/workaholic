---
created_at: 2026-01-31T20:32:00+09:00
author: tamurayoshiya@gmail.com
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: 865201c
category: Changed
---

# Add Frontmatter Generation Script to Create-Ticket Skill

## Overview

Add a bundled shell script to the `create-ticket` skill that generates valid frontmatter in one step, eliminating the error-prone manual process of running commands and copying output.

## Motivation

**Current problem:**

The create-ticket skill instructs the LLM to:
1. Run `date -Iseconds` and `git config user.email`
2. Manually copy the output into frontmatter
3. Fill in `type` and `layer` fields

This multi-step process causes validation failures:
- LLM forgets to run the commands and uses placeholders like `$(date -Iseconds)`
- LLM uses example values like `user@example.com` instead of actual git email
- Two-step "run then copy" is error-prone

**Solution:**

Provide a single shell script that outputs a complete, valid frontmatter block. The LLM calls one script, gets valid YAML, and uses it directly.

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` - Update to use script instead of manual process
- `plugins/core/skills/create-ticket/sh/frontmatter.sh` - New script to generate frontmatter

## Related History

Past tickets related to frontmatter validation and skill extraction:

- [20260129041924-add-ticket-validation-hook.md](.workaholic/tickets/archive/feat-20260129-023941/20260129041924-add-ticket-validation-hook.md) - Added the validation hook that catches these errors
- [20260131162854-extract-update-ticket-frontmatter-skill.md](.workaholic/tickets/archive/feat-20260131-125844/20260131162854-extract-update-ticket-frontmatter-skill.md) - Extracted frontmatter update skill with bundled script

## Implementation

### 1. Create Frontmatter Generation Script

Create `plugins/core/skills/create-ticket/sh/frontmatter.sh`:

```bash
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
```

### 2. Update Create-Ticket Skill

Replace the current "Step 1: Capture Dynamic Values" section with:

```markdown
## Step 1: Generate Frontmatter

Run the bundled script with type and layer arguments:

\`\`\`bash
bash .claude/skills/create-ticket/sh/frontmatter.sh <type> "<layer>"
\`\`\`

**Arguments:**
- `type`: enhancement | bugfix | refactoring | housekeeping
- `layer`: Comma-separated layer values (e.g., "Config" or "UX, Domain")

**Example:**
\`\`\`bash
bash .claude/skills/create-ticket/sh/frontmatter.sh enhancement "Config"
\`\`\`

**Output:**
\`\`\`yaml
---
created_at: 2026-01-31T20:32:00+09:00
author: developer@company.com
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---
\`\`\`

Use this output directly as your ticket's frontmatter.
```

### 3. Remove Redundant Template Section

The "Frontmatter Template" section (lines 31-45) with placeholder `$(date -Iseconds)` comments becomes redundant. Remove it and keep only the "Concrete Example" section for reference.

## Verification

1. Run the script manually and verify valid output:
   ```bash
   bash plugins/core/skills/create-ticket/sh/frontmatter.sh bugfix "UX, Domain"
   ```

2. Create a test ticket using `/ticket test` and verify:
   - No validation errors from hook
   - `created_at` has actual timestamp (not placeholder)
   - `author` has actual git email (not example)

## Notes

- Script validates `type` argument to catch typos early
- Layer is passed as a string and wrapped in `[]` by the script
- The script pattern follows existing skills (write-changelog, update-ticket-frontmatter) that bundle bash scripts
