---
created_at: 2026-02-10T15:49:17+08:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Expand commit message sections for lead agent consumption

## Overview

The current commit message format in `plugins/core/skills/commit/SKILL.md` (and its dependency `format-commit-message`) has four sections: Title, Motivation, UX Change, and Arch Change. These are insufficient for downstream lead agents (test-lead, delivery-lead, security-lead, etc.) who need to judge what is required to ship each change. The commit message should be restructured into five well-scoped sections that give each lead enough signal to act on without requiring them to read the full diff: Title, Description (with motivation and rationale), Changes (from user viewpoint), Test Planning, and Release Preparation and Following Support.

## Key Files

- `plugins/core/skills/commit/SKILL.md` - Primary target. Defines the commit workflow, parameters, and message format.
- `plugins/core/skills/commit/sh/commit.sh` - Shell script that builds the commit message from positional arguments. Must accept the new parameter set.
- `plugins/core/skills/format-commit-message/SKILL.md` - Canonical message format template. Must be updated to reflect the new five-section structure.
- `plugins/core/skills/archive-ticket/SKILL.md` - Documents archive commit usage and example; references format-commit-message.
- `plugins/core/skills/archive-ticket/sh/archive.sh` - Calls commit.sh with positional arguments; must match new signature.
- `plugins/core/skills/drive-workflow/SKILL.md` - References format-commit-message; agents derive commit content from here.
- `plugins/core/skills/drive-approval/SKILL.md` - Abandonment commits use the commit skill.

## Related History

The commit message format has evolved through several iterations: first adding structured sections (Motivation, UX Change, Arch Change), then extracting the commit skill as a standalone component integrating format-commit-message with Git Safety.

Past tickets that touched similar areas:

- [20260131145539-structured-commit-messages.md](.workaholic/tickets/archive/feat-20260131-125844/20260131145539-structured-commit-messages.md) - Introduced the structured commit format with Motivation, UX Change, and Arch Change sections (same layer: Config)
- [20260204180858-create-commit-skill.md](.workaholic/tickets/archive/drive-20260204-160722/20260204180858-create-commit-skill.md) - Extracted the commit skill as a standalone component integrating format-commit-message with multi-contributor awareness (same files)

## Implementation Steps

1. **Update `plugins/core/skills/format-commit-message/SKILL.md`** to define the new five-section format:
   - Title (unchanged: present-tense verb, 50 chars max)
   - Description: why this change was needed, including motivation and rationale. Two to three sentences, not a paragraph.
   - Changes: what users will experience differently. Concrete observable differences, or "None" for internal-only changes.
   - Test Planning: what verification was done or should be done. Mention manual checks, automated tests, or edge cases considered.
   - Release Preparation: what is needed to ship this change and support it afterward. Migration steps, configuration changes, documentation updates, monitoring, or "None" if straightforward.

2. **Update `plugins/core/skills/commit/SKILL.md`** to reflect the new parameters:
   - Replace `motivation`, `ux-change`, `arch-change` with `description`, `changes`, `test-plan`, `release-prep`
   - Update the usage section, parameter documentation, and all examples
   - Keep the Multi-Contributor Awareness section and Pre-Commit Checks unchanged

3. **Update `plugins/core/skills/commit/sh/commit.sh`** to accept the new parameter set:
   - Change positional arguments from `<title> <motivation> <ux-change> <arch-change>` to `<title> <description> <changes> <test-plan> <release-prep>`
   - Update the message body construction to produce the new labeled sections
   - Update the usage help text

4. **Update `plugins/core/skills/archive-ticket/SKILL.md`** and its example to use the new parameter names and format

5. **Update `plugins/core/skills/archive-ticket/sh/archive.sh`** to pass the new five parameters to commit.sh (positional arguments 4-7 change)

6. **Update `plugins/core/skills/drive-approval/SKILL.md`** if it references the old parameter names for abandonment commits

## Patches

### `plugins/core/skills/format-commit-message/SKILL.md`

```diff
--- a/plugins/core/skills/format-commit-message/SKILL.md
+++ b/plugins/core/skills/format-commit-message/SKILL.md
@@ -11,11 +11,15 @@
 ```
 <title>

-Motivation: <why this change was needed>
+Description: <why this change was needed, including motivation and rationale>

-UX Change: <what changed for the user>
+Changes: <what users will experience differently>

-Arch Change: <what changed for the developer>
+Test Planning: <what verification was done or should be done>
+
+Release Preparation: <what is needed to ship and support afterward>

 Co-Authored-By: Claude <noreply@anthropic.com>
 ```
@@ -25,20 +29,27 @@
 Examples:
 - Add session-based authentication
 - Fix Mermaid slash character in labels
 - Remove unused RegisterTool type

-## Motivation
+## Description

-Why this change was needed. More than a sentence, but not a paragraph. Extract from ticket Overview.
+Why this change was needed, including the motivation and rationale. Two to three sentences that give a lead agent enough context to understand the intent without reading the diff. Extract from ticket Overview.

-## UX Change
+## Changes

-What users will experience differently:
+What users will experience differently after this change:
 - New commands, options, or behaviors
 - Changes to output format or error messages
 - Write "None" if internal only

-## Arch Change
+## Test Planning
+
+What verification was done or should be done:
+- Manual checks performed and their results
+- Automated tests added, modified, or run
+- Edge cases considered or deferred
+- Write "None" if no special verification needed

-What developers need to know:
-- New files, components, or abstractions
-- Modified interfaces or data structures
-- Changes to workflow or component relationships
-- Write "None" if no structural changes
+## Release Preparation
+
+What is needed to ship this change and support it afterward:
+- Migration steps or data changes required
+- Configuration or environment changes
+- Documentation updates needed
+- Monitoring or alerting to add
+- Write "None" if the change is straightforward to ship
```

> **Note**: This patch is speculative - verify line numbers before applying.

### `plugins/core/skills/commit/sh/commit.sh`

```diff
--- a/plugins/core/skills/commit/sh/commit.sh
+++ b/plugins/core/skills/commit/sh/commit.sh
@@ -18,9 +18,10 @@

 TITLE="${1:-}"
-MOTIVATION="${2:-}"
-UX_CHANGE="${3:-None}"
-ARCH_CHANGE="${4:-None}"
-shift 4 2>/dev/null || true
+DESCRIPTION="${2:-}"
+CHANGES="${3:-None}"
+TEST_PLAN="${4:-None}"
+RELEASE_PREP="${5:-None}"
+shift 5 2>/dev/null || true

 if [ -z "$TITLE" ]; then
-    echo "Usage: commit.sh [--skip-staging] <title> <motivation> <ux-change> <arch-change> [files...]"
+    echo "Usage: commit.sh [--skip-staging] <title> <description> <changes> <test-plan> <release-prep> [files...]"
     echo ""
@@ -30,8 +31,9 @@
     echo "Parameters:"
     echo "  title      - Commit title (present-tense verb, 50 chars max)"
-    echo "  motivation - Why this change was needed (can be empty)"
-    echo "  ux-change  - User-visible changes (or 'None')"
-    echo "  arch-change - Architecture changes (or 'None')"
-    echo "  files...   - Optional: specific files to stage (ignored with --skip-staging)"
+    echo "  description - Why this change was needed, with motivation and rationale (can be empty)"
+    echo "  changes     - User-visible changes (or 'None')"
+    echo "  test-plan   - Verification done or needed (or 'None')"
+    echo "  release-prep - Ship and support requirements (or 'None')"
+    echo "  files...    - Optional: specific files to stage (ignored with --skip-staging)"
     exit 1
 fi
@@ -81,13 +83,17 @@
 # Build commit message
 COMMIT_BODY=""
-if [ -n "$MOTIVATION" ]; then
-    COMMIT_BODY="Motivation: ${MOTIVATION}
+if [ -n "$DESCRIPTION" ]; then
+    COMMIT_BODY="Description: ${DESCRIPTION}

 "
 fi
-COMMIT_BODY="${COMMIT_BODY}UX Change: ${UX_CHANGE}
+COMMIT_BODY="${COMMIT_BODY}Changes: ${CHANGES}
+
+Test Planning: ${TEST_PLAN}

-Arch Change: ${ARCH_CHANGE}
+Release Preparation: ${RELEASE_PREP}

 Co-Authored-By: Claude <noreply@anthropic.com>"
```

> **Note**: This patch is speculative - verify line numbers before applying.

## Considerations

- Each section should be concise and well-written but not a large paragraph. Two to three sentences per section is the target. (`plugins/core/skills/format-commit-message/SKILL.md`)
- The "Arch Change" section is being removed, not renamed. Architecture-relevant information should be captured in Description (rationale) and Release Preparation (what developers need to do to ship). Leads that need architecture details will read the diff. (`plugins/core/skills/format-commit-message/SKILL.md`)
- The `archive-ticket/sh/archive.sh` script currently passes 6 positional arguments to commit.sh; it will need to pass 7. Ensure the `shift` count and parameter mapping are updated together. (`plugins/core/skills/archive-ticket/sh/archive.sh` lines 9-12, 56)
- All existing examples in SKILL.md files (commit, archive-ticket, drive-approval) must be updated to show the new five-section format to avoid confusion during `/drive`. (`plugins/core/skills/commit/SKILL.md` lines 69-100)
- Lead agents currently receive commit messages via `git log` during `/scan` and `/report`. The new section labels (Description, Changes, Test Planning, Release Preparation) must be parseable by agents reading commit history. No structural change is needed in the leads themselves -- they consume free-text commit messages. (`plugins/core/agents/*-lead.md`)
