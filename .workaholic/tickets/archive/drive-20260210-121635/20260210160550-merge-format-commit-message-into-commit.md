---
created_at: 2026-02-10T16:05:49+08:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: b26ca39
category: Changed
---

# Merge format-commit-message skill into commit skill

## Overview

The `format-commit-message` skill exists as a separate directory (`plugins/core/skills/format-commit-message/SKILL.md`) but its content is already fully duplicated inside the `commit` skill. The commit skill preloads format-commit-message, reproduces the entire message template in its "Message Format" section, and provides richer per-section guidance through its parameter documentation. The separation creates maintenance burden -- any format change must be updated in both places -- with no benefit, since format-commit-message is never preloaded independently of the commit skill. Merge the content into the commit skill and remove the separate directory.

## Key Files

- `plugins/core/skills/format-commit-message/SKILL.md` - Source skill to be merged and then deleted. Contains the canonical message format template and per-section writing guidelines.
- `plugins/core/skills/commit/SKILL.md` - Target skill. Already contains the message template and references format-commit-message three times (frontmatter `skills:`, parameter docs, "Message Format" section).
- `plugins/core/skills/commit/sh/commit.sh` - Shell script that builds commit messages. No changes needed (it does not reference format-commit-message).
- `plugins/core/skills/drive-workflow/SKILL.md` - Preloads format-commit-message in its frontmatter `skills:` list. Must be updated to remove the dependency.
- `plugins/core/skills/archive-ticket/SKILL.md` - References format-commit-message in prose ("Follow the preloaded format-commit-message skill for message format"). Must be updated to reference the commit skill instead.
- `.workaholic/specs/component.md` - Lists format-commit-message in the skills inventory and Mermaid diagram.
- `.workaholic/specs/component_ja.md` - Japanese translation of the above.
- `.workaholic/policies/delivery.md` - References format-commit-message in step 5 of the archive workflow.
- `.workaholic/policies/delivery_ja.md` - Japanese translation of the above.

## Related History

This follows an established pattern of merging granular utility skills into their primary consumer skills. Multiple prior tickets performed identical consolidations (gather-spec-context into write-spec, gather-terms-context into write-terms, enforce-i18n into translate, generate-changelog into write-changelog), each time simplifying preload lists and eliminating dual-maintenance burden.

Past tickets that touched similar areas:

- [20260128002306-integrate-gather-spec-context-into-write-spec.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002306-integrate-gather-spec-context-into-write-spec.md) - Same pattern: merged a context-gathering skill into its primary consumer skill (same layer: Config)
- [20260128002211-integrate-gather-terms-context-into-write-terms.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002211-integrate-gather-terms-context-into-write-terms.md) - Same pattern: merged gather-terms-context into write-terms (same layer: Config)
- [20260128002918-merge-enforce-i18n-into-translate.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002918-merge-enforce-i18n-into-translate.md) - Same pattern: merged enforce-i18n into translate (same layer: Config)
- [20260204180858-create-commit-skill.md](.workaholic/tickets/archive/drive-20260204-160722/20260204180858-create-commit-skill.md) - Created the commit skill integrating format-commit-message with Git Safety (same files)
- [20260210154917-expand-commit-message-sections.md](.workaholic/tickets/todo/20260210154917-expand-commit-message-sections.md) - Recently expanded commit message sections from 4 to 5; updated both format-commit-message and commit skills in parallel (same files)

## Implementation Steps

1. **Inline format-commit-message content into `plugins/core/skills/commit/SKILL.md`**:
   - Remove `format-commit-message` from the `skills:` list in frontmatter
   - Replace the "Message Format" section (which currently just says "Follow the preloaded format-commit-message skill" and reproduces the template) with the full per-section writing guidelines from format-commit-message (the Title, Description, Changes, Test Planning, and Release Preparation sections with their detailed guidance paragraphs)
   - Remove the two prose references to "format-commit-message skill" in the Parameters and Message Format sections, replacing with inline descriptions

2. **Update `plugins/core/skills/drive-workflow/SKILL.md`**:
   - Remove `format-commit-message` from the `skills:` list in frontmatter
   - Drive-workflow does not directly reference format-commit-message in its prose, so no other changes needed

3. **Update `plugins/core/skills/archive-ticket/SKILL.md`**:
   - Change "Follow the preloaded **format-commit-message** skill for message format." to "Follow the preloaded **commit** skill for message format." (archive-ticket already preloads commit)

4. **Update `.workaholic/specs/component.md`**:
   - Remove `format-commit-message` from the skills bullet list
   - Remove the `FCM[format-commit-message]` node and its edges from the Mermaid diagram
   - Add a note that commit message formatting is part of the commit skill

5. **Update `.workaholic/specs/component_ja.md`**:
   - Mirror the same changes from step 4 in the Japanese translation

6. **Update `.workaholic/policies/delivery.md`**:
   - Change the reference from "format-commit-message skill" to "commit skill" in step 5

7. **Update `.workaholic/policies/delivery_ja.md`**:
   - Mirror the same change from step 6 in the Japanese translation

8. **Delete `plugins/core/skills/format-commit-message/` directory entirely**

## Patches

### `plugins/core/skills/commit/SKILL.md`

```diff
--- a/plugins/core/skills/commit/SKILL.md
+++ b/plugins/core/skills/commit/SKILL.md
@@ -1,8 +1,7 @@
 ---
 name: commit
 description: Safe commit workflow with multi-contributor awareness and structured message format.
-skills:
-  - format-commit-message
 user-invocable: false
 ---
```

> **Note**: This patch is speculative - the full inline of format-commit-message content into the Message Format section requires manual composition since it involves both removing references and adding the detailed per-section guidelines.

### `plugins/core/skills/drive-workflow/SKILL.md`

```diff
--- a/plugins/core/skills/drive-workflow/SKILL.md
+++ b/plugins/core/skills/drive-workflow/SKILL.md
@@ -2,8 +2,6 @@
 name: drive-workflow
 description: Implementation workflow for processing tickets.
-skills:
-  - format-commit-message
 user-invocable: false
 ---
```

### `plugins/core/skills/archive-ticket/SKILL.md`

```diff
--- a/plugins/core/skills/archive-ticket/SKILL.md
+++ b/plugins/core/skills/archive-ticket/SKILL.md
@@ -28,7 +28,7 @@
   <ticket-path> "<title>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"
 ```

-Follow the preloaded **format-commit-message** skill for message format.
+Follow the preloaded **commit** skill for message format.

 ## Example
```

## Final Report

Merged format-commit-message skill into the commit skill and deleted the standalone directory. The commit skill now contains the full per-section writing guidelines (Title, Description, Changes, Test Planning, Release Preparation) with detailed 3-5 sentence guidance paragraphs, making it the single authoritative source for commit message formatting. Updated 8 files total: removed the skill from frontmatter in commit and drive-workflow, updated prose references in archive-ticket and delivery policies, updated skill counts and Mermaid diagrams in component specs (both English and Japanese), and deleted the format-commit-message directory. Historical references in .workaholic/terms, stories, and archived tickets were intentionally left unchanged as they are historical records.

## Considerations

- The commit skill's "Message Format" section currently duplicates the format template from format-commit-message but defers detailed per-section guidance with "See format-commit-message skill". After merging, the detailed guidance (Title rules, Description paragraph, Changes paragraph, Test Planning paragraph, Release Preparation paragraph) should be inlined directly into the commit skill, making it the single authoritative source for commit message formatting. (`plugins/core/skills/commit/SKILL.md` lines 56-72)
- The `.workaholic/specs/component.md` Mermaid diagram has a `FCM[format-commit-message]` node with edges connecting it to other skills. These edges must be removed along with the node; the commit skill's existing node in the diagram already represents the commit workflow. (`plugins/core/skills/format-commit-message/SKILL.md`, `.workaholic/specs/component.md`)
- Several `.workaholic/` documentation files (terms, stories, policies) reference format-commit-message by name. Terms and stories are historical records and should not be modified. Only the policies (`delivery.md`, `delivery_ja.md`) should be updated since they describe current workflow. (`.workaholic/terms/workflow-terms.md`, `.workaholic/stories/feat-20260131-125844.md`)
- The existing todo ticket `20260210154917-expand-commit-message-sections.md` has already been implemented (it has a Final Report and effort value) but may not yet be archived. It references format-commit-message extensively. This merge ticket supersedes the need for format-commit-message as a separate entity. (`.workaholic/tickets/todo/20260210154917-expand-commit-message-sections.md`)
