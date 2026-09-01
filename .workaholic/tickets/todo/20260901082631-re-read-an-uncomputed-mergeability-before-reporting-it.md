---
created_at: 2026-09-01T08:26:31+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: settle-a-mergeability-reading-before-it-becomes-a-question
merge_policy:
verification_handoff: 
---

# Re-read an uncomputed mergeability before reporting it

## Overview

An operator measured `stuck-prs` reporting `403:unknown 407:unknown 409:unknown
430:unknown` hour after hour, and reading each pull request by hand turned all four into a
definite answer on the first try. The reporter's diagnosis was that the step reads only the
list endpoint; that is **not** what this tree does — `pulls-state.sh` already does a
per-pull `GET /repos/{slug}/pulls/{n}` and its header says so ("THE PER-PULL GET IS THE
POINT"). What is left is the half neither surface names: GitHub computes `mergeable`
**lazily**, and requesting the pull request is what *schedules* the background merge job.
So the tick's own first read is the request that starts the computation, answers `null`,
and — with nothing looking again — turns a *not yet* into an hourly finding, a `stuck-prs`
reminder and, eventually, a question against a person's daily budget.

The repair is one bounded second look inside the one reader, so both steps that compose it
inherit it and neither gains a network call of its own.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/observability.md` — a reading we could not make is never dressed as one we did
- `workaholic:operation` / `policies/external-dependency.md` — a third party's lazy answer is not a fact about us

## Key Files

- `plugins/workaholic/skills/moderate/scripts/pulls-state.sh` — the one reader; owns the
  per-pull read, the `blocked_by` judgement and the per-tick cache. The re-read belongs here.
- `plugins/workaholic/skills/moderate/scripts/step-stuck-prs.sh` — consumes `blocked_by`;
  its `unknown` decision text ("GitHub has not computed mergeability yet — re-read before
  acting") is the sentence this ticket makes true.
- `plugins/workaholic/skills/moderate/scripts/step-merge-conflicts.sh` — counts `unknown`
  rows into its `uncomputed` field; must keep naming what genuinely stayed unknown.
- `scripts/test-workflow-scripts.mjs` — where the hermetic assertion lands.

## Implementation Steps

1. **Reproduce first.** Against this repository's open pull requests, call the list
   endpoint and record how many rows carry `mergeable: null`; then call
   `GET /repos/{slug}/pulls/{n}` once per row and record the answers; then call it a
   second time on every row that still answered `null` and record those. Write the three
   counts down — they are what says whether a second read is worth anything here.
2. **Localize.** Confirm in `pulls-state.sh` that the `null` → `unknown` mapping happens on
   the first per-pull answer with nothing between it and the emit, and that the per-tick
   cache (`WORKAHOLIC_TICK_PULLS_STATE`) would store that first answer for both steps.
3. Add the second look inside `pulls-state.sh` alone: for the rows that answered
   `mergeable: null`, wait briefly and re-read **once**, bounded by a named, small cap on
   how many rows and how long in total, so a repository with fifty open pull requests
   cannot turn the tick into a poller. A row that answers on the re-read is classified from
   the new answer; a row that stays `null` stays `unknown`.
4. Report the re-read on the reader's own output — how many rows were re-read and how many
   were settled by it — so a tick that spent the budget and learned nothing says so.
5. Leave the `unknown` vocabulary in place. It is still the honest word for a row that
   stayed uncomputed after the second look, and `merge-conflicts`'s `uncomputed` count
   still distinguishes *could not look* from *looked and found nothing*.
6. Add a hermetic assertion (no network) that a stub whose first per-pull answer is `null`
   and whose second is `false` classifies as `conflict`, and that one which is `null` both
   times classifies as `unknown`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A pull request whose first per-pull read answers `mergeable: null` is read once more
  before any step sees `unknown`.
- The re-read is bounded by a named cap on rows and total time; exceeding it leaves the
  remaining rows `unknown` rather than extending the tick.
- A row still `null` after the re-read is still reported `unknown`, and
  `merge-conflicts`'s `uncomputed` count is unchanged for it.
- The reader's output names how many rows were re-read and how many the re-read settled.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (the new hermetic rows, plus the existing
  `pulls-state` and `stuck-prs` rows unchanged)
- The step-1 reproduction repeated after the change: no row that a hand re-read can settle
  reaches the tick as `unknown`.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes; no step gains a network call it did not
  already make, and neither consuming step's `summary` wording or `stuck:<digest>` key moves.

## Considerations

- **The reporter's proposed mechanism is a hypothesis, and this tree contradicts it.** "The
  step should do that read before it reports" is already true here (plugin 1.0.269);
  the measurement was taken against 1.0.266. Do not add a second per-pull read at the step
  level — that would give `stuck-prs` and `merge-conflicts` a network call each, which the
  per-tick cache was written to remove (its header records the correctness defect that
  caused).
- A re-read costs latency inside a step whose whole budget is a bounded REST read. Prefer
  one short wait over a retry loop; the tick runs hourly, so a row that needs longer than
  the cap is genuinely better reported as `unknown` and looked at next hour.
- The cache is keyed on the limit it was resolved at; the settled answer must go into the
  cached payload, or the second step will re-read the same rows.
