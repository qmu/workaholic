---
created_at: 2026-07-22T08:14:07+09:00
author: a@qmu.jp
type: enhancement
layer: [UX]
effort: 1h
commit_hash:
category: Added
depends_on: 20260722081406-mission-readiness-session.md
mission:
---

# /mission closes with a strategy gap discussion

## Overview

Second half of the developer's stated `/mission` expectation (2026-07-22): once the readiness session (dependency ticket) has every assigned mission drive-ready, the conversation should turn **upward** — are the missions *sufficient* for the active strategies? A strategy is direction with no completion conditions; what keeps it moving is a stream of missions executing it. `/mission` is where that sufficiency gets examined:

1. **Gap survey** — after the readiness reconciliation, read the active strategies (`strategy/scripts/list.sh`, whose `missions` rollup is computed) and mark each strategy with **no active mission advancing it** — the objective gap signal. A strategy whose only missions are archived is exactly the case to surface.
2. **Discussion, not automation** — for each gap (or when the developer says the plan feels thin), open a short discussion: ground candidate next missions in the strategy's `## Direction`, the recent mission `## Reflection` entries (`list-reflections.sh` — what the last runs said to front-load), and the archived missions' outcomes. Propose concretely ("a mission that …"), let the developer shape or reject.
3. **Hand-off into creation** — an agreed candidate flows straight into the existing mission-creation flow (`/mission "<title>"` semantics inline: worktree, interrogation, ticket set, `strategy:` stamp) without leaving the conversation. Nothing is created that was not agreed in the discussion.

## Policies

- **Design / self-explanatory-ui** — a strategy with no active mission is presented as a *claimable gap* with its Direction quoted, so the developer decides from substance, not a bare slug.
- **rules/interaction.md (decide-and-record)** — the gap survey is act-and-report (no prompt to run it); only the actual "launch this mission?" fork is the developer's question, and it arises from the discussion, not a menu.
- **Planning pillar** — mission proposals must trace to the strategy's stated Direction (why before what); the reflection feedback loop (`front-load next:`) is the evidence base the proposals cite.
- **Compute-don't-store** — sufficiency is derived per run from the strategy rollup; no stored "coverage" number.

## Key Files

- `plugins/workaholic/commands/mission.md` — append the gap-discussion step after the readiness reconciliation in the bare-argument session.
- `plugins/workaholic/skills/mission/SKILL.md` — document the sufficiency examination and its grounding sources (Direction, reflections, archive outcomes); built → rebuild `outputs/`.
- `plugins/workaholic/skills/strategy/SKILL.md` — cross-reference: the strategy side documents that `/mission` is where sufficiency is examined (strategies are never interrogated themselves).
- `plugins/workaholic/skills/strategy/scripts/list.sh` — expected sufficient as-is (computed `missions` rollup); extend additively only if the rollup lacks status split (active vs archived missions per strategy).

## Related History

- Strategy layer shipped v1.0.99 (`work-20260721-025656`): strategy artifact, mission `strategy:` relation, reflections (`append-reflection.sh` / `list-reflections.sh`) — the machinery this discussion reads.
- `20260722081406-mission-readiness-session.md` (dependency) — this step runs only after readiness, so the discussion is about *next* work, not rescuing current work.

## Implementation Steps

1. Add the gap survey + discussion step to the bare-`/mission` session prose, reading `strategy/scripts/list.sh` and `list-reflections.sh`.
2. If the strategy rollup cannot distinguish active from archived missions, extend `list.sh` additively (POSIX sh; existing keys unchanged).
3. Update both SKILL.md files, CLAUDE.md/README `/mission` rows; rebuild `outputs/`; run the verification suite.

## Quality Gate

- `node scripts/test-workflow-scripts.mjs` green; if `strategy/list.sh` is extended, hermetic fixtures pin the additive fields (a strategy with only archived missions reports the gap distinguishably).
- `node scripts/build-plugins/build.mjs` then clean `outputs/` porcelain; `verify.mjs` + `validate-metadata.mjs` pass.
- Doc truthfulness: the session's full arc (status → replans → reconciliation → gap discussion → optional creation → the `/goal /monitor ok` hand-off, never `/drive`) reads identically in command prose, mission SKILL.md, and the strategy SKILL.md cross-reference.
- No automation creep: the implementation must not auto-create missions or tickets from the gap survey — creation happens only through the agreed hand-off (assert in prose; record the check in the Final Report).

## Considerations

- An unassigned-but-active mission advancing a strategy is not a gap — the gap signal is "no *active* mission", not "no *mine*"; claiming unassigned work is the readiness session's territory.
- If every strategy is covered and the developer has nothing to add, the step is one sentence ("all strategies have active missions") — it must never pad the session.

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: The gap signal is "no *active* mission", which the existing `missions` rollup (active + archived merged) could not express — a strategy whose only missions are archived looked covered. The fix was an additive `active_missions` field, keeping `missions` for backward compat.
  **Context**: A strategy is "covered" only while something is currently advancing it; a computed active-subset rollup is the honest sufficiency measure, and it stays computed (never stored) like everything else on the strategy side.
