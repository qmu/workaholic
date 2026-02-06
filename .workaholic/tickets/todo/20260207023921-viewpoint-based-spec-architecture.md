---
created_at: 2026-02-07T02:39:21+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Implement Viewpoint-Based Spec Architecture for /scan Command

## Overview

Transform the `/scan` command's spec generation from 3 ad-hoc spec documents (`architecture.md`, `command-flows.md`, `contributing.md`) into a systematic viewpoint-based architecture with 8 predefined viewpoints. Each viewpoint is analyzed concurrently by an `architecture-analyst` subagent, giving any repository a comprehensive, multi-perspective documentation baseline.

The 8 viewpoints are: stakeholder, model, usecase, infrastructure, application, component, data, feature.

## Key Files

- `plugins/core/skills/analyze-viewpoint/SKILL.md` - New comprehensive skill with 8 viewpoint definitions, analysis prompts, Mermaid diagram types, output templates, assumption section rules, and inference baseline guidelines
- `plugins/core/skills/analyze-viewpoint/sh/gather.sh` - New context gathering script accepting viewpoint slug + base branch as arguments
- `plugins/core/skills/analyze-viewpoint/sh/read-overrides.sh` - New script to read user repo's root CLAUDE.md for viewpoint overrides/extensions
- `plugins/core/agents/architecture-analyst.md` - New thin subagent (~20-40 lines) receiving viewpoint slug, gathering context via analyze-viewpoint skill scripts, analyzing repo, writing `.workaholic/specs/<slug>.md` + `_ja.md`
- `plugins/core/agents/spec-writer.md` - Rewrite to orchestrate 8 parallel architecture-analyst invocations via Task tool (currently generates 3 ad-hoc specs)
- `plugins/core/skills/write-spec/SKILL.md` - Update directory structure and index rules for 8-viewpoint file naming convention

## Related History

The spec-writer workflow evolved through several iterations: from a monolithic sync command to ticket-based change detection, to adding filesystem validation, and most recently extracting `/scan` as a standalone command. The current 3-spec approach (architecture, command-flows, contributing) grew organically and lacks systematic coverage guarantees.

Past tickets that touched similar areas:

- [20260205203449-add-filesystem-validation-to-spec-writer.md](.workaholic/tickets/archive/drive-20260205-195920/20260205203449-add-filesystem-validation-to-spec-writer.md) - Added ACTUAL STRUCTURE validation to spec-writer (same file: spec-writer.md)
- [20260203182617-extract-scan-command.md](.workaholic/tickets/archive/drive-20260203-122444/20260203182617-extract-scan-command.md) - Extracted /scan as standalone command from /report (same layer: Config)
- [20260203122448-add-story-moderator-and-scanner.md](.workaholic/tickets/archive/drive-20260203-122444/20260203122448-add-story-moderator-and-scanner.md) - Introduced scanner two-tier orchestration pattern (same component: scanner)
- [20260127021013-extract-spec-skill.md](.workaholic/tickets/archive/feat-20260126-214833/20260127021013-extract-spec-skill.md) - Extracted spec context skill from spec-writer agent (same file: spec-writer.md)
- [20260123154228-sync-doc-specs-cross-cutting-docs.md](.workaholic/tickets/archive/feat-20260123-032323/20260123154228-sync-doc-specs-cross-cutting-docs.md) - Added cross-cutting concern analysis to spec generation (same layer: Config)

## Implementation Steps

1. **Create `plugins/core/skills/analyze-viewpoint/SKILL.md`** - Comprehensive skill defining all 8 viewpoints:

   For each viewpoint, define:
   - Slug (kebab-case identifier used as filename)
   - Description (what this viewpoint covers)
   - Analysis prompts (specific questions to answer)
   - Mermaid diagram type (flowchart, sequence, ER, class, etc.)
   - Output template (section structure for the generated spec)

   The 8 viewpoints:
   - **stakeholder**: Who uses the system, their goals, interaction patterns
   - **model**: Domain concepts, relationships, core abstractions
   - **usecase**: User workflows, command sequences, input/output contracts
   - **infrastructure**: External dependencies, file system layout, installation
   - **application**: Runtime behavior, agent orchestration, data flow
   - **component**: Internal structure, module boundaries, skill/agent/command decomposition
   - **data**: Data formats, frontmatter schemas, file naming conventions
   - **feature**: Feature inventory, capability matrix, configuration options

   Include:
   - Assumption section rules (clearly mark inferred vs explicit knowledge)
   - Comprehensiveness policy (document everything, no "not worth documenting" judgments)
   - Inference baseline guidelines (what to do when codebase has no explicit information)
   - Nested spec rules (how viewpoint specs reference each other)

2. **Create `plugins/core/skills/analyze-viewpoint/sh/gather.sh`** - Context gathering script:
   - Accept viewpoint slug as `$1` and base branch as `$2` (default: `main`)
   - Gather relevant codebase context for the given viewpoint
   - Output structured sections (similar to write-spec gather.sh pattern)
   - Include BRANCH, DIFF, COMMIT, and viewpoint-specific file listings

3. **Create `plugins/core/skills/analyze-viewpoint/sh/read-overrides.sh`** - Override reader:
   - Read the user repo's root `CLAUDE.md` for viewpoint override directives
   - Output JSON with any custom viewpoints or modifications
   - Enables future extension (e.g., Policies, Project viewpoints) without code changes

4. **Create `plugins/core/agents/architecture-analyst.md`** - Thin subagent:
   - Frontmatter: name, description, tools (Read, Write, Edit, Bash, Glob, Grep), skills (analyze-viewpoint, write-spec, translate)
   - Input: viewpoint slug, base branch
   - Instructions:
     1. Run `gather.sh <slug> <base-branch>` to collect context
     2. Run `read-overrides.sh` to check for custom directives
     3. Read analyze-viewpoint skill for the specific viewpoint definition
     4. Analyze the codebase from that viewpoint
     5. Write `.workaholic/specs/<slug>.md` following write-spec formatting rules
     6. Write `.workaholic/specs/<slug>_ja.md` following translate skill
   - Output: JSON with status and files written

5. **Rewrite `plugins/core/agents/spec-writer.md`** - Transform into thin orchestrator:
   - Add Task tool to tools list
   - Add analyze-viewpoint skill to preloaded skills
   - Replace current 7-step sequential process with:
     1. Gather base context (branch, commit hash)
     2. Invoke 8 architecture-analyst subagents in parallel via Task tool, each with a different viewpoint slug
     3. Collect results and report status
   - Output: JSON with per-viewpoint status

6. **Update `plugins/core/skills/write-spec/SKILL.md`** - Reflect new convention:
   - Update Directory Structure section to list 8 viewpoint files instead of 3 ad-hoc files
   - Update File Naming section to document viewpoint slug convention
   - Update Index File Updates section for 16 files (8 viewpoints x 2 languages)
   - Retain existing formatting rules, frontmatter requirements, and critical rules

## Considerations

- **3-level nesting**: The call chain `scanner -> spec-writer -> 8x architecture-analyst` creates depth 3 nesting. This is acceptable because all 8 analyst invocations are parallel, not sequential (`plugins/core/agents/scanner.md`)
- **Legacy spec migration**: The existing specs (`architecture.md`, `command-flows.md`, `contributing.md`) will be superseded by the 8 viewpoint outputs. Their content should be absorbed into the appropriate viewpoints rather than deleted abruptly (`plugins/core/agents/spec-writer.md`)
- **Output volume**: 16 files per scan (8 viewpoints x 2 languages) is a significant increase from 6 files (3 specs x 2 languages). Ensure each viewpoint produces substantive content, not thin stubs (`.workaholic/specs/`)
- **CLAUDE.md injection**: The `read-overrides.sh` script reads the target repo's CLAUDE.md, which may contain arbitrary content. The script should extract only viewpoint-related directives safely (`plugins/core/skills/analyze-viewpoint/sh/read-overrides.sh`)
- **Shell script policy**: The gather.sh and read-overrides.sh scripts must follow the shell script principle from CLAUDE.md - all conditional logic in scripts, not inline in agent markdown (`plugins/core/skills/analyze-viewpoint/sh/`)
- **write-spec skill backward compatibility**: Other consumers of write-spec skill (if any beyond spec-writer) should not break from the directory structure changes (`plugins/core/skills/write-spec/SKILL.md`)
- **Spec README updates**: Both `.workaholic/specs/README.md` and `README_ja.md` must be updated to list 8 viewpoint files instead of 3 ad-hoc files (`.workaholic/specs/README.md`)
- **Architecture spec self-reference**: The architecture.md spec currently documents the full plugin structure including itself. Under the new system, this self-referential content splits across component and infrastructure viewpoints - ensure no coverage gaps (`plugins/core/agents/architecture-analyst.md`)
