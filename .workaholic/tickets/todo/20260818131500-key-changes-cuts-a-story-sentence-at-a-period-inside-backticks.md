---
created_at: 2026-08-18T13:15:00+00:00
author: a@qmu.jp
assignees: 
depends_on:
feedback: [20260818112045-the-draft-release-note-s-key-changes-renders-three-dead-lines]
merge_policy:
verification_handoff: 
claim: work-20260818-132434
---

# Key Changes cuts a story sentence at a period inside backticks

## Overview

Minted while driving `20260818112341-key-changes-renders-story-less-merges-as-dead-lines`,
whose Considerations name this defect and say to raise it separately rather than widen that
unit. It is the **story-bearing** path; that ticket fixed the story-less one.

`draft-release-note.sh` takes the first sentence of a story's `## 1. Overview` paragraph with
`sed 's/\([^.]*\.\).*/\1/'` — everything up to the first `.`. A period inside a backticked
filename is a period, so a story opening on one is cut at it. Observed on the base while
rendering `## Key Changes` over `v1.0.179..HEAD`:

- `.workaholic/stories/work-20260818-083716.md` opens `` `check-version-bump.sh` answered … ``
  and renders as the single line ``- `check-version-bump.`` — a backtick that never closes, an
  unreadable fragment, and one of the section's lines carrying no information.

The line is not merely short: the unclosed backtick corrupts the markdown of everything after
it in the rendered release, so one story's wording damages a section it does not belong to.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/test.md` — the regression must fail before the fix and pass after

## Key Files

- `plugins/workaholic/skills/ship/scripts/draft-release-note.sh` — the sentence split, in the
  `awk`/`sed` pipeline that reads a story's Overview paragraph.
- `scripts/test-workflow-scripts.mjs` — `testReleaseNoteKeyChangesFallback` already builds a
  hermetic repository with a story-bearing merge; the case belongs beside it.
- `plugins/workaholic/skills/ship/SKILL.md` — §7 states what `## Key Changes` carries per merge.

## Implementation Steps

1. **Reproduce hermetically**: a story whose Overview opens with a backticked filename
   containing a period, asserting the rendered line is the whole sentence and its backticks
   balance. It must fail first.
2. **Decide the rule and write it into the script's header.** A sentence end is a period
   **followed by whitespace or end-of-string**, and not one inside a backtick span. Check the
   cheaper rule first — a period followed by a space — against the real corpus before adopting
   the backtick-aware one; abbreviations (`e.g.`) and version numbers are the cases to test.
3. **Implement it** in that one pipeline, keeping the renderer clock-free, network-free and
   byte-identical for an unchanged base.
4. **Re-render the base over a multi-release range** and compare every story-bearing line
   before and after: no line may lose content it correctly had.
5. **Update `workaholic:ship` §7** if the stated rule moves, and regenerate `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A story opening with a backticked filename containing a period renders its whole first
  sentence, with balanced backticks.
- No story-bearing line that rendered correctly before renders differently after.
- The renderer stays clock-free and idempotent: the same base state renders byte-identical output.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` with the new case.
- `bash plugins/workaholic/skills/ship/scripts/draft-release-note.sh` before and after over a
  range spanning several releases, diffing the `## Key Changes` sections.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.

**Gate** — what must pass before approval:

- The step-1 assertion fails before the change and passes after it.
- The before/after render shows no regression on any story-bearing line.

## Considerations

- **The cheap fix may be enough.** Requiring whitespace after the period fixes the observed case
  without any backtick parsing; step 2 says to check that against the corpus first rather than
  reaching for the more general rule.
- **Out of scope**: the story-less fallback, fixed on ticket
  `20260818112341-key-changes-renders-story-less-merges-as-dead-lines`.
