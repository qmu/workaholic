---
created_at: 2026-06-30T21:52:29+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash: e01fea7
category: Added
depends_on:
---

# Enrich /catch per-developer report with focus windows, struggles, branches, and generation style

## Overview

Extend the `/catch` by-developer catch-up report so that, for each developer, it answers six specific questions the current report does not:

1. **Yesterday + today's focus** — what they worked on most recently.
2. **This week's focus** — the dominant theme across the current calendar week.
3. **Last week's focus** — the same for the prior week.
4. **What they are struggling with** — open difficulties, drawn from concrete evidence (commit `Concerns:` keys, their open todo/icebox tickets, and matching story `## 6. Concerns` blocks), never invented.
5. **Branches they're working on** — each branch with its commit count and a one-line focus.
6. **Guessed generation style** — an explicit inference from commit-timestamp shape (e.g. spread-out daytime commits ⇒ "daytime ticket-driving"; a dense overnight cluster in one branch run ⇒ "overnight long-running drive").

The `/catch` skeleton already exists (added the day before this ticket): a thin `commands/catch.md` over `skills/catch/SKILL.md`, with a Phase-0 `scan-window.sh` scanner and a per-developer `general-purpose` (haiku) collector fan-out. This ticket extends three surfaces of that skeleton — the scanner's data, the collector contract, and the rendered report — without changing its architecture. **Field 7 (this-week deployments/releases) is deliberately split into a dependent ticket** because it introduces a new read of ship-produced artifacts and a different attribution join.

`/catch` stays **strictly read-only**: it writes, moves, and archives nothing. Fields 1–3 and 6 are computable from data the scanner already returns (each commit's ISO timestamp, subject, and body); field 4 reuses already-collected tickets/stories; only field 5 (per-branch grouping) requires the scanner to collect data it currently discards.

## Policies

The standard engineering policies — synced from the corporate site (qmu.co.jp) into the `workaholic` policy skills — that govern this ticket. The implementing session **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — any new script stays under `skills/catch/scripts/`; no new top-level area.
- `workaholic:implementation` / `policies/coding-standards.md` — the operative concrete standard for this shell-only change is the repo's `rules/shell.md` (POSIX sh `#!/bin/sh -eu`, no bashisms, machine-checked by `posix-lint.sh` + `test-workflow-scripts.mjs`).
- `workaholic:implementation` / `policies/command-scripts.md` — all multi-step logic (time-bucketing, per-branch grouping, generation-style timing signal) goes in the bundled `scan-window.sh`, not inline in the command/skill markdown (the repo's Shell Script Principle).
- `workaholic:implementation` / `policies/objective-documentation.md` — the report **describes** activity, it does not grade it: the generation-style guess (field 6) must be phrased as an explicit inference, and struggles (field 4) must cite concrete `Concerns:`/ticket/story evidence, never asserted difficulty.
- `workaholic:implementation` / `policies/test.md` — `scan-window.sh` is currently untested; new branch-grouping / bucketing logic should gain hermetic coverage in `test-workflow-scripts.mjs`.

## Key Files

- `plugins/workaholic/skills/catch/SKILL.md` — the primary surface. Three edits: (a) the **Collect Developer** task list gains the new analysis steps; (b) the **Collector Output JSON** schema (~lines 93–106) gains `recent_focus`, `week_focus`, `last_week_focus`, `struggles[]`, `branches[]{name, commit_count, focus}`, `generation_style`; (c) the **Report Structure** template (~lines 110–144) gains the matching rendered bullets per developer.
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — POSIX-sh scanner emitting `{window, developers[], tickets[], stories[]}`. Today it uses `git log --no-merges` (HEAD-reachable), so **branch identity is lost** — field 5 needs a new per-branch axis. Preserve its existing `0x1f`/`0x1e` separator + `jq -Rs` pattern for any new multi-line fields.
- `plugins/workaholic/commands/catch.md` — thin orchestration; no structural change expected (the fields are added in the skill, per thin-command/comprehensive-skill).
- `plugins/workaholic/skills/gather/scripts/git-context.sh` — already wired into Phase 0; reuse `repo_url` to render clickable branch/commit links (do not inline git commands).
- `scripts/test-workflow-scripts.mjs` — hermetic temp-repo harness; add coverage for the scanner's new per-branch grouping and time-bucketing.

## Related History

`/catch` and its collector/report contract were established one day before this ticket; the haiku-collector and narrative-summarization precedents inform where the new per-developer analysis runs.

- [20260630011811-add-catch-command.md](.workaholic/tickets/archive/work-20260630-011820/20260630011811-add-catch-command.md) - Direct parent: created `commands/catch.md`, `skills/catch/SKILL.md`, `scan-window.sh`, the Collector Output JSON, and the Report Structure this ticket extends; confirms email is the by-developer join key.
- [20260128211509-use-haiku-for-report-subagents.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211509-use-haiku-for-report-subagents.md) - Precedent for the `model: haiku` collector fan-out; the new dimensions widen each collector's task, so the cost/quality tradeoff is relevant.
- [20260210121628-summarize-changes-in-report.md](.workaholic/tickets/archive/drive-20260210-121635/20260210121628-summarize-changes-in-report.md) - Precedent for digesting git activity into a narrative rather than enumerating files — the behavior the focus/struggle/style summaries reuse.

## Implementation Steps

1. **Time-bucketing (fields 1–3).** Bucket each developer's commits by ISO timestamp into three windows — yesterday+today, the current calendar week, and the prior calendar week — and summarize each bucket's subjects/bodies into a one-to-two-line focus. Decide bucket boundaries in `scan-window.sh` (so the collector receives pre-bucketed groups and the boundaries are testable) rather than re-deriving dates in markdown.
2. **Struggles (field 4).** In the collector, derive `struggles[]` from concrete signals only: commit-body `Concerns:` keys, the developer's open todo/icebox tickets (already in `tickets[]`, joined by `author` email), and matching story `## 6. Concerns` blocks. Each struggle item should be traceable to its source.
3. **Per-branch axis (field 5).** Extend `scan-window.sh` to emit, per developer, a `branches[]` list with `{name, commit_count, focus}`. This requires grouping commits by branch (the current `--no-merges` HEAD-reachable scan loses branch identity) — e.g. via `git log --all`/`git branch` joined on the `work-YYYYMMDD-HHMMSS` convention and merge structure. Keep it POSIX sh; preserve the separator/jq pattern.
4. **Generation style (field 6).** Compute a `generation_style` guess from the timestamp shape of the developer's (or per-branch) commits: spread-out daytime commits ⇒ "daytime ticket-driving"; a dense overnight cluster within one branch run ⇒ "overnight long-running drive"; mixed ⇒ describe both. Compute from existing timestamps (no new data); phrase as an explicit guess.
5. **Wire the schema + template.** Add the six keys to the Collector Output JSON schema and render matching bullets in the Report Structure, ordered to read top-down (recent → this week → last week → struggles → branches → style). Keep one-level fan-out: all new data is collected by the scanner / computed in the existing collector — no collector spawns a subagent, no `AskUserQuestion` in a leaf.
6. **Tests + checks.** Add hermetic coverage in `test-workflow-scripts.mjs` for the scanner's per-branch grouping and time-bucketing (throwaway repo with dated commits across branches). Run `node scripts/test-workflow-scripts.mjs` and `sh plugins/workaholic/hooks/posix-lint.sh plugins/workaholic/skills/catch`. No `outputs/` rebuild is required — `catch` is Claude-only and excluded from the generated bundle.

## Considerations

- The scanner's current `git log --no-merges` HEAD-reachable strategy omits unmerged side branches; field 5 needs a deliberate widening to enumerate branches and attribute commits to them. Decide whether to widen `scan-window.sh`'s primary scan or add a sibling `branches[]` pass — keep the developer/commit data and the branch axis consistent. (`plugins/workaholic/skills/catch/scripts/scan-window.sh`)
- `generation_style` is a guess and must be labelled as one; do not present it as fact (`workaholic:implementation` / `objective-documentation`). (`plugins/workaholic/skills/catch/SKILL.md`)
- Keep `/catch` read-only — no ticket creation/movement, no writes of any kind. (`plugins/workaholic/skills/catch/SKILL.md`)
- Collectors are non-interactive leaves: every new field must be computable from inputs the command passes in, so new data (per-branch grouping) is collected by the scanner and handed to the collector, never fetched by the collector spawning anything. (`plugins/workaholic/skills/catch/SKILL.md`)
- Stay POSIX `#!/bin/sh -eu` — no bashisms (`rules/shell.md`); the scanner already uses `sed`/`jq`/`case`, not bash features.
- Widening each collector's task may pressure the haiku model; if summary quality drops, note it for a possible model bump (precedent: the haiku-collector ticket). (`plugins/workaholic/commands/catch.md`)

## Final Report

Development completed as planned. `scan-window.sh` now computes UTC-day time-bucket boundaries (`recent_start`/`week_start`/`last_week_start`) and tags every commit with a `bucket` (`recent`/`this_week`/`last_week`/`older`) plus its `epoch` and `branch`; the scan widened to `--branches --source` so unmerged topic branches are visible and a per-developer `branches[]` axis (name + commit_count, most-active-first) is emitted. `catch/SKILL.md` gained the six new collector dimensions (time-windowed focus, struggles from concrete signals, per-branch focus, generation-style-as-explicit-guess), the matching Collector Output keys, and the rendered Report Structure bullets.

Verified: `scan-window.sh` runs clean (posix-lint conforming); a new hermetic `testScanWindowBuckets` asserts the bucket boundaries, per-commit bucket assignment, and the two-branch axis; the full suite is **238 passed / 0 failed**; `build.mjs` + `verify.mjs` green and `outputs/` rebuilt.

### Discovered Insights

- **Insight**: `catch` **is** bundled into `outputs/workflows` (the build log lists it, and `outputs/workflows/skills/catch/catch/scripts/scan-window.sh` exists) — so editing `catch/SKILL.md` or `scan-window.sh` **does** require an `outputs/` rebuild. The ticket's premise that catch is "Claude-only and excluded from the generated bundle" was wrong; treat the build output / `outputs/` tree as authoritative, not a prior assumption.
  **Context**: The `Outputs Freshness` CI fails on any `outputs/` diff, so a catch change without a rebuild would fail CI. The same applies to ticket 2 (field 7), which also edits these files.
- **Insight**: The scanner's bucket boundaries are UTC-day based (`epoch - epoch % 86400`) to stay POSIX (no `date -d` arithmetic); committer epoch comes from `%ct` and is compared in jq against `--argjson` boundaries. This is precise enough for a focus narrative but shifts day boundaries by the local-UTC offset — acceptable here, but worth knowing if exact local-midnight bucketing is ever required.
  **Context**: `git log --source %S` attributes each commit to one branch (the ref it was walked from); a commit on multiple branches lands on whichever git walks first, so `branches[]` counts are approximate for shared commits.
