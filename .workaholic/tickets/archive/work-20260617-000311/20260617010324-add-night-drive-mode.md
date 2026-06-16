---
created_at: 2026-06-17T01:03:24+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 1h
commit_hash: 7f915a3
category: Added
depends_on:
---

# Add an autonomous "night drive" mode to /drive

## Overview

Add a **night drive** mode to `/drive`, triggered when the invocation contains the
word **"night"** (e.g. "go night /drive"), for unattended overnight runs the
developer reviews in the morning. The mode:

1. **Asks upfront which tickets to target.** Before any implementation, the
   command issues ONE `AskUserQuestion` (`multiSelect: true`) listing the
   prioritized todo tickets so the developer selects exactly which ones tonight's
   run is authorized to implement. This is the single interaction of the whole
   run.
2. **Runs autonomously, skipping the per-ticket approval gate.** For each selected
   ticket it implements, then **auto-approves** (update effort → append Final
   Report → `archive.sh` → commit) without the Step 2.2/2.3 `AskUserQuestion` — the
   upfront selection is the explicit, informed authorization for the whole batch.
3. **Prints a whole-night report to stdout at the end** so the developer can review
   every outcome in the morning: per-ticket implemented / skipped / failed, commit
   hashes, and failure reasons, plus session totals.

This builds directly on the existing drive machinery (mode detection, the
continuous loop, the Final Report / completion summary) — it is a new invocation
variant, not a new workflow. Aligns with the overnight-workflow → morning-review
vision.

**The safety reconciliation is the heart of this ticket** (see Considerations):
night mode must carve a *scoped* exception to "NEVER proceed without explicit user
approval" while keeping every other Critical Rule — no auto-icebox, no auto-abandon,
no destructive git — fully intact.

## Key Files

- `plugins/core/skills/drive/SKILL.md` - The file to branch (regenerate `dist/` after):
  - **Mode detection (L61-64)** — add `night` alongside `icebox`: "if `$ARGUMENT` contains 'night' → mode = night". Same prose-detection pattern as icebox (no script needed).
  - **Phase 1 Navigate / Navigator "Confirm Order with User" (L57-82, L267-276)** — in night mode replace the order-confirmation single-select with an upfront `multiSelect` of **which** tickets to run; the prioritizer subagent still topo-sorts the selected subset for execution order.
  - **Phase 2 Step 2.2 / 2.3 (L92-125)** — in night mode, skip issuing the approval `AskUserQuestion` and auto-resolve as "Approve" (effort + Final Report + `archive.sh` + commit), then continue.
  - **Critical Rules (L156-169)** — add the night-mode failure branch: on a ticket that can't be implemented, **skip-and-continue + record** (leave it in todo), never auto-icebox, never destructive git. Keep "Never commit ticket moves without approval" intact.
  - **Phase 3 Re-check (L127-143)** — in night mode, do NOT pick up tickets added during the run; the authorized set is exactly the upfront selection (bounds the run, preserves explicit authorization).
  - **Phase 4 Completion (L145-154)** — extend into the whole-night stdout report (per-ticket outcome, commit hash, skipped/failed + reason, totals).
  - **Workflow Critical Rules (L351-356)** — "NEVER use AskUserQuestion" stays satisfied because the gate is *skipped*, not invoked.
- `plugins/work/commands/drive.md` - Thin command (L14-16). Ensure the invocation text/`$ARGUMENT` ("night") reaches the skill's mode detection, and that the command (main agent) issues the upfront `multiSelect` selection itself (one-level fan-out: leaves never prompt). Add a one-line mode-routing note; no logic here.
- `dist/workflows/skills/drive/SKILL.md` - GENERATED mirror; regenerate via `node scripts/build-plugins/build.mjs` (Dist Freshness CI guards it).
- (If any new conditional shell is introduced — e.g. failure classification or report aggregation — it must be a bundled `plugins/core/skills/drive/scripts/*.sh` referenced via `${CLAUDE_PLUGIN_ROOT}`, per the Shell Script Principle. The mode detection and report are prose/in-context, so a new script may not be required.)

## Related History

- [20260202192408-continuous-drive-loop.md](.workaholic/tickets/archive/drive-20260202-134332/20260202192408-continuous-drive-loop.md) - The autonomous continuous loop + session-wide commit tracking night mode reuses for its run-to-completion behavior and totals.
- [20260125113309-drive-approve-and-stop-option.md](.workaholic/tickets/archive/feat-20260124-200439/20260125113309-drive-approve-and-stop-option.md) - Defines the approve+commit gate semantics night mode auto-resolves.
- [20260131194500-per-ticket-approval-in-drive-loop.md](.workaholic/tickets/archive/feat-20260131-125844/20260131194500-per-ticket-approval-in-drive-loop.md) - Establishes why approval lives at the command/main-agent level and the `pending_approval` return contract; night mode auto-resolves this at the command level.
- [20260123002535-drive-auto-continue.md](.workaholic/tickets/archive/feat-20260122-210543/20260123002535-drive-auto-continue.md) - Prior friction-reduction precedent (removed the between-ticket "continue?" prompt while keeping implementation approval) — frames which gate night mode removes.
- The auto-approval/loop-termination concerns ([21-auto-approval-configuration…](.workaholic/concerns/archive/21-auto-approval-configuration-bash-bash-in.md), [18-continuous-loop-termination…](.workaholic/concerns/archive/18-continuous-loop-termination-the-only-way.md)) carry directly into this unattended mode — see Considerations.

## Implementation Steps

1. **Detect night mode** at the existing mode-detection point (SKILL.md L61-64), parallel to `icebox`.
2. **Upfront selection**: in night mode, Phase 1 issues one command-level `AskUserQuestion` with `multiSelect: true` over the prioritized todo tickets; the resolved subset (topo-sorted by the prioritizer) is the night's authorized batch.
3. **Autonomous loop**: for each authorized ticket, implement (Step 2.1, including the existing type-check/test verification), then auto-approve — update effort, append Final Report, run `archive.sh`, commit — with NO approval `AskUserQuestion`.
4. **Failure policy (unattended)**: if a ticket cannot be implemented or its checks fail or its frontmatter update fails, **skip it and continue** — leave it in `todo`, record the reason for the report, and do NOT auto-icebox/abandon or run destructive git. Isolate its partial working-tree changes from the next ticket's commit (see Considerations).
5. **Bound the run**: do not absorb tickets added after the upfront selection (skip Phase 3's re-check in night mode); finish when the authorized batch is exhausted.
6. **Whole-night report**: at the end, print a structured stdout report — per-ticket {implemented | skipped | failed, commit hash, reason}, plus totals (implemented / skipped / failed, all commit hashes).
7. **Regenerate `dist/`** and run `verify.mjs`, `validate-metadata.mjs`, `test-workflow-scripts.mjs`.

## Considerations

- **Explicit approval is relocated, not removed.** The scoped exception to "NEVER
  proceed without explicit user approval" (SKILL.md L96) is legitimate only because
  the user makes ONE explicit, informed, selectable-option authorization of the
  exact named batch upfront. Autonomy is bounded to precisely that set.
  (`plugins/core/skills/drive/SKILL.md` Step 2.2; `standards:operation`)
- **No exception to the other Critical Rules.** Never auto-move a failed ticket to
  icebox, never auto-abandon, and never run destructive git (`git restore .` /
  `git clean` / `git reset --hard` / `git stash drop`) — the interactive Abandon
  flow's discard step requires a human and is out of bounds unattended. Failed
  tickets stay in `todo` with the working tree intact for morning review.
  (`plugins/core/skills/drive/SKILL.md` Critical Rules L156-169, Prohibited Operations)
- **Cross-ticket contamination is a real risk.** If ticket A fails mid-implementation
  leaving uncommitted changes and the loop proceeds to B, `archive.sh`'s staging
  could sweep A's partial work into B's commit. Resolve non-destructively — e.g.
  `git stash` A's changes before continuing (stash is permitted; only `git stash
  drop` is prohibited), or commit A's partial work to a clearly-labeled holding
  ref — so each successful ticket's commit stays clean and A's work survives for
  morning. Pick and document the mechanism during implementation.
  (`plugins/core/skills/drive/scripts/archive.sh`)
- **Checks still gate auto-commit.** The per-ticket type-check/test step (Workflow
  step 3) is NOT relaxed: a failing check classifies the ticket as *failed* →
  skip + record, never force-committed. Quality is preserved even without a human.
  (`standards:implementation` machine-checkable correctness)
- **The report is the deliverable / observability output.** Because no human watches
  the run, the morning report is what makes it explainable: per-ticket outcome,
  commit hash, skipped/failed + reason, totals. Make it complete and skimmable.
  (`standards:operation` Observability)
- **Termination / runaway (concern #18).** Night mode terminates deterministically
  when the finite pre-selected batch is exhausted — it must NOT fall into the
  open-ended "re-check todo until empty" loop, since new tickets were never
  authorized. (`.workaholic/concerns/archive/18-continuous-loop-termination-the-only-way.md`)
- **Auto-approval widens bash permissions (concern #21).** Unattended auto-commit
  relies on broadened `Bash` permissions; note the operational prerequisite so the
  user sets up permissions before relying on an overnight run.
  (`.workaholic/concerns/archive/21-auto-approval-configuration-bash-bash-in.md`)
- **Dist regen + version sync.** `core:drive` is `metadata.internal` with
  `${CLAUDE_PLUGIN_ROOT}`; regenerate `dist/workflows` and keep the synchronized
  semver across `marketplace.json` + plugin manifests. (CLAUDE.md Version Management, Dist Freshness CI)
- **Cross-agent degradation.** On non-Claude agents the upfront `multiSelect`
  degrades to the agent's native multiple-choice per the skill's Agent Compatibility
  note; the autonomous behavior itself is agent-neutral. (`dist/workflows/skills/drive/SKILL.md`)

## Final Report

Development completed as planned (night drive, auto-approved — this ticket
implements the very mode running it). Added a `night` branch to the mode-detection
in `core:drive`, and a comprehensive **Night Mode** section covering: the upfront
`multiSelect` authorization, the autonomous auto-approve loop, the safe-by-default
failure policy (skip-and-continue + record; `git stash` to isolate partial work;
no auto-icebox / no destructive git), the bounded run (skip Phase 3 re-check), and
the whole-night stdout report. Wired pointers at Step 2.2 (gate auto-resolved),
Phase 3 (skipped), Phase 4 (emits the report), and the Critical Rules (night-mode
failure carve-out), plus a note in the `/drive` command. Regenerated `dist/`;
build/verify/validate and 49 smoke tests pass.

### Discovered Insights

- **Insight**: Night mode keeps the Workflow "NEVER use AskUserQuestion" boundary
  intact by *skipping* the approval gate rather than auto-answering it — the
  approval is relocated to the single upfront `multiSelect`, not removed.
  **Context**: this is the conceptual hinge that lets autonomy coexist with the
  "explicit approval" Critical Rule.
- **Insight**: The cross-ticket contamination risk is real in practice — `git
  stash`-ing a failed ticket's partial work before continuing is the
  non-destructive isolation the failure policy depends on (only `git stash drop`
  is prohibited). **Context**: a future implementer wiring the actual loop must not
  skip the stash, or a later ticket's `archive.sh` (`git add -A`) would sweep in
  the failed ticket's changes.
