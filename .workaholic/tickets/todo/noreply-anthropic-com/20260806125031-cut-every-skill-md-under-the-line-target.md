---
created_at: 2026-08-06T12:50:31+00:00
author: noreply@anthropic.com
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission: slim-commands-skills-and-docs-for-ai-agent-use
merge_policy:
---

# Cut every SKILL.md under the line target

## Overview

<!-- PROPOSED. Sharpened by the mission's approval interrogation. -->

Skills have accreted formalized rules, past-incident narration, and heavy bold.
FB item 2/3: delete what is no longer needed (not merely compress), fold
past-problem notes into a short caveat list per skill, strip non-essential bold,
and aim every SKILL.md — even `drive/SKILL.md` — under ~100 lines. Detail that is
genuinely needed moves to a `reference/` companion, which the build already carries.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/*/SKILL.md` — every skill; the oversized ones first (`drive`, `mission`, `ship`, `report`, `workaholify`).
- `plugins/workaholic/skills/*/reference/*.md` — destination for detail worth keeping.
- `scripts/build-plugins/` — the build/verify that must still pass after relocation.

## Implementation Steps

1. Measure each SKILL.md line count; rank by size.
2. Per skill: delete obsolete/formalized rules, collapse past-incident prose into a
   short "Caveats" list, and remove bold that is not load-bearing.
3. Move still-needed reference detail into `reference/` and link it from the SKILL.
4. Rebuild (`node scripts/build-plugins/build.mjs`) and verify.

## Quality Gate

**Acceptance criteria:**

- Every SKILL.md reads under ~100 lines, or names why it cannot.
- Past-incident prose is consolidated into a caveat list, not scattered.

**Verification method:**

- Line-count survey before/after; `node scripts/build-plugins/verify.mjs` passes.

**Gate:**

- No workflow behavior lost; `outputs/` regenerated and committed.

## Considerations

<!-- ~100 lines is a target, not a hard cap; a few skills may justify more.
     The approval interrogation should fix the measure and the exceptions. -->
