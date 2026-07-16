---
created_at: 2026-07-16T01:28:47+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
commit_hash:
category: Changed
depends_on: [20260716012845-mission-interrogation-emits-ticket-set.md, 20260716012846-enforce-quality-gate-section.md]
mission:
---

# Drive a mission-authorized queue without the per-ticket approval prompt

## Motivation

Once `/mission` has interrogated every judgement call up front (ticket `20260716012845`) and emitted a ticket set whose gates are machine-checked (ticket `20260716012846`), the per-ticket approval prompt at `/drive` Step 2.2 is asking a question that was already answered — by the developer, at mission time, about these exact tickets.

The developer's requirement: *"Once those tickets are created, we shouldn't need to approve them one by one; we should just be able to drive through them."*

**This is not new ground, and it is not a policy departure.** Three things establish that:

- **The trip executor already has no developer gate.** `trip-protocol` states plainly: *"the three-agent QA IS the per-ticket approval gate — there is no developer AskUserQuestion"*. Draining a `todo/` queue with no per-ticket human prompt is already a sanctioned model here.
- **Night mode already skips it**, on exactly this logic: *"The per-ticket approval is satisfied by the `/drive night` batch authorization … so it is **skipped**, not invoked."* Its own ticket states the governing principle: *"Explicit approval is **relocated, not removed**. The scoped exception is legitimate only because the user makes ONE explicit, informed authorization of the exact named batch upfront."* A mission interrogation is the same shape — arguably stronger, since the developer co-authored every ticket's gate rather than authorizing a queue they did not design in that session.
- **The policy corpus asks for this.** `implementation/test`'s Goal is *"the dissolution of the current state in which humans are asked to check completeness as part of the tools invoked by AI"* — a per-ticket "did it do the thing?" prompt is precisely that. `development/overnight-ai`: *"judgment is pre-answered sufficiently, AI does not stop through the night waiting for human confirmation."* `development/review`: quality comes *"not by a process of reading back generated code and correcting it after the fact, but by policies before generation and by each developer's own QA."*

**What is removed, exactly** (settled with the developer, 2026-07-16): the **completeness check inside the drive loop** — nothing else. `/report` still writes the story and opens the PR, and `/ship` still gates the merge on evidence. The **qualitative looking-through** `development/qa-engineering` makes non-delegable is not eliminated; it **relocates to the PR**, which is what `development/review` prescribes. This distinction is the whole legitimacy of this ticket: eliminate the completeness check and you are on policy; eliminate the looking-through and you are in the state three policies exist to prevent. Do not blur them while implementing.

## Policies

- `development/overnight-ai` — Goal: pre-answered judgment so AI runs without stopping for confirmation. Responsibility: the limit — *"if AI is given a blank check to avoid stopping it, unverified inferences pile up in the code"*, so residual judgment is collected for the post-run pass, not dropped.
- `development/review` — removes after-the-fact human reading from the default; quality moves upstream to policy and downstream to the developer's own QA (the PR), not away.
- `development/qa-engineering` — the non-delegable limit: the author still owns the qualitative pass. Satisfied here by relocation to `/report`'s PR, not by deletion.
- `implementation/test` — affirms dissolving human completeness-checks inside AI-invoked tools; conditional on the emitted tickets carrying real verification (which is why `20260716012846` is a dependency, not a nicety).
- `design/modeless-design` — a blocking confirm that adds no information is an unjustified mode. The precedent is the trip design-pause removal, which used this same argument.
- `implementation/observability` — the counterweight: an unattended run must be reconstructible afterward. This is why the batch report is part of the gate, not a nicety.
- `implementation/directory-structure` / `implementation/coding-standards` — apply to all code work.

## Implementation Steps

1. **Authorization lives in `mission.md`** (developer's decision, 2026-07-16). The interrogation of `20260716012845` stamps the field at create time — authorization belongs with the thing that was actually interrogated. Rejected alternatives, recorded so they are not re-litigated: keying off the ticket's `mission:` relation alone (a ticket hand-added to the mission later would inherit an authorization nobody granted), and an explicit `/drive mission` argument (mirrors night mode, but makes authorization an act by someone who may not have run the interrogation).
2. **Build the script seam** (developer's decision, 2026-07-16) — the substantive part of this ticket. Today the approval gate is *prose in `drive/SKILL.md`* with no script, which is why neither it nor night mode has a single assertion. Add an authorization resolver under `skills/mission/scripts/` (POSIX `#!/bin/sh -eu`, one JSON line) that answers, for a given ticket: **is this ticket's queue pre-authorized?** — reading the `mission:` relation through `read-relation.sh` (never re-parsing frontmatter) and the mission's authorization field. `/drive` consults it instead of deciding in prose. This is what makes the rule testable and what gives night mode coverage as a side effect.
3. **Skip the gate; never auto-answer it.** Copy night mode's accepted mechanism exactly: Step 2.2's `AskUserQuestion` is **not issued**. Do not have the implementer "answer" it — the Workflow-level `NEVER use AskUserQuestion` boundary must stay intact. Night mode's second iteration (`c857ad1`) exists specifically to preserve this; do not regress it.
4. **Inherit night mode's failure contract** (§3 and §5) — this is where an autonomous run actually leaks, not at the approval gate:
   - **Attempt every authorized ticket.** Size, complexity, "all-or-nothing", and "this looks like it needs a human" are **not** skip reasons. A skip is legitimate only after a real attempt, and only as `failed` (implemented, checks red) or `blocked` (a **named** hard external blocker).
   - **Safety floor**: `git stash` a failed ticket's partial work so it cannot contaminate the next commit; leave the ticket in `todo`; **never** auto-icebox, auto-abandon, or run destructive git.
   - **A closed three-outcome report** (implemented / failed / blocked) whose totals **reconcile to the authorized set size**. There is no "declined" category.
5. **Do not inherit night mode's §1b group question** — it is vacuous here. A mission queue is one cohesive topic group by construction; asking "should I also include group B?" of a set the developer just designed is noise.
6. **Rewrite the false sentence.** `drive/SKILL.md` says: *"Night mode is the ONLY mode that skips the per-ticket 'explicit user approval' gate."* That becomes untrue the moment this lands. Restate the rule as: the gate is skipped exactly when a **prior explicit batch authorization** exists — `/drive night`'s invocation, or a mission's interrogation — and never otherwise.
7. **Docs in the same change**: `drive/SKILL.md` (Step 2.2, Night Mode's scoped-exception paragraph, Critical Rules), `mission/SKILL.md` (the authorization field's semantics), CLAUDE.md's `/drive` and `/mission` rows and the sources×executors prose.
8. `node scripts/build-plugins/build.mjs` — `drive/SKILL.md` and `mission/SKILL.md` are both bundled, and mission scripts are copied **six times**. Then `verify.mjs`, `validate-metadata.mjs`, `posix-lint.sh`.

## Quality Gate

**Acceptance criteria:**

| # | must hold |
| --- | --- |
| 1 | The resolver returns **authorized** for a ticket carrying `mission: <slug>` whose mission.md is stamped, and **not authorized** for: a ticket with no `mission:`, a ticket whose mission lacks the stamp, and a mission slug that does not resolve. |
| 2 | A ticket relating to **two** missions where only one is authorized resolves to **NOT authorized** — the conservative direction. A ticket is gate-free only if every mission it claims says so. (Mirrors `/drive`'s existing "all of them must pass, not the most convenient one".) |
| 3 | The relation is read via `read-relation.sh`, so `mission: [a, b]` and bare `mission: a` behave identically. |
| 4 | `drive/SKILL.md` no longer claims night mode is the only gate-skipping mode. |
| 5 | The failure contract is stated for this mode: attempt-every, closed skip set (`failed`/`blocked`), stash floor, no auto-icebox/destructive git, reconciling report. |
| 6 | Night mode's behaviour is unchanged. |

**Verification method.** Criteria 1–3 are hermetic assertions against the new resolver in `scripts/test-workflow-scripts.mjs` — temp repos with fabricated missions and tickets, no network. This is the point of the script seam: **without it, criteria 1–3 are unassertable and this ticket would be prose-for-prose.** Criteria 4–6 are prose review of the built + source SKILL.md.

Criterion 7, and the one that actually proves the feature: **one live end-to-end run.** `/mission` a small real mission (ticket `20260716012845`'s flow), then `/drive` its queue and observe that **no approval prompt is issued**, every ticket is attempted, and the batch report reconciles. The suite cannot assert "it drove without asking" — it never runs a model — so the live run is the acceptance evidence, not a nicety.

**The gate:** criteria 1–6 green; the live run shows zero prompts and a reconciling report; full suite green; `posix-lint` conforming; `verify.mjs`, `validate-metadata.mjs` pass; `git status --porcelain outputs/` empty after a rebuild.

**Watch it fail first:** revert the resolver alone via `git checkout HEAD -- <path>` (never `git stash`), confirm criteria 1–3 go red, restore.

## Final Report

Development completed as planned. Criteria 1–6 hold; **criterion 7 was not run, and that is stated rather than papered over** (below).

**Step 2's script seam is the substance, and it delivered exactly what the ticket predicted.** The approval gate was prose in `drive/SKILL.md` with nothing behind it — which is precisely why neither it nor night mode ever carried a single assertion. `drive-authorized.sh` makes the rule callable, and criteria 1–3 became assertable for the first time. The proof that the assertions are real, not decorative: flipping the resolver's rule from *every mission must be stamped* to *any* turns the conservative rows RED. Night mode inherits the coverage as a side effect, as predicted.

**Criterion 2 — the conservative direction — is the row that matters.** A ticket claiming two missions where only one is stamped resolves to **not authorized**. This mirrors `/drive`'s existing "all of them must pass, not the most convenient one": naming a mission is a commitment, not a label, so one unauthorized mission means ask.

**Step 6's false sentence is gone from source and from the built copy.** *"Night mode is the ONLY mode that skips the per-ticket approval gate"* became untrue the moment this landed, and the rule is now stated once, positively: the gate is skipped exactly when a **prior explicit batch authorization** covers the ticket — `/drive night`'s invocation or a mission's `drive_authorized: true` — and never otherwise. A third place said the same thing implicitly (the Critical Rules' "except in night mode"), and it moved too.

**What is removed is only the completeness check inside the drive loop** — the distinction the ticket called "the whole legitimacy of this ticket". The qualitative looking-through relocates to the PR (`/report` writes the story, `/ship` gates the merge on evidence) rather than being deleted. That sentence is now in `drive/SKILL.md` next to the skip, not just in this ticket, because the person who blurs it later will be reading the skill.

**Criterion 7 (the live end-to-end run) was NOT performed.** The gate asks for a real `/mission` followed by a `/drive` of its queue, observing zero prompts and a reconciling report. That needs a model-driven session against a real mission worktree; this drive is running under a different authorization (`/goal`), so a run here would prove nothing about the *mission* path — it would demonstrate the goal's authorization, not the stamp's. The ticket is explicit that the suite "cannot assert 'it drove without asking' — it never runs a model", so this remains the outstanding acceptance evidence. **The feature should be considered unproven end-to-end until someone runs it.**

### Discovered Insights

- **Insight**: The ticket's own framing — *"without the script seam, criteria 1–3 are unassertable and this ticket would be prose-for-prose"* — turned out to be the most valuable sentence in it. The seam is what let me falsify my own implementation: I broke the every→any rule deliberately and watched the conservative rows go red.
  **Context**: This is the general defence against prose-shaped features. `/drive`'s approval gate had existed for months as an untested paragraph; the moment it became a script it acquired a contract that can be checked and a failure that can be demonstrated. Any rule that decides whether to ask a human for permission belongs behind a script for exactly this reason — the alternative is a policy nobody can prove is in force.

- **Insight**: Authorization had to live on the **mission**, and the two rejected alternatives are worth keeping rejected. Keying off the `mission:` relation alone would let a ticket hand-added later inherit an authorization nobody granted; a `/drive mission` argument would let whoever runs `/drive` authorize work they never interrogated.
  **Context**: The principle underneath: **the authorization must be stamped on the thing that was actually interrogated**, by the act that did the interrogating. That is why `/mission` stamps `drive_authorized: true` only *after* the full set is emitted, and why the command explicitly forbids stamping a mission whose interrogation was cut short. An unearned stamp silently removes a gate nobody agreed to remove — and unlike a missing stamp, nothing would ever surface it.

- **Insight**: This ticket removes a prompt, but the risk it introduces is not at the prompt — it is in the **failure contract**, which is why the authorized mode inherits night mode's §3/§5 wholesale (attempt every ticket; skip only as `failed` or `blocked`; stash the partial work; a closed three-outcome report that reconciles).
  **Context**: An unattended run leaks where it decides to *stop*, not where it decides not to ask. Night mode learned this the expensive way — its §3 exists because "size, complexity, and this-looks-like-it-needs-a-human" were being used as skip reasons. Inheriting the contract rather than writing a parallel one is what keeps the two modes from drifting into two different definitions of "failed".

## Considerations

- **The dependencies are not bureaucratic.** `20260716012846` (enforce `## Quality Gate`) must land **first**: with the human out of the loop, the ticket's gate is the only bar, and today a ticket can omit it entirely — one in the live queue already does. `20260716012845` must land first because it stamps the authorization and *is* the authorization.
- **Do not make this a global `/drive` default.** The exception is scoped to a queue whose questions were demonstrably front-loaded. An unmissioned ticket written in thirty seconds has had no interrogation and keeps its gate.
- **The residual, named rather than solved** (`safety/risk-management`): the mission's own gate (`gate_type`/`gate_target`/`gate_assert`) is the mission-level objective judge, but its live verification is **not hermetic** — active concern `mission-quality-gate-server-start-and` records that `gate.sh` is declaration-and-ports only and the Playwright drive is an in-session step. So the strongest automated backstop for an unattended mission drive is the per-ticket `## Quality Gate`, not the mission gate. That is acceptable and is why `20260716012846` is a dependency — but it should be stated, not assumed.
- `planning/ai-native-future` asks that AI-driven processes keep an observable, interruptible path for a human. An unattended mission drive should remain interruptible and must leave the reconstructible record (§5 report) that `implementation/observability` requires.
