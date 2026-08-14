---
created_at: 2026-08-14T10:38:11+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-workaholify-apply-the-standards-not-report-them
merge_policy:
verification_handoff: 
---

# Walk a registry of living migrations

## Overview

PROPOSED. The ask's second item: a single registry of living migrations that
`/workaholify` walks, so a future structural change registers its migration in one
place instead of being remembered — or, as measured, forgotten.

Today `converge-layout.sh` names its two migrations inline (lines 80-87): two
`sh` calls, two hand-written JSON fragments, two `sed`-extracted counters summed
into `changed`. Adding a third means editing four places in one script and hoping
whoever ships the next P2-shaped change knows to. The failure mode is not
hypothetical: `migrate-todo-owners.sh`'s own header lists three call sites and
only one of them exists (issue #444).

The registry is also what makes the ask's "and whatever ships next" checkable
rather than aspirational — a migration that exists but is registered nowhere
becomes a test failure instead of a silent gap.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/workaholify/scripts/converge-layout.sh` — lines
  80-87 are the hardcoded list this ticket replaces; its header states the
  compose-never-reimplement line and the stages-never-commits boundary.
- `plugins/workaholic/skills/gather/scripts/migrate-todo-owners.sh`,
  `migrate-ticket-states.sh` — the two current entries; their headers are the
  model for what a registry row must carry.
- `plugins/workaholic/skills/workaholify/SKILL.md` §3a — where the contract is
  stated so a future change knows to register.
- `plugins/workaholic/hooks/layout-doctor.sh` — the before/after audit the walk
  brackets; unchanged, but the registry must not duplicate its findings.
- `scripts/build-plugins/build.mjs` / `verify.mjs` — the script-closure scan is
  `${SCRIPT_DIR}/../../<skill>/scripts/` shaped; a registry that hides a path
  from that scan ships a bundle missing its migrations.
- `scripts/test-workflow-scripts.mjs` — where the "every migration is registered"
  check belongs.
- `CLAUDE.md`, `plugins/workaholic/rules/workaholic.md` — the `/workaholify` row
  names the migrations by hand today.

## Implementation Steps

1. **Reproduce and localize first.** Run `converge-layout.sh` against a throwaway
   repository holding both legacy shapes and confirm the current output's exact
   fields (`applied`, `changed`, `decisions`, `conforming`). The registry must
   reproduce that contract byte-for-byte — this is a refactor of *how* the list
   is held, not a change to what the command reports.
2. Read `converge-layout.sh`'s header before editing: it composes and never
   reimplements a migration, it stages and never commits, and it always exits 0.
   All three survive this change unchanged.
3. Define the registry as **data**, one row per living migration, each carrying:
   the script path in the `${SCRIPT_DIR}/../../<skill>/scripts/` form the bundle
   scan requires, the argument it takes (a tickets root today), and a stable name
   for the `applied` entry. Keep it where the walk can read it without a parser
   the repository does not already have.
4. Replace lines 80-87 with a walk over the registry: run each row, collect each
   result verbatim into `applied`, and sum `migrated` into `changed`. A row that
   fails keeps the current per-migration fallback (`{"migrated": 0, "moves": []}`)
   so one broken migration cannot abort the convergence.
5. Add the enforcement that makes the registry real: a check in
   `scripts/test-workflow-scripts.mjs` asserting every `migrate-*.sh` under
   `skills/*/scripts/` appears in the registry. A migration that ships
   unregistered must fail the suite, not pass quietly.
6. Verify the bundle: `node scripts/build-plugins/build.mjs` then `verify.mjs` —
   the generated `outputs/workflows` copy must still carry both migrations.
7. State the contract in `workaholify/SKILL.md` §3a: a structural change ships
   its living migration **and registers it here**, and this is the seam every
   consuming repository converges through.
8. Update the `/workaholify` row in `CLAUDE.md` and `rules/workaholic.md` to name
   the registry rather than listing the migrations by hand.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `converge-layout.sh` derives its migration list from the registry; adding a
  migration means adding one row and nothing else.
- Output is unchanged for the same input: same `applied` entries, same `changed`,
  same `decisions`, same `conforming`, same always-exit-0.
- A `migrate-*.sh` that exists but is unregistered fails the smoke suite.
- `outputs/workflows` still carries every registered migration after a rebuild.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (new registration check).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.
- Replay of step 1's throwaway-repository run against the walked registry.

**Gate** — what must pass before approval:

- Smoke suite and bundle verification green; `outputs/` regenerated and
  committed; the §3a contract and the `CLAUDE.md` row updated in the same commit.

## Considerations

- **The bundle scan is the real constraint.** `build.mjs` detects a skill's
  script closure by the literal `${SCRIPT_DIR}/../../<skill>/scripts/` shape —
  `converge-layout.sh` says so at lines 75-79. A registry that assembles paths
  from fragments would be invisible to that scan and ship a bundle without the
  migrations. Keep each path literal in the row.
- **The registry is not the doctor.** `layout-doctor.sh` reports what needs a
  judgment; the registry holds only what is mechanical and idempotent. Do not let
  a row grow a "and if it fails, do X" branch — that is a decision, and decisions
  are reported.
- This ticket is a prerequisite in spirit for issue #444's archive-seam wiring:
  once migrations are registered rather than remembered, "which seams call this"
  becomes a readable fact instead of a header comment that drifted.
