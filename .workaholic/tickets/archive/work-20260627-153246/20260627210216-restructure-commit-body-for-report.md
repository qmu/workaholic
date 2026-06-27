---
created_at: 2026-06-27T21:02:16+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Infrastructure]
effort: 2h
commit_hash: b3f06a6
category: Changed
depends_on:
---

# Restructure the commit body to feed /report, and fix the dropped-body gap

## Overview

The structured commit body (built by `commit/scripts/commit.sh`) currently has four sections —
`Description` / `Changes` / `Test Planning` / `Release Preparation` — but two of them are dead
weight for `/report`: the overview-writer never uses `Test Planning` (the report has no test
section) or `Release Preparation` (§8 is produced by a separate release-readiness agent from the
diff). Meanwhile the two sections `/report` works hardest to produce — **§6 Concerns** and
**§7 Successful Development Patterns** — receive nothing from `git log`; they are reconstructed
solely from archived ticket `Considerations` and `Discovered Insights`, so the signal is lost if a
ticket is ever squashed or pruned.

This ticket re-aims the commit body at the report's narrative sections:

| New body key | Feeds report | Replaces |
| --- | --- | --- |
| `Why:` | §2 Motivation | `Description` (renamed) |
| `Changes:` | §3 Changes / §4 Outcome | `Changes` (kept) |
| `Concerns:` | §6 Concerns (**new signal**) | — |
| `Insights:` | §7 Successful Development Patterns (**new signal**) | — |
| `Verify:` | human/audit trail | `Test Planning` (renamed) |
| *(dropped)* | §8 comes from release-readiness | `Release Preparation` (removed per-commit) |

**Linchpin (must fix or this ticket is cosmetic):** `report/scripts/collect-commits.sh` **computes
the commit body and then throws it away** — it builds a `%b`-bearing variable but the emitted
`COMMITS_CLEANED` array contains only `hash|subject|timestamp`, even though `report/SKILL.md`'s
Overview-Generation schema advertises a `body` field. So today **no commit body reaches `/report`
at all.** Reconciling that drift — actually emitting the structured body and having the report
orchestration consume the new keys — is what makes "feed /report more directly" real.

This extends the deliberate Feb-2026 lineage that built this format
(`20260210154917-expand-commit-message-sections`, which restructured it 4→5 sections "for lead
agent consumption", and `20260210160550`, which made `commit/SKILL.md` the single source of truth).

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills —
that govern this ticket. The implementing session **MUST** read each linked policy hard copy before
writing code and keep every change defensible against that policy's Goal (目標), Responsibility
(責務), and Practices (実践).

- `workaholic:implementation` / `policies/observability.md` — **central:** the commit message is the explain-from-outside audit trail; the new `Concerns`/`Insights` keys are structured signal designed as *inputs for automation* (`/report`), not just human prose. Keep the schema minimal and stable.
- `workaholic:implementation` / `policies/command-scripts.md` — `commit.sh` is the single canonical message-contract owner that a developer and CI both invoke; the format lives in the script + its SKILL.md, never re-implemented inline in command markdown.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to every script edit; binds the POSIX shell rule (below).
- `workaholic:implementation` / `policies/directory-structure.md` — contract knowledge stays in the `commit`/`report` SKILL.md + their `scripts/`; generated copies live under `outputs/`.
- `workaholic:operation` / `policies/ci-cd.md` — reproducible local + CI verification; `commit` ships into `outputs/workflows` via the drive/report/ship closures, so regenerate `outputs/` in lockstep (Outputs Freshness CI fails on any diff).

Repo-own rules (CLAUDE.md): **Shell Script Principle** + **`rules/shell.md`** — `commit.sh` and
`collect-commits.sh` are already `#!/bin/sh -eu`; **keep them POSIX**, now machine-enforced by the
new `hooks/posix-lint.sh` gate and the dash/sh runner in `test-workflow-scripts.mjs`. **Thin
commands, comprehensive skills** — the positional contract stays in the scripts/skills. **Outputs
Freshness** — rebuild `outputs/` and commit in lockstep. **No version bump** for a refactor;
`/report`/`/ship` own release.

## Key Files

- `plugins/workaholic/skills/commit/scripts/commit.sh` — the engine. Positional signature (lines 20-25: `TITLE/DESCRIPTION/CHANGES/TEST_PLAN/RELEASE_PREP` + `shift 5`) and `COMMIT_BODY` builder (lines 84-97) are the primary edit. Replace the Description/Changes/Test Planning/Release Preparation block with Why/Changes/Concerns/Insights/Verify; drop the per-commit Release Preparation positional. Keep `Description`'s "omit when empty" behavior for the optional keys (`Concerns:`/`Insights:` render `None` or are omitted — pick one and document it). Update the usage string (line 28) and parameter help (lines 33-39).
- `plugins/workaholic/skills/commit/SKILL.md` — the knowledge layer: Usage (l.26-29), Parameters (l.31-40), Message Format template (l.59-72), per-section guidance (l.84-97), and all three Examples (l.99-133, impl/archive/abandonment) — rewrite section-for-section to the new keys.
- `plugins/workaholic/skills/drive/scripts/archive.sh` — the ONLY programmatic caller. Receives 7 positional args (l.6-13: ticket, title, repo-url, description, changes, test-plan, release-prep), forwards 5 to `commit.sh` (l.63). Re-map: the drive Final Report → Why/Changes/Concerns/Insights/Verify; the `release-prep` arg is dropped from the commit (decide whether to drop it from archive.sh's signature too or accept-and-ignore for back-compat — see Considerations). Add the two new args.
- `plugins/workaholic/skills/drive/SKILL.md` — update the Archive section + worked example (l.104-108, l.672-695, including the prose "five parameters"/"seven positional arguments" at ~l.690) AND the **Handle Abandonment** path (l.561-571) which calls `commit.sh` **directly** with the old 5 positionals. Also update the **Final Report** → archive arg mapping so the drive agent knows to source Concerns from ticket `Considerations` and Insights from `Discovered Insights`.
- `plugins/workaholic/skills/report/scripts/collect-commits.sh` — **the gap.** It computes `COMMITS` with `%b` (l.19-24) then emits `COMMITS_CLEANED` without it (l.27-37). Make it actually emit the structured body (or the parsed Why/Changes/Concerns/Insights keys) so the overview-writer receives them. Mind the JSON-escaping of multi-line bodies.
- `plugins/workaholic/skills/report/SKILL.md` — reconcile the stale `body` field in the Overview-Generation schema (l.276-284); wire the report orchestration so commit `Concerns`/`Insights` reach the workers that emit §6/§7 (see Considerations for the wiring choice). §6's `### / **Severity:** / **Description:** / **How to Fix:**` format (l.419-448) is parsed verbatim by `extract-carryover.sh` — do not change that shape.
- `scripts/test-workflow-scripts.mjs` — `testArchive` (l.218-276) is the ONLY machine assertion on the body; l.267-270 assert the four old labels and **will break**. Rewrite them to the new keys (no Release Preparation). Add a `collect-commits.sh` assertion that the emitted JSON now carries the body/new keys (currently untested).
- `scripts/build-plugins/build.mjs` — confirms `commit` ships under the drive closure into `outputs/workflows/skills/drive/commit/scripts/commit.sh`; a body change forces an argument-less rebuild.

## Related History

This is the next step in a deliberate, well-documented commit-format lineage.

Past tickets that touched similar areas:

- [20260210154917-expand-commit-message-sections.md](.workaholic/tickets/archive/drive-20260210-121635/20260210154917-expand-commit-message-sections.md) - THE direct precedent: restructured the body 4→5 sections "for lead agent consumption via git log", naming the exact sections this ticket renames/drops. Its Considerations ("new section labels must be parseable by agents reading commit history") apply verbatim.
- [20260210160550-merge-format-commit-message-into-commit.md](.workaholic/tickets/archive/drive-20260210-121635/20260210160550-merge-format-commit-message-into-commit.md) - Established `commit/SKILL.md` as the single authoritative format source; defines the edit closure (commit.sh + commit/SKILL.md + archive.sh in lockstep).
- [20260131145539-structured-commit-messages.md](.workaholic/tickets/archive/feat-20260131-125844/20260131145539-structured-commit-messages.md) - Origin of the structured body (Motivation/UX Change/Arch Change).
- [20260127205856-add-release-preparation-to-story.md](.workaholic/tickets/archive/feat-20260126-214833/20260127205856-add-release-preparation-to-story.md) - Created the per-STORY Release Preparation (§8 release-readiness) that the per-commit Release Preparation duplicates — why dropping it from each commit is low-risk.

## Implementation Steps

1. **Rewrite `commit.sh`'s signature and body builder.** New positional order: `title`, `why`, `changes`, `concerns`, `insights`, `verify` (+ optional files, `--skip-staging`). Build the body as `Why:` / `Changes:` / `Concerns:` / `Insights:` / `Verify:` + the `Co-Authored-By` trailer. Decide the empty-section rule (omit-when-empty like `Description` today, or render `None`) and apply it consistently. Keep POSIX (`#!/bin/sh -eu`, no bashisms).
2. **Re-map `archive.sh`.** Map the drive Final Report inputs to the new positionals; stop forwarding `release-prep` into the commit. Keep the existing CATEGORY heuristic and `update.sh` frontmatter stamping untouched (the Category trailer is the *next* ticket).
3. **Update the abandonment path** in `drive/SKILL.md` (l.561-571) to the new `commit.sh` signature.
4. **Rewrite `commit/SKILL.md`** (Message Format, Parameters, per-section guidance, all 3 Examples) and the `drive/SKILL.md` Archive section/example to the new keys.
5. **Fix `collect-commits.sh`** to emit the structured body (reconcile the dropped-body gap), JSON-escaping multi-line content. Update `report/SKILL.md`'s Overview schema accordingly.
6. **Wire Concerns/Insights into the report** so they reach §6/§7 (see Considerations for the chosen mechanism). At minimum, the overview-writer must receive the body; ideally the section-reviewer receives the commit `Concerns`/`Insights` as an additional input alongside tickets.
7. **Rewrite the `testArchive` body assertions** (l.267-270) and add a `collect-commits.sh` body-emission assertion.
8. **Regenerate + verify:** `node scripts/build-plugins/build.mjs`, then `node scripts/build-plugins/verify.mjs`, `node scripts/build-plugins/validate-metadata.mjs`, `node scripts/test-workflow-scripts.mjs` (all green), and `sh plugins/workaholic/hooks/posix-lint.sh` (0 findings). Stage `plugins/` and `outputs/` together.

## Considerations

- **The dropped body is the crux.** Without fixing `collect-commits.sh` (l.27-37), the restructure is purely human-readability + test churn — the report never sees the body. Verify end-to-end that a commit's `Why`/`Concerns`/`Insights` actually appears in the overview-writer's input. (`plugins/workaholic/skills/report/scripts/collect-commits.sh`)
- **Where do commit Concerns/Insights land in the report?** `collect-commits` feeds the **overview-writer** (§1-3), but §6/§7 are produced by the **section-reviewer** from tickets. Two clean options: (a) the overview-writer returns `concerns[]`/`insights[]` that the orchestrator merges into §6/§7; or (b) the orchestrator also passes the collected commit bodies to the section-reviewer. Prefer whichever keeps the one-level fan-out intact; document the choice. Do **not** change the §6 block format `extract-carryover.sh` parses. (`plugins/workaholic/skills/report/SKILL.md`, `plugins/workaholic/skills/review-sections/SKILL.md`)
- **Back-compat of `archive.sh`'s signature.** Dropping `release-prep` shifts positionals. Either renumber cleanly (and update every caller — the drive command's archive invocation) or accept-and-ignore the old slot. Renumbering is cleaner since there is exactly one programmatic caller; just update it in lockstep. (`plugins/workaholic/skills/drive/scripts/archive.sh`)
- **Empty-section rendering** must be deterministic for the test and for downstream parsing. `Description` is omitted today when empty; pick the same rule for the new optional keys and assert it. (`plugins/workaholic/skills/commit/scripts/commit.sh` lines 84-97)
- **Scope boundary:** the `Category` git trailer is the *companion* ticket (`20260627210217`), not here. This ticket leaves the verb-heuristic→frontmatter category path untouched.
- **Outputs lockstep + POSIX gate** are mandatory: `commit` is in the drive/report/ship closures, and the new `posix-lint` gate now fails any reintroduced bashism. (`scripts/build-plugins/build.mjs`, `plugins/workaholic/hooks/posix-lint.sh`)

## Final Report

Development completed as planned. The commit body is now `Why / Changes / Concerns / Insights /
Verify` (Why/Concerns/Insights omitted when empty or "None"; Changes/Verify always render), built
by an `append_section` helper in `commit.sh`. `archive.sh` gained the 8-arg signature and forwards
the new keys; `commit.sh`'s 6-positional signature, `commit/SKILL.md`, the `drive/SKILL.md` archive
+ abandonment paths, and the report/review-sections wiring all moved in lockstep. The dropped-body
gap in `collect-commits.sh` is fixed — it now emits the body via 0x1f/0x1e-delimited `git log` +
`jq`. 15 files (8 source + 7 outputs); 151/0; lint conforming.

### Discovered Insights

- **Insight**: The restructure would have been **cosmetic** without fixing `collect-commits.sh`,
  which computed the body (`%b`) and then emitted only hash/subject/timestamp — so `/report` never
  saw a commit body at all, despite `report/SKILL.md` advertising a `body` field. Always trace a
  "feed X more data" change to the actual consumer before assuming the producer is the problem; here
  the producer was fine and the pipe was severed. The fix also replaced a fragile `sed` JSON-escaping
  chain with `jq` over record/field separators (`%x1e`/`%x1f`), which is the robust way to carry
  multi-line bodies through shell into JSON.
  **Context**: `plugins/workaholic/skills/report/scripts/collect-commits.sh`.
- **Insight**: `archive.sh` (a `#!/bin/sh` script) was invoking its sub-scripts with **`bash`**
  (`bash "$COMMIT_SCRIPT"`, `bash "$UPDATE_SCRIPT"`) — a latent Alpine bug: the script is POSIX but
  would have failed on a bash-less image at the sub-call. Switched to `sh`. The new `posix-lint`
  gate does NOT catch this (it scans shebangs + bashism tokens, not `bash` *invocations* inside a
  script body), so a future lint enhancement could flag `\bbash\b` calls in `#!/bin/sh` scripts.
  **Context**: `plugins/workaholic/skills/drive/scripts/archive.sh`; relevant to the gate-hardening
  lineage (`20260627153248`).
- **Insight**: Aligning the commit-body keys one-to-one with the report's section taxonomy makes
  `git log` a *draft of the PR story* — a reviewer reading the log sees the same Why/Changes/Concerns/
  Patterns structure the report will assemble. This is the first commit authored under the new format
  (dogfooded by this very archive).
  **Context**: `plugins/workaholic/skills/commit/scripts/commit.sh`, `commit/SKILL.md`.
