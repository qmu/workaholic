---
created_at: 2026-08-17T11:37:49+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: add-the-housekeep-hourly-operations-routine
merge_policy:
verification_handoff: 
---

# Register the housekeep log area

## Overview

Step 1 of the ask: `/housekeep` needs a log storage location under `.workaholic/`. That
tree is a **closed layout** — the permitted top-level directories are fixed in two
lockstep sources, and a write into an unregistered directory is hard-blocked by
`validate-ticket.sh`'s layout gate and reported `conforming: false` by `layout-doctor.sh`,
which fails the `Validate Plugins` CI workflow. So the area is registered first, in the
same change that first writes to it, and nothing else in this mission can land before it.

The log is the tick's own record: what each run checked, what it filed, what it skipped
and why. It is what makes an unattended hourly routine auditable after the fact.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` / `policies/observability.md` — a tick's log is the only evidence an unattended run leaves
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/hooks/workaholic-layout-allowlist.txt` — the machine-readable half of
  the closed layout. Its own header states the rule: every entry is grounded in code, and a
  new directory is registered here **and** in the rules table in the same change.
- `plugins/workaholic/rules/workaholic.md` — the prose half: the area table, which since
  2026-08-13 carries a **definition** per area (what it holds, what it never holds, who
  writes it, when it is refreshed).
- `plugins/workaholic/hooks/layout-doctor.sh` — the audit; must report `conforming: true`
  with the new area present.
- `plugins/workaholic/skills/okf/` — the OKF floor: every knowledge artifact under
  `.workaholic/` carries a non-empty `type:`, and index refresh is a seam. Whether a tick
  log is a *knowledge artifact* at all is an Open Decision below.
- `CLAUDE.md` — the `.workaholic/` runtime conventions section.

## Implementation Steps

1. Settle the Open Decision below — the area's name and whether its entries are OKF
   artifacts decides the writer's shape.
2. Add the directory to `workaholic-layout-allowlist.txt` and to the table in
   `rules/workaholic.md` **in the same commit**, with the area's definition: what it holds
   (one entry per `/housekeep` tick), what it never holds (anything another area owns —
   findings become feedback records, work becomes tickets), who writes it (`/housekeep`
   only), and when it is refreshed.
3. Add the writer script under the housekeep skill's `scripts/` (append-only, one entry per
   tick, idempotent on re-run) and a reader the later steps can use to answer "did a
   previous tick already do this?".
4. Update `CLAUDE.md` and `.workaholic/README.md` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The new area appears in both lockstep sources, and `layout-doctor.sh` reports
  `conforming: true`.
- A write into the area succeeds through the validation hooks; a write into an
  unregistered sibling still fails.
- The writer is append-only and idempotent: two runs of the same tick produce one entry.

**Verification method** — the commands/tests/probes that prove them:

- `bash plugins/workaholic/hooks/layout-doctor.sh .`
- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- `Validate Plugins` CI green; the Open Decision resolved and recorded in the Final Report.

## Open Decisions

1. **Is a tick log an OKF knowledge artifact or an operational log?** Every artifact under
   `.workaholic/` carries a non-empty `type:` and is index-managed — with exactly one
   exception, `tickets/`, which was carved out deliberately. A per-hour operations log is
   the second thing in the tree that is neither knowledge nor a ticket: index-managing 24
   entries a day would churn the OKF indexes on every tick, and exempting it makes a second
   exception to a floor whose value is that it has almost none. Decide which, and name the
   area accordingly.
2. **Retention.** An hourly append-only log grows without bound in a repository whose other
   areas are all human-scale. Decide the retention rule (rolling file per day, per month, or
   pruned by age) before the first tick writes, because changing it later rewrites history
   in a tree whose conflicts are resolved append-only.

## Considerations

- The area is registered **permissively** — the allowlist permits, it does not require — so
  a consuming repository that never runs `/housekeep` is unaffected.
- `converge-layout.sh` is the living-migration registry: if this change needs one for
  repositories that already carry a differently-named ad-hoc log directory, it ships with
  its registration in the same commit.
