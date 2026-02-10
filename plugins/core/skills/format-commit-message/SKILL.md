---
name: format-commit-message
description: Structured commit message format with title, description, changes, test planning, and release preparation sections.
user-invocable: false
---

# Format Commit Message

Structured commit message format for all commits. Each section should be a short paragraph (3-5 sentences) that gives lead agents enough signal to act without reading the full diff.

## Format

```
<title>

Description: <why this change was needed, including motivation and rationale>

Changes: <what users will experience differently>

Test Planning: <what verification was done or should be done>

Release Preparation: <what is needed to ship and support afterward>

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Title

Present-tense verb, what changed (50 chars max). No prefixes like `feat:` or `[fix]`.

Examples:
- Add session-based authentication
- Fix Mermaid slash character in labels
- Remove unused RegisterTool type

## Description

Why this change was needed, including the motivation and rationale. Start with the problem or gap that existed before this change. Explain what triggered the work -- a user report, a downstream dependency, a missing capability, or a design decision. State the chosen approach and why it was preferred over alternatives. Extract context from the ticket Overview. Target 3-5 sentences so that a lead agent can understand the full intent without reading the diff.

## Changes

What users will experience differently after this change. Describe each observable difference concretely -- new commands, altered output format, changed error messages, new options, or modified default behavior. Explain the before-and-after for each difference so that a reader who has never seen the code can understand the impact. If the change is internal only, write "None" and briefly explain why there is no user-facing impact (e.g., "None -- this is a refactor of internal shell scripts with no change to CLI behavior").

## Test Planning

What verification was done or should be done to confirm this change works correctly. Describe manual checks that were performed and their results. List automated tests that were added, modified, or run. Identify edge cases that were considered and whether they were covered or deferred. If the change interacts with external systems, note how those interactions were validated. Write "None" only if the change is trivial (e.g., typo fix, comment update) and requires no special verification.

## Release Preparation

What is needed to ship this change and support it afterward. Cover migration steps or data format changes that consumers must adopt. Note configuration or environment changes required for the change to take effect. Identify documentation that needs updating (READMEs, specs, terms, changelogs). Flag any monitoring, alerting, or rollback considerations. If the change is straightforward to ship with no special requirements, write "None" and briefly explain why (e.g., "None -- backward-compatible addition with no migration needed").
