---
created_at: 2026-08-13T07:26:28+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refresh-the-outdated-documentation-to-match-current-behavior
merge_policy:
---

# Correct the outdated statements in the root README

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

`README.md` is the document a reader learns the loop from, and it carries statements
the shipped code contradicts. It was last touched at `1fbf9ba` (2026-08-12) with 79
commits on `main` since, and the drift is concentrated where the loop changed fastest.

The ask names no passage, so this ticket **locates the drift first and then corrects
it** — the proposal-time pass below is evidence to confirm, not the work list to
apply blind.

Measured against `origin/main` at `cdcbfe1`:

- `README.md:59` and `README.md:288` — "`/propose` … runs unattended in the
  `[Propose]` routine's session, on the reported ask rather than on a clock". The
  routine has fired on a fixed hourly schedule (`15 * * * *`) since 2026-08-12 and a
  tick that starts empty discovers its own asks (`workaholic:propose`, *Clock-fired
  discovery*; `propose/scripts/list-inbound-issues.sh`).
- `README.md:59`, `README.md:94`, `README.md:262` — the human merge of the proposal
  pull request as the approval seam. Proposal pull requests auto-merge on opening
  (`WORKAHOLIC_AUTO_MERGE=1`); quality is gated at the `release/*` QA window, and a
  release-scan finding is the one thing that leaves such a PR open.
- `README.md:68` — `/setup-routines` "renders copy-paste setup sheets … **It manages
  nothing**". Its contract is to *configure* the routines through a `RemoteTrigger`-family
  tool on every run, with the sheets demoted to the no-transport refusal's recovery path.
- `README.md:24` — the portable workflow list names six skills (`create-ticket`,
  `drive`, `report`, `ship`, `catch`, `mission`); `outputs/workflows/skills/` ships
  eight (`review-sections` and `write-release-note` are also there).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/commit-change-history.md` — the change and its docs land together

## Key Files

- `README.md` — the only file this ticket edits.
- `CLAUDE.md` — the current-behavior reference every corrected passage is measured
  against (**not** edited here; repository policy already keeps it current per change).
- `plugins/workaholic/skills/propose/SKILL.md` — *Clock-fired discovery* and the
  auto-merge seam, in the skill's own words.
- `plugins/workaholic/skills/workaholify/SKILL.md`, `plugins/workaholic/commands/setup-routines.md`
  — the current `/setup-routines` contract.
- `outputs/workflows/skills/` — the shipped portable skill set the README's list must match.

## Implementation Steps

1. **Localize before editing.** Walk `README.md` section by section against `CLAUDE.md`
   and the shipped skills/commands, and write down every passage that disagrees —
   confirming or dropping each item in the Overview and adding whatever it missed. The
   list above is a proposal-time reading of a 460-line document, not an exhaustive audit.
2. Correct the `/propose` rows and prose (`:59`, `:288`) to the clock-fired routine and
   its self-discovered asks, naming the hourly schedule and `list-inbound-issues.sh`.
3. Correct the approval seam (`:59`, `:94`, `:262`) to auto-merge-on-opening with quality
   gated at the `release/*` QA window, keeping the human ruling where it still lives —
   `merge_policy` recorded at creation, and the release window itself.
4. Correct the `/setup-routines` row (`:68`) to the configure-first contract with the
   sheets as the refusal's recovery path.
5. Correct the portable workflow list (`:24`) against `outputs/workflows/skills/`.
6. Apply the rest of step 1's list. Leave deliberate history in place: the retired
   `/trip`, `/monitor`, `/carry` and `/request` passages are prose *about* retirement
   and are correct as written — do not "fix" them.
7. Re-read the edited sections end to end for internal consistency: a corrected row must
   not contradict the walkthrough or the diagram legend three sections down.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No passage in `README.md` contradicts `CLAUDE.md`, the shipped commands, or the shipped skills.
- The four measured drifts above are corrected, or the ticket's Final Report says why a
  given one was not drift after all.
- Only `README.md` changed; no command, skill, script, or hook behavior was touched.

**Verification method** — the commands/tests/probes that prove them:

- `grep -nE "rather than on a clock|manages nothing" README.md` returns nothing.
- The portable workflow list is diffed against `ls outputs/workflows/skills/`.
- `git diff --name-only <base>..HEAD` lists `README.md` and nothing else.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green (unchanged by a prose-only edit, run as a regression guard).
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

## Considerations

- The README is deliberately long and narrative. Correct the statements; do not take the
  opportunity to restructure or compress it — a rewrite would bury the corrections in a
  diff nobody can review.
- `CLAUDE.md` is the reference here, not a subject. If a passage disagrees with it and
  **`CLAUDE.md`** turns out to be the wrong one, that is a separate finding: record it as
  feedback rather than editing `CLAUDE.md` inside this ticket.

## Final Report

Development completed as planned. The README was walked section by section against
`CLAUDE.md` and the shipped skills; three of the four proposal-time drifts were
confirmed and corrected, one was **dropped as not drift**, and four further
contradictions the proposal-time pass missed were found and corrected.

**Confirmed and corrected:**

1. `/propose` "on the reported ask rather than on a clock" (the command table row and
   the use-case-3 closing paragraph) — replaced with the fixed hourly schedule
   (`15 * * * *`) and clock-fired discovery of the issues assigned to it
   (`list-inbound-issues.sh`).
2. The proposal approval seam (the `/propose` row, the use-case-3 prose, and the
   mermaid edge label `the human ruling: merging the PR`) — replaced with
   merge-on-opening, a scan finding as the one thing that leaves the PR open, and the
   human judgment relocated to `merge_policy` plus the `release/*` QA window.
3. `/setup-routines` "**It manages nothing**" — replaced with the configure-first
   contract (list → diff against template → converge → report), the setup sheets
   demoted to the `no_transport` refusal's recovery path.
4. The portable workflow list — the six script-bearing workflow skills kept as they
   were, with `review-sections` added beside `write-release-note` as the second
   exposed prose skill and the bundle's true count (eight) stated, matching
   `ls outputs/workflows/skills/`.

**Dropped — not drift:** the Overview named `README.md:94` (the overnight-session
block's "you merge that pull request: the merge is the approval") as part of the
approval-seam drift. It is **correct as written**: `WORKAHOLIC_AUTO_MERGE=1` is opt-in
for `/propose` and `/implement` only, and `branching/SKILL.md:57` states explicitly
that "`/ticket`'s and `/mission`'s PRs keep their human merge". Line 94 is a `/mission`
publication, so its human merge is still the approval. Left untouched, as were the
matching statements at `:7`, `:210` and the `/mission` command row.

**Found beyond the Overview's list:**

5. The `/drive` row said a non-`auto` unit "stops at the PR". A `review` unit now
   merges its PR as soon as `/report` opens it and the scan passes.
6. The same row said "under `/implement` the PR URL is posted to Slack" — it is one
   finish line posted into the unit's feedback-item thread.
7. The lifecycle table credited `tickets/todo/` to `/ticket` alone (`/mission` and
   `/propose` both write there) and the feedback stream to `/fb`, `/ship`, `/report`
   (`/propose` writes a record on every run and is the highest-volume writer).
8. The release-record row named `releases/release-<ts>.md`; the shipped path is
   `.workaholic/releases/<release-branch>.md` (`record-release-cut.sh:182`), and the
   cut is a batch-level act invoked explicitly rather than a step of the per-unit ship.
9. The full-map legend said `/setup-routines` "reads" the routines out of the account —
   it now reads *and converges* them.

### Discovered Insights

- **Insight**: `WORKAHOLIC_AUTO_MERGE=1` is scoped per caller, not repository-wide —
  `/propose` and `/implement` set it; `/ticket` and `/mission` deliberately do not.
  **Context**: "proposal PRs auto-merge" reads easily as "all publish-tree PRs
  auto-merge", and the four README passages about approval-by-merge are split between
  the two groups. The authoritative one-line statement is `branching/SKILL.md`'s
  `publish-tree-pr.sh` table row, not the propose skill — checking the caller rather
  than the seam is what separates a real drift from a correct sentence here.

- **Insight**: the README's Documentation table and the `.workaholic/` lifecycle table
  are the two places where drift concentrates, because both are *inventories* — a row
  goes stale when a writer is added elsewhere, and nothing in the adding change
  naturally points back at the row.
  **Context**: three of the four unlisted drifts found here were inventory rows
  (`todo/` writers, `feedbacks/` writers, the release-record path). A future
  documentation pass gets the best return per minute by diffing those two tables
  against the shipped writers first.
