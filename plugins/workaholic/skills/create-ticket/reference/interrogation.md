# The interrogation seams (Workflow §4a–4d)

The developer-facing decision points of ticket creation. The command/main agent issues every prompt (leaves cannot); each question body opens with the `[<project label>]` prefix. Whether a question should fire at all is governed by `rules/interaction.md`'s Recommended-label test — restated nowhere, applied everywhere below.

## §4a Requirements Elicitation — the *what*, before the plan

For a user-facing feature the developer holds requirements you cannot derive from the code or the title: what a user must be able to *do*, what a correct/good output looks like (ask for a concrete example), and the real end-to-end workflow. Elicit them with specific questions, not a generic "any feedback?". Three hard gates:

- **A developer's invitation to ask is a hard gate.** If the developer signalled "ask me what you need", skipping the questions is a planning defect, not efficiency.
- **A user-facing feature may not be spec'd from a title.** The ticket must encode what *usable* means for a real person — the agent's later checks (artifact exists, tests pass) cannot see usability — so at least one acceptance criterion is phrased at the user-experience level.
- **If the goal is not understood well enough to write verifiable, user-experience-level acceptance, the ticket is not ready** — keep eliciting.

This is distinct from, and not silenced by, the execution phase's decide-don't-ask rule: that rule governs *how* to execute planned work. Requirements are the *what*, which only the developer holds — decide the *how*, never assume the *what*. A genuine requirements question is exactly the "developer holds information you cannot derive" fork the Recommended-label test never silences. For a purely internal/mechanical change this step is a quick confirmation; for a user-facing one it is the highest-leverage part of the ticket.

## §4b Quality Gate Interrogation — ask decisions, derive the rest

The interrogation's content splits into two kinds, and only one can become a question:

- **Developer-owned decisions** — anything with a real cost/benefit choice or information only the developer has: verification depth and method (smoke tests vs a live end-to-end run; which environment counts as proof), scope calls, risk tradeoffs, judgment-dependent edge cases. Pursue these thoroughly, as many rounds as it takes, converting vague intent ("make it robust") into verifiable criteria ("returns 422 on a missing email"). But run each through the Recommended-label test first: if you could honestly recommend an answer, do not ask — decide it and record it (below).
- **Agent-derivable criteria** — acceptance items that follow from discovery, repo conventions, and standing rules (suite green, lint conformance, docs updated in the same change). Draft these yourself into the `## Quality Gate` and present them as part of the written ticket. Recommendable ⊂ derivable, so a recommendable "decision" lands here too.

**The `Decided:` record seam.** A decision the test drops is recorded, not silently dropped, so it can be vetoed instead of becoming a hidden assumption. Write it as a `## Quality Gate` line: `Decided: <the choice> — <one-line why> (developer may override at /drive).` Example: `Decided: hermetic suite only (node scripts/test-workflow-scripts.mjs) — the change is script-internal with no runtime surface; a live run would prove nothing extra (developer may override at /drive).`

**Anti-pattern — never offer the derivable criteria back as a multi-select menu** ("which of these acceptance criteria should we check?"). Every offered item was derivable, so the question adds a decision the developer never needed to make (measured 2026-07-18: the developer's response was to ask why the question existed at all). If you can derive it — or recommend it — it goes in the ticket, not in a prompt.

Keep asking until the gate is concrete enough to drive an approval prompt. Seed decision questions from discovery's `source.test_coverage` and existing CI checks; the developer's answers are authoritative. Prefer machine-checkable substance (tests / type-checks / CI gates) over manual sign-off (`workaholic:implementation` / `test`, `workaholic:operation` / `ci-cd`).

**Do not soften this step.** A "skip if it seems obvious" escape hatch is explicitly not wanted: the decision/derivable split and the Recommended-label test narrow *what qualifies as a question*, never the bar on the gate itself. You still model the same thorough gate; what shrinks is only the count of prompts. Questions that survive the test travel through the `needs_clarification` channel the command relays via `AskUserQuestion`.

## §4c Mission association

If the mission list contains in-flight missions (the `missions/active/` area), issue one `multiSelect: true` question offering each (by `title` + `slug`) plus "None", and write every chosen slug into each ticket's `mission:` — `mission: [alpha, beta]` for two, a bare slug for one. Ended missions are never offered: new work does not advance a closed mission. No mission, or "None" → leave empty; skip the step silently when there are no missions at all. The select is multi because a ticket can genuinely advance more than one mission. Naming a mission is a commitment, not a label: `/drive` reads the quality gate of every named mission and the change must satisfy all of them — if the work cannot meet a mission's bar, do not name it.

## §4d Merge policy

Ask, once per `/ticket` run: should this work's deployment be confirmed before it merges, or should it merge immediately and have its quality gated later at the `release/*` QA window? Write the answer into every ticket of the run as `merge_policy: auto | review` (decision G5, reconciled to the 2026-08-11 auto-merge mission — neither option asks a human to review the pull request; both merge unattended). One question, two options: *auto — prove the deploy before merging* / *review — merge immediately, gated downstream at the `release/*` window*. This is one of the few genuinely unrecommendable forks — the answer depends on how much the developer trusts this particular change to reach production unconfirmed, information you do not hold. Do not derive it from the ticket's kind or size.

**Inheritance from a mission.** A ticket emitted as part of a mission's set inherits the mission's `merge_policy` and is not asked per ticket — the mission's approval decided it for the batch. The interrogation may still rule otherwise for a specific ticket (a risky one inside an `auto` mission is written `review`); record the divergence and its reason as a `Decided:` line in that ticket's `## Quality Gate`.

Leaving it empty is legal and reads as `review`. Never write `auto` because nobody answered.
