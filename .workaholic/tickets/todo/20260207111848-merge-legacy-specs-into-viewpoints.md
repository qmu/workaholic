---
created_at: 2026-02-07T11:18:48+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort:
commit_hash:
category:
---

# Merge Legacy Specs into Viewpoint-Based Documents

## Overview

Remove the three legacy spec documents (`architecture.md`, `command-flows.md`, `contributing.md`) and their Japanese translations from `.workaholic/specs/` by absorbing any unique content into the appropriate viewpoint-based documents. The viewpoint-based architecture was introduced in ticket 20260207023921 and the 8 viewpoint documents now provide comprehensive coverage of the same topics. The legacy documents are stale (referencing outdated components like `spec-writer.md` agent, `story-moderator`, and the `/story` command name) and create confusion by duplicating content already present in viewpoint specs.

## Key Files

- `.workaholic/specs/architecture.md` - Legacy document covering plugin structure, directory layout, command dependencies, documentation enforcement, architecture policy. Content maps to component, infrastructure, application, and model viewpoints.
- `.workaholic/specs/architecture_ja.md` - Japanese translation of architecture spec.
- `.workaholic/specs/command-flows.md` - Legacy document covering command execution flows for /ticket, /drive, /story. Content maps to application and usecase viewpoints.
- `.workaholic/specs/command-flows_ja.md` - Japanese translation of command flows spec.
- `.workaholic/specs/contributing.md` - Legacy document covering development setup, workflow, adding components. Content maps to stakeholder, infrastructure, and feature viewpoints.
- `.workaholic/specs/contributing_ja.md` - Japanese translation of contributing spec.
- `.workaholic/specs/README.md` - Index file that currently lists both viewpoint and legacy documents under separate sections.
- `.workaholic/specs/README_ja.md` - Japanese translation of specs index.

## Related History

The specs directory evolved from a nested subdirectory structure through flattening, then to a viewpoint-based architecture. The legacy documents were explicitly retained during the viewpoint migration with the intent to absorb their content later.

Past tickets that touched similar areas:

- [20260207023921-viewpoint-based-spec-architecture.md](.workaholic/tickets/archive/drive-20260205-195920/20260207023921-viewpoint-based-spec-architecture.md) - Introduced 8 viewpoint-based specs, explicitly noted legacy migration as a consideration (same directory: .workaholic/specs/)
- [20260129010825-flatten-specs-directory-structure.md](.workaholic/tickets/archive/feat-20260128-220712/20260129010825-flatten-specs-directory-structure.md) - Flattened specs directory from nested user-guide/developer-guide structure (same directory: .workaholic/specs/)
- [20260205203449-add-filesystem-validation-to-spec-writer.md](.workaholic/tickets/archive/drive-20260205-195920/20260205203449-add-filesystem-validation-to-spec-writer.md) - Added filesystem validation to spec-writer (same layer: Config)
- [20260127021013-extract-spec-skill.md](.workaholic/tickets/archive/feat-20260126-214833/20260127021013-extract-spec-skill.md) - Extracted spec context skill from spec-writer agent (same component: write-spec)

## Implementation Steps

1. **Audit legacy content against viewpoint documents** - Read each legacy document and compare its sections against the 8 viewpoint documents to identify any content gaps. Specifically check:
   - `architecture.md` "Directory Layout" section vs `infrastructure.md` "File System Layout" section
   - `architecture.md` "Command Dependencies" Mermaid diagrams vs `application.md` agent orchestration flows
   - `architecture.md` "Plugin Types" and "Skills" listing vs `component.md` component hierarchy
   - `architecture.md` "How Claude Code Loads Plugins" vs `infrastructure.md` "Installation" section
   - `command-flows.md` per-command flowcharts vs `usecase.md` and `application.md`
   - `contributing.md` "Adding a Command/Rule/Skill/Hooks" guides vs `stakeholder.md` onboarding and `feature.md` configuration
   - `contributing.md` "Documentation Standards" vs `data.md` and `feature.md`

2. **Merge any missing content into viewpoint documents** - If any substantive content from legacy documents is not covered by viewpoint documents, add it to the most appropriate viewpoint. Update `modified_at` and `commit_hash` frontmatter fields on any modified viewpoint files.

3. **Delete legacy documents** - Remove the 6 legacy files:
   - `.workaholic/specs/architecture.md`
   - `.workaholic/specs/architecture_ja.md`
   - `.workaholic/specs/command-flows.md`
   - `.workaholic/specs/command-flows_ja.md`
   - `.workaholic/specs/contributing.md`
   - `.workaholic/specs/contributing_ja.md`

4. **Update specs README index** - Remove the "Legacy Documents" section from `.workaholic/specs/README.md`. The file should list only the 8 viewpoint documents and cross-references to guides and policies.

5. **Update specs README_ja index** - Apply the same changes to `.workaholic/specs/README_ja.md`.

6. **Update write-spec skill** - Check `plugins/core/skills/write-spec/SKILL.md` for any references to legacy document filenames (`architecture.md`, `command-flows.md`, `contributing.md`) in the "Using the Output" section (line 55: "Compare against file listings in architecture.md to detect stale documentation"). Remove or update these references.

7. **Verify no broken links** - Search the codebase for any references to the deleted filenames (`architecture.md`, `command-flows.md`, `contributing.md` within `.workaholic/specs/` context) and update or remove them.

## Considerations

- The `architecture.md` document contains the most comprehensive directory listing of all agents and skills. The `component.md` viewpoint already covers this at a higher level (counts and groupings), but the detailed per-file listing may be useful for onboarding. Decide whether to incorporate the full listing into `component.md` or `infrastructure.md`, or accept the viewpoint-level summaries as sufficient. (`component.md`, `infrastructure.md`)
- The `command-flows.md` contains detailed Mermaid flowcharts per command that are more granular than what `application.md` provides. The `application.md` uses text-based flow descriptions. Consider whether the Mermaid diagrams should be added to `application.md` or `usecase.md`. (`.workaholic/specs/application.md`, `.workaholic/specs/usecase.md`)
- The `contributing.md` document serves as a contributor onboarding guide. While viewpoint specs describe the system as it is, they do not provide a "how to contribute" guide. Consider whether this content should move to `.workaholic/guides/` instead of being merged into viewpoint specs. (`.workaholic/guides/`)
- The legacy `command-flows.md` references `/story` as the report command name, which was renamed to `/report` in ticket 20260127014257. This staleness confirms the documents are not being maintained by the viewpoint analysts. (`.workaholic/specs/command-flows.md`)
- The `architecture_ja.md` references `spec-writer.md` as an agent file, but this agent was removed when the viewpoint-based architecture was implemented. The scanner now invokes individual `*-analyst` agents directly. (`.workaholic/specs/architecture_ja.md`)
- The `write-spec/SKILL.md` line 55 explicitly references `architecture.md` for comparing file listings. This reference must be updated to point to the appropriate viewpoint document or removed entirely. (`plugins/core/skills/write-spec/SKILL.md` line 55)
