---
created_at: 2026-08-10T08:31:27+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: color-code-the-notify-post-shapes-by-state
merge_policy:
---

# Align propose start wording and attribution link text

## Overview

Issue qmu/workaholic#333 dictated the canonical routine-template wording verbatim (Slack,
2026-08-10, developer's own words, recorded in FB
`20260810080930-fix-drift-in-routine-notify-templates-for-propose-implement-status-posts.md`).
Comparing it against the shapes this mission's own two tickets just landed on `main`
(`20260810063036-…`/`20260810063039-…`, P10 reconciliation) turned up two remaining
mismatches — everything else already matches:

1. The `/propose` design-start post reads **"Designing"**; the developer's wording is
   **"Proposing"**.
2. Every post's attribution reads **`by [Claude Code on the Web](<session URL>)`**; the
   developer's wording is **`by the [routine](<session URL>)`**.

This is a mechanical wording fix, not a design decision — the developer already decided
and confirmed the exact wording twice (the Slack dictation and issue #333 itself). Do not
re-interrogate; apply the two substitutions everywhere the current wording is pasted or
documented, keeping every emoji, link, and mention token exactly as they are today.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/routines/fb.md` — the `[Propose]` routine
  template's pasted post formats (both substitutions)
- `plugins/workaholic/skills/workaholify/routines/implement.md` — the `[Implement]`
  routine template's pasted post formats (attribution substitution only; its
  "Implementing"/"Implemented" wording already matches)
- `plugins/workaholic/skills/notify/reference/notifications.md` — the sole-sanctioned
  shape catalog (P10); every literal shape line lives here (both substitutions)
- `plugins/workaholic/skills/notify/SKILL.md` — the standing shapes list line (`📐
  designing / 🔵 proposed / …`) — lowercase category name, same substitution
- `scripts/test-workflow-scripts.mjs` — `testRoutineAnnouncementScoping`'s pinned regex
  `/(📐 Designing for|🟠 Implementing for)/` (around line 13744) asserts the *old* wording;
  update it to `Proposing` or the test fails against the corrected template
- `outputs/workflows/skills/notify/` and `outputs/workflows/skills/workaholify/` —
  generated mirrors; fix the source and rebuild via `scripts/build-plugins/build.mjs`,
  never hand-edit

## Implementation Steps

1. Re-grep the repository for `📐 Designing` and `Claude Code on the Web` against current
   `main`, since more copies may exist beyond the ones listed above.
2. In `skills/workaholify/routines/fb.md`, change `📐 Designing for` to `📐 Proposing for`
   and both `by [Claude Code on the Web](https://claude.ai/code/session_***)` lines to
   `by the [routine](https://claude.ai/code/session_***)`.
3. In `skills/workaholify/routines/implement.md`, change both
   `by [Claude Code on the Web](https://claude.ai/code/session_***)` lines to
   `by the [routine](https://claude.ai/code/session_***)`.
4. In `skills/notify/reference/notifications.md`, apply the same two substitutions to the
   `/propose` design start/finish block and the `/implement` start/finish block (four
   attribution lines total, one "Designing" occurrence).
5. In `skills/notify/SKILL.md`, change `📐 designing` to `📐 proposing` in the standing
   shapes list line.
6. Update `scripts/test-workflow-scripts.mjs`'s pinned regex and its assertion label from
   `Designing` to `Proposing` (keep `🟠 Implementing for` unchanged in the same regex).
7. Regenerate `outputs/workflows` (`node scripts/build-plugins/build.mjs`) and run
   `verify.mjs` / `validate-metadata.mjs` / `test-workflow-scripts.mjs` /
   `layout-doctor.sh` per the repository's Local Verification list.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The `[Propose]` routine template's design-start post reads `📐 Proposing for`, not
  `📐 Designing for`.
- Every pasted post format in both routine templates and in
  `workaholic:notify/reference/notifications.md` attributes the post as
  `by the [routine](<session URL>)`, not `by [Claude Code on the Web](<session URL>)`.
- No other wording, emoji, link target, or mention token changed.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "📐 Designing\|Claude Code on the Web" plugins/workaholic/skills/ outputs/workflows/skills/`
  returns no hits.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs && node scripts/test-workflow-scripts.mjs` all
  clean; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate** — what must pass before approval:

- The grep above is clean and the local verification suite passes before this ticket's PR
  is opened for review.

## Considerations

- Purely cosmetic wording; no behavior, schema, or trigger change. Scoped to this mission
  as a delta rather than a fresh mission/ticket, since it sharpens the same shape catalog
  this mission's own two tickets just landed (propose PR #334's Concerns section).
