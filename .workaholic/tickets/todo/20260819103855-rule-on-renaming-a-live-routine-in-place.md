---
created_at: 2026-08-19T10:38:55+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-workaholify-converge-the-account-s-routines
merge_policy:
verification_handoff: A RemoteTrigger-family tool over account routines — whether its update method renames in place is only answerable against a live record
---

# Rule on renaming a live routine in place

## Overview

PROPOSED. `renamed_from:` exists because convergence matches an account's
routines **by rendered name**: a template whose `name:` moved creates a *second*
routine beside the live one rather than renaming it, and no other account can
delete the survivor. That premise is written into three places as a standing
operator obligation — SKILL.md §5's rename section, both setup commands' reports,
and `render-setup-sheet.sh`'s first sheet note — and it made the 2026-08-19
`[Propose]`→`[Specificate]` swap an *ordered* manual cutover.

The reporter measured against that premise and it did not hold: *"the API's
update method renames in place, and doing so resolved this repository's
`[Propose]` -> `[Specificate]` swap in one call with no duplicate and no manual
step."* If that is right, `renamed_from:` is not an operator obligation — it is
the recovery path for the `no_transport` class, and the ordered-swap instruction
is a fallback rather than the standing rule.

This ticket rules on that, and propagates whichever answer holds. It does not
assume the reporter is right: matching is by name, so a rename in place requires
identifying the target by something *other* than its name (a stable id), and
whether the flow can do that is the actual question.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — §5's *A renamed template is
  the one convergence that cannot finish itself* and *When two renames are a
  swap, the cutover is ordered*: the two paragraphs that state the premise.
- `plugins/workaholic/skills/workaholify/scripts/render-setup-sheet.sh` — renders
  `renamed_from:` as the sheet's first note; the sheet is the no-transport
  recovery path, so this is where the instruction correctly belongs either way.
- `plugins/workaholic/skills/workaholify/routines/fb.md` (`[Specificate]`,
  `renamed_from: "[Propose] {repo_name}"`) and `prepare-release.md`
  (`[Prepare Release]`, `renamed_from: "[Release Status] …"`) — the two live
  fields; also the two the "delete once the fleet has cut over" rule applies to.
- `plugins/workaholic/commands/setup-{dev,repo,user}-routines.md` — each states
  the cutover in its report.
- `CLAUDE.md` — the routines section carries the ordered-swap instruction and the
  `[Prepare Release]` migration note at length; both change if the ruling does.

## Implementation Steps

1. **Reproduce before deciding.** Against a live account routine, determine
   whether the update method takes a stable identifier distinct from the
   rendered name, and whether updating `name` through it renames in place with
   no duplicate. Confirm by **re-reading the record**, never by the absence of an
   error — the API silently drops unknown fields. If the reporter's measurement
   cannot be reproduced, that outcome is the ruling and the rest of this ticket
   becomes documenting *why*, which is a real result and not a failure.
2. **Answer the matching question the premise rests on.** A rename in place needs
   the run to recognise `[Propose] repo` as the routine that should become
   `[Specificate] repo` — which name-matching by definition cannot do. Identify
   what supplies that link: `renamed_from:` is the obvious candidate (match the
   old name, write the new one), and it would turn the field from a human
   instruction into the convergence's own input. Rule on that explicitly.
3. **Rule on the swap case separately**, because it is strictly harder. Two
   templates trading names means an in-place rename must be *ordered* even when
   automated, or the run creates the same collision the manual instruction warns
   about. State whether the flow orders it, or refuses the swap case and keeps
   the manual instruction for it alone.
4. **Propagate the ruling.** If rename-in-place holds: SKILL.md §5's rename
   section is rewritten so `renamed_from:` is an input to convergence and the
   manual cutover is the `no_transport` recovery path; the setup commands' report
   text follows; `render-setup-sheet.sh` keeps rendering the note unchanged,
   because the sheet *is* the no-transport path. If it does not hold: the
   existing text stands and this ticket records the measurement that confirmed
   it, so the question is not re-litigated a third time.
5. **Leave the "delete the field once the fleet has cut over" rule intact**
   either way — it describes a migration's lifetime, not a rename mechanism.
6. **Update the documentation in the same change**: `CLAUDE.md`'s routines
   section (both migration notes and the ordered-swap paragraph), `README.md`,
   and `reference/routines.md`.
7. **Verify** with the repository's standard checks, then the handoff below.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Whether convergence can rename a live routine in place is answered from a
  measurement against a live record, and the measurement is recorded.
- `renamed_from:`'s standing states the answer: either an input to convergence
  with the manual cutover as the `no_transport` recovery path, or the standing
  operator obligation it is today, with the measurement that confirmed it.
- The swap case is ruled on separately from the single-rename case.
- `CLAUDE.md`, `README.md`, SKILL.md §5 and both setup command bodies agree.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs
  && node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs` (it pins the templates against drift)
- **Handoff (see frontmatter):** an interactive session carrying a
  `RemoteTrigger`-family tool performs the step-1 measurement against a live
  routine record and confirms the read-back.

**Gate** — what must pass before approval:

- The measurement is recorded in the Final Report — including a negative result —
  and every document that states the premise is updated in the same commit.

## Considerations

- **Do not take the reporter's measurement as the finding.** It is a hypothesis
  with real evidence behind it (a swap that resolved in one call), and the
  diagnosis-first rule applies: reproduce and localize first. The specific gap
  is that name-matching cannot identify a routine whose name is what changed, so
  a working rename needs something else to supply the link.
- **A negative result is a complete outcome.** If rename-in-place does not hold,
  this ticket ships the recorded measurement and nothing else moves. Three
  documents currently assert the premise; one confirmed measurement is worth
  more than leaving it open to be re-asked.
- **`verification_handoff:` is read off the ask**: the question is only
  answerable against a live account routine, and the routine-fired class carries
  no transport to reach one (measured 2026-08-19, `CLAUDE.md`).
- **Scope discipline.** This ticket rules on the rename; it does not perform the
  fleet's outstanding cutovers. Both live `renamed_from:` fields are migrations
  in flight, and moving them is the operator's act under the existing rule until
  this ruling says otherwise.
- **If the ruling is positive, `[Workaholic]`'s blast radius grows**: an hourly
  unattended tick that can rename records across an account is a larger power
  than one that can only create and update them. Weigh whether rename-in-place
  should be available to the interactive setup commands only.
