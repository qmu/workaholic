---
created_at: 2026-08-31T20:29:33+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-the-base-s-colour-past-a-bookkeeping-tip
merge_policy:
verification_handoff: 
---

# Continue the base walk past a commit nothing ran on

## Overview

PROPOSED. The core change. `attribute-base-red.sh` reads the tip and, on any `unanswerable`,
emits `tip_<reason>` before the backward walk begins. That walk exists only for the red case,
so a base whose tip carries no checks gets no reading at all. This ticket separates the one
reason that has a defined answer one step back from the reasons that are about us, and lets
only that one continue.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/attribute-base-red.sh` — the tip `case` and the
  walk's `*)` arm are the two places the collapse lives.
- `plugins/workaholic/skills/drive/scripts/read-base-checks.sh` — the one derivation of a
  commit's state; its `reason` vocabulary is what this ticket keys on, and it must not move.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the base's own check
  vocabulary is classified; a new field is described there, not a new verdict word.

## Implementation Steps

1. **Reproduce and localize first.** In a throwaway repository, build a base whose tip carries
   no checks over an ancestor that does, and record the current output: `state: unanswerable`,
   `reason: tip_no_checks`, `walked: 1`. Do not change anything until that output is captured.
2. Key the continuation on the reader's own `reason`, read from its JSON — never on a
   substring of the emitted `tip_` string and never on a second derivation of the state.
3. At the tip: `no_checks` continues into the walk; every other reason (`reader_failed`, a
   rate limit, a refused transport, `checks_pending`, an unparseable response) stays terminal
   and emits exactly what it emits today.
4. Inside the walk: a `no_checks` commit is **skipped**, not treated as unreadable and not
   treated as red. State in the header why that is sound here — nothing ran on it, so it was
   never observed to break anything — and why every other unanswerable reason must still stop
   the walk, since such a commit may itself be red.
5. A skipped commit must not become an attribution. `oldest_red` may only ever hold a commit
   the reader answered `red` for.
6. Keep the bound exactly as it is. A walk that runs out of room still reports
   `bound_exhausted` rather than guessing — that is what keeps this honest, and it is already
   the red case's behaviour.
7. Record in the header that `no_checks` continuing is a **statement about the commit** and
   that the reader stays three-valued and unchanged.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `no_checks` tip over a green ancestor answers `green`, naming that ancestor.
- A `no_checks` tip over a red ancestor answers `red` with the same attribution the walk
  would have produced from a red tip.
- A `reader_failed` tip answers exactly what it does today, byte-for-byte.
- A walk that reaches the bound answers `bound_exhausted`, never a guess.

**Verification method** — the commands/tests/probes that prove them:

- Hermetic rows in `scripts/test-workflow-scripts.mjs` covering each of the four cases above,
  with a stubbed reader so no network call is made.
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The reader (`read-base-checks.sh`) is byte-identical: this ticket changes the walk, not the
  derivation.
- No new verdict word is introduced, and nothing may act on the reading — it stays a
  judgement, reported and asked about, never reverted, re-run, gated or merged on.

## Considerations

- The walk costs one network read per commit inspected. A base whose commits are mostly
  bookkeeping now walks further before finding a checked one, so the bound is doing more work
  than before; measure the walk length in the reproduction and say whether the default of 20
  is still right rather than changing it on a hunch.
- `checks_pending` is deliberately not continued: the base has not finished answering, and
  walking past it would report an older commit's colour as though it were current — the
  failure the three-valued reader exists to prevent.

## Final Report

Development completed as planned.

The reproduction was captured first, in the suite rather than in a throwaway repository:
`testAttributeBaseRed` and `testBaseHealthStep` already build a git repo with a stubbed
`gh`, and both asserted the old collapse verbatim — `["unanswerable", false, "tip_no_checks"]`
and `base_unreadable:tip_no_checks`. Those two assertions failing is the reproduction, and
they were rewritten onto genuine own-failure fixtures rather than deleted.

`attribute-base-red.sh` now keys the continuation on the reader's own `reason`, read from its
JSON (`RC_REASON`), never on a substring of the emitted `tip_` string. At the tip, `no_checks`
falls through into the walk and every other reason emits exactly what it emitted before.
Inside the walk, a `no_checks` commit is skipped — not green, not red, not a stop — while
every other unanswerable reason still emits `unanswerable_in_walk:<reason>`.

`oldest_red` starts **empty** and takes the tip only when the tip itself read `red`, which is
what keeps a skipped commit from ever becoming an attribution. That made one new distinction
necessary at the end of the walk: with a red in hand the answer is `unattributable`
(`bound_exhausted` / `history_start`), exactly as before; with none it is `unanswerable` under
the same two reasons, because saying `unattributable` there would assert a red nothing
observed. No new verdict word was introduced and `read-base-checks.sh` is byte-identical.

The in-loop `emit unattributable bound_exhausted` became a `break` into the existing tail so
the two endings share one derivation of the reason; the red case's output is unchanged.

**On the bound.** The Considerations asked for a measurement rather than a hunch: over the
newest 60 commits of `origin/main`, the longest run of consecutive commits touching only
`.workaholic/` is **7**, against a default bound of 20. The default is still right and was
left alone. The added cost is one reader call per skipped commit, paid only on a base whose
tip carries no checks — which is the case that returned no reading at all before.

### Discovered Insights

- **Insight**: The reader's `reason` vocabulary splits cleanly into statements about the
  *commit* and statements about *us*, and only `no_checks` is in the first group.
  **Context**: That split is what makes the continuation safe to key on, and it is why
  `checks_pending` — which looks like a "not yet" and reads like a "nothing here" — must stay
  terminal: the base has not finished answering, so an older commit's colour is not current.

- **Insight**: The two ends of the walk answer different questions, and one word was doing
  both jobs. `unattributable` means *the base is red and I cannot say what broke it*; it
  requires a red actually observed. Once a walk can skip its way to the end it can also
  finish having observed no colour at all, and that is `unanswerable`.
  **Context**: A consumer that treats `unattributable` as "the base is red" — which
  `step-base-health.sh` does, composing its `the base is red at …` summary from it — would
  otherwise have announced a red base on a repository where nothing has ever been checked.
