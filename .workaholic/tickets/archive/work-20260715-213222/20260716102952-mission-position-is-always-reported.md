---
created_at: 2026-07-16T10:29:52+09:00
author: a@qmu.jp
type: enhancement
layer: [UX, Domain]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# Every handoff states where the mission stands and what carries

## Motivation

The developer, 2026-07-16:

> *"Even before and after carrying things, Claude Code always needs to mention where we are at in the mission and what to carry. In another Claude Code session, how much can we proceed with the mission? So that's the mission-centralized behavior I expected."*

The mission is meant to be the thing a developer reasons in — the durable narrative of where a body of work is heading and how far it has come. The pieces to say that already exist and are already computed: `progress.sh` gives `checked/total`, `next-acceptance.sh` gives the next step, `summary.sh` and the mission lens surface both. What is missing is the **obligation to say it at the moments that decide continuity**.

Those moments are handoffs, and there are two:

- **`/carry`** — its entire purpose is handing in-progress work to a fresh session, and it is the literal answer to *"in another session, how much can we proceed with the mission?"*. Yet its resumption ticket is written around the work in flight; nothing requires it to state the mission's position, or how far the successor session can get. A resumption ticket that says what to do next but not where it sits in the mission hands over a task, not a mission.
- **`/mission close`** — already fixed for the carry path (`a027cd1b` requires stating where the mission stands before asking, and what moves to the successor). That is one instance of the general rule; this ticket generalises it rather than leaving it as a one-off.

The failure this prevents is the one the corpus keeps demonstrating: **context that lives only in a session dies with it**. `e81d561c` shipped a known defect because the observation reached a story and no ticket. The same shape applies to mission position — if a session knows the mission is 3/7 with the next step blocked on a decision, and hands over a ticket that says only "continue the refactor", the next session rediscovers all of it.

The lens already does this **continuously** and non-forcingly on every prompt. The gap is not the steady state; it is the discontinuity — the moment work moves between sessions, which is exactly when the lens's context is lost.

## Policies

- `workaholic:design` / `policies/history-structures.md` — the handoff artifact is where "who changed what, when, and where it stands" either survives the session boundary or does not.
- `workaholic:implementation` / `policies/objective-documentation.md` — position is stated as computed fact (`checked/total`, the named next item), never a narrative impression. There is a script for this; use it.
- `workaholic:implementation` / `policies/domain-layer-separation.md` — "where does the mission stand" is domain logic with existing readers (`progress.sh`, `next-acceptance.sh`, `read-relation.sh`). No consumer re-parses frontmatter to answer it.
- `workaholic:design` / `policies/modeless-design.md` — this is reporting, not a prompt: it must never become a confirmation step. The developer asked for *less* confirmation, not more.
- `workaholic:development` / `policies/overnight-ai.md` — the point of writing judgment down is that the next run does not stop to rediscover it.
- `workaholic:implementation` / `policies/directory-structure.md`, `policies/coding-standards.md` — apply to all code work.

## Implementation Steps

1. **Make it one rule, in one place.** Write the *mission position report* into `mission/SKILL.md` as a named, reusable convention: what it contains and which scripts produce it — `checked/total` from `progress.sh`, the next unchecked item from `next-acceptance.sh`, and **how far a fresh session can proceed** (what is ready to drive now, and what is waiting on a decision or an external blocker). Every seam refers to this one definition; none re-states it.
2. **`/carry` states it.** The resumption ticket must open with the mission position when the work carries a `mission:` relation (read via `read-relation.sh` — the relation is **many-valued**, so report every mission it advances, not the first). It must answer the developer's question explicitly: how much of the mission can the next session proceed with, and what stops it. When there is no mission relation, say nothing — do not fabricate a mission-shaped frame around unrelated work.
3. **`/mission close` already does this** (`a027cd1b`). Re-point its prose at the step-1 definition instead of restating it, so the two cannot drift.
4. **Decide, and record, whether `/report` and `/ship` join.** They are the other seams that end a body of work, and both already roll missions. There is a real argument they should state position too, and a real argument that the PR story is a different audience. Decide deliberately; do not let it default. If they join, they use the same step-1 definition.
5. **Docs in the same change**: `carry/SKILL.md`, `mission/SKILL.md`, CLAUDE.md's `/carry` row (which describes it as writing a resumption ticket, with no mission dimension), and `README.md` if it says the same.
6. `node scripts/build-plugins/build.mjs` — `mission/SKILL.md` is bundled; check whether `carry` is in `DEFAULT_TARGET` before assuming its footprint. Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria:**

| case | must hold |
| --- | --- |
| `/carry` on work carrying `mission: <slug>` | the resumption ticket states `checked/total`, the next unchecked item, and what a fresh session can proceed with |
| `/carry` on work carrying **two** missions (`mission: [a, b]`) | **both** are reported — the relation is many-valued and is read through `read-relation.sh` |
| `/carry` on work with **no** mission relation | reports no mission position; nothing is fabricated |
| Position figures | come from `progress.sh` / `next-acceptance.sh` — no consumer re-derives them by parsing frontmatter |
| A mission with an empty `## Acceptance` (`0/0`) | is reported honestly as having no criteria yet, rather than as `0/0` with a missing next step (the lens's signal gate silences this case; a handoff must not, because "the mission has no criteria" is exactly what the next session needs to know) |
| Nothing added to any seam | issues an `AskUserQuestion` — this is reporting, not confirmation |
| `/mission close`'s existing behaviour (`a027cd1b`) | still holds, now sourced from the shared definition |

**Verification method:** hermetic temp repos with fabricated missions (partially-checked, empty-acceptance, two-mission relation) driving the real readers. The seam prose is verified by driving a real `/carry` against a seeded mission — state which rows are script-asserted and which are driven.

**The gate:** every row; full suite green, 0 failed; `posix-lint` conforming; `verify.mjs`, `validate-metadata.mjs` pass; rebuild clean.

**Watch it fail first:** back up any touched script, revert it alone, confirm the position assertions go red, restore from the backup.

## Considerations

- **The `0/0` row is the interesting one, and it inverts the lens's rule deliberately.** The lens stays silent on a mission with no acceptance criteria because an always-on nudge with nothing to act on is noise. A handoff is the opposite: "this mission has no criteria written yet" is precisely what the next session must know. Do not copy the lens's signal gate here — and say why in the skill, or someone will "fix" the inconsistency later.
- **Do not turn a report into a prompt.** The developer asked for less confirmation. If stating position tempts a "shall I continue?", that is the ticket failing.
- `/carry` is capture-only by design. This adds to what it captures; it must not make `/carry` do more.

## Final Report

Development completed as planned. The **Mission Position Report** is defined once in `mission/SKILL.md`; `/carry` and `/mission close` both source it rather than restating it.

**Step 4's decision, made rather than defaulted: `/report` and `/ship` do NOT join.** Both roll missions, so including them was arguable — but the report exists for **continuity across a session boundary**, and neither crosses one. Their audience is the PR reviewer, the story's own sections already say what landed, and adding mission position there would duplicate `/catch` and the lens for a reader who did not ask. Recorded in the skill with the trigger to revisit: if a reviewer ever has to ask "which mission is this?", the decision was wrong.

**The measurement that made this ticket obvious**: `carry/SKILL.md` mentioned missions **zero times**. The command whose entire purpose is answering *"in another session, how much can we proceed?"* had no mission dimension at all — it handed over a task. The resumption ticket now carries the `mission:` relation forward too, not just the prose: without it the next session cannot roll the mission either, and the relation would die at exactly the boundary this ticket exists to survive.

**Step 6's footprint check paid off**: `carry` is **not** in `build.mjs`'s `DEFAULT_TARGETS`, so `carry/SKILL.md` has no `outputs/` footprint — verified rather than assumed, and the rebuild touched only the bundled `mission/SKILL.md`.

### Discovered Insights

- **Insight**: The `0/0` rule **inverts the lens's signal gate on purpose**, and that inconsistency is the most fragile thing in this change. The lens stays silent on a mission with no acceptance criteria because an always-on nudge with nothing to act on is noise; a handoff must say it loudly, because *"the plan does not exist yet"* is the difference between "drive the queue" and "there is no queue".
  **Context**: Two readers of the same field, with deliberately opposite thresholds, is exactly the shape someone later "fixes" into consistency. So the skill states the divergence *and* the reason, and a test asserts the sentence is still there. The general lesson: when two consumers of one fact must disagree, the disagreement itself needs a home in the docs and a test — otherwise it reads as drift and gets normalised away. (This is the third such deliberate divergence in the mission model, alongside `/mission summary`'s lower assignee bar.)

- **Insight**: The whole feature is prose, and prose that nobody asserts is prose that quietly disappears. There is no script to write here — every figure already had a reader (`progress.sh`, `next-acceptance.sh`, `read-relation.sh`), which is precisely why the gap was *an obligation*, not a capability.
  **Context**: So the assertions pin the **rules** by regex against the skills: the definition exists, it answers the continuity question, it is a report and never a prompt, the `0/0` inversion is justified, the no-mission case fabricates nothing, and the template carries the relation. A future edit that quietly deletes any of them turns a test red. That is the honest ceiling for a prose feature — and it is worth more than the "watch it fail first" step the gate asked for, which does not apply when no script changed.

- **Insight**: The failure being prevented is the same one that produced three other tickets in this batch: **context that lives only in a session dies with it**. A defect written into a story shipped anyway (`e81d561c`); a problem met mid-run reached only a Final Report (`2666cea9`); and a mission's position reached only the developer's head.
  **Context**: Each was fixed by moving the fact into a structure that carries an obligation — a ticket, a queue entry, a resumption ticket. The mission model's value is entirely that it survives the session; every seam that does not state position is a place where it silently does not.
- Related: `20260716102950` moves the mission's substance into `## Experience`. If that lands first, the position report should say whether the demanded experience is met — but do not couple the tickets; each stands alone.
