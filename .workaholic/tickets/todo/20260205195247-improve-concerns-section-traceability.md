---
created_at: 2026-02-05T19:52:47+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Improve Concerns Section with Identifiable References

## Overview

Enhance the Concerns/Considerations section in tickets and stories to include specific, verifiable references. Currently these sections contain prose descriptions of risks and trade-offs, but readers cannot easily verify or locate the relevant code. Adding commit hashes and file paths transforms concerns from abstract warnings into actionable audit trails.

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` - Ticket template defining Considerations section format
- `plugins/core/skills/write-story/SKILL.md` - Story template defining section 7 (Concerns) format
- `plugins/core/skills/review-sections/SKILL.md` - Guidelines for generating Concerns section from tickets
- `plugins/core/agents/section-reviewer.md` - Subagent that produces Concerns section content

## Related History

The codebase has established patterns for adding traceability references to documentation. The Related History feature (20260127101903) added file and layer matching to help readers understand context. The commit_hash frontmatter addition (20260123135636) enabled machine-readable audit trails. This ticket extends that traceability philosophy to the Concerns section.

Past tickets that touched similar areas:

- [20260127101903-add-related-history-to-tickets.md](.workaholic/tickets/archive/feat-20260126-214833/20260127101903-add-related-history-to-tickets.md) - Added Related History section with file/layer references (same layer: Config)
- [20260123135636-add-commit-hash-frontmatter.md](.workaholic/tickets/archive/feat-20260123-032323/20260123135636-add-commit-hash-frontmatter.md) - Added commit_hash to frontmatter for traceability (same purpose: adding references)

## Implementation Steps

1. **Update `plugins/core/skills/create-ticket/SKILL.md`** to enhance the Considerations section template:

   - Add structured format for concerns with reference fields
   - Include examples showing commit hash and file path references
   - Define when references are required vs optional

2. **Update `plugins/core/skills/write-story/SKILL.md`** section 7 (Concerns) format:

   - Add reference format: `[concern description] (see [hash](url) in path/to/file.ext)`
   - Provide guidelines for linking concerns to specific commits from section 4
   - Add example showing properly referenced concerns

3. **Update `plugins/core/skills/review-sections/SKILL.md`** guidelines:

   - Add instruction to extract file paths from ticket Considerations
   - Add instruction to include commit_hash from ticket frontmatter when available
   - Update Section 7 guidelines to require identifiable references

4. **Update `plugins/core/agents/section-reviewer.md`** instructions:

   - Add step to collect commit hashes from ticket frontmatter
   - Add step to extract file paths mentioned in Considerations
   - Update output format to include references

## Patches

### `plugins/core/skills/create-ticket/SKILL.md`

```diff
--- a/plugins/core/skills/create-ticket/SKILL.md
+++ b/plugins/core/skills/create-ticket/SKILL.md
@@ -139,7 +139,15 @@ more context

 ## Considerations

-- <Any trade-offs, risks, or things to watch out for>
+- <Concern description> (`path/to/relevant-file.ext`)
+- <Concern about behavior change> (`path/to/file.ext` lines 45-60)
+- <Future technical debt> (affects `path/to/module/`)
+```
+
+**Considerations Guidelines:**
+- Each concern SHOULD reference a specific file path
+- Use parentheses to indicate the relevant location: `(path/to/file.ext)`
+- For line-specific concerns, include line ranges: `(path/to/file.ext lines 10-25)`
+- If a concern is conceptual without a specific file, omit the reference
```

### `plugins/core/skills/write-story/SKILL.md`

```diff
--- a/plugins/core/skills/write-story/SKILL.md
+++ b/plugins/core/skills/write-story/SKILL.md
@@ -112,7 +112,17 @@ flowchart LR

 ## 7. Concerns

-[Risks, trade-offs, or issues discovered during implementation. Known limitations or edge cases. Things reviewers should pay attention to. Write "None" if nothing to report.]
+[Risks, trade-offs, or issues discovered during implementation. Each concern should include identifiable references.]
+
+**Format**: `- <description> (see [hash](<repo-url>/commit/<hash>) in path/to/file.ext)`
+
+**Example**:
+- The pathspec exclusion syntax requires modern git versions (see [7eab801](<repo-url>/commit/7eab801) in `plugins/core/skills/drive-approval/SKILL.md`)
+- Auto-approval configuration may be broader than intended (`~/.claude/settings.local.json`)
+
+**Guidelines**:
+- Reference the commit hash from section 4 where the concern was introduced
+- Include the file path where readers should investigate
+- Write "None" if nothing to report
```

### `plugins/core/skills/review-sections/SKILL.md`

```diff
--- a/plugins/core/skills/review-sections/SKILL.md
+++ b/plugins/core/skills/review-sections/SKILL.md
@@ -39,10 +39,14 @@ Extract patterns and learnings from Related History sections.

 ### Section 7: Concerns

-Identify risks, trade-offs, and limitations.
+Identify risks, trade-offs, and limitations with identifiable references.

 - Extract from Considerations sections of tickets
+- Include commit_hash from ticket frontmatter (if present) for each concern
+- Include file paths mentioned in the Considerations section
 - Include technical debt introduced
 - Note any known limitations or edge cases
 - Highlight security or performance concerns if applicable
+- Format: `<description> (see [hash](url) in path/to/file.ext)`
 - If nothing noteworthy, write "None"
```

> **Note**: These patches are speculative - verify current file content before applying.

## Considerations

- Existing archived stories and tickets will not have references - this is documentation improvement, not retroactive fix (`plugins/core/skills/write-story/SKILL.md`)
- The section-reviewer subagent uses haiku model which may need careful prompting to ensure consistent reference extraction (`plugins/core/agents/section-reviewer.md`)
- Concerns without clear file associations should still be allowed to avoid forcing artificial references (`plugins/core/skills/create-ticket/SKILL.md`)
- This increases cognitive load during ticket creation but significantly improves reviewer experience
