---
title: Inconsistencies
description: Known terminology issues and potential resolutions
category: developer
last_updated: 2026-01-27
commit_hash: 82335e6
---

[English](inconsistencies.md) | [日本語](inconsistencies_ja.md)

# Inconsistencies

Known terminology issues and potential resolutions.

## "Spec" Terminology Overload

### Issue

The `/ticket` command description uses "implementation spec" to describe tickets, but "spec" has a distinct meaning in Workaholic (current state documentation in `.workaholic/specs/`).

### Current Usage

- `/ticket` description: "Explore codebase and write implementation ticket"
- But historically referred to as "implementation spec" in some contexts
- `.workaholic/specs/` contains current state documentation, not implementation plans

### Recommended Resolution

Consistently use "ticket" for implementation work requests and "spec" only for current state documentation. Update any remaining references to "implementation spec" to use "ticket" instead.

## Legacy "doc-specs", "sync-src-doc", and "sync-work" References

### Issue

Historical documentation may reference `/sync-doc-specs`, `/sync-src-doc`, or `/sync-work` commands that no longer exist. These commands have been consolidated into `/pull-request`.

### Current Usage

- Current workflow: `/report` runs spec-writer and terms-writer subagents automatically
- Historical commands: `sync-doc-specs`, `sync-src-doc`, `sync-work`, `sync-workaholic`
- Targets: `.workaholic/specs/` and `.workaholic/terms/`

### Recommended Resolution

Update any remaining references to explain that documentation sync happens automatically during `/report`. Historical documents should remain unchanged.

## Legacy "terminology" References

### Issue

The directory `.workaholic/terminology/` has been renamed to `.workaholic/terms/` for brevity. Similarly, the agent `terminology-writer` is now `terms-writer`.

### Current Usage

- Current directory: `.workaholic/terms/`
- Current agent: `terms-writer`
- Historical directory: `.workaholic/terminology/`
- Historical agent: `terminology-writer`

### Recommended Resolution

Update any remaining references from `terminology` to `terms`. Historical documents (archived tickets, stories) should remain unchanged as they reflect what existed at the time.

## Legacy "/sync-workaholic" Command References

### Issue

The `/sync-workaholic` command has been removed. Its functionality is now part of `/report` which automatically runs spec-writer and terms-writer subagents.

### Current Usage

- Current workflow: `/report` runs 4 documentation agents concurrently (changelog-writer, story-writer, spec-writer, terms-writer)
- Historical command: `/sync-workaholic` orchestrated spec-writer and terms-writer

### Recommended Resolution

Update any references to `/sync-workaholic` to explain that documentation sync happens automatically during `/report`. Historical documents should remain unchanged.

## Historical `doc/` and `.work/` Directory References

### Issue

Older documentation or comments may reference `doc/` or `.work/` directories that were renamed to `.workaholic/` in the current structure.

### Current Usage

- Current: `.workaholic/` contains all working artifacts
- Historical: `doc/` → `.work/` → `.workaholic/` (migration path)

### Recommended Resolution

Ensure all current documentation references `.workaholic/` consistently. When encountering `doc/` or `.work/` references, update them to `.workaholic/`.

## "Archive" Dual Meaning

### Issue

"Archive" is used both as a verb (the action of archiving) and as a noun (the archive directory), which is standard but can cause confusion in instructions.

### Current Usage

- Verb: "Archive the ticket after completion"
- Noun: "Check the archive for previous tickets"
- Directory: `.workaholic/tickets/archive/`

### Recommended Resolution

This is standard English usage and acceptable. When clarity is needed, prefer "archive directory" for the noun form and "archive" (verb) for the action.

## Legacy "TDD Plugin" References

### Issue

Historical documentation may reference a separate "TDD plugin" (`plugins/tdd/`) that has been merged into the core plugin.

### Current Usage

- Current: All commands, skills, and rules are in `plugins/core/`
- Historical: Some docs may reference `plugins/tdd/` or "TDD plugin"

### Recommended Resolution

Update any remaining references to the TDD plugin to refer to the core plugin instead. The ticket-driven development commands (`/ticket`, `/drive`) are now part of the unified core plugin.

## Legacy "/pull-request" Command References

### Issue

The `/pull-request` command has been renamed to `/report`. The new name better reflects that this command generates comprehensive documentation (changelog, story, specs, terms) in addition to creating a GitHub PR.

### Current Usage

- Current command: `/report`
- Historical command: `/pull-request`
- The `pr-creator` agent name remains unchanged (internal implementation detail)

### Recommended Resolution

Update any references to `/pull-request` to use `/report`. Historical documents (archived tickets, stories) should remain unchanged as they reflect what existed at the time.

## Legacy "/commit" Command References

### Issue

The `/commit` command has been removed. Running `/commit` during a `/drive` session would flush context, disrupting the workflow. Additionally, the command encouraged ad-hoc commits without tickets, undermining the ticket-driven development philosophy.

### Current Usage

- Current workflow: Commits happen through `/drive` (for ticket implementation) or `/report` (for documentation)
- Historical command: `/commit` allowed standalone commits

### Recommended Resolution

Update any references to `/commit` to explain that commits now happen through ticket-driven workflows (`/drive`, `/report`). All changes should flow through tickets for proper documentation.

## Skill Directory Structure Evolution

### Issue

Skills have evolved from single markdown files to directory-based structures with SKILL.md and sh/ subdirectories. Some older documentation may reference the flat file pattern or the `scripts/` directory name.

### Current Usage

- Current structure: `plugins/<name>/skills/<skill-name>/SKILL.md` with optional `sh/` directory
- Current skills (verb-noun format): archive-ticket, generate-changelog, calculate-story-metrics, gather-spec-context, gather-terms-context, manage-pr, define-ticket-format, drive-workflow, block-commands, enforce-i18n, write-story, write-spec, write-terms, write-changelog, analyze-performance, create-pr, assess-release-readiness
- Historical pattern: Single markdown files like `archive-ticket.md`
- Historical directory: `scripts/` (now renamed to `sh/` for POSIX shell compatibility)

### Recommended Resolution

When referencing skills, use the directory-based pattern. The `SKILL.md` file contains the skill definition, while `sh/` contains reusable POSIX shell scripts that agents can invoke.

## Legacy Ticket Root Directory References

### Issue

Active tickets have moved from `.workaholic/tickets/` (root) to `.workaholic/tickets/todo/` subdirectory. This creates a cleaner three-tier structure (todo/icebox/archive).

### Current Usage

- Current structure: `.workaholic/tickets/todo/` for active tickets
- Historical location: `.workaholic/tickets/` (root directory)
- Unchanged: `.workaholic/tickets/icebox/` and `.workaholic/tickets/archive/<branch>/`

### Recommended Resolution

Update any references to ticket storage from `.workaholic/tickets/` to `.workaholic/tickets/todo/`. Historical documents should remain unchanged as they reflect the structure at that time.

## Legacy "scripts/" Directory References

### Issue

The shell script directory within skills has been renamed from `scripts/` to `sh/` for brevity and to clarify that these are POSIX shell scripts (not bash-specific).

### Current Usage

- Current directory: `sh/` (e.g., `plugins/core/skills/generate-changelog/sh/generate.sh`)
- Historical directory: `scripts/` (e.g., `plugins/core/skills/archive-ticket/scripts/archive.sh`)

### Recommended Resolution

Update any remaining references from `scripts/` to `sh/`. All shell scripts should be POSIX-compliant (use `#!/bin/sh`, avoid bash-specific features).

## Legacy "Section 0 Topic Tree" References

### Issue

Historical documentation may reference "section 0" or "Topic Tree as a standalone section" for stories. The topic tree was initially added as section 0 at the top of stories, but was later moved to be embedded within the Journey section (section 3).

### Current Usage

- Current structure: Story has 7 sections (1-7), with Topic Tree flowchart embedded in Journey (section 3)
- Historical references: Some docs may mention "section 0" or Topic Tree as a separate section

### Recommended Resolution

Update any references to "section 0 Topic Tree" to clarify that the Topic Tree flowchart is now embedded within the Journey section (section 3). Historical documents (archived tickets, stories) should remain unchanged as they reflect the structure at that time.

## Story Section Count Evolution

### Issue

Historical documentation may reference stories having 7 sections, but the current story format has been expanded to 11 sections with additional analysis sections.

### Current Usage

- Current section count: 11 sections (Summary, Motivation, Journey, Changes, Outcome, Performance, Decisions, Risks, Release Preparation, Notes)
- Historical reference: 7 sections (Summary, Motivation, Journey, Changes, Outcome, Performance, Notes)

### Recommended Resolution

When referencing story sections, use current section numbers. Historical documents should remain unchanged. The additional sections (Decisions, Risks, Release Preparation) were added to provide more comprehensive PR context.

## Legacy Skill Naming References

### Issue

Skill names have been standardized to use verb-noun format. Older documentation may reference the previous names.

### Current Usage

| Old Name | New Name |
|----------|----------|
| changelog | generate-changelog |
| story-metrics | calculate-story-metrics |
| spec-context | gather-spec-context |
| terms-context | gather-terms-context |
| pr-ops | manage-pr |
| ticket-format | define-ticket-format |
| command-prohibition | block-commands |
| i18n | enforce-i18n |

### Recommended Resolution

Update skill name references to use the new verb-noun format. This naming convention makes skill purposes clearer (the verb indicates what action the skill performs).
