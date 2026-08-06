---
created_at: 2026-08-06T03:21:28+00:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
feedback: [20260806032120-the-setup-routines-report-presents-a-template-declared-trigger-as-if-it-were-live-wiring.md]
merge_policy:
claim: work-20260806-150055
---

# Say in the routines report that trigger wiring is unreadable from the API

## Overview

<!-- PROPOSED. Merging the pull request this was published on is what turns it
     from a proposal into queued work. -->

`/setup-routines` step 4 tells the reader to report each routine's `trigger` alongside its
`schedule`, `target_repo`, `enabled` and `status`. Every one of those except `trigger` comes
from the live account. `trigger` comes from the **template's** frontmatter — `render-routine.sh`
and `list-routine-templates.sh` both read it with `fm_field "$FILE" trigger`, because the
RemoteTrigger API carries no event-subscription field for them to read instead. The report
prints a declaration next to four measurements and marks none of them, so a reader takes the
whole block for live configuration.

On 2026-08-06 that read cost a manual investigation: this repository's `[Propose]` routine was
firing on a merged pull request while the report said `github-issue-assigned`, which is what
the template declares and what the routine was *designed* to do. The report was not wrong
about anything it could see; it was silent about what it could not.

The `workaholify` skill already records the API limitation (*What a routine can be triggered
by*, and §5's note that neither the drift report nor `/setup-routines` can see or fix the
wiring). What is missing is that the developer reading the report is told. Make the report say
it, and mark the value so the note cannot drift away from what it qualifies.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a limit that is reported is a
  known limit; one that is silently omitted reads as a measurement
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:design` / `policies/ux-principles.md` — the report answers "what runs against this
  repository", so what it cannot answer belongs in the answer

## Key Files

- `plugins/workaholic/commands/setup-routines.md` — step 4 is the report contract; it currently
  names `trigger` in the same breath as the live fields. Step 5 is the established shape for
  this ticket's addition: it already ends by naming one thing the command cannot do (the app's
  own routine-completion push) in the report itself.
- `plugins/workaholic/skills/workaholify/scripts/list-routines.sh` — emits the per-routine
  object the report is rendered from (`name`, `template`, `status`, `trigger`, `schedule`,
  `target_repo`, `enabled`, `trigger_id`, `drift`).
- `plugins/workaholic/skills/workaholify/scripts/render-routine.sh`,
  `plugins/workaholic/skills/workaholify/scripts/list-routine-templates.sh` — where `trigger`
  is read from template frontmatter. Both stay as they are; they are the evidence for the
  label, not the thing to change.
- `plugins/workaholic/skills/workaholify/SKILL.md` — §5 and *What a routine can be triggered
  by*. The fact is already here; the report contract that consumes it is what changes.
- `CLAUDE.md` — the `/setup-routines` row in the Commands table describes what the report
  covers.

## Implementation Steps

1. In `list-routines.sh`, mark the value at its source rather than only in prose: emit
   `trigger_source: "template_declared"` on each routine object and a top-level
   `trigger_readable: false`. The API exposes no trigger field, so this is a constant, not a
   probe — it is there so a renderer cannot print `trigger` without the qualifier travelling
   with it. Leave `trigger` itself unchanged; the declared intent is still the useful value.
2. In `setup-routines.md` step 4, stop listing `trigger` among the live fields. Report it as
   *the trigger the template declares*, and add the standing note in the report itself:
   trigger wiring is not exposed by the API and cannot be read, set or drift-checked here —
   confirm it in the routines UI at <https://claude.ai/code/routines>. Follow step 5's existing
   shape for naming a limit: say it plainly, once, where the reader is.
3. Say what the note is *for*, in one clause: a routine whose live wiring does not match its
   declared trigger is misconfigured and only the UI can show it — which is the case this
   ticket comes from.
4. Update `workaholify` SKILL.md §5 so the report contract there matches, and the
   `/setup-routines` row in `CLAUDE.md`. The API-limitation prose in *What a routine can be
   triggered by* is already correct and needs no change beyond a pointer from §5.
5. Rebuild if the change reaches a built skill: `node scripts/build-plugins/build.mjs`, then
   `node scripts/build-plugins/verify.mjs`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `/setup-routines` report states that trigger wiring cannot be read from the API and
  names the routines UI as where to confirm it.
- The reported `trigger` is identified as the template's declared trigger, not as live
  configuration.
- `list-routines.sh` carries the qualifier in its own output, so a future renderer inherits it
  without re-deriving the fact.
- `workaholify` SKILL.md §5 and the `CLAUDE.md` command row agree with the new report contract.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/skills/workaholify/scripts/list-routines.sh <repo-url> --live .routines/live.json`
  emits `trigger_source` per routine and a top-level `trigger_readable`.
- `node scripts/test-workflow-scripts.mjs` passes.
- `node scripts/build-plugins/verify.mjs` and
  `node scripts/build-plugins/validate-metadata.mjs` pass.
- Read the step 4 prose as someone who has never seen the repository: the trigger line is
  unambiguous about being a declaration.

**Gate** — what must pass before approval:

- No behavioral change to routine creation, refresh or removal — this ticket touches reporting
  only, and step 6's one-at-a-time verbatim confirmation is untouched.
- The note describes the API limit without asserting anything about a specific routine's live
  wiring, which the command still cannot see.

## Considerations

- **Why the JSON field and not prose alone.** The literal ask is a note in the report, and a
  prose-only change would satisfy it. The field is included because `trigger` is already read
  from the template in two scripts and rendered in a third place; a note that lives only in the
  command's markdown is a fourth copy free to drift away from the value it qualifies. If the
  reviewer prefers the smaller change, dropping step 1 leaves the ticket coherent.
- **This does not fix the misconfiguration it came from.** Repairing a live routine's trigger
  is a human act in the routines UI — the API offers no path — so the outcome here is that the
  report stops implying the question was answered.
- `trigger_readable: false` is a constant today. If the API ever exposes the wiring, this field
  is where that becomes a real probe, and the note becomes conditional on it.

## Final Report

Development completed as planned: the qualifier travels in the data (`trigger_source:
"template_declared"` per row, top-level `trigger_readable: false`), step 4 reports the
trigger as the template's declaration with the standing UI note, and the SKILL §5 and
CLAUDE.md rows agree. Note the interim nature: the queued setup-sheet mission retires
this report entirely; until that lands, this keeps it truthful.

### Discovered Insights

- **Insight**: `main`'s `CLAUDE.md` carried a live conflict-resolution defect since PR
  #263 — a stray `<<<<<<< HEAD` at line 245 and the **entire `/setup-routines` table row
  deleted** — introduced by an off-by-one in a hand-scripted resolution (0-based list
  slice over 1-based line numbers consumed one extra line and left the marker). Restored
  here from `56f9d3af` because step 4 requires editing that very row.
  **Context**: Seven merges passed over it; CI validates nothing about CLAUDE.md content.
  A hand-scripted conflict resolution that slices by index should assert the exact text
  of every line it consumes, not just the ones it keeps.
