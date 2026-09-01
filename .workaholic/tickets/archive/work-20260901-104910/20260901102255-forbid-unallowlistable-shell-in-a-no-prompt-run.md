---
created_at: 2026-09-01T10:22:55+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: compose-an-unattended-run-s-shell-so-an-allowlist-can-name-it
merge_policy:
verification_handoff: 
---

# Forbid unallowlistable shell in a no-prompt run

## Overview

PROPOSED. This is the ask's second half, and it is the general form of the first: **a routine
documented as running with no prompt at any step must not compose shell whose shape cannot be
allowlisted**, because the only observer of the resulting stall is the person the routine
exists to spare.

`rules/interaction.md`'s *An unattended run never waits for a person* already forbids waiting
and already names `rules/shell.md`'s read-tool rule as the one instance of it this repository
can hold. What it does not say is that a run's own **command composition** decides whether a
prompt can be raised at all: a command an operator's allowlist can name never reaches the
dialog. Two instances now exist rather than one, so the policy should name the axis rather
than a single case.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/rules/interaction.md` — *An unattended run never waits for a person* is
  the home; it already carries the waiting policy and points at `rules/shell.md`.
- `plugins/workaholic/rules/shell.md` — the two concrete instances the policy names.

## Implementation Steps

Diagnosis first, on the ask's own claim that this is not the first shape of the failure.

1. **Reproduce the recurrence.** Read the whole of *An unattended run never waits for a
   person* and the whole of `rules/shell.md`'s read-tool section — both, not the headings.
   Confirm that the first names waiting and the second names one shape of reaching, and that
   between them nothing states the axis: whether a composed command is one an allowlist can
   name.
2. **Localize the observer gap.** The ask's third finding is that the consuming repository's
   committed permission list was empty for an unrelated reason, so the loop had been stopping
   on reads with nothing but a parked dialog to say so. Check what already covers that:
   `/moderate`'s `blocked-tick` step (2026-08-31) notices a tick with an opening and no
   closing, one hour later. Record whether it covers this case and say so — do not re-propose
   a mechanism that exists.
3. **Write the general clause** into *An unattended run never waits for a person*: a run with
   no human present composes only commands an allowlist can name, because a command that
   cannot be allowlisted is a prompt the run has chosen to raise. Name the axis, then name its
   two instances (the read-tool rule, the plugin-path rule) as cases of it rather than as a
   list.
4. **Keep the enforcement statement honest.** The section already says its enforcement is a
   human reading it, and that what a machine holds is the *configuration* a run inherits
   (`workaholic:workaholify`). Extend that sentence to cover this clause; claim no new check.
5. **Check the ceiling.** The unattended commands (`/implement`, `/specificate`, `/propose`,
   `/moderate`) each say *no `AskUserQuestion` anywhere*, and the section already says to read
   that as *no prompt of any kind*. Confirm no command file needs its own copy, and report
   what was checked.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- *An unattended run never waits for a person* states that an unattended run composes only
  commands an allowlist can name, and names the two existing rules as instances of that axis
- The section's enforcement sentence still says plainly that this is prose a human reads, with
  the configuration half attributed to `workaholic:workaholify`
- The write records what `blocked-tick` already covers of the observer gap, so nothing later
  re-proposes it

**Verification method** — the commands/tests/probes that prove them:

- Read the section back and check each criterion against its text
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- The three commands above pass with `outputs/` regenerated and committed

## Considerations

- The section is already long and is loaded on every turn of every session. This is one
  clause and a re-pointing of two existing sentences, not a new subsection.
- The stated limit stays: what this repository owns is whether its own runs reach for an
  unallowlistable shape. Whether the harness classifies a given command as sensitive is not
  ours and must not be claimed as fixed.
- Depends on the wording landed by the two tickets before it; drive it last.

## Final Report

Development completed as planned.

**Reproduced the recurrence** (step 1): read the whole of *An unattended run never waits for a
person* and the whole of `rules/shell.md`'s read-tool section. The first names **waiting** (three
conceivable outcomes, two admitted) and pointed at the second as "the rule that removes it" where
a run's own reach raises the prompt; the second names one **shape of reaching** (an inspection
read through a Bash text pipeline). Between them nothing stated the axis — whether a composed
command is one an allowlist can name — so a session obeying both in full could still compose an
assignment-prefixed call and stall, which is exactly what the sibling ticket's measured case did.

**Localized the observer gap** (step 2): `/moderate`'s `blocked-tick` step (2026-08-31) already
covers it, and only partly. It reads its own tick log for an opening with no closing, names a
stopped tick an hour later by a structural bound, and covers `/moderate` alone — `/implement`,
`/specificate` and `/propose` write no such log. That is now recorded in the section, so nothing
later re-proposes a mechanism that exists.

**Checked the ceiling** (step 5): all four unattended commands already carry *no `AskUserQuestion`
anywhere* (`commands/implement.md`, `specificate.md`, `propose.md`, `moderate.md`), and the section
already says to read that as *no prompt of any kind*. **No command file needs its own copy**, and
the section now says so in as many words. `CLAUDE.md`'s `AskUserQuestion` enforcement bullet gains
the one-clause statement of the axis and its two instances.

The enforcement sentence still says plainly that this is prose a human reads, extended to cover
the new clause with its own reason (the composition happens at run time and never appears in this
tree's markdown), and the configuration half stays attributed to `workaholic:workaholify`. No new
check is claimed anywhere.

### Discovered Insights

- **Insight**: the two shell rules are not two rules but one axis seen at two points — *what* the
  run reaches for and *how* it spells the reach.
  **Context**: written as a list they would keep growing one measured stall at a time; written as
  an axis, a third shape is recognisable before it is measured. That is the whole reason this
  ticket was worth its own place in the mission rather than a sentence in the first one.
- **Insight**: `blocked-tick` covers exactly one of the four unattended commands, because it reads
  the log that only `/moderate` writes.
  **Context**: a later session tempted to extend it to `[Implement]` should notice that the
  extension is really "give the other three ticks a persisted opening record", which is a much
  larger change than it looks — and that the cheaper repair is upstream: not stalling.
