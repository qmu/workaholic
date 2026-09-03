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

# Pin that no command sends a session to read a plugin file by reference

## Overview

PROPOSED. The operator asked for this explicitly: pin in the test suite that no command or
skill body sends a session to read a plugin file by reference alone. Without it the inlining
holds until the next edit reintroduces a reference, and the routines park again — which is
the recurrence the operator has now reported three times across three routines.

This is the mission's third acceptance item, deliberately left unlinked when the mission was
minted because the check belongs with the named cause, and the cause is now named.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the new row lives beside the
  existing structural rows (the `gh issue|pr|repo` ban, the embedded-jq compile row, the
  no-two-templates-render-one-name row).
- `plugins/workaholic/commands/*.md` — the surfaces scanned; the routine-fired four are the
  ones that must pass, and the rest are the question step 2 answers.
- `plugins/workaholic/skills/*/SKILL.md` and `reference/*.md` — the second half of the
  operator's scope: *no command **or skill body***.
- `plugins/workaholic/rules/shell.md` — the rule the pin enforces; the pin's failure message
  points at it.
- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — the one sanctioned crossing;
  the pin must not fail on it or on the callers that legitimately expand its `src`.

## Implementation Steps

1. Define what the row detects, in the row's own name, before writing it: a **must-read
   by-reference instruction** — a body that directs the reading session to go and read a
   named section of another plugin file in order to act. Provenance citations are not that,
   and a row that cannot tell them apart will be turned off within a week.
2. Decide the scope and record it: the four routine-fired commands are where a park was
   measured, and the operator's wording covers every command and skill body. Start where the
   failure is and say explicitly which surfaces are in and which are out, rather than
   quietly scanning less than was asked for.
3. Write the row. It must fail on a reintroduced must-read reference in a scanned surface,
   and pass on: a provenance citation, a `${CLAUDE_PLUGIN_ROOT}` script invocation, and the
   sanctioned `plugin-src.sh` crossing. Assert all four cases, not only the failing one.
4. Name the row's own limit in its name, as the embedded-jq row already does: a reference
   phrased in prose the pattern cannot recognise is not detected, and the count of what
   could not be classified is part of the assertion rather than hidden by it.
5. Make the failure message actionable — the rule in `rules/shell.md`, the repair (inline
   it), and the file and line — so the next contributor fixes it rather than deleting the row.
6. Run the row against the tree **before** the sibling inlining lands, and record how many
   surfaces it fails on. That number is the measurement of how wide the defect was.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The suite fails when a must-read by-reference instruction is added to a scanned surface.
- It passes on a provenance citation, a script invocation and the sanctioned crossing.
- The scanned scope and the row's detection limit are named in the row's own name.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A deliberately reintroduced reference in one routine-fired command fails the suite.

**Gate** — what must pass before approval:

- The row is hermetic: no network, no credential, no read outside the repository.
- The pre-inlining failure count is recorded in the mission's `## Changelog`.

## Considerations

- A pattern-based row over prose will have false negatives. That is stated in its name
  rather than argued away; a row that catches the shape the operator measured three times is
  worth having even if a differently-worded reference slips past.
- False positives are the greater risk, because they train contributors to disable the row.
  The four passing cases in step 3 exist for that reason and should grow whenever a
  legitimate shape trips it.

## Final Report

Development completed as planned. The row is `no command or skill body sends a session to read a
plugin file by reference`, and it names both its scope and its limit in its own name.

**Step 6's measurement, taken before anything was written**: a standalone scan over the tree found
**0 must-read references across 86 scanned surfaces**. The sibling inlining had already removed
them, so this row starts green — it is a regression guard rather than a backlog, and that is the
honest reading of "how wide the defect was" at the moment it was measured. The one line the first
draft of the pattern flagged (`drive/reference/routing.md:340`) turned out to be a **provenance
citation**: the rule is stated in that very sentence and `per …` names where it lives. Tightening
the pattern to imperatives (`see|read|open|consult|follow`) and excluding `per` removed it, which is
the distinction step 1 required before the row was written.

**Scope, stated rather than quietly narrowed** (step 2): every command body, plus every skill's
`SKILL.md` and `reference/*.md` — the operator's own wording, *no command or skill body*. The four
routine-fired commands are inside it, not a subset of it. The scan asserts it reached more than 50
surfaces, so a walk that silently found nothing fails rather than passing.

**All four cases asserted** (step 3), not only the failing one: a reintroduced must-read is detected
in both its namespace and its path form; a provenance citation, a `${CLAUDE_PLUGIN_ROOT}` script
invocation and the sanctioned `plugin-src.sh` crossing are each asserted **not** detected.

**The limit rides the row's name** (step 4), as the embedded-jq row's does: a reference phrased in
prose the pattern cannot recognise is not detected. This is a floor on the measured shape, never a
proof that no lookup exists.

**The failure message is actionable** (step 5): it names the rule (`plugins/workaholic/rules/shell.md`),
the repair (inline it where it is needed) and the offending `file:line`.

### Discovered Insights

- **Insight**: The hard part of this row is not detection, it is **not** detecting.
  **Context**: This repository cites its own sources in nearly every paragraph. A pattern that
  cannot separate *the rule is here, and it came from there* from *go there and read it* fires
  constantly and is deleted by the first contributor it inconveniences. The `per` exclusion is the
  whole difference between a row that survives and one that does not.
