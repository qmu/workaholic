---
created_at: 2026-02-03T18:26:17+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Extract /scan Command from /report

## Overview

Split the scanner functionality from `/report` into a new standalone `/scan` command. The `/scan` command maintains `.workaholic/` documentation (changelog, specs, terms) by reflecting current branch changes. Additionally, merge story-moderator and story-writer subagents into a single story-writer subagent since scanner is no longer invoked as part of the report workflow.

This change decouples documentation scanning from PR creation, allowing users to update documentation independently without creating a PR.

## Key Files

- `plugins/core/commands/scan.md` - New command to create (invokes scanner subagent)
- `plugins/core/commands/report.md` - Remove scanner invocation, invoke story-writer directly
- `plugins/core/agents/story-moderator.md` - Delete (merge into story-writer)
- `plugins/core/agents/story-writer.md` - Take over orchestration from story-moderator
- `.workaholic/specs/architecture.md` - Update /report Dependencies diagram and add /scan Dependencies diagram
- `.workaholic/specs/architecture_ja.md` - Japanese translation updates
- `CLAUDE.md` - Add `/scan` to Commands table
- `plugins/core/README.md` - Add `/scan` to Commands table
- `README.md` - Add `/scan` to Quick Start commands

## Related History

The scanner and story-moderator were introduced recently to create a two-tier orchestration pattern. This refactoring extracts scanner as a standalone command, simplifying the /report architecture back to a single tier.

Past tickets that touched similar areas:

- [20260203122448-add-story-moderator-and-scanner.md](.workaholic/tickets/archive/drive-20260203-122444/20260203122448-add-story-moderator-and-scanner.md) - Introduced story-moderator and scanner two-tier architecture (same components)
- [20260203144736-correct-story-workflow-mappings.md](.workaholic/tickets/archive/drive-20260203-122444/20260203144736-correct-story-workflow-mappings.md) - Corrected skill/subagent mappings in story workflow (same components)
- [20260203180235-rename-story-to-report.md](.workaholic/tickets/archive/drive-20260203-122444/20260203180235-rename-story-to-report.md) - Recent rename of /story to /report (same command)

## Current Architecture

```
/report command
  |
  +-- story-moderator (orchestrates 2 groups)
        |
        +-- Parallel invocation:
        |     |
        |     +-- scanner (invokes 3 agents)
        |     |     |-- changelog-writer
        |     |     |-- spec-writer
        |     |     +-- terms-writer
        |     |
        |     +-- story-writer (invokes 4 agents)
        |           |-- overview-writer
        |           |-- section-reviewer
        |           |-- release-readiness
        |           +-- performance-analyst
        |
        +-- pr-creator
```

## Proposed Architecture

```
/scan command
  |
  +-- scanner (invokes 3 agents)
        |-- changelog-writer
        |-- spec-writer
        +-- terms-writer

/report command
  |
  +-- story-writer (invokes 4+1 agents)
        |
        +-- Phase 1 (parallel): 4 agents
        |     |-- overview-writer
        |     |-- section-reviewer
        |     |-- release-readiness
        |     +-- performance-analyst
        |
        +-- Phase 2: write story, invoke pr-creator
```

## Implementation Steps

1. **Create scan.md** at `plugins/core/commands/scan.md`:
   - Frontmatter: name: scan, description
   - Instructions: invoke scanner subagent with branch name, base branch, repository URL
   - Capture and report success/failure for changelog-writer, spec-writer, terms-writer
   - Stage and commit documentation changes: "Update documentation"

2. **Update report.md** at `plugins/core/commands/report.md`:
   - Remove story-moderator invocation
   - Invoke story-writer directly (step 3)
   - Pass branch name, base branch, repository URL, archived tickets, git log to story-writer
   - Receive PR URL from story-writer result

3. **Delete story-moderator.md** at `plugins/core/agents/story-moderator.md`:
   - File no longer needed - story-writer takes over its responsibility
   - Update architecture.md agent list to remove story-moderator entry

4. **Update story-writer.md** at `plugins/core/agents/story-writer.md`:
   - No changes needed - already handles 4 agents and pr-creator invocation
   - Verify output includes PR URL

5. **Update architecture.md**:
   - Update /report Dependencies mermaid diagram to show report -> story-writer directly
   - Add new /scan Dependencies mermaid diagram
   - Update "Documentation Enforcement" flowchart to reflect new architecture
   - Remove story-moderator from agent list in Directory Layout
   - Update agent descriptions section

6. **Update architecture_ja.md**:
   - Apply same diagram and prose changes with Japanese translations

7. **Update CLAUDE.md**:
   - Add `/scan` command row to Commands table: `| /scan | Update .workaholic/ documentation |`
   - Update Project Structure comment

8. **Update plugins/core/README.md**:
   - Add `/scan` to Commands table with description

9. **Update README.md**:
   - Add `/scan` to Quick Start commands table

## Patches

### `plugins/core/commands/report.md`

```diff
--- a/plugins/core/commands/report.md
+++ b/plugins/core/commands/report.md
@@ -20,20 +20,18 @@ This design makes stories the single source of truth for PR content, eliminating
 ## Instructions

 1. Check the current branch name with `git branch --show-current`
 2. Get the base branch (usually `main`) with `git remote show origin | grep 'HEAD branch'`
-3. **Generate documentation and create PR** using story-moderator subagent:
+3. **Generate documentation and create PR** using story-writer subagent:

-   Invoke **story-moderator** (`subagent_type: "core:story-moderator"`, `model: "opus"`):
+   Invoke **story-writer** (`subagent_type: "core:story-writer"`, `model: "opus"`):
    - Pass branch name and base branch
    - Pass repository URL (for changelog-writer)
    - Pass list of archived tickets for the branch
    - Pass git log main..HEAD

-   The story-moderator orchestrates documentation generation in two parallel groups:
-   - Scanner group: changelog-writer, spec-writer, terms-writer
-   - Story group (via story-writer): overview-writer, section-reviewer, release-readiness, performance-analyst
-   - Story-writer writes the story file and invokes pr-creator
+   The story-writer orchestrates story generation:
+   - Story agents: overview-writer, section-reviewer, release-readiness, performance-analyst
+   - Writes the story file and invokes pr-creator
    - Returns confirmation with success/failure status and PR URL

    Output locations:
-   - `CHANGELOG.md`
    - `.workaholic/stories/<branch-name>.md`
-   - `.workaholic/specs/**/*.md`
-   - `.workaholic/terms/**/*.md`

-   After story-moderator completes, stage all changes and commit: "Update documentation for PR"
+   After story-writer completes, stage all changes and commit: "Update documentation for PR"

-   **Failure handling**: If story-moderator reports agent failures, report which succeeded and which failed.
+   **Failure handling**: If story-writer reports agent failures, report which succeeded and which failed.
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -68,6 +68,7 @@ Skills are the knowledge layer. Commands and subagents are the orchestration lay
 | -------------------------------- | ------------------------------------------------ |
 | `/ticket <description>`          | Write implementation spec for a feature          |
 | `/drive`                         | Implement queued specs one by one                |
+| `/scan`                          | Update .workaholic/ documentation                |
 | `/report`                        | Generate documentation and create/update PR      |
 | `/release [major\|minor\|patch]` | Release new marketplace version                  |
```

## Considerations

- **Workflow change**: Users who want documentation updates without PR creation can now use `/scan` independently
- **Commit strategy**: `/scan` commits documentation changes separately; `/report` creates story and PR without scanning
- **Scanner invocation**: `/report` no longer invokes scanner - users should run `/scan` before `/report` if they want documentation updates
- **Typical workflow becomes**: `/ticket` -> `/drive` -> `/scan` -> `/report`
- **Backward compatibility**: Users who relied on `/report` to update all documentation must now run `/scan` first
- **Story-moderator removal**: Simplifies architecture from 2-tier to 1-tier for /report
