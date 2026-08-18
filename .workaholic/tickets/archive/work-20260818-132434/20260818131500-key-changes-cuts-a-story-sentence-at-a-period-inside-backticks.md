---
created_at: 2026-08-18T13:15:00+00:00
status: done
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

## Final Report

**Step 1, reproduced.** A hermetic story opening `` `check-version-bump.sh` answered … ``
rendered as ``- `check-version-bump.`` — an unclosed backtick and a fragment. The assertion
failed before the change and passes after it.

**Step 2, the rule — measured before it was chosen, as the ticket required.** Both candidates
were run over the repository's **199** stories with an Overview paragraph:

| Rule | Stories rendering with unbalanced backticks | Abbreviation mis-splits |
| ---- | ---: | ---: |
| Current — up to the first `.` | **32** | — |
| Cheap — `.` followed by whitespace or end-of-line | **1** | **0** |

The cheap rule was adopted, and the backtick-aware alternative the ticket also offered was **not
needed**: the two rules disagree on 41 of the 199, the cheap one is right on every one of them,
and `e.g.` / `i.e.` / `etc.` / `vs.` followed by a space appears in **zero** of the 199 first
sentences. Version numbers are safe by construction (`v1.0.105` has no space after its periods),
and the old rule cut them mid-number anyway.

**The residual 1 was not the split — it was the clamp**, cutting inside a backtick span 160
characters in. So the clamp closes a span it opened, before the ellipsis. That is the second half
of the fix, and it is what makes the acceptance criterion ("balanced backticks") true rather than
usually-true.

**Both clamps folded into one function** (`CLAMP_FN`, shared textually by the two awk programs).
This is the `low` concern the previous unit's story deferred to "when the backtick ticket rewrites
the sentence split, which touches the same pipeline" — that ticket is this one, so it was folded
here rather than left to drift.

**Acceptance criteria.**

- *A story opening with a backticked filename containing a period renders its whole first
  sentence, with balanced backticks* — hermetic case asserts the exact line
  ``- `check-version-bump.sh` answered from a local `main` nothing keeps current.``, balanced,
  with the following sentence still dropped.
- *No story-bearing line that rendered correctly before renders differently after* — rendered
  over `v1.0.179..HEAD` before and after: unbalanced-backtick lines 1 → 0, every other line
  unchanged. The corpus table above is the same measurement over all 199 stories.
- *Clock-free and idempotent* — the existing two-render comparison in the same hermetic case
  still passes, and the real base renders byte-identically twice.

**Verification run.** `node scripts/test-workflow-scripts.mjs` — **3066 passed, 0 failed**
(5 new assertions). `build.mjs`, `verify.mjs`, `validate-metadata.mjs` clean; `posix-lint.sh`
conforming.

**One test-fixture correction worth recording.** The first clamp fixture used a 200-character
unbroken token and did **not** reproduce an open span: the clamp trims back to a word boundary,
so a single long token is removed whole and takes its opening backtick with it. The span has to
contain spaces for the cut to land inside it. The fixture, not the code, was wrong — noted
because the failing assertion looked like a code defect and was not.
