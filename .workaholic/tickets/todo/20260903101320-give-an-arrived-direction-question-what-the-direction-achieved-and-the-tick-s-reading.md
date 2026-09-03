---
created_at: 2026-09-03T10:13:20+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-the-maintenance-tick-s-channel-presence-help-the-work-along
merge_policy:
verification_handoff: 
---

# Give an arrived-direction question what the direction achieved and the tick's reading

## Overview

The arrived question says N items landed and asks whether the direction is finished. It does not
say **what** the direction achieved, links nothing, and offers no reading of its own — while every
other part of this loop states a judgement rather than handing a person a bare choice. Give the
question one sentence of what landed and the tick's own reading of whether it looks finished.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/user-experience.md` — the reader of the post is the user here

## Final Report

**Outcome**: implemented.

The `arrived` body said *Everything attributed to it has landed. Announce that it ended, or say it
still stands.* — a bare choice, while every other part of this loop states a judgement and lets a
person veto it. It now names **what landed** (`N item(s) landed against it and nothing is waiting`,
off the `landed` count the heading already carried) and gives **the tick's own reading**: *it reads
finished*, or *it reads finished except for work no direction claims* when the residue is non-empty.

**It is a reading, never a verdict.** Nothing closes a direction but the operator's announcement,
and the sentence still ends by asking for exactly that — the standing rule the `arrived` question has
carried since it was written, unchanged. The composition table in `moderate/reference/workflow.md` was
updated to the new body in the same change.

**Verified**: `node scripts/test-workflow-scripts.mjs`; a live run of the step.
