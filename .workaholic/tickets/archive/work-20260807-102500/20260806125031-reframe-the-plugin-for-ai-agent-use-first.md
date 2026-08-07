---
created_at: 2026-08-06T12:50:31+00:00
author: noreply@anthropic.com
assignees: [noreply@anthropic.com]
type: housekeeping
layer: [Config]
effort:
commit_hash:
category: Changed
depends_on:
mission: slim-commands-skills-and-docs-for-ai-agent-use
merge_policy:
---

# Reframe the plugin for AI-agent use first

## Overview

<!-- PROPOSED. Sharpened by the mission's approval interrogation. -->

FB item 5: shift the plugin's primary audience from developers to AI agents
(Claude Code Web Routine and the like), with developer use kept but secondary.
This is a framing change across the top-level narration — README and CLAUDE.md
intros, the way commands/skills describe who runs them — so the docs address the
agent as the main reader and the developer as the secondary one. It pairs with the
doc-restructure ticket and should land consistently with it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `README.md` — the audience framing at the top.
- `CLAUDE.md` — the opening description and design principles.
- `plugins/workaholic/skills/*/SKILL.md` — where "a developer types…" framing should become agent-first.

## Implementation Steps

1. Identify the passages that assume a developer as the primary actor.
2. Reframe them agent-first, keeping developer use as the secondary path.
3. Ensure the routines (the agent surface) are presented as the primary use.
4. Reconcile with the doc-restructure so the framing is consistent throughout.

## Quality Gate

**Acceptance criteria:**

- README and CLAUDE.md present AI-agent use as primary, developer use as secondary.
- No passage still implies the developer is the sole/primary actor.

**Verification method:**

- Manual review of the top-level docs and skill intros.

**Gate:**

- Framing is consistent with the restructured docs; no behavior change implied.

## Considerations

<!-- This is framing, not behavior; keep it from silently changing what commands do.
     The approval interrogation should confirm the boundary. -->

## Final Report

Development completed as planned. README and CLAUDE.md open with the same audience contract — AI agents are the primary users (routines invoking /implement and /propose, sessions running the workflow skills); the developer is the operator (approves PRs, configures routines, steps in when a run defers a decision), with by-hand command use the supported secondary path. The one skill intro naming the developer as sole originator (mission) now names both seams. Frontmatter descriptions were left intact as trigger-matching surfaces, and every "developer" stating a decided behavior contract (PR-merge approval, --developer-present, icebox curation, crossing confirmation) was deliberately untouched — those are behavior, not framing.

### Discovered Insights

- **Insight**: "Operator" was the right second-audience word because the repo already uses it (`deferred_by_operator`, the §2 choice).
  **Context**: Framing vocabulary that reuses existing contract words cannot drift from the contracts.
