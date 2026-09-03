---
created_at: 2026-09-03T09:02:50+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-red-base-impossible-for-the-loop-to-miss
merge_policy:
verification_handoff: 
---

# Require a verdict per declared suite on the tip

## Overview

`read-base-checks.sh` answers the base's colour from the newest verdict the base carries, so a
suite that never ran on the offending commit is indistinguishable from one that passed. Measured:
a path-filtered workflow did not fire on a commit that broke the suite it guards, the newest
verdict on that commit was a different, green one, and the base read green for about an hour while
the loop merged into it. The declared workflows are already a list; this ticket makes the reader
require one verdict per declared suite on the tip and answer `unverified: <suite>` for a suite
with no run there.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/read-base-checks.sh` — the one reader of the base's checks
- `plugins/workaholic/skills/moderate/scripts/attribute-base-red.sh` — its consumer for the red attribution walk
- `.github/workflows/` — the declared suites the reading is taken against
- `plugins/workaholic/skills/drive/reference/claims.md` — the base's own checks vocabulary table, keyed on the words this reader emits
- `scripts/test-workflow-scripts.mjs` — the suite that fails on an unclassified word

## Implementation Steps

1. **Reproduce and localize first.** Run `read-base-checks.sh` against a commit whose declared
   workflows did not all fire and record what it answers today; confirm the missing verdict is
   reported as green rather than as absent, and name the line that does it.
2. Establish where the declared set comes from — the workflow files present on the tip — and
   whether any is legitimately conditional, so a suite that *cannot* run on a commit is not
   reported as unverified forever.
3. Add `unverified: <suite>` as its own answer, never folded into green and never into red: a
   suite that did not run is an absence of a reading, which the claims vocabulary already
   classifies as a judgement rather than a proof.
4. Register the new word in `drive/reference/claims.md`'s base-checks sub-table with its consumers,
   so the suite's unclassified-word assertion passes.
5. Leave the walk-past-a-`no_checks`-tip behaviour and every other `unanswerable` case untouched.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `read-base-checks.sh` answers `unverified: <suite>` for a declared suite with no run on the tip
- The word is neither green nor red and is registered in the base-checks vocabulary with its consumers
- Every existing answer (`green`, `red`, `unanswerable`, the walked-past `no_checks` tip) is byte-identical

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` including the vocabulary rows
- A hermetic case over a commit with a declared suite that did not run

**Gate** — what must pass before approval:

- The suite passes and no consumer reads `unverified` as green

## Considerations

- The ask's proposed mechanism — a verdict per declared suite — is the reporter's hypothesis and is
  recorded as such; step 1 establishes the current classification before it is adopted.
- A conditional workflow that legitimately never fires on most commits would otherwise report
  unverified forever; step 2 exists so that case is decided rather than discovered later.
- This ticket changes the reader only. The surfaces that report the colour are the sibling ticket's.

## Final Report

**Outcome**: implemented.

**Reproduced and localized first.** `read-base-checks.sh` answers from the verdicts a commit
*carries*: it counts completed check runs, red-first, then `no_checks` / `checks_pending` /
`checks_truncated`, then `green`. A declared workflow that never fired leaves **no run at all**, so
it contributes nothing to any of those branches and the reading is taken over whatever else is
there — the line that does it is the final `emit green`, which asks only *did anything fail* and
never *did everything run*. All seven workflows here declare `push` to `main`; two are
path-filtered (`docs-deploy.yml`, `outputs-freshness.yml`).

**Step 2's question, answered out loud.** A **path-filtered** workflow **is** declared. Its filter
is the reason it did not run, and *it did not run here* is precisely the fact that went unseen — 
exempting it would exempt the measured defect. What is exempt is a workflow that structurally
**cannot** run on a base commit (schedule-only, `workflow_dispatch` only, `pull_request` only), which
would otherwise read unverified forever. The declared set is therefore *an `on:` block naming
`push`*, read from the workflow files on the tip with `awk` over that block alone, so a `push`
appearing in a job's prose is never mistaken for a trigger.

**`unverified` rides beside the state, never inside it.** The sibling ticket's own words settle the
shape — *a tip can carry a green verdict and an unverified suite at once, and collapsing them loses
the fact* — so `state` stays `green | red | unanswerable` and `unverified[]` is its own field.
Every existing answer is byte-identical, proved by running the reader on the same commit with and
without the flag: `state`, `reason` and `failing` matched exactly.

**It is opt-in** (`--declared`) because it costs a second REST call
(`actions/runs?head_sha=…`). `attribute-base-red.sh` walks commit after commit and passes no flag,
so the attribution walk's cost does not move; the tip's reading passes it once per tick.

**A degraded declared-read answers `unverified_readable: false` with a named reason and a null
set** — never an empty array, which means *every declared suite ran* and is the opposite of *we
could not tell*.

**Registered** in `drive/reference/claims.md`'s base-checks sub-table as a **judgement** (it is the
absence of a reading, like `unanswerable`), with its consumers, so the suite's unclassified-word
assertion passes.

**Verified live on this repository's own tip**: `Docs Deploy` reads unverified there, because the
merge that made the tip touched no `docs/**`. Before this change nothing anywhere could say so.

**Suite addendum.** The vocabulary row pins the emitted set by parsing the two scripts' own `emit`
calls rather than a list. `unverified` is emitted as a **field** rather than as a state, so the
extraction learns that shape explicitly (`"unverified":` in the reader's output) — keeping the
"the scripts say what they emit" property the state words have, rather than adding a hand-kept name.
