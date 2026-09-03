---
created_at: 2026-09-03T10:42:22+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-the-squash-body-so-a-unit-s-housekeeping-stays-off-the-trunk
merge_policy:
verification_handoff: 
---

# Derive a merge's squash title and body in one place

## Overview

A squash merge whose API call carries no `commit_message` gets the forge's own default: the
concatenation of every commit on the branch. Nothing in this loop composes that text, so a unit's
claim stamp, heartbeats and index refreshes become the trunk's permanent record. This ticket adds
the one derivation the call sites will read — the sibling of `gather/scripts/merge-method.sh`,
which already established the shape: one script answers, every call site reads it and none spells
it.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/ci-cd.md` — what enters the trunk is a deliberate record

## Key Files

- `plugins/workaholic/skills/gather/scripts/merge-method.sh` — the sibling derivation; its header
  states why a call site may not spell the answer, and this script follows that shape.
- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — NEW. The one derivation of a
  merge's `commit_title` and `commit_message`.
- `.workaholic/stories/work-<branch>.md` — the branch story, the composed statement of what the
  unit did; the source the body prefers.
- `plugins/workaholic/skills/story/` — where the story is written, for the section the composer
  reads.


## Implementation Steps

1. **Reproduce and localize first.** On this repository, list the commits on `main` whose message
   text contains `Refresh heartbeat` and open one of them: confirm the text is a squash body and
   not a heartbeat commit. Then confirm by reading the five REST merge call sites
   (`ship/scripts/merge-pr.sh`, `branching/scripts/publish-tree-pr.sh`,
   `drive/scripts/retry-undelivered.sh`, `drive/scripts/catch-up-claim.sh`,
   `branching/scripts/settle-stranded-publication.sh`) that none of them passes `commit_message` or
   `commit_title`. Record both counts in the story.
2. Write `merge-commit-body.sh <pull-request-number|--branch <branch>>`, emitting JSON
   `{ok, title, body, source, reason}`.
3. `source` is three-valued and each is named: `story` (the branch story's summary), `fallback`
   (a one-line statement naming the unit and its pull request, when no story resolves), and
   `unreadable:<reason>`. An unreadable read takes the fallback and says so — it never returns the
   forge's default by omission.
4. Emit the body over stdout only; write no file, touch no ref, make no network call beyond the
   one a pull-request lookup needs, and never read a Slack transport.
5. Add a hermetic row to `scripts/test-workflow-scripts.mjs` covering all three `source` values.


## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `merge-commit-body.sh` answers with a `title` and a non-empty `body` for a unit with a story,
  for one without, and for one whose story could not be read.
- The script writes no file and creates no ref.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A hand run against a merged unit's branch on this repository, comparing the emitted body with
  that merge's actual squash body.

**Gate** — what must pass before approval:

- The three `source` values are each exercised by a hermetic test.
- No call site is changed by this ticket — it adds the derivation only.


## Considerations

- The ask names the branch story as the obvious source. That is the reporter's proposal and it is
  carried here as the hypothesis to test, not as a settled design: a unit with no story is the
  case the fallback exists for, and the fallback's one line is already better than the
  concatenation.
- A body has a size ceiling at the forge. The composer should stay well inside it rather than
  discover the limit at a merge.
