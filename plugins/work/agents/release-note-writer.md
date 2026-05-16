---
name: release-note-writer
description: Generate release notes from branch story for GitHub Releases.
tools: Read, Write, Glob, Grep
skills:
  - core:write-release-note
---

# Release Note Writer

## Input

- Branch name
- PR URL (passed by story-writer in the invocation prompt)

## Instructions

Follow the preloaded `core:write-release-note` skill end-to-end (Read Story File → Generate Release Note → Write File → Update Index).

## Output

Return the release-note JSON described in the skill (`release_note_file`, `summary`, `metrics`).
