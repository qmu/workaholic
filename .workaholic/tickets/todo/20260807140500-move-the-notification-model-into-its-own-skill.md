---
created_at: 2026-08-07T14:05:00+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
---

# Move the notification model into its own skill

## Overview

**The notification model does not belong in `workaholic:workaholify`** (developer's
ruling, 2026-08-07). Workaholify is the environment-setup gateway — bootstrap, CLAUDE.md
audit, routine setup sheets — yet it also carries the runtime notification model: the
thread lookup (Q1), the post shapes, the mention resolution, the red-alert dedup, and
the what-earns-a-post bright line. A routine told to "find its reply thread per the
workaholic:workaholify lookup" is being pointed at a setup skill for a runtime
procedure, which reads as a category error to anyone meeting it fresh.

Move the whole notification model into a new dedicated skill, `workaholic:notify`, so
the consumers (`/implement`'s route step, `/propose`'s finish post, the routine
prompts) name a skill whose name says what it holds. Workaholify keeps what is
genuinely setup: bootstrap, audit, the routine templates themselves and their setup
sheets — with a pointer to `workaholic:notify` for the model the templates defer to.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — a thing lives where its name says it lives
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/notify/` — NEW skill (SKILL.md + reference/); receives the
  notification sections from `workaholify/SKILL.md` and `workaholify/reference/notifications.md`.
- `plugins/workaholic/skills/workaholify/SKILL.md` + `reference/notifications.md` — the
  sections leave; a one-line pointer to `workaholic:notify` stays where the templates defer.
- `plugins/workaholic/skills/workaholify/routines/fb.md`, `routines/implement.md` — the
  prompts reference the lookup by its new home; both stay exactly four lines.
- `plugins/workaholic/skills/drive/SKILL.md` + `reference/routing.md`,
  `plugins/workaholic/skills/propose/SKILL.md` + `reference/workflow.md` — consumer
  references retargeted.
- `scripts/test-workflow-scripts.mjs` — the Q1 and notification pins move to the new home.
- `CLAUDE.md`, `README.md`, docs — any mention of where the notification rules live.

## Implementation Steps

1. Create `skills/notify/` (frontmatter: description naming the runtime notification
   model; `metadata.internal: true`; no scripts of its own — `unit-feedback-stems.sh`
   stays in drive) and move the notification sections verbatim-in-substance: One thread
   per feedback item, the Q1 stateless lookup with its bounds, which thread an
   /implement unit's posts land in, the post shapes, mention resolution, red-alert
   dedup, the bright line, and the withdrawn-P9 history (reference/).
2. Leave workaholify a pointer; retarget drive/propose/routine-prompt references to
   `workaholic:notify`; keep both prompts at four lines.
3. Retarget the test pins; add a pin that workaholify's SKILL no longer states the
   lookup itself (pointer only), so the model cannot silently grow back there.
4. Rebuild outputs (drive/propose bundles carry the references), verify, full suite green.

## Quality Gate

**Acceptance criteria:**

- `workaholic:notify` holds the whole notification model; workaholify holds none of it
  beyond a pointer.
- The routine prompts and every consumer reference name `workaholic:notify`; both
  prompts are still four lines.

**Verification method:**

- `node scripts/test-workflow-scripts.mjs` green with the retargeted pins;
  `build.mjs`/`verify.mjs`/`validate-metadata.mjs` pass.

**Gate:**

- No rule of the model is lost or weakened in the move (Q1 bounds, exact-token-only,
  per-unit posts, /implement-only scoping all survive verbatim in substance).
