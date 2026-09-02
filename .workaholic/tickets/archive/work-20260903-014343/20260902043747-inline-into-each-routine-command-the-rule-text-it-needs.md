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

# Inline into each routine command the rule text it needs

## Overview

PROPOSED. This is the repair the operator named as *at the source*: the reference is what
makes the session reach, so the reference goes. A command that says "see `workaholic:notify`,
*One thread per feedback item*" hands a routine session a lookup to perform; a command that
carries the rule hands it the rule.

The repository already holds this principle — *the command is the ceiling*, and a routine
prompt names the command and nothing else because a rule written elsewhere reaches a fleet
only by being re-pasted. The four routine-fired commands are where it is not yet applied to
the rules they cite.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/commands/propose.md`, `implement.md`, `specificate.md`,
  `moderate.md` — the four ceilings; each cites skill sections by name today.
- `plugins/workaholic/skills/notify/reference/notifications.md` — the shape catalog the
  measured `sed` lines were reaching for; the post shapes are already inlined into the
  commands and pinned, which is the pattern to extend.
- `plugins/workaholic/skills/notify/SKILL.md`, *One thread per feedback item* — the named
  section in the operator's first example.
- `scripts/test-workflow-scripts.mjs` — where the existing byte-identical post-format pins
  live; a newly inlined rule joins them.
- `plugins/workaholic/skills/workaholify/routines/*.md` — the templates, which must stay
  thin pointers; nothing inlined here.
- `CLAUDE.md` — the template-rules section that states the ceiling principle.

## Implementation Steps

1. Enumerate, per routine-fired command, every by-reference instruction it makes — every
   "see `workaholic:<skill>`, *<section>*" that a session must resolve to act correctly.
   Distinguish a reference the run must **read to act** from a citation that merely records
   provenance; only the first is a reach.
2. For each must-read reference, inline the text the run needs into the command, byte-
   identical to its source, and pin the pair in the suite exactly as the post formats are
   pinned. Byte-identical is what keeps two copies from becoming two rules.
3. Where the needed text is too large to inline, that is a signal the command is asking the
   run to do something the command has not scoped. Say so in the change rather than
   inlining a summary — a paraphrased ceiling is a third version of the rule.
4. Leave provenance citations as they are. A session does not need to open a cited record to
   act, and stripping citations would cost the repository its own traceability for no gain.
5. Keep the routine templates thin: the prompt names the command and the load fallback and
   nothing else. This ticket moves text into commands, never into templates.
6. Update `CLAUDE.md`'s template-rules and `workaholic:notify`'s ceiling statement so the
   principle is written as *the command carries what the run must read*, not merely *the
   command names the shapes*.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every must-read reference in the four routine-fired commands is inlined or explicitly
  reported as too large, with the scope problem named.
- Each inlined text is pinned byte-identical to its source.
- The routine templates are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, including the new pins
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- A new pin fails when one copy is edited alone.
- `outputs/` regenerated; the `Outputs Freshness` check is clean.

## Considerations

- Inlining grows the four commands and duplicates text. That cost is accepted and already
  paid once for the post formats, for the same reason: the ceiling is what the session
  reads, and the pin is what stops the copies drifting.
- The judgement in step 1 is the whole ticket. Inlining every citation would bloat the
  commands to no purpose; inlining none leaves the reach. Say which references were judged
  must-read and why.

## Final Report

**Outcome**: implemented.

**The enumeration (step 1).** Across the four routine-fired ceilings, the by-reference
instructions divide in two. **Provenance citations** — `(`workaholic:notify`, *The command is the
ceiling*)`, `rules/interaction.md`, the measured-origin notes — are left exactly as they are: a
session does not open them to act, and stripping them would cost the repository its traceability
for no gain (step 4). The **must-read** class had one survivor that the existing pin cannot see:
`/implement` and `/specificate` each told the run to post "into its reply thread (the
`workaholic:notify` lookup)" — an instruction to **perform** a lookup whose rules lived one file
away. The pin added by ticket `20260902043747-pin-…` matches *see `X`, *section**; a lookup named
in prose is the same reach in a shape that pattern cannot recognise, which is exactly the residue
its own assertion name warns about.

**The inlining (step 2).** `workaholic:notify`, *One thread per feedback item* — the four ordered
cases, the private-inclusive search rule, the fuzzy-matching prohibition and the two-query bound —
is now carried **byte-identical** in `commands/implement.md` and `commands/specificate.md`, with a
new suite pin (`the routine-fired commands carry the lookup they perform`) asserting the copies
against the source. Byte-identical is what keeps two copies from becoming two rules.

**What is deliberately NOT inlined.** `/propose` and `/moderate` never run the search — the
inbound sweep replies on a coordinate it already holds (case 1, no query) and the moderation root
is found by a key the tick derives — so carrying the lookup there would be three copies of a rule
with two readers. The suite asserts that in **both** directions, so a later contributor extending
the list is making a decision rather than repairing an omission.

**Nothing was too large to inline** (step 3), so nothing is reported unscoped; the block is
~4 KB.

**Templates untouched** (step 5): no routine template was edited.

**The principle restated (step 6)**: `CLAUDE.md`'s template-rules bullet and
`workaholic:notify`'s *The command is the ceiling* now read *the command carries what the run must
read*, not merely *the command names the shapes* — with the must-read / provenance distinction,
the byte-identical requirement, and the too-large-is-reported rule stated in both.

**Verification**: `node scripts/test-workflow-scripts.mjs` → 6380 passed, 0 failed (7 new rows).
**The gate was proven, not assumed**: changing `at most two search queries per lookup` to `three`
in `/implement` alone fails the pin (`FAIL /implement carries the thread lookup byte-identical to
workaholic:notify`); the edit was reverted and the suite re-run green. `build.mjs` + `verify.mjs`
clean with `outputs/` unchanged — `notify` is not a bundled skill, so the `Outputs Freshness`
check is clean.
