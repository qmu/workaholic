---
created_at: 2026-07-16T01:28:45+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 2h
commit_hash:
category: Changed
depends_on: [20260716102950-mission-describes-experience-not-gate.md]
mission:
---

# /mission interrogates once, then emits the whole drive-ready ticket set

## Motivation

`/mission "<title>"` is supposed to produce a mission that is ready to drive. Today it produces an empty shell and asks nothing.

`create.sh` is a POSIX scaffold: it writes frontmatter with **empty** `gate_type`/`gate_target`/`gate_assert`, and `## Goal` / `## Scope` / `## Acceptance` / `## Changelog` as HTML comments. It cannot interrogate and must not — it is `allowed-tools: Bash`. All elicitation is one prose sentence in `commands/mission.md` step 3 — *"work with the developer to fill in `## Goal`, `## Scope`, and the `## Acceptance` checklist … and the mission's quality gate"* — with **no question protocol and no stop condition**. Step 4 then says to run the full `create-ticket` Workflow *"once per kickoff ticket the developer wants to start the mission with"*: the ticket set is whatever the developer happens to name, not something the session determined.

Compare `create-ticket` §4b, which for a *single ticket* is explicit, mandatory, anti-"minimal friction", and enumerates what to pin down. The mission — the larger, information-richer unit — has nothing.

The developer's requirement, verbatim: *"When a user creates a mission, Claude Code should ask the user as many questions as necessary to establish the right direction and determine what tickets are needed to achieve the mission goal … By the end of this mission command session, we should have a complete set of tickets to drive through one by one … all questions must be asked before the drive-over tickets get created."*

This ticket builds that interrogation. It is independently valuable: a fully-interrogated, gate-bearing mission queue is better **even if `/drive` keeps asking per ticket**. It also closes the active concern `missions-are-born-matching-the-lens`, whose prescribed fix is verbatim this — *"the fix belongs in `create.sh` — require or prompt for a first acceptance criterion at creation time"* — because a mission scaffolded with an empty `## Acceptance` renders `0/0` and is invisible to the mission lens.

## Policies

- `planning/modeling-centric-design` — the interrogation must yield a **structured model** (stakeholders, events, data, constraints), not a Q&A transcript hard-coded into tickets. The bar is structure, not question count.
- `planning/verify-before-building` — with no per-ticket gate downstream, an unverified premise is not caught at ticket 3; it is concretized across the whole mission. High-uncertainty areas are proved small before the set is emitted.
- `development/overnight-ai` — "identify in advance the points where AI would want to ask for judgment and write the answers to those questions into the ticket. We eliminate the causes of stopping in the night before the run starts." This is the interrogation's purpose stated as policy.
- `implementation/objective-documentation` — acceptance criteria are recorded as verifiable statements, not intentions.
- `implementation/directory-structure` — the protocol is knowledge and belongs in the skill; the command names the rounds (Thin commands, comprehensive skills).
- `implementation/coding-standards` — any new logic goes in a POSIX `#!/bin/sh -eu` script under `skills/mission/scripts/`, never inline in markdown.

## Implementation Steps

1. **Write the interrogation protocol into `skills/mission/SKILL.md`** (not the command — `commands/mission.md` is already 99 lines and the Design Principle caps it at orchestration). Model it on `create-ticket` §4b: mandatory, explicitly non-skippable, "grill, don't tick a box". Define the rounds it must cover:
   - **Direction** — the business "why", the outcome, what is explicitly out of scope. (`## Goal`, `## Scope`)
   - **The demanded experience** — the user experience, the behavior required, and/or the overall structure the mission pursues. (`## Experience`, added by `20260716102950`.) **This replaces the mission-gate round** — see the amendment below.
   - **The ticket set** — how many tickets, what each covers, the `depends_on` order. This is the question nobody asks today, and it is the round that matters most.
   - **Per-ticket pre-answers** — everything `create-ticket` §4b would have asked later, asked now, per ticket in the set.
   - **Acceptance** — one checklist item per criterion, each naming the ticket that satisfies it.
2. **Have `commands/mission.md` issue the rounds.** All `AskUserQuestion` must be at command/main-agent level (CLAUDE.md One-Level Fan-Out: a subagent cannot ask). "As many questions as necessary" therefore means **multiple sequential rounds** — which §4b already sanctions. A `general-purpose` leaf may *propose* the question set as JSON; only the command may ask. Every question body needs the `[<project label>]` prefix or `guard-askuserquestion-label.sh` rejects it (exit 2).
3. **Respect the ordering constraint.** `## Acceptance` items link tickets by `(#<filename>)` marker, so Acceptance can only be *finalised* once the ticket filenames exist. The requirement "all questions before the tickets are created" is satisfiable — the **writing** order is: questions → ticket set decided → tickets written → Acceptance written naming them. Do not read the requirement as "Acceptance first".
4. **Emit the set in one pass**, not N serial `create-ticket` runs. Each ticket still carries its mandatory `## Policies` and `## Quality Gate`, stamped `mission: <slug>` and ordered by `depends_on`. Reuse `create-ticket`'s split mechanics (unique timestamp +1s, foundation first, dependencies only where genuinely ordered).
5. **Decide the split cap deliberately.** `create-ticket` §4 caps a split at "2-4 discrete tickets" — a real conflict with "a complete set" for a mission-sized goal. A mission decomposition is closer to `trip-protocol`'s Decomposition gate than to a `/ticket` split. Either carve out a mission-scoped exception **and say so in the skill**, or keep the cap and explain why a mission is capped at 4. Do not violate it silently.
6. **Docs in the same change**: CLAUDE.md's `/mission` row and mission-model prose, `README.md`, `.workaholic/README.md`, and `mission/SKILL.md`'s note that "`create.sh` scaffolds `## Acceptance` empty … the fix belongs in `create.sh`" — which this ticket makes stale.
7. `node scripts/build-plugins/build.mjs` — `mission/SKILL.md` and `create.sh` are bundled (**six copies** of the scripts, one per DEFAULT_TARGET). `commands/mission.md` is Claude-only and has no `outputs/` footprint. Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Amendment (2026-07-16) — re-aimed off the mission gate

This ticket was written against the old model, in which a mission declared a quality gate at kickoff. The developer has since ruled that model out, verbatim:

> *"Claude Code has a tendency to stick with the quality gate defined at the very beginning of the mission … during the course of a mission, we often change the quality gate, making a heavy upfront quality gate somewhat nonsensical. Instead, what we should describe in a mission is the user experience, the demanded behavior, or the overall structure. We need fewer quality gates and more of a plan or tickets to make the mission complete."*

So this ticket's **interrogation drops the mission-gate round entirely** and asks instead about the **demanded experience/behavior/structure** and the **ticket plan**. Concretely:

- The `gate_*` round is **removed**, not softened. `20260716102950` demotes those fields to optional-and-normally-empty; an interrogation that demanded all three would contradict the schema it writes into — exactly the code-versus-doc drift this repo keeps paying for.
- The `## Experience` round is **added** (the section `20260716102950` introduces).
- **Gate row 1 below is amended** accordingly: non-empty `## Goal` / `## Scope` / `## Experience` / `## Acceptance` (≥1 item). The `gate_*` clause is struck.
- Everything else stands. The ticket's core value — *interrogate once, then emit the whole drive-ready ticket set* — is unchanged and is what the developer asked for ("more of a plan or tickets"). The per-ticket `## Quality Gate` in each emitted ticket (row 3) is **unaffected and stays mandatory**: it is written when the work is understood, and it is the bar `20260716012847`'s unattended drive holds itself to. Mission gate and ticket gate are different things; do not conflate them while implementing.

**Depends on `20260716102950`** for the `## Experience` section it interrogates into.

## Quality Gate

**Acceptance criteria:**

| # | must hold |
| --- | --- |
| 1 | A mission created through the new flow has **non-empty** `## Goal`, `## Scope`, `## Experience`, and `## Acceptance` (≥1 item). No HTML-comment placeholders survive. (**Amended**: the original clause requiring non-empty `gate_type`/`gate_target`/`gate_assert` is struck — see the Amendment above.) |
| 2 | Every `## Acceptance` item names the ticket that satisfies it, in the `(#<filename>)` form `tick-acceptance.sh` already matches on. |
| 3 | The emitted tickets exist in the worktree's `todo/<user>/`, each carrying `mission: <slug>`, a `## Policies` section, and a **non-empty `## Quality Gate`**. |
| 4 | `depends_on` forms a valid order — the foundation ticket has none; the drive Navigator topologically sorts the set with `cycle_warning: null`. |
| 5 | The mission passes the **lens signal gate** (≥1 acceptance criterion), i.e. it is no longer born invisible. This is the `missions-are-born-matching-the-lens` fix, and closing that concern is part of the gate. |
| 6 | `mission/scripts/gate.sh <slug>` returns `valid: true` with the interrogated values and resolves the worktree's `dev_port`. |

**Verification method.** Hermetic, in `scripts/test-workflow-scripts.mjs`, extending §8f (the existing create-spine test — note it currently **writes the kickoff ticket itself**, because generation is model work, so it proves plumbing, not generation). The script-checkable half is what §8f already does plus criteria 1/2/5/6: assert the *artifacts*. The interrogation itself is model behaviour and is **not** script-testable; prove it by one live `/mission "<title>"` run and inspect the resulting `mission.md` + ticket set against criteria 1–4.

**The gate:** criteria 1–6 hold; one live run produces a set that `/drive` prioritizes without a cycle warning; full suite green; `posix-lint`, `verify.mjs`, `validate-metadata.mjs` pass; `git status --porcelain outputs/` empty after a rebuild.

**Watch it fail first** on the script-checkable half: revert `create.sh` alone via `git checkout HEAD -- <path>` (never `git stash`), confirm the new assertions go red, restore.

## Final Report

Development completed, **as amended**. The ticket was written against the old heavy-gate model; the Amendment above re-aimed it mid-queue and the implementation followed the amendment, not the original.

**Step 5's split-cap decision, made deliberately and recorded** (the ticket forbade a silent violation): the `create-ticket` "2–4 discrete tickets" cap is **carved out for missions**, and the exception is stated in the skill. The cap is right for one request that turns out to be several; a mission is the opposite case — a durable goal that spans *many* tickets **by definition**, where "a complete set to drive through one by one" is the requirement. Capping at 4 would force either an incomplete plan or a fake ticket boundary. A mission decomposition is closer to `trip-protocol`'s Decomposition gate and takes the same rule: one ticket per genuinely separable unit of work, however many that is. The cap still binds `/ticket` itself.

**Step 3's ordering constraint held without compromise.** "All questions before any ticket is created" and "`## Acceptance` names tickets by `(#<filename>)`" look contradictory but are not: the **asking** order and the **writing** order differ — ask everything → decide the set → write the tickets → write Acceptance naming them. That sentence is now in the skill, because the reading "Acceptance first" is the natural misreading and it would be unimplementable.

**The concern this closes.** `missions-are-born-matching-the-lens` prescribed exactly this fix — *"the fix belongs in `create.sh` — require or prompt for a first acceptance criterion at creation time"* — and the lens prose that recorded the accepted consequence has been reconciled in this commit. It should be closed at the next `/report` triage. But the closure is **partial, and the SKILL now says so**: `create.sh` is a POSIX scaffold and still cannot interrogate, so a hand-authored `mission.md` that bypasses `/mission` still arrives at `0/0` and stays invisible to the lens. That residue is the *same shape* as the unassigned-mission gap fixed earlier today (`b75b83c0`): **a default on the sanctioned path does not constrain the other paths.** Claiming the concern is fully closed would have repeated the mistake it documents.

### Discovered Insights

- **Insight**: This ticket's own premise — that a fully-interrogated mission is *"gate-bearing"* — was invalidated by a ticket driven three hours later in the same queue. The Amendment exists because the developer's direction landed mid-drive, and the honest move was to strike the gate round rather than implement a mandatory interrogation for fields the schema now calls optional-and-normally-empty.
  **Context**: A ticket and the schema it writes into must agree, or the interrogation becomes the thing that keeps a demoted field alive. This is the third ticket in this batch whose premise was falsified between writing and driving — the pattern is strong enough to name: **a ticket is a hypothesis with a timestamp**, and the queue's value depends on re-reading its premises against the code at drive time rather than trusting them.

- **Insight**: The interrogation is prose and cannot be unit-tested, which makes it tempting to assert nothing and call the ticket done. What *is* assertable is the seam: the protocol exists and is marked non-skippable, the command routes to it rather than restating it (Thin commands, comprehensive skills), the gate round is gone, and — the row with actual teeth — **a ticket the interrogation emits passes the real `validate-ticket.sh`**.
  **Context**: That last row is what ties this ticket to `e12448d4`: the emitted tickets must carry non-empty `## Policies` and `## Quality Gate` or the hook rejects them, so "emit the whole set" cannot degrade into emitting shells. The general rule: when the behavior is prose, assert the *contract at its boundary* rather than pretending the prose is testable — and say plainly which rows are driven rather than hermetic.

- **Insight**: The `0/0` invisibility this closes is a **two-sided** problem and only one side was ever recorded. The concern blamed `create.sh` for scaffolding `## Acceptance` empty; the real cause is that nothing *required* the section to be filled before the mission was considered created. Fixing `create.sh` alone was impossible — it is `allowed-tools: Bash` and cannot ask a question.
  **Context**: This is why the fix lives in the interrogation rather than the scaffold, and why the concern's own prescribed remedy ("fix `create.sh`") was not followed literally. A prescribed fix in a concern is a hypothesis too; the concern correctly identified *where the symptom appeared* and misidentified *what could act on it*.

## Considerations

- **`create.sh` must stay non-interactive.** It is `#!/bin/sh -eu` and bundled six times. The interrogation happens at command level and *passes results in*; do not grow the script an interactive mode.
- **A transcript is not a model** (`planning/modeling-centric-design`). Asking 20 questions and pasting the answers into Goal is not this ticket done. The output is a structured mission whose Acceptance is checkable.
- The interrogation is what makes tickets B (approval-free drive) legitimate — it is the authorization. If it is thin, B is a blank cheque. Treat depth here as load-bearing, not friction.

## Findings

- The prior art is `.workaholic/tickets/archive/work-20260714-000543/20260714011847-mission-create-worktree-kickoff.md` (commit `86bdbc3`), which built the kickoff path and left the interrogation gap. Its own Considerations already flag that per-ticket `/ticket` is "interactive and heavy" — which is the cost this ticket removes by batching.
- `mission/SKILL.md` already pre-assigns this fix: *"If unfilled missions accumulate, the fix belongs in `create.sh`, not in more lens rules."*
