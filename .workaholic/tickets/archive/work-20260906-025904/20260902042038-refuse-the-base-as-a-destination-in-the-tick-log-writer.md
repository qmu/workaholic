---
created_at: 2026-09-02T04:20:38+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
claim: work-20260906-025904
---

# Refuse the base as a destination in the tick log writer

## Overview

PROPOSED. `persist-log.sh` publishes the tick log to the ref `gather/scripts/log-ref.sh`
derives, and on this repository that is the orphan `workaholic-log` branch. On a
repository that has not converged, the same code path wrote the day files straight to the
base — measured on a consuming repository, 2026-08-20 through 2026-08-31: hundreds of
`Log the propose tick` / `Log the moderation tick` commits, 12 day files, roughly 7,000
lines. The base was the pre-migration *default*, so nothing refused it.

This ticket makes the base an outright refusal rather than a default. The writer resolves
its destination, compares it to the base branch, and when the two are the same it writes
nothing, names the refusal, and lets the caller report it — whatever the migration state
of the repository it runs in.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a machine writer's destination is part of its runtime contract

## Key Files

- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the one writer of the tick
  log; the refusal belongs here, beside the destination resolution it already performs.
- `plugins/workaholic/skills/gather/scripts/log-ref.sh` — the one derivation of the log
  ref; the base comparison reads its answer rather than re-deriving one.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the caller that reports each
  step's outcome; a refusal here is reported by name, never swallowed.
- `plugins/workaholic/skills/moderate/SKILL.md` — states what the tick persists and where;
  the refusal is stated where the seam is described.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the refusal is pinned here.

## Implementation Steps

1. Read `persist-log.sh` end to end and locate every point at which the destination ref is
   resolved, including the `--record` path that deliberately targets the base. Record which
   writes are log writes and which are record writes — the refusal must not touch the
   second, because a feedback record belongs on the base by design.
2. Add the destination check in `persist-log.sh`: when the resolved *log* destination
   equals the base branch, write nothing and emit a named refusal (a `reason` word of its
   own, e.g. `log_destination_is_base`) with exit 0, so the tick continues and reports it.
3. Leave `--record`'s base-targeting write untouched and assert that in the code's own
   comment, so a later reader does not widen the refusal into it.
4. Report the refusal through `run.sh`'s existing per-step reporting, as `degraded` with
   the reason, so a tick that could not persist its log says so rather than looking quiet.
5. State the refusal in `workaholic:moderate` beside the existing description of the
   persist seam, and in `CLAUDE.md`'s `.workaholic/` runtime conventions where the off-main
   log is described.
6. Add a hermetic test in `scripts/test-workflow-scripts.mjs` that runs the writer in a
   throwaway repository whose log ref resolves to the base and asserts: nothing committed,
   the named refusal on stdout, exit 0.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `persist-log.sh` writes no commit when the resolved log destination is the base branch,
  and names the refusal.
- The `--record` path still lands feedback records on the base, byte-identically.
- A tick whose log persist was refused reports it as a named degradation rather than `ok`.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A throwaway repository where `log-ref.sh` resolves to the base: run `persist-log.sh` and
  assert `git log` on the base is unchanged.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, including the new assertion.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

## Considerations

- The refusal must be keyed on the *destination*, never on whether a migration has run:
  keying it on migration state reproduces the defect on any repository whose migration
  is incomplete.
- A repository that has not converged will now have its tick log refused rather than
  written to the base. That is the intended outcome and it is why the sibling ticket
  *Complete the log move from the tick* exists: refusing alone leaves such a tick with no
  memory, so the two ship together.

## Final Report

Development completed as planned, against a tree that had moved under the ticket. The log
branch this ticket was written for was retired on 2026-09-03, three days after the ticket was
written: `log-ref.sh`, `ensure-log-ref.sh`, `hydrate-log.sh` and
`migrate-moderations-off-main.sh` are deleted, `.workaholic/moderations/` is git-ignored, and
`persist-log.sh` no longer resolves a log destination at all. Step 1's enumeration therefore
found **one** road left from this writer to the base — the `--record` path — and that road takes
whatever a caller names, so a record naming a `.workaholic/moderations/` day file would put the
log back on `main` through the publication seam. The refusal is keyed on that destination.

`persist-log.sh` refuses `log_destination_is_base` with nothing written and exit 0, before the
publish tree is opened. `--record`'s ordinary base write is untouched and the code says in its
own comment that it must not be widened into. `run.sh` needed no change: it already reports the
persist's `status`/`reason` verbatim, so the refusal reads as a named degradation.

### Discovered Insights

- **Insight**: `report()` in `persist-log.sh` exits, so the guard cannot live in a
  `printf | while read` pipeline — the body runs in a subshell and the `exit` would end only
  that subshell, letting the refused call carry on into the publication.
  **Context**: several readers in this tree use that pipeline idiom for record lists; any of
  them that grows an early-exit refusal has the same trap. The guard uses a newline-`IFS` `for`
  loop instead, which runs in the caller's own shell.
- **Insight**: the retirement left the *name* `persist-log.sh` and every call site in place on
  purpose, so the script's header is now the only record that the log half ever existed.
  **Context**: a reader who greps for the log's publication finds a script whose name promises
  it and a body that refuses it; the header paragraph is load-bearing documentation, not
  commentary.
