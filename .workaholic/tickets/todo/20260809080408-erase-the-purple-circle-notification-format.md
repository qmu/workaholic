---
created_at: 2026-08-09T08:04:08+00:00
author: a@qmu.jp
assignees: 
depends_on:
feedback: [.workaholic/feedbacks/20260809080335-erase-purple-circle-notification-feature.md]
merge_policy:
claim: work-20260809-085355
---

# Erase the purple-circle (🟣) notification format

## Overview

<!-- PROPOSED. What this ticket would implement and why, from the feedback and
     repository state the proposal grew from. Merging the pull request this was
     published on is what turns it from a proposal into queued work. -->

Removes the 🟣 ("Merged by `<@U…>`") purple-circle notification shape from `workaholic:notify`'s reference documentation and every other place the plugin describes or would emit it, per the developer's direct ask (qmu/workaholic#317). The shape currently marks a human-merge finish line, distinguishing it from the unattended 🚀 auto-merge line; this ticket erases the format itself, not the distinction it currently carries, so whatever text replaces it must still let a developer tell an auto-merge from a human merge at a glance.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

<!-- The files this ticket would touch, each with why it is relevant. -->

- `plugins/workaholic/skills/notify/reference/notifications.md` — defines the 🟣 `Merged by <@U…>` shape (the "Shapes of the runner's posts" section)
- `plugins/workaholic/skills/notify/SKILL.md` — the notify skill's own standing rules; check for a 🟣 mention
- `plugins/workaholic/skills/drive/SKILL.md` and `plugins/workaholic/skills/drive/reference/routing.md` — the drive skill's route step, which currently selects the 🟣 line on a human merge
- `outputs/workflows/skills/drive/SKILL.md` and `outputs/workflows/skills/drive/reference/routing.md` — generated mirrors; do not hand-edit, regenerate via `build.mjs`
- `plugins/workaholic/skills/workaholify/routines/*.md` — routine prompt templates; confirm neither embeds the 🟣 shape verbatim (Q2 embeds literal formats directly in the prompt, so a stale copy here would survive a skill-only edit)

## Implementation Steps

<!-- The ordered steps. A proposal is judged on these, so they are the point. -->

1. Grep the repository for the purple-circle emoji (🟣) to enumerate every source file that defines, documents, or emits it (the Key Files list above is the proposal's own pass; the implementer should re-run the grep against the current `main`, since more may have landed since this proposal).
2. Remove the 🟣 shape from `notify/reference/notifications.md`, deciding and documenting what (if anything) now distinguishes a human merge from `🚀 Auto Merge by Claude` in the merge-finish line — the removal must not silently collapse that distinction.
3. Update `drive/SKILL.md` / `drive/reference/routing.md` (and the `[Implement]` routine template, if it names the shape) to stop selecting the 🟣 line at the route step, matching whatever replacement (or removal) step 2 decided.
4. Regenerate `outputs/workflows` (`node scripts/build-plugins/build.mjs`) so the generated `drive` mirror picks up the change, and run `verify.mjs` / `validate-metadata.mjs` / `test-workflow-scripts.mjs` / `layout-doctor.sh` per the repository's Local Verification list.
5. Update `CLAUDE.md`'s `/drive`/`/implement` rows and any other doc naming the retired shape, in the same change (per this repository's "update the docs in the same change" rule).

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- <proposed> No file under `plugins/workaholic/` or `outputs/` defines, documents, or emits the 🟣 purple-circle shape.
- <proposed> A developer reading the post-change notify/drive docs can still tell an auto-merge from a human merge from the finish line alone.

**Verification method** — the commands/tests/probes that prove them:

- <proposed> `grep -rn "🟣" plugins/workaholic/ outputs/` returns no hits.
- <proposed> `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs && node scripts/test-workflow-scripts.mjs` all clean; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate** — what must pass before approval:

- <proposed> The grep above is clean and the local verification suite passes before this ticket's PR is opened for review.

## Considerations

<!-- Risks and open questions the proposal already sees. -->

- The 🟣 shape currently carries information (a human, not an automated policy, approved this merge) that the ask does not say to drop — only the *format* is to be erased. The implementer should decide and record what (if anything) replaces that signal, rather than silently losing the auto/human distinction.
- `outputs/workflows/` is generated; the fix belongs in `plugins/workaholic/` source with a rebuild, never a hand-edit to the generated mirror (`Outputs Freshness` CI would catch a hand-edit as drift anyway).
