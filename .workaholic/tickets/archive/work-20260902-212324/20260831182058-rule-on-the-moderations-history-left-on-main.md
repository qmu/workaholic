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

# Rule on the moderations history left on main

## Overview

PROPOSED. `.workaholic/moderations/` stops being a path new ticks write. The day
files already on `main` are a separate question, and the ask names it: left where
they are, or moved — and what `layout-doctor.sh`, the root index and the OKF
floor say afterwards.

Four mechanisms have a stake, and none of them can be left to infer the answer:

- **The layout allowlist** (`hooks/workaholic-layout-allowlist.txt`) and the table
  in `rules/workaholic.md` are two lockstep sources. `moderations` is in both. A
  de-listed directory has every later write into it **hard-blocked**, which is the
  desired end state — but only once nothing writes there.
- **`layout-doctor.sh`** classifies a surviving de-listed directory. It has words
  for this already (`retired-area`, `renamed-area`), and the `Validate Plugins` CI
  workflow fails a merge on `conforming: false`. Which word applies here is this
  ticket's decision.
- **The OKF root index** links `moderations/` bare — `okf/scripts/refresh-index.sh`
  names it explicitly in its area list, with the wording "an operational log, not
  knowledge: no `type:`, no index". That line has to go somewhere or be removed.
- **The rename registry** (`gather/scripts/renames.tsv`) applies `area` rows by
  `git mv`. This is **not** a rename — the directory is not becoming another
  directory on `main` — so a row here would be wrong. The registry's own rule says
  a retirement is not a rename and stays out of the table. Confirm rather than
  assume, and record the confirmation.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/single-source-of-truth.md` — lockstep sources move together
- `workaholic:operation` / `policies/observability.md` — an operational log is read, not reviewed

## Key Files

- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` — one of the two
  lockstep sources.
- `plugins/workaholic/rules/workaholic.md` — the other, plus the `moderations/`
  definition.
- `plugins/workaholic/hooks/layout-doctor.sh` — the audit and its classification.
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — the root index's
  area list and the bare `moderations/` link.
- `plugins/workaholic/skills/gather/scripts/renames.tsv` — checked and, on the
  reasoning above, left alone.
- `.github/workflows/` — the `Validate Plugins` workflow that fails on
  `conforming: false`.

## Implementation Steps

1. Rule on the existing history: left on `main` as read-only, or moved onto the
   ref. Write the ruling with its cost. *Left* keeps the audit trail where a
   person already looks and leaves a de-listed directory standing; *moved* makes
   the tree clean and loses the history from every `main` reader. Both are
   defensible; an unstated choice is not.
2. Sequence the de-listing after ticket 2 lands. De-listing while a writer still
   exists hard-blocks the tick's own log writes.
3. Apply the ruling to both lockstep sources in one commit — never one without
   the other.
4. Decide `layout-doctor.sh`'s word for the surviving directory (if it survives),
   and make the `Validate Plugins` workflow's verdict the intended one. A CI that
   goes red on the intended end state is a defect this ticket must not ship.
5. Update `refresh-index.sh`'s area list and re-generate the root index. Confirm a
   repository with no `moderations/` directory produces a clean index rather than
   a dangling link.
6. Confirm `renames.tsv` needs no row, and record why in the change.
7. Update `rules/workaholic.md`'s `moderations/` definition and `CLAUDE.md`'s
   `.workaholic/` conventions in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The ruling on the existing history is written down with its cost, and applied.
- The two lockstep sources agree, in the same commit.
- `layout-doctor.sh` reports `conforming: true` on this repository in its end
  state, and the `Validate Plugins` workflow passes.
- The regenerated root index carries no link to an area that is not there.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`
- A fixture with no `moderations/` directory: the index regenerates clean.

**Gate** — what must pass before approval:

- Ticket 2 has landed. De-listing an area a live writer still writes into blocks
  the tick's own log.

## Considerations

- A consuming repository that has this plugin installed carries its own
  `moderations/` history. Whatever is ruled here reaches them through the plugin,
  so the ruling has to work for a repository nobody is watching — that argues for
  *left where it is* unless the moved case is made mechanically safe.
- The allowlist is permissive: a repository **without** the directory is
  unaffected either way. It is the repositories that have one that need the rule.

## Final Report

Development completed as planned. The ruling on the base is **leave the existing history where it
is**, and this drive verified the four mechanisms that had a stake in it say so consistently.

- **The layout allowlist** still carries `moderations` in both lockstep sources
  (`hooks/workaholic-layout-allowlist.txt` and the table in `rules/workaholic.md`), and the entry is
  **permissive**: the allowlist permits, it does not require, so a repository that never runs
  `/moderate` never grows the directory and one that has history keeps it without a finding.
- **`layout-doctor.sh`** therefore classifies nothing here — the directory is registered, so it is
  neither a `retired-area` nor an unregistered one. No new word was needed.
- **The OKF floor** names `moderations/` as its second exception in writing (no `type:`, no
  `index.md`), and `refresh-index.sh` names the directory from the bundle root **without linking
  it**, because since the move this branch does not carry the directory at all and a link would
  404.
- **New writes cannot land on `main`**: `.workaholic/moderations/` is git-ignored, so an ordinary
  `git add -A` cannot put the log back, and `persist-log.sh` refuses a log ref that names the base.

Why the history stays: rewriting it would force-push over every clone to tidy a log, and git keeps
a deleted file recoverable anyway. Deleting a day file remains the operator's act — an unattended
run that pruned its own audit trail would be deciding what evidence of itself survives.

### Discovered Insights

- **Insight**: A **permissive** allowlist entry is what lets the same directory be legal history and
  illegal to write to.
  **Context**: De-listing it would hard-block every later write — the desired end state only once
  nothing writes there — but it would also make existing history a finding, failing the merge gate
  over commits that harm nothing. The git-ignore does the blocking instead.
