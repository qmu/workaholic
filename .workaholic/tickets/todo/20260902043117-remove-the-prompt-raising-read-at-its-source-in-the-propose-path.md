---
created_at: 2026-09-02T04:31:17+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-tick-from-parking-on-a-permission-prompt
merge_policy:
verification_handoff: 
---

# Remove the prompt-raising read at its source in the propose path

## Overview

PROPOSED. The operator's instruction is explicit about where the repair goes: **at the
source** — restructure the command's own reads and acts so no prompt is ever raised, or rule
on the specific allow entry a person can approve. Not a retry, not a fallback, not leaving
the tick to park hourly.

This ticket takes the candidate the diagnosis ticket named and removes it, choosing between
the two sanctioned repairs on evidence rather than preference.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the run completes or fails; it does not wait

## Key Files

- `plugins/workaholic/commands/propose.md` — where a rule the run needs is inlined, if that
  is the repair chosen.
- `plugins/workaholic/skills/propose/SKILL.md`, `reference/loop.md` — the references that
  make a session reach.
- `plugins/workaholic/rules/shell.md`, `plugins/workaholic/rules/general.md` — the rules
  that already say what a run may reach for; if they are not being obeyed, the repair is
  structural rather than another sentence.
- `.claude/settings.json` — `permissions.allow`, if the ruled repair is an allow entry.
- `plugins/workaholic/skills/workaholify/SKILL.md`, *Where an unattended run's prompt policy
  is configured* — the configuration a run inherits; a per-repository allow entry belongs
  in the same place the policy is already recorded.

## Implementation Steps

1. Take the named candidate. Decide between the two repairs the operator sanctioned, and
   write the decision down with its reason:
   - **Restructure**, when what the run needs is content the command can carry itself, so
     nothing has to be fetched at run time. This is the preferred repair because it removes
     the reach rather than permitting it.
   - **An allow entry**, when the run genuinely must touch that path and the shape is one an
     allowlist can name exactly. Ruled once, recorded where the prompt policy is recorded,
     and never a wildcard that permits more than the named shape.
2. Apply the chosen repair. Where it is a restructure, the content moves into the surface
   the session actually reads, so the reach never happens; where it is an allow entry, add
   exactly the shape and nothing wider.
3. Do not add a retry, a timeout, or a fallback around the prompt. A run that works around
   a prompt still spends its fire; the instruction is that the prompt is never raised.
4. If the diagnosis named two candidates it could not separate, take both — the cost of
   removing one reach that was not the cause is a smaller run, and the cost of guessing
   wrong is another hour of parked ticks.
5. Verify against the same evidence the diagnosis used: the reach that would have been
   composed is no longer available to compose, or the shape is now named by the allowlist.
6. Update `plugins/workaholic/rules/shell.md`, `rules/general.md`, `workaholic:workaholify`
   and `CLAUDE.md` in the same change wherever the repair changes what those documents say.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The named cause is removed at its source, by restructure or by a named allow entry.
- No retry, timeout or fallback around a prompt was added.
- The decision between the two repairs is recorded with its reason.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A `/propose` run in a container reaches its report without a prompt.

**Gate** — what must pass before approval:

- The end-to-end run above completes; a run that still parks is not this ticket done.

## Considerations

- An allow entry is the weaker repair: it permits the reach rather than removing it, and it
  is a per-account or per-repository record that a fresh container may not carry. Prefer the
  restructure and say why whenever the entry is chosen instead.
