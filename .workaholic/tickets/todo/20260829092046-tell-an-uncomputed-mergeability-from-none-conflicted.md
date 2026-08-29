---
created_at: 2026-08-29T09:20:46+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: land-the-loop-s-own-work-when-the-base-moves-under-it
merge_policy:
verification_handoff: 
claim: work-20260829-093646
---

# Tell an uncomputed mergeability from none conflicted

## Overview

PROPOSED. `step-merge-conflicts.sh` counts only rows carrying `"blocked_by": "conflict"`,
and when that count is zero it reports:

> `<N> open pull request(s), none conflicted (read cap <L>, truncated: <t>)`

`pulls-state.sh` has a fourth answer that sentence does not carry. `mergeable` is computed
lazily by GitHub — `null` until a background merge job finishes — and the reader maps that
to `blocked_by: unknown` precisely so the state is nameable. Step 4 then folds `unknown`
into its zero and speaks with the voice of a completed reading: **none conflicted**. A tick
that could not look and a tick that looked and found nothing are byte-identical at the only
surface anybody reads.

**Measured** (tick `20260829-085055`, issue #710): step 4 reported `none conflicted` over
the same open set in which step 6 named four conflicted pull requests — #622, #625, #633
and #688, the oldest unmergeable since 2026-08-26. Whatever share of that gap was timing,
the reporting defect stands on its own: `unknown` had no way to reach the log.

This is the *found nothing* versus *could not look* collapse this repository has repaired by
name in `attributed-work.sh`, in `list-claims.sh`'s three-valued merged lookup and in
`ci-retirement-turn.sh`. The same repair, one seam over: a reading we could not make is
never dressed as one we did.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — every outcome reported by its own name

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — the `count -eq 0`
  branch that says `none conflicted`, and the `conflicted` grep that produces the count.
- `plugins/workaholic/skills/moderate/scripts/pulls-state.sh` — where `unknown` is already
  derived and documented; **it needs no change**, which is what keeps this to one seam.
- `plugins/workaholic/skills/moderate/scripts/step-stuck-prs.sh` — already counts `unknown`
  among its blocked rows; read it so the two vocabularies stay one.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — step 4's contract, where the
  fourth state must be stated rather than left to be inferred from the script.

## Implementation Steps

1. **Reproduce before repairing.** Over a stubbed transport answering `mergeable: null` for
   every open pull request, run step 4 and capture today's output: `status: ok`,
   `none conflicted`, an empty `conflicted[]` and no `event`. That is the sentence the fix
   must make impossible.
2. **Localize.** Confirm the collapse is entirely in step 4's zero branch — `pulls-state.sh`
   already emits `unknown`, and `step-stuck-prs.sh` already counts it — so nothing outside
   this one branch is implicated.
3. Count `unknown` rows beside `conflict` rows and report them **by their own name**: a tick
   with no conflicts and some uncomputed rows says how many it could not read, and never
   says `none conflicted` about them. A tick with neither keeps today's wording exactly.
4. Choose the status deliberately and record the choice: `unknown` is GitHub not having
   finished, not our own failure, so it is **not** `degraded` (which names an unreadable
   transport) and **not** `blocked` (which asserts a conflict nobody proved). Report it as a
   named part of an `ok` reading, and say so where the contract is stated.
5. Leave the posting behaviour alone. Step 4 posts nothing of its own by design — its
   finding rides step 6's reminder — so this ticket must not add an `event` for `unknown`,
   or one pull request draws two Slack lines in one tick, which is the noise the gate exists
   to prevent.
6. State the fourth outcome in `reference/workflow.md`'s step 4 entry, beside the existing
   three.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick whose open pull requests are all `mergeable: null` **never** reports
  `none conflicted`; it names the uncomputed count.
- A tick with no conflicts and no uncomputed rows reports today's wording byte-identically.
- `unknown` is reported as part of an `ok` reading, distinct from `degraded` (transport
  unreadable) and from `blocked` (a proved conflict).
- Step 4 still supplies **no** `event` and still posts nothing — one pull request, one Slack
  line per tick, unchanged.
- `pulls-state.sh` is unmodified: no second derivation of `blocked_by` exists anywhere.

**Verification method** — the commands/tests/probes that prove them:

- The stubbed-transport reproduction from step 1, as a hermetic case in
  `scripts/test-workflow-scripts.mjs`: it fails on today's tree and passes after.
- A fixture with zero conflicts and zero unknowns, asserted byte-identical before and after.
- A grep proving step 4 emits no `event` key on any path.
- `node scripts/test-workflow-scripts.mjs`, `node scripts/build-plugins/build.mjs`,
  `node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- The hermetic case asserts the **absence of the words** `none conflicted` under an
  all-`unknown` fixture, not merely the presence of a count — a wording that keeps the
  claim while appending a number must still fail it.

## Considerations

- **Independent of its sibling.** `20260829092043-read-the-tick-s-conflict-state-once-per-tick.md`
  removes the *disagreement* between steps 4 and 6 by resolving the state once; it does not
  make a shared `unknown` honest. With only that ticket, both steps say `none conflicted`
  together. Either can land first.
- **`unknown` is not a conflict and must not be counted as one.** Reporting it as blocked
  would send a claim holder after a conflict nobody proved — the wrong direction, on the
  merged-lookup precedent that a wrong `merged` releases live work while a wrong `in flight`
  only delays a claim.
- The `truncated` and `read cap` clauses already in the sentence stay: they name a different
  limit — how much of the open set was read at all — and losing them would trade one silent
  boundary for another.
