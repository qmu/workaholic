---
created_at: 2026-09-01T12:24:48+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-the-tick-add-to-a-standing-thread-instead-of-restating-itself
merge_policy:
verification_handoff: 
---

# Drill the day-keyed root and the stabilized post gate offline

## Overview

PROPOSED. Both behaviours this mission ships are only observable through Slack, which no
hermetic test can reach — so without a drill the regression that returns them to an hourly root
is invisible until somebody reads the channel and counts. `scripts/e2e/loop-drill.sh` already
drills the loop's own mechanisms offline, with one CI matrix leg per drill so the red check is
named after the drill. This adds `verify-tick-thread` there and registers it, so the day-keyed
root and the stabilized gate each have a breaker written against the behaviour.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; `verify-all` derives what it runs from its own `case` arms plus the register.
- `docs/loop-drill-runbook.md` §9 — the drill register, one table, one reader.
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check names the drill.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's reader.

## Implementation Steps

1. Add a `verify-tick-thread` arm to `scripts/e2e/loop-drill.sh`, hermetic: no credential, no
   network, no Slack. It drives `lib/tick-thread-key.sh` and `render-tick-post.sh` over
   fixtures and asserts behaviour, never a return shape.
2. Assert the two behaviours this mission bought, each phrased as the failure it would catch:
   two ticks an hour apart on one local day resolve **one** key (a regression to a per-tick key
   fails here); and two summaries differing only in a transport-derived per-item state open
   **no** root (a regression that re-embeds the pair list fails here).
3. Assert what must not move with them: a tick either side of the day boundary still gets its
   own root, and a pull request entering or leaving the stuck set still opens one. A drill that
   only proves the silence would pass a change that silenced everything.
4. Register the drill in `docs/loop-drill-runbook.md` §9 with a **`bearing: "breaker"`** row
   written against the behaviour — an unregistered drill reads `skipped:unclassified` and fails
   `test-workflow-scripts.mjs`; a registered one with no breaker row is `unproved` and counted
   outside the passing total.
5. Confirm it runs as its own matrix leg in `loop-drills.yml`, so `/moderate`'s `drill-health`
   step can name it when it goes red.
6. Add the failure-reason → file blame row the runbook keeps, so a red leg points at the file
   to open.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-tick-thread` passes offline with no credential.
- `verify-all` includes it and reports it in the drill vocabulary (`pass` / `fail` /
  `skipped:<reason>`).
- The register carries a `bearing: "breaker"` row, so the drill is not counted `unproved`.
- Reverting either behaviour change turns the drill red.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-tick-thread`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs` — the unclassified-drill row.
- Revert each behaviour locally and confirm the drill fails; restore.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-all`

## Considerations

- **The revert test in step 4 of the verification is the point of the ticket.** A drill that
  passes both before and after the change proves nothing; the register calls that `unproved`
  by name, and it is the easy failure mode here because both behaviours are about something
  *not* being posted.
- Drive this last: it drills what the first four tickets build, and writing it earlier means
  writing it against a design that has not settled.
- The drill must stay hermetic. Reaching Slack to prove a thread would make it a credentialed
  drill, which `loop-drills.yml` cannot run on every push — and then the regression is invisible
  again, which is the defect this ticket exists to close.
