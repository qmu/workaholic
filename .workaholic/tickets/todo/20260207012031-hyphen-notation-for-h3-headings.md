---
created_at: 2026-02-07T01:20:31+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Change H3 Heading Numbering from Dot to Hyphen Notation

## Overview

Change the h3 heading numbering convention from dot notation (`### 1.1. Subsection`) to hyphen notation (`### 1-1. Subsection`) across all markdown generation skills and the general rule. The h2 format (`## 1. Section`) remains unchanged. This affects the write-story skill templates, the general rule definition, and all other skills that define or reference numbered h3 headings.

## Key Files

- `plugins/core/rules/general.md` - Contains the numbered headings rule definition with `### 1.1. Subsection` example
- `plugins/core/skills/write-story/SKILL.md` - Story template with h3 patterns: `### 4.1.`, `### 4.2.`, `### 9.1.`, `### 9.2.`, `### 10.1.`, `### 10.2.`, `### 10.3.`
- `plugins/core/skills/write-story/SKILL.md` - Format specification line: `### 4.N. <Title>`
- `plugins/core/skills/create-pr/SKILL.md` - References `## 1. Summary` section with numbered headings
- `plugins/core/skills/create-ticket/SKILL.md` - Ticket template (currently uses unnumbered headings, may need numbered headings applied)

## Related History

The numbered headings convention was formalized as a rule after it was already in consistent practice across stories and skills. The original ticket added the rule to general.md with dot notation, and the write-story skill template established the `4.1.` pattern for Changes subsections.

Past tickets that touched similar areas:

- [20260128-numbered-headings-rule.md](.workaholic/tickets/archive/feat-20260128-012023/20260128-numbered-headings-rule.md) - Added numbered headings rule to general.md (same rule being modified)
- [20260127100459-add-topic-tree-to-story.md](.workaholic/tickets/archive/feat-20260126-214833/20260127100459-add-topic-tree-to-story.md) - Modified story structure headings (same file: write-story/SKILL.md)
- [20260127205429-add-overview-to-story-summary.md](.workaholic/tickets/archive/feat-20260126-214833/20260127205429-add-overview-to-story-summary.md) - Modified story summary heading format (same file: write-story/SKILL.md)

## Implementation Steps

1. **Update general rule** - Change the h3 example in `plugins/core/rules/general.md` from `### 1.1. Subsection` to `### 1-1. Subsection`

2. **Update write-story skill template** - Change all h3 heading patterns in `plugins/core/skills/write-story/SKILL.md`:
   - `### 4.1.` to `### 4-1.`
   - `### 4.2.` to `### 4-2.`
   - `### 4.N.` to `### 4-N.`
   - `### 9.1.` to `### 9-1.`
   - `### 9.2.` to `### 9-2.`
   - `### 10.1.` to `### 10-1.`
   - `### 10.2.` to `### 10-2.`
   - `### 10.3.` to `### 10-3.`
   - Update the format guideline line from `### 4.N. <Title>` to `### 4-N. <Title>`

3. **Update create-pr skill** - Change any h3 references in `plugins/core/skills/create-pr/SKILL.md` if they use dot notation

4. **Verify other skills** - Check `drive-approval`, `drive-workflow`, `analyze-performance`, and `write-overview` skills for h3 references that use dot notation and update them to hyphen notation

## Patches

### `plugins/core/rules/general.md`

```diff
--- a/plugins/core/rules/general.md
+++ b/plugins/core/rules/general.md
@@ -8,4 +8,4 @@
 - **Never commit without explicit user request** - Only create git commits when executing a command that has commit steps (`/drive`, `/report`)
 - **Never use `git -C`** - Run git commands from the working directory, not with `-C` flag
 - **Link markdown files when referenced** - When mentioning `.md` files in documentation, use markdown links: `[filename.md](path/to/file.md)` not just backticks. Especially important for stable docs (specs, terms, stories).
-- **Number headings in documentation** - Use numbered headings for h2 and h3 levels: `## 1. Section`, `### 1.1. Subsection`. For h4, number only when it helps identify topics. Applies to specs, terms, stories, and skills. Exceptions: READMEs and configuration docs.
+- **Number headings in documentation** - Use numbered headings for h2 and h3 levels: `## 1. Section`, `### 1-1. Subsection`. For h4, number only when it helps identify topics. Applies to specs, terms, stories, and skills. Exceptions: READMEs and configuration docs.
```

### `plugins/core/skills/write-story/SKILL.md`

> **Note**: This patch covers the key changes; the full file has additional occurrences of the same pattern.

```diff
--- a/plugins/core/skills/write-story/SKILL.md
+++ b/plugins/core/skills/write-story/SKILL.md
@@ -77,13 +77,13 @@

 One subsection per ticket, in chronological order:

-### 4.1. <Ticket title> ([hash](<repo-url>/commit/<hash>))
+### 4-1. <Ticket title> ([hash](<repo-url>/commit/<hash>))

 - First file changed with description of modification
 - Second file changed with description of modification
 - ...

-### 4.2. <Next ticket title> ([hash](<repo-url>/commit/<hash>))
+### 4-2. <Next ticket title> ([hash](<repo-url>/commit/<hash>))

 - First file changed with description of modification
 - Second file changed with description of modification
@@ -96,7 +96,7 @@
 - **CRITICAL**: Commit hash MUST be a clickable GitHub link, not plain text
   - Wrong: `(abc1234)` or `(<hash>)`
   - Correct: `([abc1234](<repo-url>/commit/abc1234))`
-- Format: `### 4.N. <Title> ([hash](<repo-url>/commit/<hash>))`
+- Format: `### 4-N. <Title> ([hash](<repo-url>/commit/<hash>))`
 - **MUST list all files changed** as bullet points, not paragraph prose
 - Reference ticket Implementation section or Changes section for the complete file list
 - Chronological order matches ticket creation time
@@ -132,7 +132,7 @@

 **Metrics**: <commits> commits over <duration> <unit> (<velocity> commits/<unit>)

-### 9.1. Pace Analysis
+### 9-1. Pace Analysis

 [Quantitative reflection on development pace - was velocity consistent or varied? Were commits small and focused or large? Any patterns in timing?]

-### 9.2. Decision Review
+### 9-2. Decision Review

@@ -160,11 +160,11 @@

-### 10.1. Concerns
+### 10-1. Concerns

-### 10.2. Pre-release Instructions
+### 10-2. Pre-release Instructions

-### 10.3. Post-release Instructions
+### 10-3. Post-release Instructions
```

## Considerations

- Existing story files in `.workaholic/stories/` already use dot notation (`4.1.`, `9.1.`, etc.) and will not be retroactively changed. Only newly generated files will use hyphen notation. This creates a format inconsistency between old and new stories (`plugins/core/skills/write-story/SKILL.md`)
- The `create-pr` skill references `## 1. Summary` which uses h2 numbering (unchanged), but verify no h3 references use dot notation (`plugins/core/skills/create-pr/SKILL.md`)
- Skills like `drive-approval` and `analyze-performance` contain numbered h3 headings in their own SKILL.md documentation structure, not just in templates for generated files. Decide whether the change applies only to output templates or also to the skill files themselves (`plugins/core/skills/drive-approval/SKILL.md`, `plugins/core/skills/analyze-performance/SKILL.md`)
- The existing archived ticket `20260128-numbered-headings-rule.md` documents the original dot notation decision; this change supersedes that convention (`.workaholic/tickets/archive/feat-20260128-012023/20260128-numbered-headings-rule.md`)
