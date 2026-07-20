---
created_at: 2026-07-21T02:57:20+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain, Config]
effort:
commit_hash:
category:
depends_on:
mission: reorganize-missions-under-strategies
---

# Add commit-count KPI script and catch surface

## Overview

Make **commit count** measurable as the orchestration-throughput KPI: not a KPI of human developer performance, but of *how well a fleet of coding agents is orchestrated and kept running* — how many agents, for how long, producing how much code change. The unit is meaningful only because per-commit size is normalized (the changed-lines gate, ticket `20260721020759`, keeps non-generated commits at ~a-few-hundred lines); this ticket builds the **measurement**, that one builds the **normalization**. Reference it; do not restate its thresholds.

One deterministic script computes the numbers; `/catch` surfaces them. No dashboard, no stored metrics files — the KPI is derived from git history on demand, identical for any caller.

## Policies

The standard engineering policies that govern this ticket. Read each linked hard copy before writing code; keep every change defensible against its Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout (applies to all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX script (applies to all code work)
- `workaholic:development` / `policies/weekly-quota.md` — the KPI measures *value throughput of orchestration*, and quota consumed only to raise a number is explicitly worthless; the docs must carry this guard
- `workaholic:development` / `policies/commit-change-history.md` — history is never reshaped for the number: no squash/rebase grooming, agent-authored incremental commits stay as they are; the KPI reads history, it never motivates rewriting it
- `workaholic:operation` / `policies/ci-cd.md` — the metric is a reproducible script, same result for human or AI
- `workaholic:implementation` / `policies/objective-documentation.md` — the KPI's definition (what is counted, over what window, why) documented verifiably

## Key Files

- `plugins/workaholic/skills/gather/scripts/commit-kpi.sh` — new: args `[window]` (default `1 week`, `git log --since` syntax); emits `{window, total_commits, agent_commits, agent_share, median_changed_lines, p90_changed_lines, oversize_commits}` where `agent_commits` counts commits bearing an Anthropic `Co-Authored-By` trailer (the same identification the ~8,600-commit study used), changed-lines stats use `--numstat` excluding binary rows, and `oversize_commits` counts non-generated commits over the `MAX_COMMIT_CHANGED_LINES` constant once ticket `20260721020759` lands (read the constant from the release-scan script's definition — single source; emit `null` while it does not exist yet). Placed in `gather` because it is a shared read-only context script, `/catch` its first consumer.
- `plugins/workaholic/skills/catch/SKILL.md` + its scanner scripts — the catch report gains an **Orchestration throughput** block per developer window: agent-commit count, share, median/p90 changed lines, oversize count; one compact table, prose kept minimal.
- `plugins/workaholic/commands/catch.md` — mention the new block (thin; knowledge stays in the skill).
- `plugins/workaholic/skills/release-scan/scripts/scan-branch-safety.sh` — read-only reference for the threshold constant name (from ticket `20260721020759`); no changes here.
- `scripts/test-workflow-scripts.mjs` — hermetic: throwaway repo with trailered and untrailered commits of known sizes → assert counts, median/p90 math, window filtering, and the `null` oversize behavior pre-gate.
- `outputs/workflows` — catch is a built target and gather is in its closure: run the argument-less build. `CLAUDE.md` (`/catch` row), `README.md` in the same change.

## Implementation Steps

1. Implement `commit-kpi.sh` (POSIX, `git log`/`--numstat`/awk only, no network) with the exact output contract above.
2. Add the Orchestration-throughput block to the catch skill's report composition, fed by the script's JSON.
3. Document the KPI's definition and both policy guards (no count-gaming, no history reshaping) in the catch SKILL block and the `.workaholic/README.md` KPI note.
4. Hermetic tests; full build; docs.

## Quality Gate

Interrogated at mission creation (2026-07-21); verification depth ruling: hermetic suite + in-session demo.

**Acceptance criteria**

- On a fixture repo, `commit-kpi.sh` returns exact counts (trailer detection, window filter), correct median/p90 over known sizes, and `oversize_commits: null` while the gate constant is absent.
- `/catch`'s report renders the block from the JSON without recomputing anything inline.
- The KPI definition and its two guards are documented; ticket `20260721020759` is referenced, its thresholds not duplicated.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green with the fixture cases.
- `node scripts/build-plugins/build.mjs` + `verify.mjs` + `validate-metadata.mjs` green; POSIX lint.

**Gate**

- Suite green, build/verify green, and an in-session demo: run `commit-kpi.sh` against this repository and show the real numbers.

## Considerations

- Windowed medians on small repos are noisy; the script reports counts honestly and leaves interpretation to the reader — no smoothing, no targets encoded (`skills/gather/scripts/commit-kpi.sh`).
- Cross-repo aggregation (the fleet view over many projects) is deliberately out of scope here — per-repo numbers first; an aggregator would live outside any single repo's plugin instance.
- If ticket `20260721020759` renames its constant, this script's single-source read is the only coupling point to update (`scan-branch-safety.sh`).
