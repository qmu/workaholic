---
created_at: 2026-09-02T04:31:17+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-tick-from-parking-on-a-permission-prompt
merge_policy:
verification_handoff: 
---

# Name what raises the prompt in the Propose tick, from evidence

## Overview

PROPOSED. The tick parks at `requires_action` on records recreated fresh on 2026-09-01, so
the wiring is not stale and the raise is something the run itself does. The equivalent
failure on `[Moderate]` was measured and its cause recorded — a prompt raised by two
**reads** of a plugin script under the container's `~/.claude` — but nothing has established
that the `/propose` path parks for the same reason rather than a different one.

This is the mission's diagnosis step. It changes no behaviour; it produces the named cause
the next ticket removes. Adopting the previous case's cause without evidence is exactly the
inheritance the diagnosis-first rule exists to prevent.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — an unattended run's failure modes are part of its contract

## Key Files

- `plugins/workaholic/commands/propose.md` — the ceiling the routine session reads; every
  by-reference instruction in it is a candidate.
- `plugins/workaholic/skills/propose/SKILL.md` and `reference/loop.md` — the run's steps
  and every cross-skill reference they make.
- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — resolves a path under the
  plugin cache, which is the path class the container classifies as sensitive.
- `plugins/workaholic/rules/shell.md` and `plugins/workaholic/rules/general.md` — the
  existing rules about what a run may reach for and how it spells it.
- `plugins/workaholic/skills/workaholify/SKILL.md`, *Where an unattended run's prompt policy
  is configured* — the recorded prior case and the configuration a run inherits.
- `.claude/settings.json` — the `permissions.allow` list a person can extend.

## Implementation Steps

1. Collect the evidence that exists: the parked run's own prompt text, if the operator can
   supply it, and the `[Moderate]` case's recorded prompt shape. Write down what is
   established and what is assumed, separately.
2. Walk `/propose`'s own path — the command, the skill, `reference/loop.md`, and every
   script it invokes — and list every operation that touches a path under the container's
   `~/.claude`, every reference that tells a session to go and read a plugin file, and every
   command shape the allowlist cannot name.
3. For each candidate, say what a session would plausibly compose to satisfy it, and whether
   that composition is allowlistable. A reference that makes the session reach is a
   candidate even when the command body contains no shell at all.
4. Rank the candidates by the evidence, and name the one the next ticket removes. Where the
   evidence cannot separate two, say so and name both — the removal ticket can take both.
5. Record the finding in the mission's `## Changelog` and in the ticket's findings, with the
   file and line for each candidate.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The candidate list is derived from the `/propose` path in this tree, not inherited from
  the `[Moderate]` case.
- Each candidate names a file and a line and says why it would raise a prompt.
- What is evidence and what is inference are separated in the finding.

**Verification method** — the commands/tests/probes that prove them:

- A reader can open each named candidate at the cited line.

**Gate** — what must pass before approval:

- No behaviour change: the diff touches findings and the mission changelog only.

## Considerations

- The prompt text is the strongest evidence and it lives outside this repository, in the
  routine's session record. If it cannot be obtained, say so and rank on the path walk
  alone rather than presenting inference as measurement.
