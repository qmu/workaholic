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
