# Workaholic

Private, cross-agent distribution of structured development workflows and engineering standards. It is richest on **Claude Code**, where it installs as a plugin marketplace (slash commands, hooks, `/trip` Agent Teams); the portable skills also ship to **Codex** (via `.agents/plugins/marketplace.json` → `outputs/workflows`) and to **OpenCode** plus 40+ other agents via the Agent Skills standard / `skills` CLI. Authored source lives under `plugins/`; cross-agent artifacts are generated into `outputs/`.

## Important

Edit `plugins/` not `.claude/`. This repo develops plugins - changes go to `plugins/`, never `.claude/` unless explicitly requested.

**Update the docs in the same change.** When a change alters behavior, structure, commands, skills, or conventions, update every affected document — `README.md`, `.workaholic/README.md`, `CLAUDE.md`, `plugins/workaholic/rules/*.md` — in the same commit as the change. Outdated documentation is a defect: before requesting approval for any change, check whether the docs that describe the touched area still tell the truth (`/report` runs `doc-drift.sh` as a backstop, but the fix belongs at change time, not report time).

## Project Structure

```
.claude/                 # Local Claude Code configuration
  rules/                 # Repository-scoped rules
.claude-plugin/          # Marketplace configuration
  marketplace.json       # Marketplace metadata and plugin list
plugins/                 # Plugin source directory
  workaholic/            # The single plugin (no dependencies; skills exposed cross-agent)
    .claude-plugin/      # Plugin configuration
    .codex-plugin/       # Hand-maintained Codex-facing manifest
    skills/              # workflow skills (branching, carry, catch, check-deps, commit, create-ticket, discover, drive, explain, gather, mission, monitor, okf, report, review-sections, ship, strategy, system-safety, trip-protocol, validate-writer-output, workaholify, write-release-note) + policy skills (planning, design, implementation, operation, each linking English hard copies under its policies/ dir)
    commands/            # ticket, drive, trip, report, ship, catch, carry, explain, commit, mission, monitor, workaholify (Claude-only; ignored by other agents)
    agents/              # Agent Teams members only: planner, architect, constructor (launched by /trip)
    hooks/               # ticket validation (validate-ticket.sh, PostToolUse Write|Edit — frontmatter, location, the mandatory `## Policies` / `## Quality Gate` body sections, a resolvable `mission:` relation, and the remaining-only lint on `resume-*` tickets, all on `todo/<user>/` only) + mission validation (validate-mission.sh, PostToolUse Write|Edit — assignee key always; owner/strategy/Experience/Acceptance floor once `drive_authorized: true`; archive/ never retro-blocked) + structural move guard (guard-ticket-structure.sh, PreToolUse Bash — blocks non-canonical ticket moves like done/ or todo/<user>/archive/) + always-on policy lens (policy-lens.sh) + always-on mission lens (mission-lens.sh, UserPromptSubmit + Stop) + generated policy-index.md
    rules/               # diagrams, general, shell, typescript, workaholic
scripts/                 # Repo tooling
  claude.sh              # Launcher
  build-plugins/         # Generates outputs/ from plugins/workaholic/skills (run argument-less for a full build)
outputs/                    # GENERATED, committed cross-agent artifacts — do NOT hand-edit (CI-guarded)
  workflows/             # Portable workflows plugin: .codex-plugin/plugin.json + self-contained skills/
  okf/                   # OKF v0.1 knowledge bundle of the four pillars' policies (Open Knowledge Format)
.agents/                 # Codex marketplace
  plugins/marketplace.json  # Codex plugin list (workflows -> ./outputs/workflows)
docs/                    # Documentation
  dependencies/          # Dependency-decision logs (vendor-neutrality policy)
```

## Architecture Policy

### Component Nesting Rules

| Caller                         | Can invoke                                   | Cannot invoke              |
| ------------------------------ | -------------------------------------------- | -------------------------- |
| Command                        | Skill, `general-purpose` subagent            | —                          |
| Skill                          | Skill; (when loaded by a command/main agent) may direct it to spawn `general-purpose` subagents | Command                    |
| `general-purpose` subagent     | Skill (via preload)                          | Command, Task (no nesting) |

There are two distinct kinds of "subagent" in this repo, and the table above governs only the first:

- **`general-purpose` subagents** are the built-in Claude Code subagent type. They have **no `.md` agent file** — a command (or a skill running in the command's main-agent context) spawns them with a `Task` call whose prompt says "preload `workaholic:<skill>`, run `<section>` with these inputs, return `<schema>`." This is how `/report`, `/drive`, and `/ticket` fan out. Skills cannot issue `Task` calls themselves; the prohibition on Skill→Subagent that previously appeared here is lifted **only** in the sense that a skill's prose may instruct its loading agent (a command/main agent) to spawn `general-purpose` leaves.
- **Named Agent Teams members** (`planner`, `architect`, `constructor` in `plugins/workaholic/agents/`) are launched **only by `/trip`** as Agent Teams members — not as `Task` subagents. They are exempt from the nesting table; `/trip` is intrinsically Agent-Teams-based and Claude-Code-only.

`/trip` and `/drive` converge on the **ticket** as the unit of work. The model is **sources × executors**: the ticket is the spine, *sources* fill the `tickets/todo/` queue and *executors* drain it to `tickets/archive/`.

- **Sources** (write to `todo/`): `/ticket` (human-directed, with discovery) and a trip's **Decomposition gate** (trip-protocol Planning Step 5 — the Constructor decomposes the agreed design into tickets, each carrying the mandatory `## Policies` and a **Trip Origin** link back to its `.workaholic/trips/<name>/designs/` rationale).
- **Executors** (drain `todo/ → archive/`): the **drive executor** (`/drive` — solo main-agent + developer approval per ticket), the **trip executor** (`/trip` — three-agent team, with Constructor implements → Architect reviews → Planner E2E standing in for the developer gate; `drive/archive.sh` archives each ticket), and the **monitor executor** (`/monitor` — parallel missions: after a developer-confirmed pre-flight, one leaf per mission `.worktrees/<slug>/` worktree owns the **whole** of that worktree's work — a mission needing a replan has that replan *applied* by its own leaf (delta tickets, body sections, the authorizing commit), then drives — while the main agent stays a thin dispatcher owning only the developer prompts a leaf cannot issue and actively tuning the wave size down for interference/resource load; looping bounded waves until every mission completes or only escalation-blocked items remain; only `drive_authorized` missions run unattended, because a leaf can never ask).

`/trip` is **context-aware** (like `/report` and `/ship`): `/trip <instruction>` over an empty queue is source+executor (design → decompose → drive, as **one continuous run** — the team flows from the fixed design straight into the build with no developer green-light pause; review happens afterward via `/report`); `/trip` over a populated queue is executor-only (trip-drive the existing `/ticket` queue, no design — the `ticket → trip` direction); `/trip` over nothing tells you to `/ticket` first. `/trip summary` is the read-only exception: it launches no team and instead reports every trip under `trips/` (plan phase/step) plus the todo-queue snapshot a `/trip` would execute. Because both executors read the same `todo/`, you can switch between them mid-queue (`trip → interrupt → /drive`). So `trips/` holds the *why*, `tickets/` the *what*, and `/report`/`/ship` treat a trip exactly like a drive.

### No Per-Workflow Agent Files

Workflow orchestration does **not** get dedicated agent `.md` files. A command spawns `subagent_type: "general-purpose"` subagents whose prompts instruct them to preload the relevant `workaholic` skill and run a named section. The knowledge lives in the skill; the subagent is a throwaway leaf. The only agent `.md` files in the repo are the Agent Teams members `/trip` requires (`planner`, `architect`, `constructor`).

When adding a new fan-out step, do not create an agent file — write the knowledge as a section in a `workaholic` skill and have the command spawn a `general-purpose` subagent that preloads it.

### One-Level Fan-Out

A subagent **cannot** nest `Task` calls and **cannot** call `AskUserQuestion`. Therefore:

- All fan-out happens at the command/main-agent level. No subagent-that-spawns-subagents.
- All user interaction (`AskUserQuestion`) happens at the command/main-agent level.
- Leaf `general-purpose` subagents do non-interactive work only and return JSON for the command to act on.

When a workflow needs both parallel work and a user decision, the command spawns the leaves, collects their JSON, then issues the `AskUserQuestion` itself.

### Plugin Dependencies

There is **one** plugin (`workaholic`) with `dependencies: []` — everything that was previously split across `core`, `standards`, and `work` now lives in it. All skill references are same-plugin: `${CLAUDE_PLUGIN_ROOT}/skills/<name>/...` (no cross-plugin `../<name>/` paths) and `workaholic:<skill>` namespaces. The `workflows` plugin in the marketplace is the **generated** `outputs/workflows` bundle, not an authored plugin.

### Cross-Agent Skill Exposure

The `workaholic` plugin's skills are installable by non-Claude agents (Cursor, OpenCode, Codex, Pi, 50+) via `npx skills add qmu/workaholic`. The `skills` CLI (`vercel-labs/skills`) reads `.claude-plugin/marketplace.json`: the `skills` array on the `workaholic` plugin entry labels its cross-agent discovery group (the `design`/`implementation`/`operation` policy skills). Three rules keep the exposed set honest:

- **Script-bearing skills carry `metadata.internal: true`** in their SKILL.md frontmatter. Claude Code ignores this field (the skills still load normally); the `skills` CLI hides them from cross-agent discovery. This is required because the CLI always scans the plugin's `skills/` dir — `metadata.internal` is the only per-skill exclusion. Any new skill that invokes a bundled script MUST include it.
- **The pure-prose skills are intentionally exposed** (no `metadata.internal`): the three policy skills (`design`/`implementation`/`operation`) plus `write-release-note` and `review-sections`. They have no bundled script, no `${CLAUDE_PLUGIN_ROOT}`, no namespaced preload — so they resolve on every agent via the `skills` CLI. The script-bearing workflow skills also reach non-Claude agents, but only through the generated `outputs/workflows` bundle (see below), never the source.
- **Why script-bearing skills stay internal** (verified 2026-05-26): every agent (Claude Code, OpenCode, Codex, Pi) runs a skill's shell in the *project* CWD and only injects the skill's base directory as text for the *model* to prepend — none `cd`s into the skill dir. Claude Code additionally expands `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_SKILL_DIR}` deterministically at load time. Rewriting a script call to the spec-relative `scripts/X.sh` form would drop that determinism and rely on non-deterministic model-prepend — unacceptable for skills workaholic runs in its own Claude-Code `/drive`/`/ship` critical path. So script-bearing skills keep the token and stay internal.

The plugin's `commands/`, `agents/`, `hooks/`, and `rules/` are Claude-Code-only: the `skills` CLI reads only the `skills/` dir, so those directories are not exposed through that path. Codex still installs the raw plugin directory from `.agents/plugins/marketplace.json` and parses `hooks/hooks.json`; that file must keep `hooks` as its only top-level key because Codex rejects Claude-only sibling keys such as `description`. Hook documentation lives here and in `.claude-plugin/plugin.json`, not in `hooks/hooks.json`.

To preview what the CLI would install, run `npx skills add . --list` (add `INSTALL_INTERNAL_SKILLS=1` to include internal skills).

#### Cross-agent distribution (workflow skills, built)

The workflow skills (ticket/drive/report/ship/catch/mission) depend on shared scripts elsewhere in the plugin (via `${CLAUDE_PLUGIN_ROOT}`) and so are **not** self-contained in source. They ship to non-Claude agents as a **generated, self-contained, committed plugin** at `outputs/workflows/`, produced by `scripts/build-plugins` from the DRY `plugins/workaholic` source (`trip` is excluded — Agent Teams, Claude-only). **One neutral generated dir serves every non-Claude agent** through two manifests that point at it:

- **Codex** reads `.agents/plugins/marketplace.json` (repo root); its `workflows` plugin `source.path` is `./outputs/workflows`, and Codex consumes the co-located `outputs/workflows/.codex-plugin/plugin.json`.
- **OpenCode, Cursor, Pi, 40+** get it via the `skills` CLI, which reads the `workflows` plugin entry in `.claude-plugin/marketplace.json` (`source: ./outputs/workflows`) and its `skills/` (the `design`/`implementation`/`operation` policy skills are exposed the same way). The `skills` CLI ignores the co-located `.codex-plugin/` dir, so the same folder serves both systems. `write-release-note` and `review-sections` ship inside this plugin too.

Source-vs-artifact rule: the `plugins/workaholic` workflow skills keep `metadata.internal: true` and `${CLAUDE_PLUGIN_ROOT}` (so the `skills` CLI never offers the broken source); the **committed `outputs/workflows/` artifacts** are the public versions — self-contained, `${CLAUDE_PLUGIN_ROOT}` rewritten to relative paths, and `metadata.internal` / `user-invocable` / the `skills:` preload block stripped with namespace prefixes flattened by `publicizeSkillMd`. **Regenerate with the argument-less `node scripts/build-plugins/build.mjs` whenever a `workaholic` workflow skill or its script closure changes** (a *targeted* build only writes a throwaway scratch dir and does not touch `outputs/`). `outputs/` is **committed, not gitignored** — Codex and the `skills` CLI install by reading repo paths, so the artifacts must be present. The `Outputs Freshness` CI workflow (`.github/workflows/outputs-freshness.yml`) rebuilds and fails on any `outputs/` diff, keeping artifact and source in lockstep.

Claude Code reads `plugins/` directly and consumes nothing from `outputs/`. The `workflows` entry in `.claude-plugin/marketplace.json` is read by Claude Code too, so it is **opt-in** — its description points Claude users to the `workaholic` plugin to avoid installing duplicate workflow skills.

#### OKF knowledge bundle (generated)

`outputs/okf/` is an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) (OKF v0.1) bundle of the four pillars' policy hard copies, generated by `scripts/build-plugins/okf.mjs` (wired into the same argument-less `build.mjs` full build): one concept document per `plugins/workaholic/skills/<pillar>/policies/*.md` with OKF frontmatter (`type`/`title`/`description`/`resource`/`tags`; no `timestamp` — commit-date-derived values would break the rebuild-and-diff freshness guard), bundle-absolute intra-bundle links, and a bundle-root `index.md` declaring `okf_version`. Any OKF consumer reads it straight from the repo path — no marketplace manifest involved, so neither Claude Code nor the `skills` CLI/Codex ever installs it as a plugin. `verify.mjs` asserts freshness plus OKF conformance (parseable frontmatter, non-empty `type`, reserved filenames, in-bundle link resolution); the `Outputs Freshness` CI diff over `outputs/` covers it like every other generated artifact. The adoption record (reason/assessment/monitoring/exit) is `docs/dependencies/okf.md`; OKF vocabulary stays inside `okf.mjs` — the translation boundary — and never shapes the source conventions.

#### `.workaholic/` as an OKF bundle (runtime)

Separately from the generated policy bundle, the `.workaholic/` tree of any project using the plugin is itself kept OKF-compatible **as the workflows generate documents**: every written artifact carries frontmatter with a non-empty `type` (tickets `enhancement|bugfix|refactoring|housekeeping`, stories `Story`, strategies `Strategy`, missions `Mission`, release notes `Release Note`, deferred concerns `Concern`, trip artifacts `Direction|Model|Design|Review|Rollback|Trip Plan|Event Log`), and the internal `okf` skill's `refresh-index.sh` deterministically regenerates the bundle hierarchy — `.workaholic/index.md` (bundle root, declares `okf_version`) plus per-area `index.md` files — before each knowledge commit (called by `drive`'s `archive.sh`, `ship`'s `commit-release-note.sh`/`extract-deferred-concerns.sh`, and the `report` story flow). `stories/index.md` stays report-maintained; `tickets/` internals are never index-managed (the queue scripts and structure guards own that tree). `README.md` and `index.md` are the two files allowed at the `.workaholic/` root. Those same commit seams also **roll any related mission** (`missions/active/<slug>/mission.md`; ended missions live under `missions/archive/<slug>/`, moved there by the mission skill's `close.sh` — the only sanctioned way to end a mission — with a living migration relocating any legacy flat `missions/<slug>/` dir by its `status` on the next mission-script touch): when an archived ticket, shipped story, or extracted/resolved concern carries a `mission:` relation, the seam appends a `## Changelog` line and reconciles the mission's `## Acceptance` checklist through the `mission` skill's shared, idempotent mutators (`append-changelog.sh` / `tick-acceptance.sh`), so a mission's progress (`checked ÷ total`, computed — never stored) and history stay current without hand-editing. The relation is **many-valued** — an artifact records every mission it advances (`mission: [alpha, beta]`; a bare `mission: alpha` still reads as one) and each seam rolls all of them, reading the field through the mission skill's single reader (`read-relation.sh`) rather than parsing frontmatter itself. Data is plural, **placement stays singular**: `.worktrees/<slug>` remains keyed 1:1 to a mission, and a ticket is still driven in exactly one worktree. `/drive` holds a ticket to the quality gate of **every** mission it names — naming a mission is a commitment, not a label. Above missions sits the **strategy** (`strategies/active|archive/<slug>/strategy.md`, `type: Strategy`) — long-lived direction with no completion conditions, managed by the internal `strategy` skill (`create.sh`/`list.sh`/`read-strategy-relation.sh`/`retire.sh`). A mission records the one strategy it executes as `strategy: <slug>` on `mission.md`, read only through `strategy/scripts/read-strategy-relation.sh`; nothing is stored on the strategy side, so per-strategy mission rollups are **computed** by `list.sh` and archives never dangle. A strategy has no worktree, tickets, assignee, or acceptance checklist — it is direction, not work; `refresh-index.sh` indexes its two areas like `missions/`.

### Design Principle

**Thin commands, comprehensive skills.**

- **Commands**: Orchestration only (~50-100 lines). Define workflow steps, spawn `general-purpose` subagents, handle all user interaction.
- **`general-purpose` subagent prompts**: Orchestration only. Name the `workaholic` skill to preload, the section to run, the inputs, and the return schema — no per-workflow `.md` file.
- **Skills**: Comprehensive knowledge (~50-150 lines). Contain templates, guidelines, rules, and bash scripts.

Skills are the knowledge layer. Commands (and the leaf subagents they spawn) are the orchestration layer.

### Common Operations

Commands, skills, and subagent prompts must use skills for common operations instead of inline shell commands:

| Operation | Skill | Usage |
| --------- | ----- | ----- |
| Git context (branch, base, URL) | gather | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh` |
| Ticket metadata (date, author) | gather | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh` |

Never write inline git commands like `git branch --show-current` or `git remote show origin` in command or agent markdown files. Preload the skill and gather context through it.

### Shell Script Principle

> **CRITICAL: Never use complex inline shell commands in subagent or command markdown files.**

This includes:
- **Conditionals**: `if`, `case`, `test`, `[ ]`, `[[ ]]`
- **Pipes and chains**: `|`, `&&`, `||`
- **Text processing**: `sed`, `awk`, `grep`, `cut`
- **Loops**: `for`, `while`
- **Variable expansion with logic**: `${var:-default}`, `${var:+alt}`

Extract ALL multi-step or conditional shell operations to bundled scripts in skills (`skills/<name>/scripts/<script>.sh`). This ensures consistency, testability, and permission-free execution.

**Wrong** (inline conditional):
```bash
current=$(git branch --show-current)
if [ "$current" = "main" ]; then echo "on_main"; fi
```

**Correct** (skill script):
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/check.sh
```

### Skill Script Path Rule

> **CRITICAL: All skill shell script references must use `${CLAUDE_PLUGIN_ROOT}`.**

Claude Code expands `${CLAUDE_PLUGIN_ROOT}` inline in all plugin content (skills, agents, commands) at load time. This resolves to the plugin's installed directory. Relative paths like `.claude/skills/` do NOT resolve at runtime and cause exit code 127 failures.

**Wrong** (relative path):
```bash
bash .claude/skills/gather/scripts/ticket-metadata.sh
```

**Correct** (same-plugin reference):
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh
```

**Correct** (cross-plugin reference — declared dependency):
```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/check-worktrees.sh
```

### Plugin Boundary Rule

> **CRITICAL: Reach skills only through `${CLAUDE_PLUGIN_ROOT}` and their loaded namespace. Never spelunk for skill content on disk.**

A command's skills are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}` at load time. Invoke them by their loaded namespace (`workaholic:`) and run their bundled scripts via `${CLAUDE_PLUGIN_ROOT}`. Do **not**:

- read or run anything under `~/.claude/plugins/marketplaces/` or any other global/marketplace install — those may be stale copies from older versions and will silently run obsolete logic;
- guess a plugin or skill namespace. `drivin`, `trippin`, `core`, `standards`, and `work` are **obsolete** plugin names — all merged into the single `workaholic` plugin, which is the only live plugin.

If a skill you expect is not in context, ask the user which plugins are loaded — do not search the filesystem for it. The five `workaholic` command `**Notice:**` headers carry a short echo of this rule.

## Commands

| Command                          | Description                                      |
| -------------------------------- | ------------------------------------------------ |
| `/ticket <description>`          | Write implementation spec for a feature **in this repository** (bare `/ticket` or `/ticket summary` reports your assigned todo tickets instead of creating one) |
| `/request <description>`         | File a ticket in **another** repository — the only sanctioned way to cross a repo boundary. Masks this project's customer context and requires the developer to confirm the exact body before writing (non-skippable) |
| `/drive`                         | Implement queued specs one by one (a mission-authorized queue drives without the per-ticket prompt; an unqueued problem met mid-run becomes a ticket rather than a stop) |
| `/commit`                        | Commit working changes with a policy-conformant message (small non-ticketed changes; prefer `/drive` for ticketed work) |
| `/report`                        | Context-aware: generate story or journey report and create PR (warns on the branch-safety scan) |
| `/ship`                          | Context-aware: merge PR, deploy, and verify (blocks pre-merge on the branch-safety scan; secrets non-overridable) |
| `/mission ["<title>" \| "<instruction about an existing mission>" \| summary \| close <slug>]` | Create a mission (a durable, information-rich goal spanning many tickets — creating one resolves the **strategy** it executes (infer / create-on-the-spot / ask only when genuinely ambiguous), interrogates the developer to a drive-ready state, then spins up a dedicated `.worktrees/<slug>/` worktree holding the mission statement and the **whole** ordered ticket set it emitted), **replan** an existing active one (which also resolves the strategy link for a legacy/thin mission that lacks one) (a free-form instruction referencing it — no subcommand — re-enters the interrogation scoped to what changed, applies the delta, and emits delta tickets; also how a `carried` successor or a thin hand-authored mission gets fleshed out), list existing missions with computed progress, show just **your** assigned active missions (`summary`), or close one (achieved / abandoned / **carried** — done as framed, remainder inherited by a successor mission) into `missions/archive/` and tear down its worktree |
| `/monitor`                       | Run your missions in parallel: a developer-confirmed pre-flight (mission set, current position incl. unmerged work, unattended-drive eligibility, cross-mission interference), then one leaf per mission `.worktrees/<slug>/` worktree owning the **whole** of that worktree's work — replan *application* (delta tickets, body sections, authorizing commit) included, not just the drive — looping bounded waves until every mission's completion conditions are met or only explicitly deferred escalations remain. Blockers and escalations are **pushed to the developer as one-at-a-time decisions** (create/replan/claim/worktree), never just reported — an interactive run never emits its terminal `ok` over a decision it did not ask; final output line `ok`/`pending`, so a caller-side loop (e.g. `/goal /monitor ok`) can wait on it. The orchestrating agent is a **non-blocking dispatcher**: it interprets, lightly investigates, and directs — never editing inside a worktree itself (replan bookkeeping included) — leaves run in the background while it keeps taking instructions and decisions and actively tunes the wave size down when interference or resource load argues against full parallelism, and each driven mission's declared dev environment is booted at dispatch inside its own worktree on its allocated ports (stopped at run end when the run started it). It **accumulates each mission's agent-hours** (each leaf's dispatch→completion wall-clock, summed and recorded once per mission per run-id via `record-run-hours.sh`) into `actual_hours`, and the final report shows predicted vs actual per mission. Only `drive_authorized` missions run unattended. PRs stay with `/report`/`/ship`. Claude-Code-only, like `/trip` |
| `/catch [window]`                | Read-only by-developer catch-up report over a recent window (commits, tickets, stories) plus a Missions view (each active mission's derived progress, merged activity, and unmerged in-flight work), then follow-up Q&A |
| `/carry`                         | Hand off in-progress work to a fresh session (capture-only): write a resumption ticket / trip checkpoint a later `/drive` continues, instead of relying on compaction. States the **Mission Position Report** for every mission the work advances — how far it stands, what is next, and how much a fresh session can proceed with |
| `/explain <question> [dir]`      | Answer a repo question and export a printer-ready PDF report (HTML printed by a real browser); exports to `dir`, else Desktop→Home (Home write asks permission) |
| `/workaholify`                   | Wire the current repo to the standards: refer to the `workaholify` gateway skill (reaches the `policies/`), audit `CLAUDE.md` against the documentation standard, and confirm the working-directory advisory hook is active — rules stay in the skill, not copied into `CLAUDE.md` |
| `/release [major\|minor\|patch]` | Release new marketplace version                  |

## Development Workflow

1. **Create specs**: Use `/ticket` to write implementation specs
2. **Implement specs**: Use `/drive` to implement and commit each spec
3. **Create PR**: Use `/report` to generate story and create PR
4. **Ship**: Use `/ship` to merge PR, deploy, and verify
5. **Release**: Use `/release` to bump version and publish

## Type Checking

No build step required - this is a configuration/documentation project.

## Local Verification

Before pushing changes to workflow scripts or plugin manifests:

```bash
node scripts/build-plugins/build.mjs              # regenerate outputs/ AND hooks/policy-index.md if you touched a core skill, a pillar SKILL.md, or build.mjs
node scripts/build-plugins/verify.mjs             # assert generated skills are self-contained AND the policy index is in sync
node scripts/build-plugins/validate-metadata.mjs  # assert Codex manifests are well-formed and version-aligned
node scripts/test-workflow-scripts.mjs            # hermetic smoke tests for branching + drive scripts
```

The smoke tests create throwaway repositories under the OS temp dir, exercise the scripts there, assert on JSON output and filesystem state, and clean up. They never touch the working tree or call `gh`/network — safe to run anywhere.

### Commit-subject and branch-name enforcement

The commit-subject rule (present-tense, ≤50 chars, no `feat:`/`[bracket]` prefix — see `skills/commit/SKILL.md`) and the branch-name rule (`work-YYYYMMDD-HHMMSS`, named only by `create.sh`) are enforced as gates, not just prose, in **two layers**:

- **Agent/harness surface (always on, zero opt-in):** `hooks/guard-git-commit.sh` and `hooks/guard-git-branch.sh` are blocking `PreToolUse(Bash)` hooks (shipped active in `hooks.json`). The commit gate blocks a direct `git commit` only when its `-m` subject is off-policy (it does **not** block `Co-Authored-By` trailers, conformant subjects, or script-wrapped commits like `commit.sh`/`archive.sh`, which never expose a top-level `git commit`). The branch gate blocks off-pattern/variable branch creation. Both route the caller to the sanctioned script.
- **Human-terminal surface (opt-in):** `hooks/git/commit-msg` is a git-native hook that enforces the **same subject rule** on every commit (including a developer's own terminal `git commit`), since `PreToolUse(Bash)` cannot see those. It is subject-only (never rewrites the message). Install it deliberately per-repo:

  ```bash
  sh ${CLAUDE_PLUGIN_ROOT}/hooks/install-git-hooks.sh   # sets core.hooksPath; refuses to clobber an existing one / classic .git/hooks without --force
  ```

  Bypass a single commit with `git commit --no-verify`; undo with `git config --unset core.hooksPath`. All layers share one rule source — the canonical validator is `skills/commit/scripts/check-subject.sh` (it pins `LC_ALL` to a UTF-8 locale so a multibyte subject measures identically on every host), which `commit.sh` runs itself before staging anything (closing the script-wrapped path the `PreToolUse` gate deliberately does not inspect) and which both hooks reach through the stable `hooks/lib/check-subject.sh` delegator — so the layers cannot drift. Because the validator lives in the commit skill's `scripts/`, the generated `outputs/workflows` bundle carries the gate too (rebuild on change); the hooks themselves remain Claude-Code-only / git-native with no `outputs/` footprint. `commit-msg` is exempt from `posix-lint` only because git requires that exact extensionless name; it is POSIX `#!/bin/sh -eu` by construction.

### AskUserQuestion project-label enforcement

The `[<project label>]` prompt-prefix convention (each `AskUserQuestion` question body opens with the owning repo's label, from `skills/gather/scripts/project-label.sh`, so a developer with many parallel sessions sees which repo is asking) is enforced as a gate, not just prose. `hooks/guard-askuserquestion-label.sh` is a blocking `PreToolUse(AskUserQuestion)` hook (shipped active in `hooks.json`): it reads `tool_input.questions[].question` and exits 2 (re-issue) when any body lacks a leading `[…]` label. It fires on every `AskUserQuestion` by design — labeling any prompt with its repo is a net good, so the over-fire onto ad-hoc questions is intentional. Claude-Code-only, POSIX `#!/bin/sh -eu`, **no `outputs/` footprint**. The rule itself stays where it was — the per-skill "User interaction" prose — this hook only makes it machine-checked.

A companion `hooks/guard-working-directory.sh` (`PreToolUse(Bash)`, shipped active) is **non-blocking**: it reminds and steers a top-level cwd-moving `cd` toward an absolute path or a `( cd … )` subshell so the working directory stays at the repo root, but never blocks a deliberate `cd`. It is the machine-surfaced half of the `workaholify` working-directory ground rules (`skills/workaholify/`); like the other guards it is Claude-Code-only, POSIX `#!/bin/sh -eu`, with no `outputs/` footprint.

### Repository confinement

Every write lands inside the current repository or one of its own worktrees. Crossing to another repository is done **only** through `/request`, which masks this project's customer context before filing. Two layers, and the order matters:

- **The rule is primary.** It lives in `rules/general.md` ("Never modify another repository", plus "Never carry one repository's context into another's artifacts"), which is `paths: '**/*'` — always loaded, and shipped to every repo that installs the plugin. This is deliberately where the weight sits: the rule is what an agent reads before it acts.
- **The hook is a syntactic backstop.** `hooks/guard-repo-confinement.sh` is a blocking `PreToolUse(Write|Edit)` hook (shipped active) that resolves `tool_input.file_path` against `git rev-parse --show-toplevel` plus every entry of `git worktree list`, and exits 2 when the target is outside all of them. It runs PreToolUse because `validate-ticket.sh` is PostToolUse — refusing *after* the file exists in the foreign repo is not confinement. It accepts worktrees in both directions, because missions run in `.worktrees/<slug>/` and a toplevel-only test would break the mission model. It also exempts the agent's per-project memory store (`~/.claude/projects/<slug>/memory/`): that is the harness's own store — not another repository — the harness itself directs the agent to write there, and a stale memory's only correction path is a write (blocking it once left a memory contradicting the current design firing every session with no way to repair it). It fails open outside a git repo. Claude-Code-only, POSIX `#!/bin/sh -eu`, no `outputs/` footprint.

**Do not grow the hook toward content matching.** A path is syntax and a matcher handles it well; a customer's vocabulary is semantic and a matcher cannot recognise it — the terms that leak are usually not enumerable until the moment they leak. That judgement belongs to `/request`, where a person confirms it.

`/request` (`commands/request.md` + `skills/request/`) is the outlet the confinement needs: `resolve-target.sh` resolves the target and reports its **visibility** (public vs private is a different decision, and the developer must see which they are making), and `file-request.sh` is the only sanctioned writer of a cross-repo artifact. Between them sits the step that actually does the work — **the developer confirms the exact body, verbatim, and this cannot be skipped**. `file-request.sh`'s checks are mechanics (empty body, malformed filename, this repo's own name or path); they are not assurance. The test suite asserts this directly: the four real leaked sentences from the incident file through the script *without complaint*, because none of them names this repo. That is not a bug to fix — it is the measured reason the human gate exists, and `request/SKILL.md` §1 explains why no matcher can replace it.

The guard watches the Write/Edit tools; a shell redirect from Bash is not seen (which is how `file-request.sh` writes), and neither is a write performed by an MCP server (which is how `/explain`'s browser prints its PDF to the developer's Desktop). The threat model is an agent doing the natural thing, not one evading a gate.

**It cannot exempt a caller, and that shapes `/explain`.** A `PreToolUse` hook receives only `tool_input.file_path` — never which skill is asking — so an `.html` bound for Home is indistinguishable from any other write there and there is no narrow carve-out to write. `/explain` therefore stages its HTML **in-repo** at a git-ignored `.explain/<slug>.html` and lets the **browser** write the PDF to `chosen_dir` over MCP. The export is unchanged; only the staging file moved. `skills/explain/SKILL.md` §2-4 carries the rationale, and `test-workflow-scripts.mjs` pins the constraint ("confine blocks a non-repo path outside the repo (export dir)") so the dead `<chosen_dir>/<slug>.html` path cannot be reintroduced silently.

**The rule only reaches a repo that installs the plugin.** This is the failure that produced the incident: rules, hooks, and the scan are all inert in a repo where `workaholic@workaholic` is not in `enabledPlugins` — no matter what is written here. Enable it at the user level (`~/.claude/settings.json`) so every repo is covered, not per-project.

### Always-on policy lens

`hooks/policy-lens.sh` is a non-blocking `UserPromptSubmit` hook that injects the engineering-policy lens for the workflow commands that carry the `workaholic:policy-lens` sentinel marker (`/ticket`, `/report`, `/ship`, `/trip`, `/drive`, `/monitor`). The sentinel rides in the expanded command body, so the lens fires once per workflow invocation and stays in accumulated context. Two layers, by design:

- **Refer for bodies**: the hook points at the four pillar policy skills (`workaholic:planning`/`design`/`implementation`/`operation`); the full Goal/Responsibility/Practices live in `skills/<pillar>/policies/<slug>.md` and are read **on demand** when a change touches that policy.
- **Embed the index only**: the hook appends `hooks/policy-index.md` — a **generated** table of contents (per-policy heading + one-line summary across all four pillars), produced by `scripts/build-plugins/policy-index.mjs` from the four `SKILL.md` `## Policies` sections. This is the single bounded exception to "refer, never embed": headings are an index, not policy rules. The `## Policies` sections stay the single source of the heading list (kept fresh from qmu.co.jp by the `workaholic-standards-sync` controller). **Regenerate with `build.mjs` after editing any pillar's `## Policies` list.** Freshness is enforced in CI the same way `outputs/` is: the `Outputs Freshness` workflow rebuilds and fails on any diff to the committed `hooks/policy-index.md` (not by `verify.mjs`, which only flags a stale *working-tree* index when run before a build — after a build it is vacuously fresh).

### Always-on mission lens

`hooks/mission-lens.sh` keeps the agent — and the developer — oriented to the roadmap. It is registered on two events and is **non-forcing** on both (it never blocks a stop): on every `UserPromptSubmit` it injects a **model-visible** `additionalContext` line, and on every `Stop` a **user-visible** `systemMessage`. Each names the **active** missions (`.workaholic/missions/active/<slug>/mission.md`) that pass all **three** gates, with derived `checked/total` and the next unchecked acceptance item: **assignee** (the mission is *not somebody else's* — it matches the current `git config user.email`, or it is **unassigned**, in which case it is surfaced to everyone as claimable, after the developer's own; only another developer's mission stays silent), **location** (the worktree-focus rule below), and **signal** (at least one acceptance criterion). The signal gate exists because the line is printed unasked, directly above the agent's answer: a mission whose `## Acceptance` is empty renders as `0/0` with no next step — a technical condition with nothing to act on — so it says nothing instead. It is a silent no-op when nothing passes all three, so it usually costs only a few greps per turn (with many missions the per-mission `progress.sh` subshells are not free; if that ever bites, the fix is a batch reader in `skills/mission/scripts/`, not parsing inlined into the hook).

**Summarize on change.** The roster rarely changes within a session, yet a long `/goal` Stop condition re-fires this hook on essentially every turn — and re-injecting the whole block each time buries the developer's own message under redundant context (worse the larger the roster). So the **full** block is emitted only when the roster **changed** since the last turn of this session (or on the first turn, or when `session_id` is absent — a case that cannot be deduped and stays full, keeping the bare-harness/test path backward-compatible). An **unchanged** turn collapses to a compact one-liner — the count plus the single next action plus a `/mission summary` pointer — so the active goal and next step stay visible without the volume. The change-detector is keyed per session **and** per event (`UserPromptSubmit` and `Stop` dedupe independently), cksum-compared under `${TMPDIR:-/tmp}/workaholic-mission-lens/`, and fails open to the full roster; it never blocks a stop, so `/goal`'s gating is untouched. (`/goal` itself is a Claude Code harness feature, not a workaholic command — the only lever this repo owns over that per-turn volume is this hook's roster injection.)

`/mission summary` deliberately keeps the **lower** bar — assignee alone — so an unfilled `0/0` mission is still visible on demand. An always-on nudge and a list you asked for should not share a threshold; the divergence is intentional, not drift. The **assignee** gate itself is shared: both read "not somebody else's", so an unassigned mission surfaces in each (`summary.sh` returns it with an empty `assignee`; the lens marks it unclaimed). Unassigned missions were previously invisible in both — an exact email match excluded them for everybody, since an absent field matches no email that can exist.

The **worktree-focus** rule (missions run in their own `.worktrees/<slug>` worktree) has three cases, each decided rather than left to fall through: inside a mission's worktree it surfaces **only that mission** (you are already focused on it, so other worktrees' missions are noise); inside a worktree that owns **no** mission — a `/drive` worktree such as `.worktrees/work-20260714-005155` — it surfaces **nothing at all** (that session is focused on one ticket; the roadmap is not its business); and in the main tree it surfaces only missions that do **not** own a dedicated worktree (a worktree-owned mission stays silent everywhere but its own worktree). Basename-matching is sound here because `slug.sh` is the single source deriving both the mission directory name and the worktree name. This keeps each worktree's nudge scoped to its own work instead of listing every mission you own.

- **Why two events:** a `Stop` hook cannot inject model-visible context without `decision: block` (which would *force* the agent to keep working) — its only non-forcing channel is the user-facing `systemMessage`. So the model-facing half deliberately rides `UserPromptSubmit` (the same mechanism `policy-lens.sh` uses), which fires exactly when the agent decides "what to do next"; the `Stop` half is the developer-facing nudge. Together they honor "every time the agent stops or asks what next" without ever hijacking the turn.
- **Assignee is the gate:** the field is stamped by `mission/scripts/create.sh` (self-assigned to the creator by default; see the mission skill's *Assignee* section). Because each git worktree checks out its own `.workaholic/missions/`, the lens that fires in a worktree reflects the missions assigned to whoever is working that tree.
- **Reuse, not duplication:** the hook computes progress via `mission/scripts/progress.sh` and the next step via `mission/scripts/next-acceptance.sh`, so the Acceptance-scoping convention lives in one place. Claude-Code-only, POSIX `#!/bin/sh -eu`, **no `outputs/` footprint** (lives in `hooks/`, not built). The mission skill itself *is* built into `outputs/workflows`, so the `assignee`/`next-acceptance.sh` changes there require a `build.mjs` rebuild; the hook does not.

### Release-safety scan

The `release-scan` skill (`skills/release-scan/scan-branch-safety.sh`) is a **deterministic, script-only** branch-safety gate that `/report` (warn) and `/ship` (block, pre-merge) run over `git diff <base>..HEAD` to catch, before content reaches a public remote: **credentials** (`secret`, hard block — `release-scan/scripts/lib/secret-patterns.sh`, whose generic-assignment rule matches on the **value**, not the key name: a quoted-alphanumeric or line-ending bare run is a literal, and everything else — identifier, call, env read, template, annotation — is a reference that needs no rule of its own), **oversized/too-many files plus per-commit changed-lines** (`size`, overridable — `MAX_FILES`/`MAX_FILE_ADDED_LINES`/`MAX_FILE_BYTES` per file/branch, and `MAX_COMMIT_CHANGED_LINES` per commit via a `too-large-commit` rule that sums a commit's **non-generated** added+deleted lines, exempting binary rows, lockfiles, minified artifacts, `linguist-generated` paths — workaholic marks `outputs/**` so — and any file already over the per-file ceiling; it standardizes commit size so commit count is a comparable throughput unit), and **re-introduction of an already-known client/project term** (`leak`, confirm — the git-ignored, developer-maintained `.workaholic/leak-denylist`). It emits `{verdict, findings[]}` with each finding citing `file:line` + the matched rule (objective, so it can gate a merge); the consumers enforce the severity tiers. It is a script, not a subagent, on purpose — a merge gate must be reproducible, not a model judgment.

**Read the scope of the `leak` rule literally.** It matches listed terms in the branch diff, nothing more. It is blind to content already on `main`, and because the denylist is git-ignored it is a silent no-op in any repo where nobody created the file. It does **not** enforce "keep motivation generic, never name other repos/clients" — that rule is enforced by confining every workflow's writes to the current repo and by `/request`'s masking confirmation, which is a judgement a person makes when content crosses a repository boundary. A `pass` verdict means "no listed term was re-introduced", never "no client context here". An earlier version of this paragraph claimed the scan machine-enforced the convention; a structured internal-hostname pattern that backed that claim was removed after it was measured to detect none of five real leaks while misfiring on `metadata.internal`.

## Version Management

Version files (all must stay at the same semver):
- `.claude-plugin/marketplace.json` - root `version` AND every `plugins[].version` entry (workaholic, workflows)
- `plugins/workaholic/.claude-plugin/plugin.json`
- `plugins/workaholic/.codex-plugin/plugin.json` - hand-maintained Codex-facing manifest

Generated (do NOT hand-edit; rebuild with `node scripts/build-plugins/build.mjs`):
- `outputs/workflows/.codex-plugin/plugin.json` - version is read from `.claude-plugin/marketplace.json`'s `workflows` plugin entry at build time

`.claude-plugin/marketplace.json` is the single source of truth. When bumping version:
1. Read current version from `.claude-plugin/marketplace.json`
2. Increment PATCH by default (e.g., 1.0.0 → 1.0.1)
3. Update the root `version` and every `plugins[].version` in `.claude-plugin/marketplace.json`
4. Update `plugins/workaholic/.claude-plugin/plugin.json` and `plugins/workaholic/.codex-plugin/plugin.json` to match
5. Regenerate `outputs/workflows/` so its Codex manifest picks up the new version
6. Stage and commit: `Bump version to v{new_version}`
