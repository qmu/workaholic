---
created_at: 2026-09-01T03:25:02+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: deliver-a-stranded-publication-that-needs-nothing-but-a-merge
merge_policy:
verification_handoff: 
---

# Act on every clean publication the run reads

## Overview

Widening the act (the mission's first ticket) changes nothing on its own: the run has to call
it. `workaholic:drive` §5 says the run acts "for each entry §1's reading gave whose
`mergeability` is **`mechanical`**", §7 says it reports the act's word "for each `mechanical`
one it acted on", and `CLAUDE.md` says the same twice. So a `clean` entry would be read, named
in the report and left alone.

`/moderate`'s `stranded-publications` step is the other half of the same boundary, and it stays
where it is deliberately: it asks about `content` only, because only a person can judge a
collision. What has to change there is the **statement** — `moderate/reference/workflow.md`
records that the repairable half "is not a finding at all: `/implement` settles it through
`settle-stranded-publication.sh`", which becomes true of two classes rather than one.

This ticket makes the caller act on `clean`, reports it in the vocabularies that already exist,
and updates every document that names which class each act owns — in the same change, as this
repository requires.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — §1 (the once-per-run reading), the settle
  paragraph that names `mechanical`, §7's per-publication report line, and the `ok`-token rows
  for a settled publication's delivery.
- `CLAUDE.md` — *A publication is not a claim, and has its own reader and act* (the act's class),
  and the `/implement` run-report bullet naming the `mechanical` one it acted on.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the `stranded-publications`
  step's own section and its `needs_ruling` classification row, both of which state which half
  `/implement` settles.
- `plugins/workaholic/skills/moderate/scripts/step-stranded-publications.sh` — read to confirm
  its `content` candidate selection is unchanged, and to decide whether its `settleable` count
  (today `mechanical`) should count `clean` too.
- `plugins/workaholic/commands/implement.md` — read; change only if it names the class.
- `outputs/` — regenerated, never hand-edited.

## Implementation Steps

1. **Reproduce first.** Read `list-stranded-publications.sh` in this repository and record the
   current classes. Confirm from `workaholic:drive` §5 and §7 that a `clean` entry is read and
   named but never acted on — quote the two sentences that say `mechanical`. That is the gap.
2. **Widen the act's trigger in `workaholic:drive` §5**: the run calls
   `settle-stranded-publication.sh <number>` once for each entry whose `mergeability` is
   `mechanical` **or** `clean`, still once and never a loop, still never batched. `content`,
   `unanswerable` and an operator-facing publication reach no act, exactly as today.
3. **Report both classes in the same words.** §7's per-publication line keeps its shape: the
   pull request, its `mergeability` (an `unanswerable` reading as unanswerable, never as
   `clean`), and — when the run acted — the act's own word beside the delivery's own word. The
   rule that naming a publication the run acted on and reporting no outcome for it is
   non-conformant now covers both classes.
4. **Leave the `ok`-token rows alone in substance and check them for wording**: a settled
   publication whose delivery reports `merge_refused` still forbids `ok`; a delivered one stops
   withholding it; a refusal that waits on a person still moves no token. If any row says
   `mechanical`, widen it the same way.
5. **Update `CLAUDE.md` in the same commit** — both places, saying which classes the act takes
   and what a `clean` settlement skips.
6. **Update `moderate/reference/workflow.md`**: the `stranded-publications` step's question is
   still `content` only and its reasoning is unchanged; what changes is the sentence naming what
   `/implement` settles. Decide whether the step's `settleable` count should include `clean` —
   it is a count reported to a reader, not a candidate set, so widening it keeps the reader's
   picture true; state the decision either way.
7. **Regenerate and verify**: `node scripts/build-plugins/build.mjs`, then `verify.mjs`,
   `validate-metadata.mjs` and `node scripts/test-workflow-scripts.mjs`.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `workaholic:drive` §5 directs the run to act on `mechanical` and `clean`, and no other class.
- §7 reports, per publication, the `mergeability` whether or not the run acted, and — when it
  acted — the act's word beside the delivery's word, for both classes.
- `CLAUDE.md` and `moderate/reference/workflow.md` name the same classes as the skill; no
  document still says the act takes `mechanical` alone.
- `/moderate`'s `stranded-publication` question still fires on `content` only.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `grep -rn "mechanical" plugins/workaholic/skills/drive/SKILL.md CLAUDE.md` read by hand: every
  surviving occurrence is deliberate.

**Gate** — what must pass before approval:

- `outputs/` is regenerated, never hand-edited, and the `Outputs Freshness` check would pass.
- No new claim verdict word, no row in `reference/claims.md`, no field on any artifact.

## Considerations

- **The documentation is the deliverable here, as much as the trigger.** A widened act that two
  documents still describe as `mechanical`-only is a drift this repository treats as a defect,
  and the surfaces are the ones a later reader consults to decide what the loop owns.
- **The `settleable` count in `step-stranded-publications.sh` is the one judgement call.** It
  reports how many the loop can settle without a person; leaving it at `mechanical` understates
  that after this change. It is a count and not a candidate set, so widening it changes no
  question, no key and no addressee — but it must be a decision that is stated, not a silent
  edit.
- **This ticket depends on the mission's first ticket.** Directing the run to act on `clean`
  before the act accepts it would produce a `not_mechanical:clean` refusal on every tick — noise
  in place of a gap. Drive them in order.

## Final Report

Development completed as planned.

The gap was read before it was closed. `workaholic:drive` §5 said the run acts "for each entry §1's
reading gave whose `mergeability` is **`mechanical`**", and §7 said it reports the act's word "for
each `mechanical` one it acted on"; `CLAUDE.md` said the same in two places. Against this
repository's own reading that morning — six open publications, five of them `clean` — the caller
read five entries, named all five in the report and acted on none.

What changed, and nothing else did:

- `workaholic:drive` §5 now triggers on `mechanical` **or** `clean`, still once per entry, never
  a loop and never batched, and names what a `clean` settlement skips (the merge, the
  regeneration, the fast checks, the push) and what it does not (the gate, the delivery seam).
  A new paragraph records why the class had no owner, with the measured five.
- §7's per-publication line keeps its shape for both classes — the class is already the second
  thing on it, so no second vocabulary was needed — and the non-conformance rule now covers both.
- The token rows moved in wording only: a settled publication whose delivery reports
  `merge_refused` still forbids `ok`, a delivered one stops withholding it, and a refusal that
  waits on a person still moves no token. The `pending` row's prose no longer asserts that the
  loop pushed, because a `clean` settlement pushes nothing.
- `CLAUDE.md` states both classes in both places.
- `moderate/reference/workflow.md` and `step-stranded-publications.sh` keep `content` as the whole
  candidate set, for its own unchanged reason.

The one judgement call, stated rather than silently edited: the step's **`settleable` count** now
includes `clean`. It is a reader-facing number, not a candidate set, so widening it changes no
question, key, cap, addressee or gate — and leaving it at `mechanical` would have reported `1
settleable by the loop itself` on a morning when the loop owned five. A count that understates
what the loop owns is how a reader stops trusting the summary.

`/moderate`'s `stranded-publication:<number>` question still fires on `content` alone; the suite's
existing rows pin that and pass unchanged.

### Discovered Insights

- **Insight**: The class boundary was written down in five places and the act in one, so widening
  the act alone would have left the caller reading `clean` entries it was documented never to
  touch — and every one of those five documents is what a later session consults to decide what
  the loop owns.
  **Context**: `drive/SKILL.md` (§5 trigger, §7 report line, two token rows), `CLAUDE.md` (the
  act's contract and the run-report bullet), `moderate/reference/workflow.md` (the step section
  and the `needs_ruling` row) and the step script's own header. The count in
  `step-stranded-publications.sh` was the only one that was a number rather than a sentence,
  which is exactly why it needed a stated decision rather than a reflex.
