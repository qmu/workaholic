---
created_at: 2026-09-01T08:26:33+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: settle-a-mergeability-reading-before-it-becomes-a-question
merge_policy:
verification_handoff: 
---

# Name the loop's own repair on a conflicted pull request

## Overview

The operator's words were that Moderation "only spews reports and shows no sign of
resolving anything". The measurement behind them: four conflicting pull requests, all four
colliding on `.workaholic/stories/index.md` — the loop's own generated OKF index — two of
them on nothing else, reported hourly as somebody's work. Diagnosis found the acting half
already built and the **telling** half wrong. `catch-up-claim.sh` clears a `mechanical`
conflict on this identity's own reported claim, `settle-stranded-publication.sh` clears a
publication's, and since ticket `20260901041500` `claim-mergeability.sh` computes with
`.gitattributes` out of reach, so a generated-index collision now classifies `mechanical`
rather than `clean` and actually reaches those actors on the next `[Implement]` tick.

What the tick says about such a pull request is still the pre-catch-up sentence: `stuck-prs`
renders "the claim holder must resolve the conflict — nobody else may push to that branch"
for **every** conflict. So the one class the loop repairs itself is announced to a person as
theirs, and it queues behind a question budget of ten a day. This ticket changes the
wording and nothing else.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a report names the decision, not the colour
- `workaholic:implementation` / `policies/objective-documentation.md` — the spec and the step say the same thing
- `workaholic:implementation` / `policies/command-scripts.md` — wording changes, keys do not

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-stuck-prs.sh` — composes the per-row
  `decision` text and the `HEADLINE`; the `conflict` arm is the sentence to correct.
- `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — its header records
  the standing rule (this step reports and never rebases) and its 2026-08-29 narrowing
  (catch-up is not a third party and not a rebase); the summary should not contradict it.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step specs and the
  question bodies the `🙋` contract governs.
- `plugins/workaholic/skills/drive/reference/claims.md` — the mergeability vocabulary and
  who may act on which class; the source the new wording must agree with.

## Implementation Steps

1. **Reproduce first.** On this repository, run `pulls-state.sh` and `step-stuck-prs.sh`
   and capture a `conflict` row's rendered `decision`. Separately run
   `drive/scripts/claim-mergeability.sh` for the same branch and record its class. Show the
   two side by side: a `mechanical` class under a sentence that says only a person can act.
2. **Localize.** Confirm the `decision` string is composed in `step-stuck-prs.sh`'s `awk`
   block from `blocked_by` alone, and that `blocked_by` carries no class — so the sentence
   cannot currently distinguish the two cases.
3. Decide, in the ticket's own terms, where the class comes from **without adding a fetch
   to a step that has none**: `merge-conflicts`'s header refuses a network read inside
   itself on a measurement, and `list-claims.sh` fetches. Either the step reads a class
   already resolved elsewhere in the tick, or — if none is available — the wording is
   corrected generically, naming that a conflict confined to the loop's generated indexes
   is cleared by the executor's own catch-up rather than by the reader.
4. Rewrite the `conflict` decision so it says what the addressee should do: wait for the
   next `[Implement]` tick where the loop's catch-up clears it, or resolve it where a real
   content decision is involved. Keep `stuck:<digest>` and the `blocked_by` set byte-identical
   — this is wording, and the header already records that the heading was once mistaken for
   the key.
5. Make the same correction in `moderate/reference/workflow.md`'s spec for the step and in
   the `catchup-blocked` question body, so the operator meets one voice (`workaholic:notify`,
   the `🙋` contract: lead with what happened, identifier after it).
6. Do **not** add an acting step to `/moderate`. It never pushes into a branch the claim
   protocol owns; the actors are `/implement`'s catch-up and `settle-stranded-publication.sh`,
   and this ticket's job is to say so.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A conflicted pull request's reported decision distinguishes the class the loop clears
  itself from the class that waits on its holder, and names which actor clears the first.
- `stuck:<digest>`, the `blocked_by` set and the `needs_agent` shape are unchanged.
- `/moderate` gains no merge, no push and no new network read.
- `moderate/reference/workflow.md` and the question body carry the same wording as the step.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`
- The step-1 reproduction repeated: the rendered decision for a generated-index conflict
  no longer reads as the holder's sole work.

**Gate** — what must pass before approval:

- Both commands above pass, and a diff review shows no change to any key, digest or
  `blocked_by` value.

## Considerations

- **The reporter's proposed mechanism is a hypothesis.** "Give the conflict step the repair
  — merge the base into the branch where the union attribute applies and push" describes
  `catch-up-claim.sh`, which exists and runs from `/implement`. Putting it in `/moderate`
  would break the standing rule that the tick never pushes into a claim branch, and
  `step-merge-conflicts.sh`'s header records why a third party writing a claim branch was
  refused. If the measured gap turns out to be *latency* (the repair waits for the next
  `[Implement]` tick), that is a separate ask against the executor's cadence, not this one.
- The escalation budget the ask names (20 findings held, ten questions a day) is the
  subject of the active mission `say-when-the-check-in-queue-is-stuck-and-bound-the-hold`;
  do not re-solve it here.

## Final Report

Development completed as planned.

The reproduction ran first and showed the defect exactly as the ticket described it. This
repository's five conflicted pull requests all rendered the same `decision` —
*the claim holder must resolve the conflict — nobody else may push to that branch* —
while `claim-mergeability.sh` classified them into two different classes: #832
(`.workaholic/stories/index.md` alone) and #755 (six generated indexes and manifests) read
**`mechanical`**, which `/implement`'s own catch-up clears, and #774, #633 and #622 read
**`content`**. Two pull requests the loop repairs itself were announced to a person as
theirs.

Localizing confirmed the second half: the `decision` string is composed in
`step-stuck-prs.sh`'s `awk` block from `blocked_by` alone, and `blocked_by` carries no
class — so the sentence could not distinguish the two cases.

**Where the class could come from, decided in the ticket's own terms.** The class lives in
`ship/scripts/lib/conflict-class.sh` via `claim-mergeability.sh`, which needs the branch
**ref**; this step reads GitHub over REST through `pulls-state.sh`, which carries no class,
and the reader that fetches (`list-claims.sh`) is not composed here — `run.sh` shares only
`WORKAHOLIC_TICK_REPORTS` and `WORKAHOLIC_TICK_PULLS_STATE`, neither of which holds a
class. So the ticket's named fallback applies: the wording is corrected **generically**,
naming both actors, and the per-branch judgement stays with `catchup-blocked` (§26), which
reads the class off a claim row that already has it.

Wording only. `stuck:<digest>`, the `blocked_by` set, `headline` and the `needs_agent`
shape are byte-identical — the diff touches no line that computes any of them. No acting
step was added to `/moderate`: it still merges nothing, pushes into no claim branch and
makes no new network read.

### Discovered Insights

- **Insight**: `step-stuck-prs.sh`'s decision strings live inside a single-quoted shell
  string wrapping an `awk` program, and `step-merge-conflicts.sh`'s summaries live inside
  single-quoted `printf` formats. An apostrophe in either — `the loop's`, `the holder's` —
  terminates the shell quote, and `awk` fails with *runaway string constant* at runtime
  rather than at `sh -n`.
  **Context**: Any future wording change to these rows has to be written without
  apostrophes, or the quoting has to change first. `sh -n` passes either way, so the only
  proof is running the step.

- **Insight**: The step's `stuck:<digest>` changed between the before and after runs
  (`stuck-2009658084` → `stuck-342529036`) for a **data** reason, not a wording one: three
  rows that read `unknown` in the first run had settled to nothing-blocking by the second.
  **Context**: A digest comparison across two live runs proves nothing about a wording
  change. What proves it is the diff — the lines that compute `pairs`, `digest`, `kinds`
  and `headline` are untouched.
