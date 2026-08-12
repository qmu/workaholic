---
created_at: 2026-08-12T22:30:46+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback:
merge_policy:
claim: work-20260812-223743
---

# Pin the plugin source across the freshen step

## Overview

<!-- Minted mid-run by /implement while driving
     20260812221941-record-loop-drill-run-20260812-221056-in-the-drill-log.md. -->

`plugin-src.sh` resolves the plugin tree the run will execute, and its stated rule is
"pick the newest source available, ties going to the checkout" — with the checkout
justified by a header comment reading *"This repository IS the plugin; after the run's own
freshen it is by definition the newest"* (`plugin-src.sh:16-26`).

That justification is true only **after** the freshen, and the resolver runs **before** it:
the Unified Run's step 0 resolves the source, step 0b then calls `sync-main.sh`, which is
allowed to move the working tree. So the `plugins/` content backing every subsequent script
path can change — including backwards — while the run is already using it.

Measured 2026-08-12T22:24Z on the `[Implement]` tick that minted this ticket. The session
started on a harness branch whose tip was `origin/main` (1e49199), so the checkout candidate
resolved at 1.0.172 and won the tie. Reaching a surveyable state then checked out the local
`main`, which was the container image's stale baked clone (77c462d, 200 behind, tip on no
remote branch) — and the plugin source silently reverted with it, to a `sync-main.sh`
predating its own §5 realignment. That older copy answered `diverged` / `both_diverged`,
which the command's step-0b table reads as *terminate `pending`*. The tick would have been
lost to the very failure §5 was written to prevent, and its own report would have named a
plugin version (1.0.172) that was not the code it ran. The run recovered only because it
re-invoked the script from the version-pinned registry cache by hand.

The registry cache path (`~/.claude/plugins/cache/workaholic/workaholic/<version>/`) is
immutable and version-addressed, so it cannot move under a run. The checkout is the right
*version* oracle and the wrong *execution* surface for the window that spans the freshen.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — one rule source; the
  resolver's stated contract must match what its callers can rely on
- `workaholic:operation` / `policies/observability.md` — a run must not report a plugin
  version other than the one whose code it executed
- `workaholic:implementation` / `policies/directory-structure.md` — script closure and
  where the resolver's contract is documented

## Key Files

- `plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` — the resolver; the
  tie-break rule and its header rationale (`:16-26`), the `candidates[]` emission (`:202-216`)
- `plugins/workaholic/skills/check-deps/SKILL.md` — the documented contract callers read
- `plugins/workaholic/commands/implement.md`, `plugins/workaholic/commands/drive.md` —
  step 0 (resolve/verify) and step 0b (freshen), the ordering at issue
- `plugins/workaholic/skills/drive/SKILL.md` §1 — the freshen step's own description
- `plugins/workaholic/rules/general.md` — "the harness binding is an input, never a
  precondition"; this adds the companion rule about *which* input survives a freshen
- `scripts/test-workflow-scripts.mjs` — hermetic smoke tests (temp repos, no network)

## Implementation Steps

1. Reproduce first, so the fix is measured rather than assumed: in a throwaway clone, set
   local `main` to a commit whose `plugins/` predates a script change, check out a second
   branch at `origin/main`, run `plugin-src.sh` (expect `source: checkout`), then
   `git checkout main` and re-read the same script path — confirm the content changed.
2. Decide the resolution in `plugin-src.sh` and record it in its header: when the checkout
   and an **immutable** candidate (registry cache) report the **same** version, prefer the
   immutable one, because a tie on version is not a tie on stability. Keep "newest wins"
   untouched on the version axis — a genuinely newer checkout must still win.
3. Emit the property rather than leaving it to be re-derived: add a per-candidate
   `immutable: true|false` to `candidates[]`, and a top-level `src_immutable`. A caller that
   must survive a tree-moving step then has a field to read instead of a convention to
   remember.
4. Make the ordering explicit in the two command markdowns: step 0's resolution is what the
   whole run executes, so state that the source must be immutable **or** re-resolved after
   step 0b. Prefer stating it once in `skills/check-deps/SKILL.md` and pointing at it.
5. Add the rule to `rules/general.md` beside the existing binding rule, in one sentence.
6. Extend `scripts/test-workflow-scripts.mjs`: a hermetic case asserting that on an equal
   version the resolver picks the immutable candidate and reports `src_immutable: true`.
7. Update `CLAUDE.md`'s plugin-boundary bullet in the same change (the doc rule) — the
   sanctioned crossing now carries a stability qualifier.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With a checkout and a registry cache at the **same** version, `plugin-src.sh` reports the
  registry cache path in `src`, `source: registry`, and `src_immutable: true`.
- With the checkout at a **strictly newer** version, it still wins (`source: checkout`) —
  the newest-wins rule is unchanged on the version axis.
- `candidates[]` carries `immutable` for every candidate.
- `plugin-src.sh`'s header states the tie-break and names the freshen window as its reason.
- `rules/general.md`, `skills/check-deps/SKILL.md` and `CLAUDE.md` state the rule
  consistently; no document still implies the checkout is safe across a tree-moving step.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the new hermetic cases pass with the rest.
- `bash plugins/workaholic/skills/check-deps/scripts/plugin-src.sh` in a temp clone for each
  of the two version arrangements above; read `src`, `source`, `src_immutable`.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — the
  generated bundle stays self-contained and in sync.
- `git diff` — no behaviour change to the newest-wins path beyond the equal-version tie.

**Gate** — what must pass before approval:

- The equal-version tie resolves to the immutable path, a strictly-newer checkout still
  wins, the smoke tests pass, and `outputs/` is regenerated.

## Considerations

- **Do not "fix" this by dropping the checkout candidate.** It is what lets this repository
  develop its own plugin and what makes a genuinely newer checkout executable; the defect is
  the tie-break, not the candidate.
- Re-resolving after the freshen is the alternative fix. It is weaker: it leaves the window
  open for anything step 0 itself does with the source (the `check.sh` call already made),
  and it puts the burden on every future caller. Preferring the immutable path on a tie fixes
  it in one place. Both could be done; the ordering statement in step 4 is cheap.
- A container whose baked `main` is stale is the same class of environment artifact as the
  superseded binding this resolver already exists for, and as `sync-main.sh` §5. This ticket
  does not touch §5 — that mechanism worked as designed once the current copy was the one
  running.

## Final Report

Development completed as planned. The defect was reproduced before the fix, in a throwaway
repository with a checkout and a version-addressed cache at the same version: `plugin-src.sh`
resolved `source: checkout`, and re-reading the same `src` path after the tree moved returned
different content (`echo CURRENT` → `echo STALE`) while the run still reported version 1.0.5.
The same probe after the fix resolves the cache path and reads byte-identical content across
the move.

The resolution is the second tie-break axis the ticket specified — **newest version wins; an
equal version goes to the immutable candidate** — plus `src_immutable` and a per-candidate
`immutable` so a caller reads the property instead of re-deriving it. Immutability is read off
the path, not off the source name: a candidate is immutable when it is **version-addressed**
(its own basename is the version it carries, the cache layout
`<cache>/workaholic/workaholic/<version>/`). That test is env-free and correctly calls a
checkout, a clone, and a binding pointing at either mutable — including the case a source-kind
rule would get wrong, a developer who bound `${CLAUDE_PLUGIN_ROOT}` to a working tree.

Two deviations from the steps as written, both recorded rather than silently taken:

- **Step 4** asked for the ordering statement in the two command markdowns. Those commands are
  now thin aliases that carry no step 0/0b tables at all (the resolve-then-freshen ordering
  lives in `drive/SKILL.md` §1), so adding it there would have contradicted *thin commands,
  comprehensive skills*. Taken as the step's own stated preference: stated once in
  `check-deps/SKILL.md` and pointed at from `drive/SKILL.md` §1, which is the text both
  commands delegate to.
- The ticket's `## Policies` cites `workaholic:operation` / `policies/observability.md`, which
  does not exist — the operation pillar ships `ai-production-investigation.md`, `ci-cd.md`, and
  `no-customer-support-in-repo.md`. The intent (a run must not report a plugin version other
  than the one whose code it executed) is answered by `src_immutable` and by the run report
  recording it; no policy file was invented to match the citation.

### Discovered Insights

- **Insight**: This ticket's own defect fired on the run that implemented it, and the recovery
  path was the one the ticket predicted. The tick started on a harness branch at `origin/main`
  with a *shallow* clone whose local `main` was the image's stale baked tip; `sync-main.sh`
  answered `not_on_main`, then `diverged`/`both_diverged` after switching to `main`.
  **Context**: The shallow clone is what made the divergence unreadable — `git merge-base` was
  empty, so the two histories looked unrelated rather than 456 apart. `git fetch --unshallow`
  turned it into a plain fast-forward with 0 local-only commits, and the reflog (`branch:
  Created from refs/remotes/origin/main`, one entry) is what proved nothing local was at risk.
  A future run meeting `diverged` on a cloud container should check `--is-shallow-repository`
  and the reflog before reading it as a human's decision to preserve.

- **Insight**: The equal-version tie is the *normal* state on a cloud tick, not an edge case.
  **Context**: The bootstrap installs the same version into the registry cache that the
  checkout carries, so nearly every tick hits the tie and — before this change — took the
  mutable side of it. The window is only as long as step 0 → step 0b, but that is exactly the
  span containing `sync-main.sh`, the one step whose job is to move the tree.
