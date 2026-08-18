---
created_at: 2026-08-18T13:26:36+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818132525-rename-the-repository-tick-s-post-heading-to-release-preparation.md]
merge_policy:
verification_handoff: 
claim: work-20260818-134024
---

# Rename the tick's post heading to Release Preparation

## Overview

The repository-scoped `[Prepare Release]` tick posts one Slack root headed
`📦 Prepare release`. That wording arrived on 2026-08-18 (issue #485), which moved it
from `📦 Release status` to match the `/prepare-release` command name. On seeing it
applied, the developer ruled the heading should be **`📦 Release Preparation`** — a noun
phrase naming the report, not the command's imperative verb form.

The change is a string rename in the four places that carry the shape, plus the two
documents that quote it. It is safe by the same reasoning issue #485 established: the
notify lookup's dedup key is `` `deploy:<digest>` `` and **nothing searches the
heading**, so the visible wording carries no dedup weight and the cutover costs no
duplicate post.

**What does not move**: the routine's own name stays `[Prepare Release]` (convergence
matches routines by name, and a second rename there would create a second routine
exactly as `renamed_from:` documents), the command stays `/prepare-release`, the `📦`
stays, the token stays, and both posting gates stay.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the canonical post
  shape (`### /prepare-release — the repository tick's one line`), plus three prose
  references to `📦 Prepare release` in the standup and stuck-PR sections.
- `plugins/workaholic/skills/workaholify/routines/prepare-release.md` — the routine
  template's authorized post format (the fenced block near the end) and the paragraph
  **The post shape moved too**, which records the 2026-08-18 rename and must record this
  one rather than being overwritten.
- `plugins/workaholic/skills/notify/SKILL.md` — *The repository tick's status line*
  (three occurrences, including the *key is `deploy:<digest>`, never the heading*
  paragraph, which is the justification this change relies on).
- `plugins/workaholic/skills/standup/SKILL.md`, `plugins/workaholic/skills/housekeep/scripts/step-stuck-prs.sh`
  — each cites `📦 Prepare release` as the precedent shape; both must still name a
  heading that exists.
- `scripts/test-workflow-scripts.mjs` — pins the routine templates' post formats
  byte-identical to `notifications.md`'s copies; the assertion is what proves the rename
  landed in both places or in neither.
- `CLAUDE.md` — the Routines section states the heading moved `📦 Release status` →
  `📦 Prepare release`; it must state this second move and keep the first as history.
- `outputs/workflows/` — generated; regenerate, never hand-edit.

## Implementation Steps

1. Enumerate every occurrence of the literal `📦 Prepare release` across `plugins/`,
   `scripts/`, `docs/` and `CLAUDE.md`, separating the **shape** (the two fenced post
   blocks) from **prose citations** of it. Both sets move; the shape is what the test pins.
2. Rename the shape to `📦 Release Preparation - <N> commit(s) waiting on <target>` in
   `notify/reference/notifications.md` and in `workaholify/routines/prepare-release.md`,
   leaving the remaining four lines of the block (the one-sentence body, `Draft note:`,
   `` `deploy:<digest>` ``, the session URL) byte-identical.
3. Update the prose citations in `notify/SKILL.md`, `standup/SKILL.md` and
   `housekeep/scripts/step-stuck-prs.sh` so no document names a heading that is no longer
   posted.
4. Extend, do not overwrite, the two paragraphs that record the naming history — the
   template's **The post shape moved too** and `notifications.md`'s **The heading was
   renamed with the command** — so the sequence `📦 Release status` → `📦 Prepare release`
   → `📦 Release Preparation` reads as a record, with the same reason (the heading carries
   no dedup weight) stated once and cited.
5. Update `CLAUDE.md`'s Routines section in the same commit, and state plainly that the
   **routine name and the command name did not move** — only the post heading — so a
   later reader does not infer a third `/setup-repo-routines` migration.
6. Verify the byte-identical pin still holds, regenerate `outputs/` with
   `node scripts/build-plugins/build.mjs`, and note in the Final Report that the live
   `[Prepare Release]` routines' prompts need the same one-line update in the web UI —
   a prompt is an account-level record no plugin change can reach.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No file under `plugins/`, `scripts/`, `docs/` or `CLAUDE.md` contains the string
  `📦 Prepare release`; the post shape reads `📦 Release Preparation - <N> commit(s)
  waiting on <target>`.
- The routine template's post block and `notifications.md`'s copy remain byte-identical
  to each other.
- The dedup key, both posting gates, the `📦` prefix, the routine name `[Prepare Release]`
  and the command `/prepare-release` are unchanged by the diff.
- The naming history is extended rather than replaced, and `CLAUDE.md` says the routine
  name did not move.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "📦 Prepare release" .` returns nothing outside `.workaholic/` history.
- `node scripts/test-workflow-scripts.mjs` (the byte-identical template pin).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.
- `git diff` review confirming `deploy:<digest>`, the gates and the routine name are untouched.

**Gate** — what must pass before approval:

- All of the above pass, and the Final Report names the manual web-UI prompt update the
  live routines still need.

## Considerations

- The live routines' prompts carry the old format string and are account-level records;
  nothing in this repository can update them. That is a stated follow-up for the operator,
  not a blocker on this ticket.
- A routine posting the old heading and one posting the new heading will coexist until
  every prompt is updated. Harmless: the dedup is on the token, so the two never duplicate
  each other's work and never suppress each other.
- This is the heading's second rename in one day. The value here is the developer's
  explicit ruling on the applied wording; the ticket's job is to apply it and record the
  sequence, not to relitigate either move.

## Final Report

Development completed as planned. The heading is `📦 Release Preparation - <N> commit(s)
waiting on <target>` in both places that carry the shape, and the three prose citations
(`notify/SKILL.md`, `standup/SKILL.md`, `housekeep/scripts/step-stuck-prs.sh`) name a heading
that exists. The dedup key, both posting gates, the `📦`, the routine name `[Prepare Release]`
and the command `/prepare-release` are untouched by the diff.

### What the operator still has to do by hand

The live `[Prepare Release]` routines' prompts carry the old format string. A routine is an
account-level record and nothing in this repository can reach it, so **each account running
the routine must edit its prompt's post block in the web UI** — one line, the heading only.
It is a stated follow-up and not a blocker: the dedup is on `` `deploy:<digest>` ``, so a
routine posting the old heading and one posting the new never duplicate or suppress each
other; they simply read inconsistently until the prompts are updated. This is the same class
of manual act the `renamed_from:` field carries for the routine's own name, and it is
deliberately **not** given a second mechanical carrier: the routine name did not move, so
there is no migration to detect.

### Discovered Insights

- **Insight**: the byte-identical pin CLAUDE.md claimed for every routine's post shape only
  ever existed for `[Standup]`.
  **Context**: "All are byte-identical to `notify/reference/notifications.md`'s copies and
  pinned against drift by `test-workflow-scripts.mjs`" was true of one template out of five.
  This ticket's own acceptance cited that pin as its proof, so the pin had to be written
  before it could hold — `testPrepareReleasePostShape` now covers both of this template's
  blocks. Worth checking the remaining three templates against the same claim; a documented
  guarantee nothing enforces is how a shape drifts in one copy and not the other.

- **Insight**: a rename's acceptance criterion and its own step 4 pulled in opposite
  directions, and the step won.
  **Context**: the acceptance said no file under `plugins/` may contain `📦 Prepare release`,
  while step 4 required the naming history to be *extended* so the sequence reads as a record
  — which means naming the retired heading in prose. The grep was scoped "outside `.workaholic/`
  history", and a naming-history paragraph is history wherever it lives, so the mechanical
  assertion was written against the **post shapes** rather than the files. A rename that
  erased its own record would be the documentation defect this repository's own rule forbids,
  which is the stronger reading of both instructions.

- **Insight**: this is the heading's second rename in one day and the command's third in
  three, and none of them cost anything.
  **Context**: that is a property of the design, not luck — the dedup key was deliberately
  put on content (`deploy:<digest>`) rather than on the visible prefix, so the words a human
  reads are free to change. The 2026-08-17 decision that believed otherwise is the one that
  cost something: it held a rename back for a duplicate post that was never possible.
