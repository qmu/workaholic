---
created_at: 2026-08-31T18:20:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
---

# Keep the tick's feedback records on the base

## Overview

PROPOSED. `persist-log.sh` carries two payloads on one commit, and only one of
them is moving. The tick log is an operational log and leaves `main`; the
**feedback records** the tick writes (`--record <repo-relative-path>`, added
2026-08-23) are knowledge under the OKF floor, cited by missions and tickets
through the `feedback:` relation, and they belong on `main` exactly where they
are. A change that moved them onto the log ref would make every `feedback:` ref
the loop later writes unresolvable.

So the seam splits. This ticket makes the split explicit and keeps the record
half's contract intact: records are named **one by one**, never a sweep of
whatever is staged (which would let an unrelated container file reach the base);
a record already on the base is left untouched, because a feedback record is
immutable; and each is reported `carried` / `already_on_base` / `missing` /
`unreadable`.

`filed-records.sh` asks the **tree** whether a record landed, and an `unlanded`
record counts as not filed. That reader must keep answering about the base after
the split — a `<step>-filed` line on the log ref is not evidence of a filing.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/error-handling.md` — a degradation is named, never silent
- `workaholic:design` / `policies/data-handling.md` — knowledge and operational log have different homes

## Key Files

- `plugins/workaholic/skills/moderate/scripts/persist-log.sh` — the `--record`
  carry and its per-record reporting.
- `plugins/workaholic/skills/moderate/scripts/filed-records.sh` — asks the tree
  whether a record landed; must keep asking the base.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the call sites that pass
  `--record`.
- `plugins/workaholic/skills/feedback/scripts/create.sh` — stages a record and
  stops, which is why the carry exists at all.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — the feedback area's
  index, regenerated before a knowledge commit.

## Implementation Steps

1. Separate the two payloads at the seam: the day file goes to the ref (ticket 2),
   the named records go to the base. Decide whether the record carry stays in
   `persist-log.sh` or moves to its own script, and state the reason either way.
2. Keep the record contract byte-for-byte: named one by one, an already-landed
   record untouched, per-record `carried` / `already_on_base` / `missing` /
   `unreadable` in the output.
3. Keep the record commit going through the publish tree onto the base, with the
   caller's checkout left byte-identical and no branch created.
4. Prove `filed-records.sh` still answers about the **base**. If it reads the tick
   log to find candidates, it must still resolve each against the base tree, and
   an `unlanded` record must still count as not filed.
5. Make the two halves independent in their reporting: a log persist that failed
   must not be reported as a failed filing, and a record that could not be carried
   must not be hidden by a successful log persist.
6. Update `workaholic:moderate`, `rules/workaholic.md` and `CLAUDE.md`, which
   currently describe both payloads as riding "the same commit".

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A tick that writes a feedback record lands that record on `main` and its log on
  the ref, in one run.
- Each record is still reported by its own word; a record already on the base is
  byte-identical afterwards.
- `filed-records.sh` answers `unlanded` for a record that reached neither, and
  never reports a filing from a `<step>-filed` log line alone.
- One half failing is reported as that half failing, with the other's outcome
  unchanged.

**Verification method** — the commands/tests/probes that prove them:

- A hermetic fixture: a tick with one new record and one already-landed record;
  assert both destinations and both reported words.
- `node scripts/test-workflow-scripts.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- A test that fails if records are written to the log ref. Without it the whole
  point of this ticket is unenforced.

## Considerations

- This is the one commit the tick still makes to `main`, and it is a small,
  bounded, knowledge-carrying one. The mission's aim is a `main` of product
  change; a feedback record **is** a change to the shared record. Say this in the
  documentation so a later reader does not "finish the job" by moving it too.
- Watch the OKF index refresh: a record commit still regenerates the feedback
  area's index, and that regeneration must not drag the log area's absence into
  the same diff.

## Final Report

Development completed as planned. The seam is split: the log goes to its ref, the tick's
feedback records stay on the base through the publish tree.

- **The record carry stays inside `persist-log.sh`** rather than moving to its own script.
  Reason: the caller contract (`--record <path>`, one flag on the tick's closing act) is
  what `run.sh` already passes at three call sites, and a second script would mean a second
  call site to keep in step for no change in behaviour. The two halves are separate code
  paths inside one script, each with its own destination, seam and reported outcome.
- **The record contract is byte-for-byte**: named one by one, never a sweep; an
  already-landed record left untouched; per-record `carried` / `already_on_base` /
  `missing` / `unreadable`.
- **The halves report independently.** A publish tree that would not open is reported with
  its own reason and the log's outcome beside it, so a failed carry is never hidden by a
  log persist that worked, and a failed persist is never reported as a failed filing.
- **A tick with no records opens no publish tree and commits nothing to the base**, which
  is what makes "no commit on the base writes the log" true of the whole script.
- `filed-records.sh` needed no change and the reason is now written down.

### Discovered Insights

- **Insight**: `filed-records.sh` survives the split untouched because its oracle is *the
  tree*, and records did not move. A routine's container is a fresh clone of the base, so a
  record in the checkout is a record on the base — the same equivalence, still true.
  **Context**: the ticket anticipated repair work here. What it actually needed was the
  reason stated, so a later change that moves records cannot quietly break the reader.

- **Insight**: the argument against moving records is stronger than "they are knowledge" —
  it is that the `feedback:` relation resolves a record **by its path on the base**. On an
  orphan ref no `.workaholic/` reader fetches, every ref the loop later wrote would dangle.
  **Context**: written into the skill so a later reader does not "finish the job".
