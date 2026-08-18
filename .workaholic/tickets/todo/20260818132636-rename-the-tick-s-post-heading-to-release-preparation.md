---
created_at: 2026-08-18T13:26:36+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: [20260818132525-rename-the-repository-tick-s-post-heading-to-release-preparation.md]
merge_policy:
verification_handoff: 
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
