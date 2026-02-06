---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-02-07
commit_hash: d5001a0
---

[English](workflow-terms.md) | [日本語](workflow-terms_ja.md)

# Workflow Terms

Actions and operations in the development workflow.

## drive

Drive is the operation that processes tickets from `.workaholic/tickets/todo/` sequentially. For each ticket, it implements the described changes, requests user approval, commits the work, and archives the ticket. This creates a structured development flow where work is captured before implementation and documented after completion. Invoked with `/drive` command. Related terms: ticket, archive, commit.

## abandon

Abandon is one of four approval options during `/drive` workflow when implementation proves unworkable. When selected, it discards uncommitted implementation changes (via `git restore`), requires a Failure Analysis section documenting what was attempted and why it failed, moves the ticket to `.workaholic/tickets/abandoned/`, commits to preserve the analysis, and continues to the next ticket. Related terms: ticket, failure-analysis, drive, approval.

## archive

Archive moves completed tickets from the active queue (`.workaholic/tickets/todo/`) to branch-specific directories (`.workaholic/tickets/archive/<branch>/`). This preserves implementation records while clearing the active queue. The archive-ticket skill handles this automatically after successful commits. Related terms: ticket, drive, icebox.

## sync

Sync operations update derived documentation (specs, terms) to reflect the current codebase state. Unlike commits that record changes, syncs ensure documentation accuracy. The `/report` command automatically synchronizes the `.workaholic/` directory via spec-writer and terms-writer subagents. Related terms: spec, terms.

## release

A release increments the marketplace version, updates version metadata in `.claude-plugin/marketplace.json`, and publishes changes. The `/release` command supports major, minor, and patch version increments following semantic versioning and creates appropriate git tags. Related terms: changelog, plugin.

## story

Story is the operation that orchestrates multiple documentation agents concurrently to generate all artifacts (changelog, story, specs, terms), then creates or updates a GitHub pull request. This is the primary command for completing a feature branch and preparing it for review. The `/story` command replaced the earlier `/report` command to better reflect the story document as the central artifact. Related terms: changelog, spec, terms, agent, orchestrator.

## report (Deprecated)

Report was the previous name for the `/story` command. The functionality remains the same—orchestrating documentation generation and PR creation—but the name now emphasizes the story document as the central artifact. Related terms: story.

## workflow

In Workaholic's context, workflow refers to GitHub Actions workflows (YAML files in `.github/workflows/`) that automate release processes and CI/CD tasks. Workflows are triggered manually via `workflow_dispatch` or automatically on events like tag pushes. The release workflow automates version bumping, changelog extraction, and GitHub Release creation. Related terms: release, GitHub Actions.

## concurrent-execution

Concurrent execution is a pattern where multiple independent agents are invoked in parallel when they write to different locations and have no dependencies. The orchestrating command sends multiple Task tool invocations in a single message, allowing simultaneous work. Example: `/story` runs changelog-writer, spec-writer, terms-writer, and release-readiness concurrently in phase 1, then story-writer sequentially in phase 2. Related terms: agent, orchestrator, Task tool.

## scan

Scan is the operation that updates `.workaholic/` documentation by running all documentation scanners in parallel. The `/scan` command invokes the scanner subagent, which orchestrates 4 writers concurrently: changelog-writer (updates CHANGELOG.md), spec-writer (generates 8 viewpoint-based specs), terms-writer (maintains term definitions), and policy-writer (generates 7 policy documents). After all writers complete, changes are staged and committed. Invoked with `/scan` command. Related terms: spec, terms, policy, changelog, scanner, concurrent-execution.

## approval

Approval is a decision point in `/drive` workflow that occurs after implementation and before commit. Three selectable options are presented: Approve (commit and continue), Approve and stop (commit and end session), and Abandon (discard changes, write failure analysis, move to abandoned). Users can also provide free-form feedback via the "Other" option, which triggers the ticket-update-first rule: the ticket's Implementation Steps must be updated before any code changes are made. The previous "Needs revision" selectable option has been removed in favor of this free-form feedback approach. Related terms: drive, ticket, abandon, commit, feedback.

## feedback

Feedback is the free-form text a user provides during `/drive` approval when they want changes to the implementation. Rather than selecting a predefined option, users select "Other" and type their feedback. The drive-approval skill enforces the ticket-update-first rule: the ticket's Implementation Steps section must be updated with new or modified steps BEFORE any code changes are made. A Discussion section is appended to the ticket for traceability, recording the user feedback, ticket updates, direction change, and action taken. Related terms: approval, drive, ticket.

## release-readiness

Release readiness is a pre-release analysis evaluating whether branch changes are suitable for immediate release. The release-readiness subagent runs during `/story` alongside other documentation agents, producing a verdict (ready/needs attention) with concerns and instructions. Analysis considers breaking changes, incomplete work, test status, and security concerns. Output appears in the story's Release Preparation section. Related terms: release, story, agent.

## prioritization

Prioritization is the process of analyzing ticket metadata (type, layer, effort) and ordering tickets for optimal execution during `/drive`. Claude Code determines recommended order based on severity (bugfix > enhancement > refactoring > housekeeping), context grouping (same-layer tickets together), and effort estimates. Users see the proposed order and can accept, override, or pick individual tickets. Related terms: drive, ticket, context-grouping, severity.

## context-grouping

Context grouping is an optimization strategy during ticket prioritization where tickets modifying files in the same architectural layers (Config, Infrastructure, Domain) are grouped and processed sequentially. This reduces cognitive load and context switching overhead, allowing developers to maintain focus on specific codebase areas. Related terms: prioritization, ticket, layer.

## severity

Severity is a prioritization criterion based on ticket type: bugfixes (addressing broken functionality) take highest priority, followed by enhancements (new features), refactoring (code improvements), and housekeeping (maintenance). This ensures critical issues are resolved before new functionality work, maintaining production stability. Related terms: prioritization, ticket, type.

## structured-commit-message

A structured commit message extends beyond a simple title to include detailed sections capturing the "why" and scope of changes. Format: title (present-tense verb), detail (1-2 sentences explaining why), UX changes (user-facing impacts), Arch changes (architecture impacts), and Co-Authored-By trailer. Empty sections use "None". Commits created during `/drive` workflow. Related terms: commit, archive-ticket, format-commit-message skill.

## ux-changes

UX changes are user-visible impacts documented in the "UX:" section of structured commit messages. These describe what users will see or experience differently: new commands, options, behaviors, output format changes, or error messages. If no user-facing changes, the field contains "None". Helps generate user guide updates. Related terms: structured-commit-message, commit, arch-changes.

## arch-changes

Arch changes are developer-facing and structural impacts documented in the "Arch:" section of structured commit messages. These describe new files, components, abstractions, modified interfaces, data structures, or workflow relationships. If no architectural changes, the field contains "None". Helps generate specification updates. Related terms: structured-commit-message, commit, ux-changes.
