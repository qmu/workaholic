---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-02-11
commit_hash: f7f779f
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

## report

Report is the operation that generates a story document and creates or updates a GitHub pull request for the current branch. The `/report` command invokes the story-writer subagent to synthesize branch work into a comprehensive PR description. Before story generation, `/report` automatically performs a patch version bump following CLAUDE.md Version Management conventions, ensuring every merged PR triggers a GitHub release. The command focuses on PR creation without triggering full documentation scans, making it faster than `/scan`. Related terms: story, changelog, release, story-writer, agent.

## story (Deprecated)

The `/story` command has been removed. Its original purpose—orchestrating full documentation scans and PR creation—has been split into two commands: `/scan` for full documentation updates and `/report` for PR creation with story generation. This separation provides clearer command semantics and allows developers to choose between full scans or focused PR preparation. Related terms: report, scan.

## workflow

In Workaholic's context, workflow refers to GitHub Actions workflows (YAML files in `.github/workflows/`) that automate release processes and CI/CD tasks. Workflows are triggered manually via `workflow_dispatch` or automatically on events like tag pushes. The release workflow automates version bumping, changelog extraction, and GitHub Release creation. Related terms: release, GitHub Actions.

## concurrent-execution

Concurrent execution is a pattern where multiple independent agents are invoked in parallel when they write to different locations and have no dependencies. The orchestrating command sends multiple Task tool invocations in a single message, allowing simultaneous work. Example: `/story` runs changelog-writer, spec-writer, terms-writer, and release-readiness concurrently in phase 1, then story-writer sequentially in phase 2. Related terms: agent, orchestrator, Task tool.

## scan

Scan is the operation that updates `.workaholic/` documentation by invoking all 17 documentation agents directly in parallel. The `/scan` command orchestrates 8 viewpoint analysts (stakeholder, model, usecase, infrastructure, application, component, data, feature), 7 policy analysts (test, security, quality, accessibility, observability, delivery, recovery), changelog-writer, and terms-writer as concurrent Task calls within the command itself. This direct invocation pattern (replacing the previous scanner subagent) provides real-time per-agent progress visibility to the user. Each agent must use `run_in_background: false` to preserve Write/Edit permissions. After all agents complete, output is validated, index files are updated, and changes are staged and committed. Related terms: spec, terms, policy, changelog, concurrent-execution, viewpoint-analyst, policy-analyst, run_in_background.

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

A structured commit message extends beyond a simple title to include five detailed sections capturing context for downstream lead agents. Format: Title (present-tense verb, 50 chars max), Description (motivation and rationale, 2-3 sentences), Changes (user-visible differences or "None"), Test Planning (verification done or needed), Release Preparation (ship and support requirements), and Co-Authored-By trailer. This expanded format replaced the previous 4-section format (Motivation, UX Change, Arch Change) to provide better signal for test-lead, delivery-lead, security-lead, and other domain leads. The commit skill handles message construction via `commit.sh`, and format-commit-message skill content was merged into the commit skill. Related terms: commit, archive-ticket, commit skill.

## format-commit-message (Deprecated)

The format-commit-message skill was a separate skill defining commit message formatting, previously located in `plugins/core/skills/format-commit-message/SKILL.md`. It has been merged into the commit skill to eliminate dual-maintenance burden and simplify preload lists. The commit skill now contains the full per-section writing guidelines (Title, Description, Changes, Test Planning, Release Preparation) as the single authoritative source for commit message formatting. Historical references in archived tickets and stories remain unchanged as they are historical records. Related terms: commit, structured-commit-message, skill.
