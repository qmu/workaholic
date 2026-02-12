---
created_at: 2026-02-12T12:38:36+08:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash:
category:
---

# Fix Duplicate Japanese Specs When CLAUDE.md Declares Japanese-Only Written Language

## Overview

When a consumer project's root `CLAUDE.md` declares Japanese as the only written language (e.g., `Written Language: Japanese`), the `/scan` command produces doubled spec files in `.workaholic/specs/`. Both `application.md` and `application_ja.md` end up containing Japanese content, because the translate skill's critical rule unconditionally mandates creating `_ja.md` counterparts for every `.workaholic/` file, regardless of what language the primary file is already written in.

The root cause is twofold:

1. The `translate` skill hardcodes Japanese (`_ja.md`) as a mandatory translation target for all `.workaholic/` files, without checking if Japanese is already the primary language.
2. The `model-analyst` agent hardcodes "Write Japanese Translation" as an explicit instruction step, rather than deferring to the user's CLAUDE.md like other agents do.

The fix must make translation behavior dynamic: detect the primary language from the consumer's `CLAUDE.md`, skip translation when the primary language matches the translation target, and never hardcode a specific translation language in agent instructions.

## Key Files

- `plugins/core/skills/translate/SKILL.md` - Contains the "CRITICAL RULE" that unconditionally requires `_ja.md` for all `.workaholic/` files (lines 119-153)
- `plugins/core/agents/model-analyst.md` - Only agent that hardcodes "Write Japanese Translation" as step 5 (line 40)
- `plugins/core/skills/analyze-viewpoint/SKILL.md` - Output template hardcodes language navigation links with `_ja.md` suffix (line 48)
- `plugins/core/skills/write-spec/SKILL.md` - Spec directory structure assumes English primary + `_ja.md` translations (line 79)
- `plugins/core/rules/i18n.md` - Multi-language documentation rule, needs to address primary-language-as-translation edge case (lines 53-57)

## Related History

The i18n system was built incrementally, first establishing multi-language policy, then adding bilingual support for `.workaholic/`, and finally hardening the translate skill with a critical enforcement rule. Each step assumed English as the primary language, creating this blind spot for Japanese-primary projects.

Past tickets that touched similar areas:

- [20260123234825-multi-language-documentation-policy.md](.workaholic/tickets/archive/feat-20260123-191707/20260123234825-multi-language-documentation-policy.md) - Established the multi-language documentation policy with English as assumed primary
- [20260124002738-bilingual-work-directory-policy.md](.workaholic/tickets/archive/feat-20260123-191707/20260124002738-bilingual-work-directory-policy.md) - Updated CLAUDE.md to allow English or Japanese in `.workaholic/` (same layer: Config)
- [20260124003751-bilingual-work-documentation.md](.workaholic/tickets/archive/feat-20260123-191707/20260124003751-bilingual-work-documentation.md) - Created `_ja.md` translations assuming English originals
- [20260124112637-add-translate-skill.md](.workaholic/tickets/archive/feat-20260124-105903/20260124112637-add-translate-skill.md) - Added the translate skill with the hardcoded Japanese rule

## Implementation Steps

1. **Update the translate skill** (`plugins/core/skills/translate/SKILL.md`) to make the `.workaholic/ Translation Requirements` section conditional on the consumer's CLAUDE.md language configuration. Replace the unconditional "CRITICAL RULE" with logic that:
   - Reads the consumer project's root CLAUDE.md to determine the primary written language for `.workaholic/`
   - Only produces `_ja.md` translations when the primary language is NOT Japanese
   - When the primary language IS Japanese, produces `_en.md` (English) translations instead, or skips translation entirely if no secondary language is declared
   - Documents the decision tree clearly so agents can follow it

2. **Update the model-analyst agent** (`plugins/core/agents/model-analyst.md`) to remove the hardcoded "Write Japanese Translation" step. Replace it with the same dynamic pattern used by all other agents: "Write translations per the user's translation policy declared in their root CLAUDE.md."

3. **Update the analyze-viewpoint skill** (`plugins/core/skills/analyze-viewpoint/SKILL.md`) to make the language navigation links in the output template dynamic. Instead of hardcoding `[English](<slug>.md) | [Japanese](<slug>_ja.md)`, the template should describe how to determine the correct language pair based on the consumer's CLAUDE.md.

4. **Update the write-spec skill** (`plugins/core/skills/write-spec/SKILL.md`) to make the viewpoint file naming description language-neutral. Line 79 states "Each viewpoint file has a corresponding `_ja.md` translation" which should instead describe that viewpoint files may have translation counterparts based on the project's language configuration.

5. **Update the i18n rule** (`plugins/core/rules/i18n.md`) to add guidance for when the primary language matches a translation target. Add a section clarifying that translations should complement the primary language, not duplicate it.

## Patches

### `plugins/core/agents/model-analyst.md`

```diff
--- a/plugins/core/agents/model-analyst.md
+++ b/plugins/core/agents/model-analyst.md
@@ -37,9 +37,9 @@

 4. **Write English Spec**: Write `.workaholic/specs/model.md` following the preloaded analyze-viewpoint and write-spec skills. Include multiple Mermaid diagrams within content sections and an Assumptions section with `[Explicit]`/`[Inferred]` prefixes.

-5. **Write Japanese Translation**: Write `.workaholic/specs/model_ja.md` following the preloaded translate skill.
+5. **Write Translations**: Produce translations per the user's translation policy declared in their root CLAUDE.md, following the preloaded translate skill.

 ## Output

 ```json
-{"viewpoint": "model", "status": "success", "files": ["model.md", "model_ja.md"]}
+{"viewpoint": "model", "status": "success", "files": ["model.md", "<translation files if produced>"]}
 ```
```

### `plugins/core/skills/translate/SKILL.md`

```diff
--- a/plugins/core/skills/translate/SKILL.md
+++ b/plugins/core/skills/translate/SKILL.md
@@ -117,9 +117,15 @@

 ## .workaholic/ Translation Requirements

-**CRITICAL RULE**: When creating or editing any `.md` file in `.workaholic/`, you MUST also create or update the corresponding `_ja.md` translation.
+**CRITICAL RULE**: When creating or editing any `.md` file in `.workaholic/`, you MUST check the consumer project's root CLAUDE.md to determine the primary written language, then produce translations accordingly.
+
+**Decision logic:**
+
+- If the primary language is English (or bilingual English/Japanese): produce `_ja.md` translations as counterparts
+- If the primary language is Japanese only: do NOT produce `_ja.md` files (this would duplicate the primary content). Instead, produce `_en.md` translations if a secondary language is declared, or skip translations entirely
+- If the primary language is another language: produce translations for declared secondary languages using the appropriate suffix

-### File Naming for .workaholic/
+### File Naming for .workaholic/ (default: English primary)

 Use suffix-based naming for translations:
```

> **Note**: The translate skill patch is speculative - the exact wording of the decision logic should be refined during implementation to match the style of surrounding documentation.

### `plugins/core/skills/write-spec/SKILL.md`

```diff
--- a/plugins/core/skills/write-spec/SKILL.md
+++ b/plugins/core/skills/write-spec/SKILL.md
@@ -76,7 +76,7 @@
 | feature        | `feature.md`         | Feature inventory, capability matrix, configuration      |

-Each viewpoint file has a corresponding `_ja.md` translation (e.g., `stakeholder_ja.md`).
+Each viewpoint file may have a corresponding translation file (e.g., `stakeholder_ja.md` when the primary language is English). The translation suffix depends on the consumer project's CLAUDE.md language configuration.

 ## Frontmatter
```

## Considerations

- The leader skills (lead-ux, lead-infra, lead-db, etc.) already use the correct dynamic pattern ("produce translations per the user's root CLAUDE.md"), so they do not need changes. The `model-analyst` agent is the sole agent that hardcodes Japanese (`plugins/core/agents/model-analyst.md` line 40)
- The `analyze-viewpoint` output template hardcodes `[English](<slug>.md) | [Japanese](<slug>_ja.md)` as language navigation. This needs to become dynamic or be described as an example rather than a literal template (`plugins/core/skills/analyze-viewpoint/SKILL.md` line 48)
- The `translate` skill's enforcement section ("This is not optional") should be preserved but reframed: translation is still mandatory when applicable, but "applicable" now depends on the language configuration (`plugins/core/skills/translate/SKILL.md` lines 151-153)
- Consumer projects that currently have both English and `_ja.md` files will not be affected by this change, since the English-primary path remains the default behavior
- This fix does not address the scenario where a consumer project uses a non-English, non-Japanese primary language (e.g., Chinese). That would require additional work to make the translation target fully configurable, but is out of scope for this bugfix

## Final Report

Implementation followed the ticket plan across all 5 files:

1. **translate skill** - Replaced unconditional `_ja.md` critical rule with decision logic that checks consumer CLAUDE.md primary language. Preserved enforcement but scoped it to applicable cases.
2. **model-analyst agent** - Replaced hardcoded "Write Japanese Translation" step with dynamic "Write Translations" per consumer CLAUDE.md.
3. **analyze-viewpoint skill** - Made output template language navigation links dynamic with a comment indicating they depend on consumer CLAUDE.md.
4. **write-spec skill** - Changed viewpoint file description from assuming `_ja.md` to language-neutral wording.
5. **i18n rule** - Added rule 8: never duplicate the primary language as a translation target.
