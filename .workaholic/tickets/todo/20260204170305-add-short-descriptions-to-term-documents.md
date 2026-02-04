---
created_at: 2026-02-04T17:03:05+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add short descriptions to term documents

## Overview

Add a "short_description" YAML frontmatter field to each term entry in `.workaholic/terms/` documents. This field provides a concise (5-15 word) semantic description that enables automated terminology consistency analysis:

- **Same meaning, different term** - Detect synonyms that should be consolidated
- **Different meaning, same term** - Identify homonyms needing disambiguation
- **Context-dependent variations** - Find terms whose meaning varies by usage context

The short description captures the semantic essence, distinct from the longer Definition section which provides full context and examples.

## Key Files

- `.workaholic/terms/core-concepts.md` - Plugin system terms (plugin, command, skill, rule, agent)
- `.workaholic/terms/core-concepts_ja.md` - Japanese translation
- `.workaholic/terms/artifacts.md` - Documentation artifacts (ticket, spec, story, changelog)
- `.workaholic/terms/artifacts_ja.md` - Japanese translation
- `.workaholic/terms/workflow-terms.md` - Workflow actions (drive, archive, sync, release)
- `.workaholic/terms/workflow-terms_ja.md` - Japanese translation
- `.workaholic/terms/file-conventions.md` - File naming conventions
- `.workaholic/terms/file-conventions_ja.md` - Japanese translation
- `plugins/core/skills/write-terms/SKILL.md` - Update term entry format documentation

## Related History

Terminology documentation has evolved to improve brevity and maintainability. The terms directory was renamed from "terminology" for conciseness.

Past tickets that touched similar areas:

- [20260127010716-rename-terminology-to-terms.md](.workaholic/tickets/archive/feat-20260126-214833/20260127010716-rename-terminology-to-terms.md) - Renamed terminology directory and agent to terms (same layer: Config)

## Implementation Steps

1. **Define short_description format** - Add to term entry format in write-terms skill. The field should be 5-15 words capturing semantic meaning, not functional description.

2. **Update core-concepts.md** - Add short_description to each term:
   - plugin: "A modular package of Claude Code extensions distributed as a unit"
   - command: "A user-invocable slash action that performs a specific task"
   - skill: "A helper routine providing reusable knowledge or scripts"
   - rule: "Guidelines and constraints shaping Claude behavior"
   - agent: "A specialized subprocess with dedicated context for focused tasks"
   - (continue for all terms in file)

3. **Update artifacts.md** - Add short_description to each term:
   - ticket: "A work request capturing planned changes and implementation outcomes"
   - spec: "Current state documentation providing authoritative reference"
   - story: "Branch narrative synthesizing motivation, progression, and outcome"
   - (continue for all terms in file)

4. **Update workflow-terms.md** - Add short_description to each term:
   - drive: "Process tickets sequentially, implementing and committing each"
   - archive: "Move completed work to branch-specific long-term storage"
   - (continue for all terms in file)

5. **Update file-conventions.md** - Add short_description to each term

6. **Update Japanese translations** - Mirror short_description fields in all `*_ja.md` files with translated content

7. **Update write-terms skill** - Document the short_description field in the term entry format section

## Patches

### `plugins/core/skills/write-terms/SKILL.md`

```diff
--- a/plugins/core/skills/write-terms/SKILL.md
+++ b/plugins/core/skills/write-terms/SKILL.md
@@ -62,6 +62,8 @@ Term Categories
 ```markdown
 ## term-name

+short_description: A concise 5-15 word semantic description for consistency analysis
+
 Brief one-sentence definition.

 ### Definition
```

### `.workaholic/terms/core-concepts.md`

```diff
--- a/.workaholic/terms/core-concepts.md
+++ b/.workaholic/terms/core-concepts.md
@@ -13,6 +13,8 @@ Fundamental building blocks of the Workaholic plugin system.

 ## plugin

+short_description: A modular package of Claude Code extensions distributed as a unit
+
 A modular collection of commands, skills, rules, and agents that extends Claude Code functionality.

 ### Definition
@@ -31,6 +33,8 @@ A modular collection of commands, skills, rules, and agents that extends Claude

 ## command

+short_description: A user-invocable slash action that performs a specific task
+
 A user-invocable slash command that performs a specific task.

 ### Definition
```

> **Note**: Patches are speculative - verify exact line numbers and content before applying. Similar patterns apply to all other term entries across all term documents.

## Considerations

- The short_description should focus on semantic meaning, not implementation details
- Keep descriptions under 15 words to ensure they remain concise and comparable
- Translations in `*_ja.md` files must preserve semantic equivalence, not be literal translations
- Consider future tooling: a script could compare short_descriptions using semantic similarity to detect potential synonyms or homonyms
- The inconsistencies.md file may need updates if analysis reveals terminology issues
