---
created_at: 2026-08-10T09:01:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split
merge_policy:
---

# Scope QA, release-planning, and post-release quality-check loops

## Overview

FB `20260810090035` names three complementary loops the auto-merge policy
depends on as its safety net — a QA loop, a release-planning loop, and a
post-release quality-check loop — but does not design any of them; per the
propose skill's own bar ("vague, a direction nobody can start" → record-only
if attempted as a mission today), they are not yet decomposable into
tickets. This ticket does not implement the loops. It writes one scoped
feedback record per loop (kind: `insight`, each naming what the loop would
watch, when it would run, and what "done" looks like at a first-pass level)
so each can become its own `/propose`/`/mission` session's input later,
instead of the intent living only in this ticket's prose or being silently
dropped once this mission is driven.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:planning` / `policies/project-initiation.md` — scoping new work streams before design begins
- `workaholic:development` / `policies/managing-change-history.md` — the feedback stream as the durable record of this direction

## Key Files

- `.workaholic/feedbacks/` — where the three scoped records land (via `workaholic:feedback`'s `create.sh`, the only sanctioned writer)
- `docs/loop-engineering-workflow.md` — cross-reference point for how these loops relate to the existing propose/drive/ship loops

## Implementation Steps

1. For each of the three loops, write a scoped `kind: instruction` feedback
   record (not `insight` — each is an ask, not an observation) stating: what
   it would watch or trigger on, roughly when it would run relative to the
   existing propose → implement → ship → release-cut sequence, and what a
   first, minimal version of "done" looks like — concrete enough that a
   later `/propose` run does not read it as "vague, a direction nobody can
   start."
      - QA loop: what does it check, and against what (the `release/*`
        branch? every merge to `main`? something else)?
      - Release-planning loop: what does "plan the release" mean here — is
        it the existing `/ship` §6 promotion confirmation, or a new agent
        role?
      - Post-release quality-check loop: what does it check once something
        is actually in production, and what does it do if it finds a
        problem?
   2. Do not scaffold missions for any of the three in this ticket — that is
      deliberately left to a later `/propose`/`/mission` session once each
      is concrete enough to meet the ticket floor and the judgment bar.
   3. Cross-reference the three new feedback records from the branch-model
      documentation ticket (the companion ticket in this mission), so a
      reader following the auto-merge change finds the safety-net plan.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Three feedback records exist, one per named loop, each concrete enough that a `/propose` run reading it would not have to answer "what does this loop actually do" from scratch.
- None of the three loops is implemented or half-implemented by this ticket — it is scoping only.

**Verification method** — the commands/tests/probes that prove them:

- Read each of the three records against the propose skill's judgment bar (`workaholic:propose`, *The judgment bar*) and confirm none reads as "vague, a direction nobody can start."

**Gate** — what must pass before approval:

- The three records are cross-linked from the companion branch-model ticket/doc so they are discoverable, not just written.

## Considerations

- This ticket is deliberately scoping, not designing — attempting full mission decomposition for all three loops in one pass risks the same "vague, unsure" outcome the propose bar warns against; better to scope now and decompose each separately once its shape is clearer.
- The QA loop and post-release quality-check loop may turn out to overlap significantly (both are "check quality," differing mainly in timing) — flag this explicitly in the two records rather than silently merging them, so a human decides whether they are really one loop or two.
