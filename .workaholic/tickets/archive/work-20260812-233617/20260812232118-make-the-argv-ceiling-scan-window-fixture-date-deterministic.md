---
created_at: 2026-08-12T23:21:18+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260812231818-hermetic-smoke-suite-fails-off-the-routine-image-on-the-argv-ceiling-fixture.md]
merge_policy:
claim: work-20260812-233617
---

# Make the argv-ceiling scan-window fixture date-deterministic

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

`node scripts/test-workflow-scripts.mjs` ends **2423 passed, 1 failed** on the operator
server (Amazon Linux 2023, aarch64, measured 2026-08-12 22:00 UTC) while passing in CI
and in the routine web sessions. The failing assertion is *"and its window_events
survived the transport change"* (`scripts/test-workflow-scripts.mjs:7122`), which expects
`missions[0].window_events` to have length 1 on the argv-ceiling corpus
(`testScanWindowOversizedCorpus`).

The suite is the local verification gate `CLAUDE.md` names, and it is supposed to be
hermetic — "creates throwaway repositories under the OS temp dir, never touches the
working tree, never calls `gh`/network". A fixture whose verdict depends on the machine's
wall clock or timezone breaks that promise: it makes the gate unusable off the routine
image and trains a reader to ignore a red line.

**Localization already measured during proposal discovery** (confirm it first, do not
assume it): the fixture writes a mission changelog line hardcoded to `2026-08-12`
(`test-workflow-scripts.mjs:7087`), while `scan-window.sh` derives its window cutoff from
the repository's own commits —
`git log --since="$WINDOW" --format=%cd --date=format:'%Y-%m-%d' --reverse | head -n1`
(`catch/scripts/scan-window.sh:249-251`) — and then keeps only events with
`.date >= $cutoff`. `%cd` renders each commit in **the offset the commit itself recorded**,
i.e. the committer's local timezone at fixture-creation time, so the cutoff is *the run's
own today, locally*. Reproduced here: an identical empty commit made under `TZ=Asia/Tokyo`
at 2026-08-12T23:19Z yields cutoff `2026-08-13`; under `TZ=UTC`, `2026-08-12`. With a
`2026-08-13` cutoff the hardcoded `2026-08-12` event is filtered out, `window_events` is
empty, and the assertion fails — exactly the operator server's symptom.

Two consequences follow, and the second is why this is not merely an environment quirk:

- Any machine whose local offset is ahead of UTC fails the fixture during the last hours
  of the UTC day (JST from 15:00 UTC onward).
- The hardcoded date is a **time bomb everywhere**: from 2026-08-13 onward the cutoff is a
  later day than the frozen event on *every* machine, CI included. The operator server
  merely crossed the boundary first.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testability.md` — deterministic, hermetic verification
- `workaholic:development` / `policies/qa-ownership.md` — the local gate must be trustworthy

## Key Files

- `scripts/test-workflow-scripts.mjs` — `testScanWindowOversizedCorpus` (~7077-7128); the
  hardcoded changelog date at :7087 and the `window_events` assertion at :7122.
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — `WINDOW_START_DATE`
  (:249-251) and the `jq` window filter `($cutoff == "" or .date >= $cutoff)` (:284-286);
  the transport change (`--slurpfile`) the assertion guards is at :270-283.
- `plugins/workaholic/skills/mission/scripts/append-changelog.sh` — the production writer
  of those lines; `DATE="${4:-$(date +%Y-%m-%d)}"`, i.e. the machine's **local** date, and
  it accepts an explicit date "for deterministic tests".
- `outputs/workflows/skills/catch/scripts/scan-window.sh` — generated mirror; rebuild if
  the script side changes.

## Implementation Steps

1. **Reproduce and confirm the localization before changing anything.** Run the fixture
   in isolation on both environments (operator server and a UTC container). Print the
   `WINDOW_START_DATE` the run derives and the `window_events` array `scan-window.sh`
   emits, and diff them. The claim to confirm is that the cutoff is the run's *local*
   today and the event date is frozen at `2026-08-12`; a cheap check is running the same
   fixture under `TZ=UTC` and `TZ=Asia/Tokyo`, and again with the system clock (or
   `GIT_COMMITTER_DATE`) advanced one day. If the measurement disagrees with the
   localization above, follow the measurement and record the divergence.
2. **Decide where the defect is, on that evidence.** Expect it to be fixture-only:
   production writes changelog dates with local `date +%Y-%m-%d` and reads a cutoff
   formatted from local commit offsets, so the two sides agree in a real repository. Only
   if step 1 shows the *script* dropping an event it should keep — e.g. a genuine
   local/UTC mismatch between writer and reader on the boundary day — does
   `scan-window.sh` change; say which in the Final Report either way.
3. **Make the fixture derive both dates from one clock.** Pin the fixture's commits to an
   explicit `GIT_AUTHOR_DATE`/`GIT_COMMITTER_DATE` at a fixed `+00:00` offset and write the
   changelog line with that same date string, so the cutoff and the event are two views of
   one value rather than one derived and one frozen. Keep the timestamp inside the
   `"2 weeks ago"` window (derive it from now, do not freeze it in the past, or the window
   filter stops being exercised at all). The fixture must stay generated-not-committed and
   sized from `MAX_ARG_STRLEN`, which is the property it exists to test.
4. **Sweep for the same pattern.** Grep the suite for fixtures that compare a hardcoded
   `YYYY-MM-DD` against a value the run derives from *now*
   (`.workaholic/missions/**` changelog lines are the main shape; `scan-window`,
   `commit-kpi` and story-window fixtures are the candidates). Fix any second site the
   same way; if there is none, say so — the sweep's result is part of the deliverable.
5. **Re-run the whole suite on both environments** and record the counts.
6. If `scan-window.sh` changed at all, rebuild the generated bundle
   (`node scripts/build-plugins/build.mjs`) and re-run `verify.mjs`, then update any
   affected documentation in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `node scripts/test-workflow-scripts.mjs` passes with **0 failures** on the operator
  server (Amazon Linux 2023, aarch64) and in a UTC container.
- The argv-ceiling fixture passes under at least `TZ=UTC` and `TZ=Asia/Tokyo`, and with the
  effective date advanced by a day — no wall-clock date is hardcoded on one side of a
  comparison whose other side is derived from the run's own clock.
- The fixture still crosses `MAX_ARG_STRLEN` and still asserts the mission join and
  `window_events` over the whole corpus; nothing is weakened to make it pass (an assertion
  deleted or relaxed to `>= 0` fails this gate).
- The Final Report names the verdict of step 2 (fixture-only vs. script defect) and the
  result of the step-4 sweep.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` on both environments; paste the trailing
  `N passed, M failed` line from each.
- `TZ=Asia/Tokyo node scripts/test-workflow-scripts.mjs` and the same under `TZ=UTC`.
- A one-day-ahead run (e.g. `faketime`, or an explicit `GIT_COMMITTER_DATE`/system-clock
  shift on the throwaway repo) showing the fixture still green.
- If `scan-window.sh` changed: `node scripts/build-plugins/build.mjs` clean, then
  `node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- The suite is green on both environments, and no assertion in the touched fixture was
  removed or loosened.

## Considerations

- **The reporter's suspicion is a hypothesis, not the diagnosis.** The issue names
  "locale/tool differences the transport change exposed" and the file-not-argv path from
  the PR #391 lineage. The `--slurpfile` transport is what the assertion *guards*, and the
  discovery above points at the date comparison instead — but step 1 confirms this on the
  failing machine before any edit; do not let either framing (the reporter's or this one)
  stand in for a measurement.
- **"Pin the fixture inputs" has a trap.** Freezing the commits at a date in the past
  eventually pushes them outside `"2 weeks ago"`, at which point `WINDOW_START_DATE` is
  empty, the filter degrades to "keep everything", and the assertion passes without
  testing the windowing it is named for. Derive the pinned timestamp from now; do not
  hardcode a calendar day.
- **A real-repository edge worth noting but not fixing here**: the cutoff is formatted from
  the earliest in-window commit's *recorded* offset while `append-changelog.sh` stamps the
  reader's *local* date, so a mission event written on a boundary day by a contributor in
  another timezone can fall one day either side of the cutoff in `/catch`. Nobody has
  reported it; if step 1 turns it up as the real cause, it becomes this ticket's subject,
  otherwise leave it as an observation.
- The generated `outputs/workflows/` mirror of `scan-window.sh` must not be hand-edited;
  it is rebuilt or it is untouched.

## Final Report

Development completed as planned.

**Step 1 — reproduced before changing anything.** An isolated repro (a throwaway repo with
the fixture's mission changelog, run against `scan-window.sh`) printed the derived cutoff
next to the emitted `window_events`, at 2026-08-12 23:36 UTC:

| run | cutoff (`%cd`) | `window_events` |
| --- | --- | --- |
| `TZ=UTC` | `2026-08-12` | the `2026-08-12` event, kept |
| `TZ=Asia/Tokyo` | `2026-08-13` | `[]` — the operator server's symptom |
| commit pinned to 2026-08-14 | `2026-08-14` | `[]` — the same failure on any machine |

The measurement matches the localization the ticket recorded: `%cd` renders each commit in
the offset that commit itself recorded, so the cutoff is the run's own local today, while
the changelog line was frozen at `2026-08-12`.

**Step 2 — verdict: fixture-only.** `scan-window.sh` is not changed. In a real repository
both sides are local: `append-changelog.sh` stamps `date +%Y-%m-%d` and the cutoff is
formatted from local commit offsets, so writer and reader agree. Only the fixture pinned one
side to a calendar constant. (`build.mjs` ran clean with no diff, which is the same fact
from the generated side: no script changed, so `outputs/` did not move.)

**Step 3 — one clock on both sides.** `testScanWindowOversizedCorpus` now pins the repo's
only commit to an explicit `+00:00` instant derived from `Date.now()` (24 h back, so it is
inside the `"2 weeks ago"` window and never in the future) and dates the changelog event
with that same string — cutoff and event are two views of one value. A second changelog
line 30 days back was added so `window_events.length === 1` proves the cutoff still
*filters*, and a new assertion names the surviving artifact. Nothing was removed or
loosened; the corpus is still sized from `MAX_ARG_STRLEN` and still generated, not
committed.

**Step 4 — sweep result: one site.** Every other `YYYY-MM-DD` constant in the suite is
compared against a date the fixture itself passes to the script (`append-changelog.sh`,
`close.sh`), or is deliberately far outside the window and stays there (`2010-01-01` in
the commit-KPI fixture). The other two `window_events` fixtures already derive both sides
from the run's clock: `testScanWindowMission` writes its changelog through `archive.sh` at
real now, and the deployments fixture pins its commits with `GIT_*_DATE` computed from
`now`. No second site to fix.

### Discovered Insights

- **Insight**: `git log --date=format:'%Y-%m-%d'` with `%cd` renders in the *commit's own*
  recorded offset, not the reader's — so `scan-window.sh`'s window cutoff is "today" in
  whatever timezone the earliest in-window commit was made in.
  **Context**: any future fixture or feature comparing a date string against that cutoff
  has to derive both sides from one clock. Freezing the pinned instant at a calendar day is
  the trap in the other direction: once it drifts outside the window the cutoff goes empty,
  the filter degrades to "keep everything", and the assertion silently stops testing the
  windowing it is named for.
- **Insight**: this defect was latent-by-date, not environment-specific. The operator server
  (JST) merely crossed the boundary a few hours before every other machine would have on
  2026-08-13.
  **Context**: a red line on one developer's machine that CI cannot reproduce is worth
  reading as a clock or locale question before a platform one.
