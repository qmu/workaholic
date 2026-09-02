---
created_at: 2026-09-02T04:37:47+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-a-routine-tick-from-parking-on-a-permission-prompt
merge_policy:
verification_handoff: 
---

# Read a skill section with the Read tool, never with sed or grep

## Overview

PROPOSED. The operator supplied the exact shape from the stuck prompts:

    sed -n '/One thread per feedback item/,/^## /p' $S/skills/notify/SKILL.md | head -50
    sed -n '/stateless/I,/^## /p' $S/skills/notify/SKILL.md

with `$S` the plugin cache under the container's `~/.claude`. No command body contains that
line. The session composed it to resolve a by-reference instruction, and the container
classified the path as Claude's own configuration and parked the run.

`rules/shell.md` already says a run reaches for a read tool and not a Bash text pipeline.
It is not being obeyed. This ticket makes the rule name the exact shape that is failing, in
the surfaces a routine session actually reads.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — an unattended run's read path is part of its contract

## Key Files

- `plugins/workaholic/rules/shell.md` — the rule's home; today it states the axis in general
  terms and names no shape.
- `plugins/workaholic/rules/general.md` — the ceiling bullet about how a plugin path is
  spelled when a run composes it.
- `plugins/workaholic/commands/propose.md`, `implement.md`, `specificate.md`,
  `moderate.md` — the four ceilings a routine session reads; the rule must be visible from
  where the session is standing, not one file away.
- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — the sanctioned resolver
  whose `src` is exactly the `$S` in the failing lines; the rule governs what may be done
  with that answer.
- `CLAUDE.md` — the AskUserQuestion / unattended-run enforcement gate, which already states
  this axis and can now state the shape.

## Implementation Steps

1. Write the rule in `rules/shell.md` naming the shape rather than the principle: a section
   of a skill, a command or any plugin file is read with the **Read** tool. `sed`, `grep`,
   `cat`, `head`, `tail` and `awk` over a path under the plugin tree are named as the shape
   that raises a prompt, with the operator's two measured lines quoted as the examples.
2. Say **why**, in one sentence, because a rule whose reason is invisible gets re-decided:
   the container classifies a path under `~/.claude` as Claude's own configuration, so a
   shell read of it prompts, and an unattended run cannot answer a prompt.
3. Carry the rule into the four routine-fired command ceilings. The measured lesson from the
   language rule is that a ceiling outranks a general document read earlier — so a rule that
   lives only in `rules/` will lose to whatever the command shows.
4. Extend `CLAUDE.md`'s enforcement-gate bullet on unattended runs with the named shape, so
   the repository's own statement matches the plugin's.
5. Do not add a hook that blocks the shape. A `PreToolUse` deny would turn a prompt into a
   refusal mid-run, which is a different failure; the repair the operator asked for is that
   the session never composes it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The rule names the exact shape, the tool to use instead, and the reason.
- It is present in `rules/shell.md` and in all four routine-fired command ceilings.
- No hook is added that blocks the shape at run time.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- `outputs/` regenerated; the `Outputs Freshness` check is clean.

## Considerations

- This ticket alone is not the repair, and the operator said so: the rule already existed in
  weaker form and was not obeyed, because the **reference** is what makes the session reach.
  Naming the shape narrows the failure; the sibling ticket removes the reach.

## Final Report

**Outcome**: implemented — and most of it was **already standing when this ticket was driven**,
which is reported rather than re-claimed.

**What was already on the base** (`#875`, and `#846` before it): `rules/shell.md`, *A skill or
reference file is read with the Read tool, never with a shell*, names the shape (`sed`, `grep`,
`cat`, `head` or any other shell reader over a plugin path), names the tool to use instead, and
states the reason — the container classifies a path under `~/.claude` as Claude's own
configuration, so a shell read of it prompts and an unattended run cannot answer. All four
routine-fired ceilings (`propose.md`, `implement.md`, `specificate.md`, `moderate.md`) carry it,
and `test-workflow-scripts.mjs` pins per command that they do. No hook blocks the shape.

**The residue this ticket closed** was step 4: `CLAUDE.md`'s own enforcement-gate bullet stated
the **principle** ("a read tool, never a Bash text pipeline") and named no shape, so the
repository's statement was weaker than the plugin's. It now names the shape, the tools that raise
the prompt, the reason, the measured line, where the rule lives, why it is carried into the
ceilings, and that no hook enforces it.

**Nothing was added that the ticket forbids**: no `PreToolUse` deny, no retry, no fallback.

**Verification**: `node scripts/test-workflow-scripts.mjs` → 6373 passed, 0 failed;
`build.mjs` + `verify.mjs` clean, `outputs/` unchanged (this change touches `CLAUDE.md` only).
