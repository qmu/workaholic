---
created_at: 2026-08-10T06:30:39+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: [20260810063036-resolve-the-color-per-state-notify-shape-catalog.md]
mission: color-code-the-notify-post-shapes-by-state
merge_policy:
---

# Apply the color-per-state notify shape catalog

## Overview

Apply the color-per-state notify shape catalog resolved by the companion design ticket
(`20260810063036-resolve-the-color-per-state-notify-shape-catalog.md`) across every place
the current 📐/🛠️ shapes are documented or pasted into a live routine prompt, per issue
qmu/workaholic#330 (FB `20260810062845`). This is a mechanical application, not a design
decision — the color mapping and the design-start color placement are already decided by
the design ticket; this ticket finds every reference and rewrites it to match.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/SKILL.md` — the standing rules and shape list (*Post
  shapes, mentions, and the red-alert dedup*)
- `plugins/workaholic/skills/notify/reference/notifications.md` — the sole-sanctioned shape
  catalog (P10); every literal shape line lives here
- `plugins/workaholic/skills/workaholify/routines/fb.md` — the `[Propose]` routine
  template; its prompt pastes the literal post format
- `plugins/workaholic/skills/workaholify/routines/implement.md` — the `[Implement]`
  routine template; same concern for its own start/finish shapes
- the prompt-is-the-ceiling rule's example text (wherever it quotes a notify shape as its
  worked example — locate via grep, per Implementation Step 1)
- `outputs/workflows/skills/notify/` — generated mirror; fix the source and rebuild, never
  hand-edit
- `scripts/build-plugins/build.mjs` — regenerates `outputs/workflows` from the source
  skills

## Implementation Steps

1. Re-grep the repository for the current shapes (`📐 Designing`, `📐 Proposed`, `🛠️
   Implementing`, `🛠️ Implemented`) across `plugins/workaholic/`, `outputs/`, and
   `CLAUDE.md`, since more references may exist than the Key Files list above.
2. Apply the design ticket's resolved catalog to each hit, keeping line wording unchanged
   (issue #300's two-line format) — only the leading emoji and state word change.
3. Update both routine prompt templates in `skills/workaholify/routines/` so a rendered
   setup sheet pastes the new shapes verbatim.
4. Update the prompt-is-the-ceiling rule's example text to the new shapes.
5. Regenerate `outputs/workflows` (`node scripts/build-plugins/build.mjs`) and run
   `verify.mjs` / `validate-metadata.mjs` / `test-workflow-scripts.mjs` /
   `layout-doctor.sh` per the repository's Local Verification list.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- No file under `plugins/workaholic/`, `outputs/`, or `CLAUDE.md` describes the old
  double-duty `📐`/`🛠️` shapes as current
- Every shape in `reference/notifications.md` maps one color to exactly one state, with
  🚀 Auto Merge named as the deliberate exception
- Both routine prompt templates render the new shapes

**Verification method** — the commands/tests/probes that prove them:

- A grep for the retired `📐 Designing`/`📐 Proposed`/`🛠️ Implementing`/`🛠️ Implemented`
  shapes across `plugins/workaholic/`, `outputs/`, and `CLAUDE.md` returns no hits
  describing them as current (historical/decision-log mentions naming them as *retired*
  are fine)
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs && node scripts/test-workflow-scripts.mjs`
  all clean; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`

**Gate** — what must pass before approval:

- The grep above is clean and the local verification suite passes before this ticket's
  PR is opened for review

## Considerations

- Purely mechanical once the design ticket resolves the catalog — do not re-decide the
  color mapping or the design-start placement here.
- This mission's own ticket-reconciliation precedent
  (`20260809085953-reconcile-stale-notification-shape-references-post-p10.md`, still in
  the backlog as this proposal is written) shows the failure mode to avoid: a partial
  edit that updates one shape's line but leaves an adjacent reference to a different
  retired shape unchanged. Re-grep after editing, not just before.

## Final Report

Development completed as planned. Applied the companion design ticket's resolved catalog
mechanically across every live reference:

- `plugins/workaholic/skills/notify/SKILL.md` — the shape-list summary line, the
  `🟠 Implementing` / `🟢 Implemented` start/finish rule, and the `🔵 Proposed` thread-root
  bullet.
- `plugins/workaholic/skills/notify/reference/notifications.md` — both literal shape
  code blocks (`/propose` and `/implement`) and every prose sentence naming the current
  shape (five occurrences beyond the code blocks itself), including renaming
  `🔴 drive blocked` to `🔴 Blocked` in the outcome-shape block.
- `plugins/workaholic/skills/workaholify/routines/fb.md` and
  `plugins/workaholic/skills/workaholify/routines/implement.md` — the pasted literal
  post formats in both routine prompts.
- `outputs/workflows/` and `CLAUDE.md` — grepped and confirmed to carry no occurrence of
  the old shapes (the `notify`/`workaholify` skills are Claude-Code-only and are not part
  of the generated bundle; `CLAUDE.md`'s one shape mention predates P10 and is tracked by
  the separate, already-backlogged ticket
  `20260809085953-reconcile-stale-notification-shape-references-post-p10.md` — left
  untouched, out of scope here).

### Discovered Insights

- **Insight**: The `notify` and `workaholify` skills carry `metadata.internal: true` and
  are never part of `computeClosure` for any of the six skills `build.mjs` assembles into
  `outputs/workflows` (confirmed via `grep -rl` over `outputs/` returning no hits for any
  of the shape strings before or after this change).
  **Context**: A future notify-shape change does not need an `outputs/` rebuild to stay
  correct there, though running the build remains the standard verification step and
  catches drift in the six skills that *are* bundled.

## Verify

`node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` all clean; a repository-wide grep for the retired
`📐 Proposed` / `🛠️ Implementing` / `🛠️ Implemented` / `🔴 drive blocked` shapes across
`plugins/workaholic/`, `outputs/`, and `CLAUDE.md` returns zero hits; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`. `node scripts/test-workflow-scripts.mjs` run separately to confirm no regression (unrelated to this shape-text-only change).
