---
created_at: 2026-08-14T06:45:13+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: give-propose-a-strategy-artifact-form
merge_policy:
---

# Add the Strategy form to /propose's judgment and emit path

## Overview

PROPOSED. `/propose`'s judgment names exactly three forms today (`propose/SKILL.md`,
*The form follows the work's shape*): mission with its ticket set, one loose ticket,
or the record alone. The ask adds a fourth — **Strategy** — so a dated, owned
direction that carries no executable plan stops being forced into a mission it cannot
decompose or into record-only silence. The artifact and its only writer already exist
(`workaholic:strategy`, `strategies/scripts/create.sh`, `validate-strategy.sh`), so
this ticket is the *selection rule* plus the emit path inside the publish tree — not a
new artifact.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` — *The form follows the work's shape* is the three-row table this ticket makes four, plus the judgment bar that selects it.
- `plugins/workaholic/skills/propose/reference/workflow.md` — steps 7–9 decide the form and scaffold; the strategy path is a new branch there.
- `plugins/workaholic/skills/strategy/SKILL.md` + `scripts/create.sh` — the artifact's model and its only writer; `create.sh` refuses an empty aim, empty assignees, a non-`YYYY-MM-DD` `target_date`.
- `plugins/workaholic/hooks/validate-strategy.sh` — the write-time floor a proposal-written strategy must clear.
- `CLAUDE.md` (`/propose` row, the Strategy bullet) and `plugins/workaholic/rules/workaholic.md` — the operator-authored sentence lives here and must move in the same commit.

## Implementation Steps

1. Write the selection rule before any code: what makes an ask strategy-shaped rather than mission-shaped — a direction with a **date** and an **owner** and **no decomposable plan**. State the precedence against the other three forms explicitly, since a vague direction is record-only today and must not silently become a strategy instead.
2. Resolve the `target_date` and `assignees` question the artifact forces: `create.sh` refuses both when empty, and `/propose` may not fill an assignee from the running identity — the triggering issue's assignee is the only sanctioned source, and an unassigned issue therefore cannot produce a strategy. Record what happens then (fall back to record-only, naming the reason).
3. Add the strategy branch to `reference/workflow.md` step 9, writing through `strategy/scripts/create.sh` inside the publish tree — never Write/Edit the file directly.
4. Extend the PR-body and step-13 report vocabulary so the chosen form is named ("strategy" beside mission / loose ticket / record-only), and keep the `[Proposal]` title prefix unchanged.
5. Update `CLAUDE.md`, `rules/workaholic.md` and `docs/proposal-loop-runbook.md` in the same commit — including the "no command, hook or routine writes one" sentence, whichever way the Open Decision below is resolved.
6. Regenerate `outputs/` (`node scripts/build-plugins/build.mjs`) and run the local verification set.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `propose/SKILL.md` names four forms with a written condition selecting each, and the strategy row states why it is not a mission.
- A strategy-shaped ask emits a `.workaholic/strategies/<slug>.md` that passes `validate-strategy.sh` inside the proposal PR.
- An ask with no resolvable assignee does **not** emit a strategy, and the run reports the reason.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && git diff --exit-code outputs/`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The three commands above pass and the Open Decision below is resolved in writing, not silently.

## Considerations

- Strategy carries no ticket plan, so a strategy-only proposal publishes no executable work. That is the artifact's design, but it means the mission ticket floor has no analogue here — nothing stops a run from emitting strategies indefinitely. A stated bar (a strategy is emitted only for an ask that names a date and an owner) is the only brake.
- `create.sh` refuses empty `assignees`, which is the one artifact where empty is a refusal rather than team-owned. `/propose`'s standing rule forbids substituting the running identity, so the two rules meet exactly at an unassigned issue — step 2 above exists for that intersection.

## Open Decisions

- **Does `/propose` become a strategy writer at all?** `workaholic:strategy`, `CLAUDE.md` and `rules/workaholic.md` all state the artifact is operator-authored and that "no command, hook or routine writes one" — written 2026-08-13, one day before this ask. Two readings, and this session cannot recommend one: **(a)** the rule is widened — `/propose` may write a strategy, because the proposal only reaches `main` when the operator merges the PR, which is the same approval a mission gets; **(b)** the rule holds — `/propose` never writes the file, and a strategy-shaped ask instead produces the record plus a named recommendation the operator turns into a strategy by hand. The driving session must resolve this explicitly and record the resolution in its Final Report; do not infer it from the ask's framing.

## Final Report

Development completed as planned.

### Open Decision resolved

**Does `/propose` become a strategy writer at all?** — resolved as **(a), repaired**:
the rule is widened by exactly one clause, and the clause carries its own price.
`/propose` may **draft** a strategy into its proposal pull request, and **a proposal
carrying a strategy never auto-merges**.

The reasoning, and why neither side was taken as written:

- **(a) as stated is defeated by a checkable fact.** Its justification is "the proposal
  only reaches `main` when the operator merges the PR, which is the same approval a
  mission gets". That premise stopped being true on 2026-08-11, when propose pull
  requests began auto-merging on open (`WORKAHOLIC_AUTO_MERGE=1`). Taking (a) verbatim
  would land a machine's reading of an inbound ask on `main` as the operator's resolved
  decision with nobody having decided it — and `strategies/` would become a second
  inbound stream, the exact drift the artifact's own definition names ("two homes for
  direction only drift when both are inboxes; only one of these is").
- **(b) holds the definition but under-delivers.** Never writing the file would leave the
  fourth form as prose-only advice, and the mission's `## Experience` — a dated, owned
  direction coming out of `/propose` "as a strategy in the proposal PR" — unmet.
- **The repair restores the premise (a) needs instead of arguing about it.** Suppressing
  auto-merge for the strategy form makes the operator's merge the act that authors the
  artifact, which is precisely what "operator-authored" was protecting. The mechanism
  already exists — a release-scan finding is the one thing that leaves a propose PR open
  — so this adds a second reason, not a new mechanism.
- **What deliberately did not move**: `create.sh` stays the only writer, `close.sh` the
  only writer of an end state, `/drive` still never surveys a strategy, and the citation
  link still runs strategy → feedback only.

Two things were weighed and found not to decide it: the mission's `## Experience` wording
(a `/propose` draft that auto-merged, so not an operator approval), and the ask's own
framing (subject `observer_ai:claude[bot]` — an AI observer's suggestion, not the
developer's instruction). The resolution rests on the auto-merge fact, not on either.

### Discovered Insights

- **Insight**: The 2026-08-11 auto-merge change silently invalidated an argument the
  rest of the repository still leans on — "approval by merge" (K1). Any rule whose
  justification is "a human merges the PR" needs re-checking against which flow it sits
  in: `/propose` PRs merge themselves, `/drive`'s `review` units merge themselves too.
  **Context**: this ticket's Open Decision was written one day after the auto-merge
  landed and still cited approval-by-merge as live. Expect the same stale premise
  wherever a decision record predates 2026-08-11 but reads as current.
- **Insight**: `hooks/validate-strategy.sh` grandfathers git-tracked files, and
  `strategy/scripts/create.sh` runs `git add` on what it writes — so validating a
  freshly-created strategy passes trivially through grandfathering unless the file is
  un-staged first. **Context**: any test asserting the write floor actually holds must
  test an untracked file, or it proves nothing.
