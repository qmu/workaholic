---
created_at: 2026-08-06T12:50:31+00:00
author: noreply@anthropic.com
assignees: [noreply@anthropic.com]
type: refactoring
layer: [Config]
effort:
commit_hash:
category: Changed
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

## Final Report

Development completed as planned. Sixteen oversized SKILL.md files went 6,040 → 2,219 lines. Nine now read under 100; the seven above name their reason: drive (130 — the §7 token table is the /goal contract and stays near-verbatim, plus gate/effective-policy tables and §-anchors other files reference), workaholify/create-ticket (120 — externally referenced section roster + test-pinned phrases), propose/branching/mission (119/119/118 — referenced heading identities and script invocation blocks), ship/report (105 — numbered-section skeleton named by commands and docs). Incident narrations folded into per-skill Caveats bullets; genuinely needed detail moved to reference/ companions (report 5 files, drive 5, ship 3, workaholify 3, feedback 2, branching 2, catch/explain 1 each; mission/create-ticket extended their existing dirs). All externally referenced section headings were grepped and preserved; every remaining script invocation keeps its ${CLAUDE_PLUGIN_ROOT} form.

### Discovered Insights

- **Insight**: Two smoke-test pins now point at relocated prose (report's `## Handoff` template block, and index-order checks) — the rules live in reference/ files, not the SKILL.md the tests read.
  **Context**: Retargeting them is the pare-tests ticket's scope in this same unit, with the agents' deletion lists as the map of what moved versus what retired.
- **Insight**: A referenced section heading is the real floor under a SKILL.md's size — the cut bottomed out where commands, hooks, docs and tests name sections by identity.
  **Context**: Future growth should extend reference/ files, never the SKILL.md, which is now mostly an index plus hard rules.
