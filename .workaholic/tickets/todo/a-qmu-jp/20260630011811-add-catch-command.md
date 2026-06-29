---
created_at: 2026-06-30T01:18:11+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Add `/catch` — a by-developer development catch-up report

## Overview

Add a new **read-only** workflow command, `/catch`, that produces a by-developer working report covering roughly the **last two-plus weeks** of repository activity, so a developer can quickly absorb the overall direction of development and how each individual is taking their part — then ask Claude follow-up questions to go deeper.

`/catch` reads the existing evidence trail — **tickets** (`.workaholic/tickets/{todo,archive,icebox}/`), **stories / reports** (branch stories, `.workaholic/trips/`), **docs**, and **commit messages** — and fans out **parallel `general-purpose` collector sub-agents on a faster/cheaper model (`haiku`)** to gather and summarize each developer's activity concurrently. The main agent then synthesizes a cross-developer narrative and stands ready for interactive Q&A.

It follows the established `/report` house pattern: a **thin `commands/catch.md`** delegating to a **comprehensive `skills/catch/` skill** that holds the orchestration prose, the synthesis template, and the bundled POSIX scan scripts. Crucially — and unlike `/trip`, which is bound to ad-hoc Claude Code Agent Teams — `/catch` stays **Agent-Skills-compatible**: the parallel fan-out is framed as a Claude Code *enhancement* with an explicit sequential fallback, and the skill ships to non-Claude agents through the generated `outputs/workflows/` bundle.

`/catch` is **purely consumptive**: it never writes, moves, or auto-emits tickets, and never mutates the ticket spine (no auto-emission, per the established `/report` precedent).

## Policies

The standard engineering policies — synced from qmu.co.jp into the `workaholic` policy skills — that govern this ticket. The implementing session (via `/drive` or `/trip`) **MUST** read each linked policy hard copy before writing code and keep every change defensible against that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — new command/skill/scripts must land in the conventional plugin layout (`commands/catch.md`, `skills/catch/SKILL.md`, `skills/catch/scripts/*.sh`); applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — style conventions for the bundled shell scripts; applies to all code work.
- `workaholic:implementation` / `policies/command-scripts.md` — consolidate the window/author-scan and collection logic into runnable, teammate/AI-usable scripts rather than inline shell; this is the core lever of the feature.
- `workaholic:implementation` / `policies/domain-layer-separation.md` — keep collection/summarization knowledge in the skill and its scripts; the command is orchestration-only.
- `workaholic:implementation` / `policies/objective-documentation.md` — the report must describe **actual** commit/ticket activity factually, never an aspirational or invented narrative.
- `workaholic:operation` / `policies/ai-production-investigation.md` — by analogy: `/catch` is a read-only investigation surface; it must only **read** tickets/stories/docs/commits and must not mutate the ticket spine.
- `workaholic:operation` / `policies/ci-cd.md` — if `/catch` ships cross-agent, the `Outputs Freshness` CI gate must stay green; regenerate `outputs/` and never leave a drift.

## Key Files

### New files
- `plugins/workaholic/commands/catch.md` — the new thin command (~20–40 lines). Models on `commands/report.md`.
- `plugins/workaholic/skills/catch/SKILL.md` — the new comprehensive skill (orchestration prose, Agent Compatibility preamble, synthesis template, output schema). Models on `skills/report/SKILL.md`.
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` — new POSIX `sh` script enumerating the developers active in the window and the per-developer commit/ticket evidence. Models on `skills/report/scripts/collect-commits.sh`.

### Templates to copy (do not edit)
- `plugins/workaholic/commands/report.md` - closest command template: frontmatter, `policy-lens` marker, Notice + Plugin-boundary boilerplate, one-sentence delegation.
- `plugins/workaholic/commands/ticket.md` - canonical parallel fan-out idiom ("spawn N `general-purpose` subagents in a single message ... each preloading `workaholic:<skill>` ... Wait for all").
- `plugins/workaholic/skills/report/SKILL.md` - primary skill template: `metadata.internal: true` + `user-invocable: false` frontmatter, the `## Agent Compatibility` preamble (sequential fallback), phase-based orchestration, and the `Worker Output Mapping` table idiom.
- `plugins/workaholic/skills/discover/SKILL.md` - template for specifying a leaf collector as a named section with explicit inputs, depth/time budgets, and a strict return JSON schema.
- `plugins/workaholic/skills/review-sections/SKILL.md` - reference for the pure-prose synthesis style (only relevant if a split synthesis skill is chosen — see Considerations).

### Reuse (do not re-implement)
- `plugins/workaholic/skills/gather/scripts/git-context.sh` - reusable git context (branch/base/URL) and the SSH→HTTPS repo-URL transform for linking commits.
- `plugins/workaholic/skills/report/scripts/collect-commits.sh` - the `%x1f`/`%x1e` + `jq -Rs` escaping idiom that safely JSON-encodes arbitrary multi-line commit bodies; copy it rather than hand-escaping. Adapt the range to `--since='2 weeks ago'` and add `%an`/`%ae`.
- `plugins/workaholic/skills/gather/scripts/user-slug.sh` - the single canonical email→slug rule (`a@qmu.jp`→`a-qmu-jp`). Use it as the by-developer grouping key so the developer axis matches `tickets/todo/<user-slug>/`.

### Registration / wiring
- `scripts/build-plugins/build.mjs` - if `/catch` ships cross-agent, add the skill to the build targets so its self-contained copy lands in `outputs/workflows/`.
- `.claude-plugin/marketplace.json` - only touched if the skill is cross-agent exposed (add to the `workflows` plugin's `skills` array) and at release for version alignment. The command + internal skill need no entry (auto-discovered).
- `CLAUDE.md` - add `/catch` to the Commands table and the skills inventory line under Project Structure.

## Related History

No prior ticket proposes `/catch`, but every building block has archived precedent: the parallel sub-agent fan-out, running that fan-out on cheaper models, scanning commits/stories into a digest, and the recipe for shipping a brand-new thin-command + backing-skill pair.

- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Established the parallel collector fan-out pattern `/catch` reuses.
- [20260129-parallel-discovery-ticket-command.md](.workaholic/tickets/archive/feat-20260129-023941/20260129-parallel-discovery-ticket-command.md) - Command-level fan-out that spawns leaves and merges their JSON (one-level fan-out shape).
- [20260129015817-add-discover-history-subagent.md](.workaholic/tickets/archive/feat-20260128-220712/20260129015817-add-discover-history-subagent.md) - Non-interactive leaf that scans the ticket corpus and returns structured findings — directly analogous to a `/catch` collector.
- [20260128211509-use-haiku-for-report-subagents.md](.workaholic/tickets/archive/feat-20260128-012023/20260128211509-use-haiku-for-report-subagents.md) - Direct precedent for running fan-out workers on a faster/cheaper model — the `model: "haiku"` lever this ticket reuses.
- [20260123161059-branch-story-generation.md](.workaholic/tickets/archive/feat-20260123-032323/20260123161059-branch-story-generation.md) - Branch story is one of the inputs `/catch` reads; closest existing "narrative from tickets/commits" workflow.
- [20260210121628-summarize-changes-in-report.md](.workaholic/tickets/archive/drive-20260210-121635/20260210121628-summarize-changes-in-report.md) - Precedent for digesting git/commit changes rather than enumerating every file — the summarization behavior `/catch` needs.
- [20260628002048-add-commit-slash-command.md](.workaholic/tickets/archive/work-20260628-002047/20260628002048-add-commit-slash-command.md) - Most recent template for shipping a brand-new thin command + backing skill.
- [20260204180858-create-commit-skill.md](.workaholic/tickets/archive/drive-20260204-160722/20260204180858-create-commit-skill.md) - The "comprehensive skill behind a thin command", Agent-Skills-portable authoring recipe.

## Implementation Steps

1. **Author the bundled scan script** `plugins/workaholic/skills/catch/scripts/scan-window.sh` (POSIX `#!/bin/sh -eu`, **never bash** — Alpine has no bash):
   - Accept an optional window argument, defaulting to `2 weeks ago` (`git log --since=...`).
   - Emit a JSON object keyed by developer: for each author active in the window, the author name/email, derived `user-slug` (call the sibling `../../gather/scripts/user-slug.sh` via `${SCRIPT_DIR}`), commit list (hash/subject/timestamp/body using the `%x1f`/`%x1e` + `jq -Rs` idiom copied from `collect-commits.sh`, with `%an`/`%ae` added), and the paths of that developer's tickets under `tickets/todo/<slug>/` and `tickets/archive/`.
   - Also emit the list of stories/branch-story files and trip designs in scope, so collectors know what to read.
   - Add a hermetic case to `scripts/test-workflow-scripts.mjs` (throwaway repo, asserts JSON shape) following the existing branching/drive smoke-test style.
2. **Author the skill** `plugins/workaholic/skills/catch/SKILL.md`:
   - Frontmatter: `name: catch`, `allowed-tools: Bash`, `user-invocable: false`, a `skills:` preload list (`gather` + the four policy pillars), and `metadata.internal: true` (**mandatory** — the skill bundles a script; this is the only per-skill exclusion that hides token-bearing source from the `skills` CLI).
   - An `## Agent Compatibility` preamble (copy `report`'s) framing parallel fan-out and `AskUserQuestion` as Claude Code enhancements with sequential/plain-chat fallbacks — **this is what keeps `/catch` Agent-Skills-compatible** rather than Agent-Teams-bound.
   - A phased Run Workflow:
     - **Phase 0 — Window & roster:** run `scan-window.sh` (through `${CLAUDE_PLUGIN_ROOT}`) to get the active-developer roster and per-developer evidence pointers.
     - **Phase 1 — Parallel collect (fan-out):** the command spawns **one `general-purpose` collector per developer in a single message, `model: "haiku"`**, each preloading `workaholic:catch` and running a named "Collect Developer" section that reads that developer's commits/tickets/stories/docs and returns a strict JSON summary (focus areas, themes, notable changes, open threads). Wait for all.
     - **Phase 2 — Synthesize:** the main agent assembles a by-developer report plus a top-level "overall direction" synthesis, via a `Worker Output Mapping`-style table.
     - **Phase 3 — Present & stand by:** print the report and invite follow-up questions (the Q&A happens in the main agent's normal turn-taking — no extra mechanism).
   - Define the collector's return JSON schema and the report template explicitly in the skill.
3. **Author the thin command** `plugins/workaholic/commands/catch.md` (~20–40 lines, orchestration only): frontmatter `name: catch` + `skills: [workaholic:catch]`; the `**Notice:**` trigger line; the `**Plugin boundary — do not spelunk:**` paragraph; the optional `<!-- workaholic:policy-lens ... -->` marker (include it — `/catch` judges development direction and benefits from the lens); and one sentence delegating to the skill's workflow and stating the main agent spawns the collectors as `general-purpose` subagents. Reference scripts only via `${CLAUDE_PLUGIN_ROOT}` (relative paths fail with exit 127).
4. **Cross-agent exposure:** add the `catch` skill to the build targets in `scripts/build-plugins/build.mjs` and to the `workflows` plugin's `skills` array in `.claude-plugin/marketplace.json`, so its self-contained public copy ships to non-Claude agents the same way `report`/`drive`/`ship` do. Regenerate with `node scripts/build-plugins/build.mjs`. (See Considerations for the alternative of keeping it Claude-only.)
5. **Document:** add `/catch` to the Commands table in `CLAUDE.md` and to the skills inventory line under Project Structure.
6. **Verify:** `node scripts/build-plugins/build.mjs` → `node scripts/build-plugins/verify.mjs` → `node scripts/build-plugins/validate-metadata.mjs` → `node scripts/test-workflow-scripts.mjs`. Confirm the `Outputs Freshness` gate would pass (no uncommitted `outputs/` diff).

## Considerations

- **Cross-agent exposure is a real fork.** Two house-consistent shapes exist: **(A)** one script-bearing internal `catch` skill carrying both the scan script and the synthesis prose, shipped cross-agent via the build like `report`/`drive`/`ship`; or **(B)** split a script-bearing internal collector skill from a pure-prose, standalone synthesis skill modeled on `review-sections`. The request's emphasis on Agent-Skills compatibility is satisfied by **(A)** with a strong `## Agent Compatibility` preamble — recommended for simplicity. Choose **(B)** only if the synthesis prose must install standalone on non-Claude agents. (`plugins/workaholic/skills/review-sections/SKILL.md`)
- **One-level fan-out is non-negotiable.** Collector leaves are non-interactive: they must not nest `Task` calls and must not call `AskUserQuestion`. The developer roster must therefore be known at the command level (from Phase 0) **before** the leaves are spawned — fan out per developer, not per "discover more developers". (CLAUDE.md One-Level Fan-Out)
- **No per-workflow agent file.** The collectors are throwaway `general-purpose` leaves preloading `workaholic:catch`; do **not** add any `agents/*.md` — those are reserved for `/trip`'s Agent Teams members. (CLAUDE.md No Per-Workflow Agent Files)
- **Read-only — never mutate the spine.** `/catch` must not write, move, or auto-emit tickets; the `guard-ticket-structure.sh` hook enforces canonical ticket moves and the no-auto-emission precedent stands. (`plugins/workaholic/hooks/guard-ticket-structure.sh`)
- **POSIX shell only, no inline shell in markdown.** All windowing/grouping/log logic lives in `scan-window.sh` (`#!/bin/sh -eu`); the command/skill markdown invokes it as a single `${CLAUDE_PLUGIN_ROOT}/skills/catch/scripts/...` call. (CLAUDE.md Shell Script Principle)
- **Window default vs. argument.** "Over 2 weeks" should default to `--since='2 weeks ago'` but accept an override argument (e.g. `/catch 30 days`) so the catch-up horizon is tunable; keep the default explicit in the script, not the markdown.
- **Performance / cost.** Per-developer `model: "haiku"` collectors keep the fan-out cheap and fast; the `model:` annotation is a Claude-Code-only hint that `publicizeSkillMd` strips when generating the portable copy, so it does not leak into the cross-agent artifact. (`scripts/build-plugins/build.mjs`)
- **Version alignment at release.** Adding files does not itself bump the version, but a release must keep `.claude-plugin/marketplace.json` (root + every `plugins[].version`), `plugins/workaholic/.claude-plugin/plugin.json`, and `plugins/workaholic/.codex-plugin/plugin.json` aligned; `outputs/workflows/.codex-plugin/plugin.json` regenerates. (CLAUDE.md Version Management)
