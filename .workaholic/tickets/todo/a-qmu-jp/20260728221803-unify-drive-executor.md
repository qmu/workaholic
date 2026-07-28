---
created_at: 2026-07-28T22:18:03+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, UX]
effort: 4h
commit_hash:
category: Changed
depends_on: 20260728221802-add-claim-protocol-scripts.md
mission: loop-engineering-unified-drive
---

# Unify the drive executor

## Overview

Execute decisions G1–G2, G4–G5, and I7: `/drive` becomes the **sole executor**, identical interactively and on the cron, with **no drive-time confirmation**. Its run shape:

1. **Survey** — fetch; read in-flight claims (`list-claims.sh`); read approved missions (status axis, ticket 221801) and the backlog (`todo/` tickets not mission-claimed); subtract the claimed.
2. **Partition** the unclaimed remainder into **PR-units** ("what deserves one merge"): each approved mission is one unit; related backlog tickets group into one batch unit (relatedness is the executor's judgment — same subsystem/files/dependency chain; when unsure, smaller units). Selection is autonomous — the interactive run *reports* the partition, it never asks.
3. **Per unit**: `claim.sh` → drive the unit's tickets in its worktree exactly as today's authorized-queue drive (per-ticket implement → gate → `archive.sh`; the per-ticket approval prompt is gone — approval happened at the artifact level: mission approval or ticket creation) → the report seam (`/report`'s story + `create-or-update.sh`, scoped to the claim branch, non-interactive: warn-tier scan findings recorded in the PR body).
4. **Route by effective merge policy (G5)**: every member `merge_policy: auto` (mission policy for mission units; per-ticket for batches, absent = `review`) **and** the scan free of overridable blocks → the automated `/ship` doctrine (deploy/verify proof, merge, release, extraction) and worktree teardown (I6); otherwise → stop at the PR and post its URL to Slack via `propose/scripts/notify-slack.sh`. A `secret` finding always hard-stops; a `size` block on an auto unit **demotes it to the PR path** (an unattended run never overrides a gate — G5's "as always").
5. **Account and report**: per-unit agent-hours recorded via `mission/scripts/record-run-hours.sh` (I7 — the absorbed `/monitor` seam) for mission units; the run ends with the honest reconciliation and terminal token (`N units: shipped/PR'd/blocked` … final line `ok` only when nothing claimable remains undone, else `pending`) — the `/goal`-compatible contract (I4) now lives here.

The "Drive Every 5 Minutes" routine (G4) is this command on a cron; document it beside the proposal runbook.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal, Responsibility, and Practices.

- `workaholic:planning` / `policies/modeling-centric-design.md` — the survey→partition→drive→route pipeline is the model; state it in the SKILL before the steps
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` for any new script (applies to all code work)
- `workaholic:operation` / `policies/overnight-ai.md` — unattended runs collect judgment calls for the morning instead of stopping; the attempt-first doctrine carries over from night mode
- `workaholic:operation` / `policies/operational-planning.md` — the routine's runbook states observables and failure modes
- `workaholic:implementation` / `policies/objective-documentation.md` — the effective-policy derivation and the terminal-token truth table are written verifiably

## Key Files

- `plugins/workaholic/skills/drive/SKILL.md` — the rewrite's core: a new **Unified Run** section (survey/partition/claim/drive/route/report, the effective-merge-policy table, the demote-on-size rule, the terminal truth table), the per-ticket-prompt retirement (approval moved to the artifact level — reference ticket 221801's model), night-mode text folded in (the unified run *is* the unattended shape; `/drive night` becomes a synonym), and the honest-terminal contract relocated from the monitor skill.
- `plugins/workaholic/commands/drive.md` — thin orchestration of the Unified Run; headless-compatible (no `AskUserQuestion` anywhere in the run; the command is on the policy-lens sentinel list already). Interactive invocations get the same behavior plus richer progress narration.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — NEW: the deterministic half of partitioning — emit `{missions: [approved-unclaimed], backlog: [unclaimed tickets + frontmatter summary]}` for the model to group (grouping is judgment; the survey is script).
- `plugins/workaholic/skills/drive/scripts/effective-policy.sh` — NEW: given a unit (mission slug or ticket list), derive `auto|review` per G5 (mission policy; per-ticket with absent=review; any review member → review). One place, tested.
- Automated `/ship` reuse: the route step drives `workaholic:ship`'s Ship Flow non-interactively for auto units — deploy-contract proof, merge, CI release, extraction — with the already-decided constraints (secrets hard-stop; size demotes to PR; the §1-4 no-confirmation-method halt demotes to PR likewise). Factor the interactive `AskUserQuestion` seams so the unattended caller takes the demote path instead of prompting (`skills/ship/SKILL.md` gains an **Unattended routing** note; no logic forks).
- `plugins/workaholic/skills/mission/scripts/record-run-hours.sh` — caller changes from `/monitor` prose to `/drive` (script unchanged; I7).
- Worktree teardown at ship: after an auto unit merges, `cleanup-mission-worktree.sh` + remote branch deletion (the release side of I6).
- `docs/drive-loop-runbook.md` — NEW: the 5-minute cron entry (same env-file pattern as the proposal runbook), one-runner-per-repo note superseded by claims (multi-runner is now safe — that is the point), observability (claim branches, PRs, terminal tokens in the cron log), failure modes (stale claims, demoted auto units, secret hard-stops).
- `scripts/test-workflow-scripts.mjs` — `plan-units.sh` and `effective-policy.sh` hermetic coverage; the run pipeline itself is prose-verified (sentinel greps) like the monitor contract was, plus the truth-table cases as script tests where derivable.
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` — `/drive` row rewritten; the executors paragraph collapses to one executor (the `/monitor`/`/trip` rows fall in the next ticket).

## Implementation Steps

1. Write the Unified Run model into the drive SKILL (pipeline, effective-policy table, demotion rules, terminal truth table, headless contract).
2. Implement `plan-units.sh` and `effective-policy.sh`; wire `record-run-hours.sh`'s new caller.
3. Rewrite `commands/drive.md` around the pipeline; fold night mode in.
4. Add the ship skill's Unattended routing note and verify the auto-unit path never prompts (demote paths for size/no-confirmation; hard-stop for secrets).
5. Wire teardown-at-ship (cleanup + branch delete after merge) and PR + `notify-slack.sh` for review units.
6. Write `docs/drive-loop-runbook.md`; tests; docs sweep; argument-less build; commit regenerated `outputs/`.

## Quality Gate

Interrogated at mission creation (2026-07-28, decision record G1–G5/I4/I6/I7); verification depth ruling: hermetic suite for the deterministic halves + prose-sentinel verification for the run contract, per repo precedent (the monitor contract's method).

**Acceptance criteria**

- `/drive` (one command) surveys claims + approved missions + backlog, partitions autonomously, claims before driving, and never issues `AskUserQuestion` mid-run — interactively or on the cron.
- `effective-policy.sh` implements G5 exactly (absent = review; any review member wins; tested); auto units ship through the full evidence-gated doctrine with secrets hard-stopping and size **demoting to PR, never auto-overriding**; review units end at a PR whose URL is posted via the notifier.
- Mission units record agent-hours via the absorbed seam; the run's final line is the honest token (`ok` only when nothing claimable remains undone).
- The 5-minute runbook exists and mirrors the proposal runbook's shape; multi-runner is documented as safe via claims.
- Suite/build/verify/metadata green; docs updated in the same change.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green (plan-units, effective-policy, truth-table cases, prose sentinels); build + verify + validate-metadata green; posix-lint conforming.

**Gate**

- Suite green, and a hermetic dry demo: seed an approved mission + two backlog tickets in a throwaway repo, run `plan-units.sh` + `effective-policy.sh`, and show the partition + routing a run would take.

## Considerations

- **Never auto-override a gate.** The interactive `/ship` may ask a human to accept a size block; the unattended route must demote to the PR path instead — G5's `auto` means "no *approval* needed", never "no *gate* applies".
- The per-ticket approval prompt's retirement is phase-3 doctrine, not a loosening: approval moved to artifact creation (`merge_policy` question) and mission approval — record that relocation in the drive SKILL where the prompt used to be specified.
- Keep `/goal` compatibility (I4): the terminal token contract is verbatim the monitor one; `/goal /drive ok` becomes the caller-side loop.
- Batch grouping judgment stays conservative like the propose bar: unrelated tickets in one PR is the failure mode reviewers pay for; when unsure, one ticket per unit.
- `/report` and `/ship` remain independently usable on a hand-driven branch — the unified run *composes* them; it must not absorb or fork them.

