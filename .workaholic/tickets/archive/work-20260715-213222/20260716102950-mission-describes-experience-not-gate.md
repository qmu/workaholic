---
created_at: 2026-07-16T10:29:50+09:00
author: a@qmu.jp
type: refactoring
layer: [Domain]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
---

# A mission describes the experience it demands, not a gate fixed at kickoff

## Motivation

The mission schema puts its weight in the wrong place. `gate_type` / `gate_target` / `gate_assert` are declared at creation — before any of the work exists — and `mission/SKILL.md` calls them "the mission's own quality gate … the objective 'is the outcome good?' check". `20260716012845` would have gone further and made interrogating them **mandatory** at kickoff, with a gate row demanding all three be non-empty.

The developer's judgement, 2026-07-16, verbatim:

> *"Claude Code has a tendency to stick with the quality gate defined at the very beginning of the mission. We don't need a lot of quality gates for the mission right now like we used to have. Because during the course of a mission, we often change the quality gate, making a heavy upfront quality gate somewhat nonsensical. Instead, what we should describe in a mission is the user experience, the demanded behavior, or the overall structure. We need fewer quality gates and more of a plan or tickets to make the mission complete."*

Two failures are named there, and they are different. The first is **staleness**: a gate fixed at kickoff is a prediction about work nobody has done yet, and it goes stale as the mission learns — but it stays in the file, and an agent keeps steering by it. The second is **misplaced weight**: a `gate_target` route and a one-line assert are a thin, brittle proxy for what a mission is actually *for*, which is a demanded experience and behavior. A route that returns 200 is not evidence the experience is right.

The evidence that the gate is not carrying its weight is already in the corpus, unprompted: **every mission created to date has all three fields empty** (`20260716012845` says so plainly), and `20260716021000` measured that `gate.sh` *"can never resolve the ports of a mission living in its own worktree"* — the prescribed layout. So the mission gate is a field nobody fills, read by a script that cannot work in the one place it is meant to run. It has been inert since it shipped, and nothing broke — which is the strongest available evidence about how much it was carrying.

The durable content is what the developer named: the **experience/behavior/structure** the mission demands, plus a **plan of tickets** that gets there. The mission already has a plan mechanism — `## Acceptance`, whose items name tickets by `(#<filename>)` — so the plan is not missing; the *experience* is, and the gate is crowding it out.

This is deliberately **not** a change to per-ticket `## Quality Gate` sections, which stay mandatory and machine-checked (`e12448d4`). Those get *more* load-bearing as `/drive` stops asking per ticket: a ticket gate is written when the work is understood and is the bar an unattended run holds itself to. A mission gate is written before anything is understood. Do not conflate them while implementing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the schema lives in `mission/SKILL.md` and the scaffold in `create.sh`; no new home.
- `workaholic:implementation` / `policies/coding-standards.md` — `create.sh` keeps its contract as the single scaffold writer; the schema it writes and the schema documented cannot diverge.
- `workaholic:implementation` / `policies/objective-documentation.md` — the experience description must stay **verifiable** prose, not aspiration: "the list reorders without a reload" is checkable, "feels fast" is not. The gate's one virtue was objectivity, and dropping the gate must not drop that.
- `workaholic:design` / `policies/history-structures.md` — the mission is the durable narrative; what it records is what a later session reads to know where the work is heading.
- `workaholic:planning` / `policies/modeling-centric-design.md` — a mission should carry a **structured model** of the demanded behavior, which is precisely what a route-plus-assert gate is not.
- `workaholic:implementation` / `policies/test.md` — the boundary condition: a mission with no gate must still compute progress and still surface in the lens and summary.

## Implementation Steps

1. **Add `## Experience` to the mission body**, between `## Scope` and `## Acceptance`. It records what the developer named: the **user experience**, the **demanded behavior**, and/or the **overall structure** the mission pursues. Scaffold it in `create.sh` alongside the other sections, and document it in `mission/SKILL.md`'s body-sections list as the section that carries the mission's substance. Keep it objective per `objective-documentation` — describe behavior that can be observed, not qualities that cannot.
2. **Demote `gate_*` to optional, and say why in the schema.** Keep the fields (a mission that genuinely has a stable, objective outcome check should still be able to declare one, and `gate.sh` still reads them), but `mission/SKILL.md`'s *Quality gate* section must stop presenting them as the mission's "is the outcome good?" answer. State plainly: empty is the **normal** case, not a defect; a gate declared at kickoff predicts work that does not exist yet and goes stale as the mission learns; the durable content is `## Experience` plus the ticket plan. Record that every mission to date left all three empty.
3. **Do not interrogate the gate at creation.** This ticket fixes the schema; `20260716012845` owns the interrogation and is being re-aimed to ask about experience/behavior/structure and the ticket plan instead of the gate. Make sure the two agree — a schema that says "optional" and an interrogation that demands all three is exactly the drift this repo keeps paying for.
4. **Docs in the same change**: `mission/SKILL.md` (schema block, body sections, *Quality gate* section), CLAUDE.md's mission-model prose (which describes the gate as the mission-level "is the outcome good?" check), and `README.md` if it states the same.
5. `node scripts/build-plugins/build.mjs` — `mission/SKILL.md` and `create.sh` are bundled (**six copies** of the scripts). Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria** (assertions in `scripts/test-workflow-scripts.mjs`, hermetic temp repos, driving the real `create.sh`):

| case | must hold |
| --- | --- |
| A mission scaffolded by `create.sh` | has a `## Experience` section, positioned between `## Scope` and `## Acceptance` |
| The scaffold's `gate_*` fields | still present and still empty — this change does not remove them |
| A mission with **empty** `gate_*` | is fully functional: `progress.sh` computes, `summary.sh` reports it, the lens surfaces it (subject to its existing gates). An absent gate is never an error anywhere |
| `gate.sh` on a mission with empty `gate_*` | unchanged behaviour — no regression |
| Existing missions (no `## Experience`) | are **not** retro-broken: every reader still works on a mission written before this change |
| `mission/SKILL.md` | documents `## Experience` as the mission's substance and `gate_*` as optional-and-normally-empty; no doc still calls the gate the mission's "is the outcome good?" check |

**Verification method:** hermetic temp repos driving the real scripts, plus a `doc-drift`-style read of the three docs. No network.

**The gate:** every row; full suite green, 0 failed; `posix-lint` conforming; `verify.mjs`, `validate-metadata.mjs` pass; `git status --porcelain outputs/` shows only this change's intended diff after a rebuild.

**Watch it fail first:** back up `create.sh`, revert it alone (never `git stash` — it takes the tests away and the check passes vacuously; and never revert **uncommitted** work, which has no HEAD to return to), confirm the `## Experience` assertions go red, restore from the backup.

## Considerations

- **Do not delete `gate_*`.** The ticket is about weight, not existence: a mission with a genuinely stable outcome check should keep the option, and `gate.sh` plus `20260716021000` still read the fields. Deleting them would also strand the `carried` inheritance path (`a027cd1b`) that copies them to a successor.
- **`## Experience` must not become a second Goal.** `## Goal` is the business "why"; `## Experience` is the demanded behavior/structure — what the thing does, not why it is worth doing. If the distinction cannot be held in the SKILL's own wording, say so rather than shipping two sections nobody can tell apart.
- The mission gate's one real virtue was that it was **objective** — a named route and an asserted condition, never "looks good". `## Experience` is prose and loses that enforcement automatically. Do not pretend otherwise: state the objectivity requirement in the SKILL and accept that it is a convention, not a check.
- Related and separate: `20260716021000` fixes `gate.sh`'s port resolution. That bug is real whether or not gates are de-emphasised, and this ticket does not close it.

## Final Report

Development completed as planned. Every gate row holds.

`## Experience` is scaffolded between `## Scope` and `## Acceptance` and documented as the mission's substance; `gate_*` is demoted to optional-and-normally-empty in the schema, with the reasoning recorded rather than asserted. The **Considerations' distinction was holdable**: `## Goal` says *why the work is worth doing*, `## Experience` says *what the thing does*. That sentence is now in the SKILL, because a distinction that cannot be stated in one line ships as two sections nobody can tell apart.

**The gate is demoted, not deleted** — deliberately. `gate.sh` still reads the fields, the `carried` inheritance path (`a027cd1b`) still copies them to a successor, and a mission with a genuinely stale-proof outcome check can still declare one. What changed is where the weight sits.

**Four docs stated the old rule and all four moved in this commit**: `mission/SKILL.md` (schema block, body sections, and the *Quality gate* section, retitled to say optional), `drive/SKILL.md` (which told the implementer the gate was "the mission-level 'is the outcome good?' check on top of the per-ticket gate"), and `gate.sh`'s own header. CLAUDE.md turned out **not** to carry the claim — I grepped rather than assumed, which is why it is not in the diff.

The `drive/SKILL.md` change is the one that matters most in practice: it is what an implementing session actually reads per ticket. It now says that when a mission declares no gate — the common case — the implementer reads the mission's `## Experience` and judges the change against the behavior it demands. Without that, demoting the gate would have left `/drive` with *nothing* to check a mission-related change against, which would have been strictly worse than a stale gate.

### Discovered Insights

- **Insight**: The strongest argument for this change was already in the corpus and nobody had read it as an argument. **Every mission ever created left all three `gate_*` fields empty**, and `gate.sh` cannot resolve ports in the one layout the gate is specified to run in (`20260716021000`). The gate has been inert since it shipped and nothing broke.
  **Context**: That is not a side note — it is the measurement. A feature that is universally unfilled and structurally unrunnable, in a repo that otherwise notices everything, is telling you what it is worth. The lesson generalizes: before defending a mechanism on design grounds, check whether anyone has ever used it. Two independent tickets had each recorded half of this and neither drew the conclusion.

- **Insight**: Demoting a check is only safe if something replaces what it was checking. The gate's one real virtue was **objectivity** — a named route plus an asserted condition, never "looks good" — and `## Experience` is prose, which loses that automatically.
  **Context**: The honest position, now written into the SKILL, is that objectivity survives as a **convention rather than a check**: describe behavior that can be observed. Pretending prose is enforceable would be the failure; so would dropping the requirement silently because it is no longer machine-checked. Note the asymmetry with the per-ticket `## Quality Gate`, which went the other way this same session (`e12448d4`) — it became *more* enforced, because a ticket gate is written when the work is understood.

- **Insight**: The gate lived in more places than the schema. The claim "this is the mission-level 'is the outcome good?' check" appeared in `drive/SKILL.md` and in `gate.sh`'s header — neither of which the ticket's step 4 listed, and one of which is the file an implementing session actually reads.
  **Context**: A demotion that updates the schema but leaves the consumer's prose intact changes nothing where it counts: `/drive` would have kept steering by a gate the schema now calls optional. When changing what a field *means*, grep for the sentence rather than the field name — the assertion travels further than the identifier.
