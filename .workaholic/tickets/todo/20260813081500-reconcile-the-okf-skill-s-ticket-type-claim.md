---
created_at: 2026-08-13T08:15:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: refresh-the-outdated-documentation-to-match-current-behavior
merge_policy:
---

# Reconcile the okf skill's ticket type claim

## Overview

Minted mid-run while driving
`20260813072628-update-the-artifact-hub-and-rules-docs-to-current-behavior.md`. The
problem is real and observed, but it sits in a **skill**, outside that mission's
stated scope (`README.md`, `docs/*.md`, `.workaholic/README.md`,
`plugins/workaholic/rules/*.md`), so it is queued rather than fixed opportunistically.

`plugins/workaholic/skills/okf/SKILL.md:15` enumerates per-file OKF conformance and
includes tickets among the documents carrying a `type:`:

> tickets (`type: enhancement|bugfix|refactoring|housekeeping`), stories
> (`type: Story`), missions (`type: Mission`), feedbacks (`type: Feedback`), release
> notes (`type: Release Note`) …

Three independent sources say the opposite, and the code agrees with them:

- `CLAUDE.md`, *`.workaholic/` runtime conventions*: "**Tickets are the exception**: no
  `type:` frontmatter, and `tickets/` internals are never index-managed."
- `.workaholic/README.md:10` — the same exception, in the artifact hub every consuming
  repository inherits.
- The shipped tickets themselves: none of the three tickets in this mission's set
  carries a `type:` field, and `hooks/validate-ticket.sh` does not require one.

So the skill is the stale one. It matters more than a stray sentence would, because
`okf/scripts/refresh-index.sh` is the writer of the bundle indexes and this skill is
what a session reads before touching them: a session that believes tickets are
index-managed knowledge documents may try to give them a `type` or fold `tickets/`
into the OKF index, which the layout rules elsewhere forbid.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:development` / `policies/distribute-policies-as-plugins.md` — the skills ship as agent context

## Key Files

- `plugins/workaholic/skills/okf/SKILL.md` — the stale enumeration (line 15).
- `plugins/workaholic/skills/okf/scripts/refresh-index.sh` — check whether the code
  shares the belief or only the prose does.
- `plugins/workaholic/hooks/validate-ticket.sh` — the ticket floor; it requires no `type:`.
- `CLAUDE.md`, `.workaholic/README.md` — the two current-behavior statements of the exception.
- `outputs/okf/` — the generated bundle; confirm nothing there depends on the claim.

## Implementation Steps

1. **Confirm the direction of the error before editing.** Read
   `refresh-index.sh` and `okf.mjs` to establish whether the ticket `type:` vocabulary
   is merely described or actually consumed. If any code reads it, this ticket is a
   different (larger) change and should say so rather than editing prose around live
   behavior.
2. Correct `okf/SKILL.md:15` to state the exception the rest of the project states:
   tickets carry no `type:` and `tickets/` is not index-managed.
3. Grep the plugin for the retired vocabulary
   (`enhancement|bugfix|refactoring|housekeeping` as a ticket `type`) and correct or
   remove whatever else still carries it; the `type`/`layer` ticket fields were retired
   2026-08-07, so this may be a survivor of that change.
4. Regenerate the outputs bundle (`node scripts/build-plugins/build.mjs`) — `okf` is a
   script-bearing skill and the `Outputs Freshness` CI fails on any diff.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `okf/SKILL.md` no longer claims tickets carry a `type:`, and states the exception instead.
- No file under `plugins/workaholic/` still describes a ticket `type:` vocabulary, or the
  Final Report names each survivor and why it is legitimate.
- No behavior change: the index regeneration writes the same files it wrote before.

**Verification method** — the commands/tests/probes that prove them:

- `grep -rn "type: enhancement" plugins/ outputs/` returns nothing.
- `bash plugins/workaholic/skills/okf/scripts/refresh-index.sh` leaves `.workaholic/index.md`
  and the per-area indexes byte-identical (`git status --short` clean afterwards).

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green.
- `node scripts/build-plugins/build.mjs` then `verify.mjs` green, with `outputs/` committed
  if the skill's text changed.

## Considerations

- The reverse reading is possible and must be ruled out first (step 1): if tickets were
  *meant* to be OKF-typed and the exception is the regression, the fix belongs in the
  ticket writer and the layout rules, not in this skill. The evidence points the other
  way — no shipped ticket carries the field and no hook asks for it — but the check is
  cheap and the cost of guessing wrong is a schema change made by accident.
- Scope this to the contradiction. `okf/SKILL.md` is otherwise current, and a rewrite
  would bury a one-line correction in an unreviewable diff.
