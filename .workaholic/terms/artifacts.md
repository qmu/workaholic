---
title: Artifacts
description: Documentation artifacts generated during development workflows
category: developer
last_updated: 2026-02-04
commit_hash:
---

[English](artifacts.md) | [日本語](artifacts_ja.md)

# Artifacts

Documentation artifacts generated during development workflows.

## ticket

A ticket is an implementation work request that captures what should change and records what happened. Tickets define discrete units of work with YAML frontmatter (created_at, author, type, layer, effort, commit_hash, category) and sections for Overview, Key Files, Implementation Steps, and Final Report. Active tickets live in `.workaholic/tickets/todo/`, deferred ones in `icebox/`, and completed ones in `archive/<branch>/`. Files follow timestamp-prefixed naming like `20260123-123456-feature-name.md`. Created with `/ticket` and processed with `/drive`. Related terms: spec, story.

## spec

A spec is current state documentation that provides an authoritative reference snapshot of the codebase. Unlike tickets (which describe changes), specs describe what exists now and are updated via the spec-writer subagent during `/report` to reflect the current state after changes. Specs live in `.workaholic/specs/` with files like `architecture.md` or `api-reference.md`. Related terms: ticket, story. Note: The `/ticket` command description mentions "implementation spec" which conflates ticket and spec terminology.

## story

A story is a comprehensive document synthesizing the motivation, progression, and outcome of development work across multiple tickets on a branch. Stories serve as the single source of truth for PR descriptions, containing 11 sections: Summary, Motivation, Journey (with Topic Tree flowchart), Changes, Outcome, Performance, Decisions, Risks, Release Preparation, and Notes. Stories live in `.workaholic/stories/<branch-name>.md` and their content (minus frontmatter) is copied directly to GitHub as the PR body. Related terms: ticket.

## changelog

The changelog is the root CHANGELOG.md file that maintains a historical record of all changes across all branches. Entries are generated from archived tickets during PR creation, each including a commit hash, brief description, and link to the originating ticket. Branch changelogs no longer exist; tickets serve as the single source of truth for change metadata. Related terms: ticket, story.

## journey

The journey is section 3 of a story document, providing a high-level narrative (typically 100-200 words) of how development progressed, focusing on phases and pivots rather than individual ticket details. It answers "how did we get here?" while the Changes section provides the detailed "what changed?". The Topic Tree flowchart is embedded at the beginning of the Journey section. Appears in `.workaholic/stories/<branch-name>.md`. Related terms: story, topic-tree, changes.

## topic-tree

A topic tree is a Mermaid flowchart diagram embedded in the Journey section of a story, showing how tickets relate to each other. It groups tickets by concern using subgraphs, shows decision progression with arrows, and uses `&` syntax for parallel work. Format: `flowchart LR` with subgraphs representing themes. Helps PR reviewers quickly understand change scope and structure. Appears in `.workaholic/stories/<branch-name>.md`. Related terms: story, ticket.

## changes

The changes section is section 4 of a story document, providing a comprehensive list of all changes as subsections in the format `### 4.N. <Ticket title> ([hash](commit-url))`. Each subsection contains a 1-2 sentence description from the ticket's Overview, serving as the detailed "what changed?" companion to Journey's "how did we get here?". Appears in `.workaholic/stories/<branch-name>.md`. Related terms: story, journey, ticket.

## related-history

Related History is a ticket section that links to past archived tickets touching similar files, layers, or concerns. Each entry uses markdown links with repository-relative paths for GitHub navigation. Format includes a summary sentence followed by bullet points with ticket links and descriptions. The create-ticket skill guides finding related history by searching same files, layers, or terminology. Appears in `.workaholic/tickets/todo/<ticket>.md`. Related terms: ticket, archive.

## failure-analysis

Failure Analysis is a ticket section appended when a developer abandons a ticket during `/drive` approval. It documents what was attempted, why it failed, and insights for future attempts. The ticket is then moved to `.workaholic/tickets/abandoned/` and committed to preserve the learning in git history. The handle-abandon skill guides structuring comprehensive analysis. Related terms: ticket, abandon, final-report.

## final-report

The Final Report is an optional section at the end of a ticket documenting what differed between planned and actual implementation. When development proceeds as planned, it can state "Development completed as planned." Otherwise, it explains deviations and may include a Discovered Insights subsection. Appears in `.workaholic/tickets/archive/<branch>/<ticket>.md`. Related terms: ticket, discovered-insights, archive.

## discovered-insights

Discovered Insights is an optional subsection within Final Report that documents architectural patterns, code relationships, historical context, or edge cases discovered during implementation. Insights should be actionable and specific, capturing learnings valuable to future developers. Categories include hidden design decisions, non-obvious dependencies, and surprising behaviors. Appears in `.workaholic/tickets/archive/<branch>/<ticket>.md`. Related terms: ticket, final-report, archive.
