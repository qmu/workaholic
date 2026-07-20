---
created_at: 2026-07-21T02:57:19+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission: reorganize-missions-under-strategies
---

# Auto-create PR for completed missions in monitor

## Overview

The mission lifecycle ruling (mission creation, 2026-07-21): "merge the worktree and clean up when all tickets are done" is implemented as **PR-auto-creation, not auto-merge**. When a driven mission reaches genuine completion per `status.sh`, `/monitor` itself carries that mission's worktree through the report flow — release-scan (warn tier), story generation, PR creation — so the morning starts at "review and `/ship`", not at "run `/report` N times". Merge remains `/ship`'s deploy-evidence-gated step (full auto-merge was explicitly rejected: it would bypass PR review and the deploy-before-merge doctrine); worktree teardown remains `/mission close` after ship.

This runs in the **main agent (dispatcher)**, not in a leaf: a `general-purpose` leaf cannot invoke a command, and the report flow's machinery is reachable as skills from the command level (the same way `/report` itself uses them). PR outcomes are reported per mission; a PR-creation failure is listed as its own item and **does not** change the mission's completion classification or the terminal token — `ok` keeps meaning "every driven mission complete", with PR status stated separately and honestly.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX where scripted (applies to all code work)
- `workaholic:development` / `policies/overnight-ai.md` — the run's output is reviewable results by morning; an open PR is the reviewable unit
- `workaholic:operation` / `policies/ci-cd.md` — the PR path reuses the deterministic release-scan gate; nothing new bypasses it
- `workaholic:development` / `policies/qa-engineering.md` — completion classification and PR status reported separately, neither self-graded

## Key Files

- `plugins/workaholic/skills/monitor/SKILL.md` — §3/§5: after terminal classification, a **PR phase** for each `complete` mission: within `( cd <worktree_path> && … )`, run the report skill's story/PR flow scoped to that worktree's branch (release-scan warn-tier findings ride into the PR body as `/report` already does); collect `{mission, pr_url | error}`; then the final report and token.
- `plugins/workaholic/commands/monitor.md` — Step 4 gains the PR phase (dispatcher-owned, sequential per completed mission to keep `gh` and story generation simple); the report lists PR URLs / failures.
- `plugins/workaholic/skills/report/SKILL.md` + its scripts — reuse, do not fork: whatever entry the report flow exposes for "story + PR from this branch" is called as-is; if the flow assumes interactive confirmation, add the non-interactive path guarded to monitor's use (decide-and-record: warn-tier scan findings are recorded in the PR body instead of asked).
- `plugins/workaholic/skills/mission/SKILL.md` — lifecycle prose: complete → PR (monitor) → `/ship` (human, deploy-gated) → `/mission close` (teardown); "merge and clean up" formally means this chain.
- `scripts/test-workflow-scripts.mjs` — hermetic coverage for any new/changed script surface (no `gh`/network in tests — assert up to the PR-command boundary, e.g. the composed call and its inputs, per the existing suite's no-network doctrine).
- `outputs/workflows` — mission (and report, if its skill changes) are built targets: run the argument-less build. `CLAUDE.md` (`/monitor` row: "PRs stay with /report/ship" wording becomes "monitor opens the PR; merge stays /ship"), `README.md`, `.workaholic/README.md` in the same change.

## Implementation Steps

1. Specify the PR phase in the monitor skill: trigger (only `complete` per `status.sh`, gate included when declared), execution seat (dispatcher, subshell per worktree), sequencing (one at a time), outcome collection, and the story's mission rolls (the existing report seam already appends `story reported` — verify it fires on this path too).
2. Thread the non-interactive report path: story written, release-scan run with warn findings folded into the PR body, PR created from the mission worktree's branch; no `AskUserQuestion` anywhere in the phase.
3. Update `commands/monitor.md` Step 4 and the final-report shape (`pr_url`/`pr_error` per completed mission).
4. Update mission SKILL lifecycle prose; reconcile the CLAUDE.md `/monitor` row.
5. Tests to the no-network boundary; full build; docs.

## Quality Gate

Interrogated at mission creation (2026-07-21); verification depth ruling: hermetic suite + in-session demo.

**Acceptance criteria**

- A mission classified `complete` gets exactly one PR attempt per run; incomplete/blocked missions get none.
- PR failure appears as its own report item and never alters completion counts or the `ok`/`pending` token.
- No interactive prompt exists on the PR path; warn-tier scan findings are recorded in the PR body.
- Docs and built outputs updated in the same change; the story seam still rolls the mission (`story reported` changelog line).

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green (composed-call assertions, no network).
- `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` green; POSIX lint for touched scripts.

**Gate**

- Suite green, build/verify green, and an in-session walkthrough of the phase's decision table (complete/incomplete/failure paths) against a throwaway repo's status fixtures — the `gh`-touching step itself is exercised the first real night, and the first morning review confirms the PR arrived (recorded expectation, not a hermetic assertion).

## Considerations

- Secrets remain non-overridable at `/ship`; the monitor PR phase must not weaken any scan tier — it only relocates *when* the warn-tier run happens (`skills/release-scan/`).
- Story quality overnight is acceptable-by-design: the PR is reviewed in the morning; a weak story is amended then, cheaply (decide-and-record doctrine).
- Sequential PR creation avoids interleaved `gh` auth/rate issues across many missions; revisit only if morning latency measurably matters (`commands/monitor.md`).
- If the report flow's context detection (journey vs story) mis-detects inside a mission worktree, scope it explicitly by branch — do not fork the flow (`skills/report/SKILL.md`).

## Final Report

Development completed as planned.

### Discovered Insights

- **Insight**: No new script was needed — the report flow's `create-or-update.sh` is already non-interactive, so the monitor PR phase reuses the Write Story + create-or-update seam inside a `( cd <worktree_path> && … )` subshell scoped by branch. The only report-side change is a documentation note; forking the flow was avoided.
  **Context**: `plugins/workaholic/skills/report/scripts/create-or-update.sh` never prompts; interactivity in `/report` is context-detection and concern triage, both bypassed by scoping to the mission worktree's known branch.
- **Insight**: The PR-phase trigger is exactly `status.sh`'s `complete` flag, already covered by testMonitorStatus — so the hermetic boundary for this ticket is that decision table, and the gh-touching step is exercised the first real night (per the ticket's own gate). A PR failure is deliberately decoupled from the terminal token so `ok` never over-reports.
  **Context**: `plugins/workaholic/skills/monitor/scripts/status.sh` complete-derivation; monitor SKILL §5 keeps token computation after and independent of the PR phase.
