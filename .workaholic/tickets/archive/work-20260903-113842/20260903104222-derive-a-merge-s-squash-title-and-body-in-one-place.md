---
created_at: 2026-09-03T10:42:22+09:00
status: done
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

## Final Report

**Outcome**: implemented.

**Reproduced and localized first**, as step 1 required. On this repository's `main`: **48** commits
whose message body carries the text `Refresh heartbeat`, and **48 of 48** have a subject that is
*not* `Refresh heartbeat` — every one is a squash body rather than a heartbeat commit. The longest
is 11,515 lines (`499a7435`). Reading the five REST merge call sites confirmed the other half:
**zero** of them passed `commit_message` or `commit_title`; the repository contained no occurrence
of either string.

**Added** `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh`, the sibling of
`merge-method.sh`: `merge-commit-body.sh <number>` or `--branch <branch> [--number <n>] [--title <t>]`,
emitting `{ok, title, body, source, reason}` on stdout and nothing else. `source` is three-valued and
each is named — `story` (the branch story's `description:` line), `fallback` (one sentence naming the
unit and its pull request, a publication's ordinary answer), `unreadable:<reason>` (which **still**
yields the fallback body, so a composer failure never hands the forge its default back by omission).
The body appends the branch's own commit subjects with housekeeping-marked ones dropped, capped at
`WORKAHOLIC_MERGE_BODY_MAX_SUBJECTS` (40, remainder counted) and `WORKAHOLIC_MERGE_BODY_MAX_BYTES`
(8000, a truncation that says so). It writes no file, touches no ref, and its one network read is the
pull-request lookup `--branch` skips.

**Two implementation notes worth keeping.** The obvious `%s%x00%b` single-walk record format cannot
work: a command substitution drops NUL bytes, so every commit body ran into the next subject and the
first version emitted one mangled entry. The shipped shape is two walks — subjects, and `git log
--grep='^Workaholic-Housekeeping:'` for the marked set — which loses no separator and leaves the
marker test as git's own. And the ticket's own hypothesis held: the branch story is the right source,
and the fallback covers the publication case the ticket named.

**No call site was changed by this ticket** (its gate says so); the five are the four tickets after it.

**Verified**: `node scripts/test-workflow-scripts.mjs` — the new row *the squash body is one
derivation, and no call site spells it* exercises all three `source` values plus the marker filter and
the write-nothing assertion.
