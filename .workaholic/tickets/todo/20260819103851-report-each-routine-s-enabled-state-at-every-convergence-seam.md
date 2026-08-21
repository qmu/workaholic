---
created_at: 2026-08-19T10:38:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-workaholify-converge-the-account-s-routines
merge_policy:
verification_handoff: A RemoteTrigger-family tool over account routines — the enabled field can only be read from a live routine record
---

# Report each routine's enabled state at every convergence seam

## Overview

PROPOSED. No routine template declares an `enabled` field, and convergence diffs
`name`/prompt/`model`/`cron_expression`/`autofix_on_pr_create`/connectors — not
`enabled`. A routine that is switched off is therefore converged in every other
field and left silently off, and its report line is indistinguishable from a
healthy routine's.

That is not hypothetical: the measurement behind this mission found **both** of
this account's live routines disabled since 2026-08-12, and nothing in any
report said so. A convergence that reports "no changes" about a dead routine is
the same class of untrue-but-plausible report the mission exists to remove.

The floor this ticket delivers is **reporting**: every routine a convergence run
touches or skips states its enabled state. Whether convergence should also *set*
that field is a genuine decision and is carried below as an Open Decision, not
assumed — a human disabling a routine is a signal, and an updater that silently
re-enables it overrides a deliberate act with no record.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/SKILL.md` — §5 step 2 enumerates the
  diffed fields; the one place the field set is stated, so the one place a
  reported-but-not-diffed field must be described.
- `plugins/workaholic/commands/setup-dev-routines.md`,
  `setup-repo-routines.md`, `setup-user-routines.md` — each restates the diffed
  field list in its own body; all three drift together if the set moves.
- `plugins/workaholic/commands/workaholify.md` — the fourth seam once ticket 1
  of this mission lands; sequence this ticket after it or update both.
- `plugins/workaholic/skills/workaholify/routines/*.md` — the six templates. If
  the Open Decision resolves toward convergence *setting* the field, this is
  where the declaration would live; if it resolves toward reporting only, they
  are untouched and the absence should be documented as deliberate.
- `plugins/workaholic/skills/workaholify/reference/routines.md` — carries the
  live-drift addendum; the natural home for what an enabled-state read means.

## Implementation Steps

1. **Establish where `enabled` actually lives on a routine record** before
   writing any prose about it. Read one live record through the transport and
   record the field's real name and shape. The API silently drops unknown
   fields, so a read-back — never the absence of a 400 — is what confirms
   anything (the same rule `autofix_on_pr_create` was discovered under).
2. **Add the enabled state to the reported line, not to the diff.** Every
   routine a run creates, updates, finds identical, or skips as out of scope
   states whether it is enabled. A disabled routine converged in every other
   field must read as *converged but off*, never as healthy.
3. **Do not resolve the Open Decision below inline.** Ship the reporting half
   whatever the answer; wire the setting half only on the operator's ruling.
4. **State the field set in one place.** If the four command bodies each keep
   their own list, adding a fifth reported field means four edits and a silent
   drift risk. Prefer deferring all four to SKILL.md §5's enumeration.
5. **Update the documentation in the same change**: `CLAUDE.md`'s setup-command
   rows where they enumerate the diffed fields, and `README.md` likewise.
6. **Verify** with the repository's standard checks, then the handoff below.

## Open Decisions

<!-- Recorded verbatim rather than resolved: the proposing session cannot ask,
     and neither side of this fork is recommendable without the operator. -->

1. **Should convergence *set* a routine's enabled state, or only report it?**
   The reporter raised this as a real decision and explicitly asked that it be
   ruled on rather than assumed: *"whether convergence should also set it is a
   real decision (a human disabling a routine is a signal, not drift)."*
   - **Report only** treats a disabled routine as a deliberate human act and
     never overrides it. Cost: a routine disabled by accident, or by an incident
     nobody remembers, stays off forever and every run keeps saying so.
   - **Converge it** makes the templates the whole truth about a routine's
     wiring, consistent with "drift is the rendered diff". Cost: the fleet-wide
     `[Workaholic]` tick could re-enable, every hour, a routine a person
     switched off deliberately — with no field anywhere recording that they did.
   - A third shape exists and should be weighed rather than skipped: a template
     could declare `enabled:` explicitly, making the answer per routine instead
     of global.
   The driving session resolves this explicitly and records the resolution in
   its Final Report; a silent choice is not acceptable here.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- Every convergence seam reports each routine's enabled state, including
  routines it made no change to.
- A disabled routine's report line is distinguishable from a healthy one's.
- The Open Decision above is resolved explicitly in the Final Report, and the
  setting half is implemented only if that resolution says so.
- The diffed/reported field set is stated in one place, not four.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs
  && node scripts/build-plugins/validate-metadata.mjs`
- `node scripts/test-workflow-scripts.mjs`
- **Handoff (see frontmatter):** an interactive session carrying a
  `RemoteTrigger`-family tool reads a live routine record, confirms the enabled
  field's real name and shape, and confirms a disabled routine is reported as
  disabled.

**Gate** — what must pass before approval:

- The script checks pass, the Open Decision is answered in the Final Report, and
  the documentation is updated in the same commit.

## Considerations

- **The reporting half is the floor and ships either way.** Even under the
  most conservative resolution, a run that cannot say a routine is off is a run
  that can report a dead fleet as prepared — the exact defect this mission
  answers.
- **`verification_handoff:` is read off the ask**, not inferred: the enabled
  field exists only on a live account routine, and the routine-fired class
  carries no transport to read one (measured 2026-08-19, `CLAUDE.md`).
- **Sequencing.** Ticket 1 of this mission adds a fourth seam. Driving this
  ticket first means editing three command bodies and then a fourth; driving it
  second means one pass. Prefer second, but neither order is wrong.
- **The `[Workaholic]` tick is the risk surface for the setting half**, not the
  interactive setup commands: it runs hourly and unattended across every
  repository the account has set up. Whatever the ruling, weigh it against that
  caller, not against a human typing `/setup-dev-routines`.
