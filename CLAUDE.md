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
    skills/              # workflow skills (branching, carry, catch, check-deps, commit, create-ticket, discover, drive, explain, gather, okf, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, workaholify, write-release-note) + policy skills (planning, design, implementation, operation, each linking English hard copies under its policies/ dir)
    commands/            # ticket, drive, trip, report, ship, catch, carry, explain, commit, workaholify (Claude-only; ignored by other agents)
    agents/              # Agent Teams members only: planner, architect, constructor (launched by /trip)
    hooks/               # ticket validation (validate-ticket.sh, PostToolUse Write|Edit) + structural move guard (guard-ticket-structure.sh, PreToolUse Bash — blocks non-canonical ticket moves like done/ or todo/<user>/archive/) + always-on policy lens (policy-lens.sh) + generated policy-index.md
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
- **Executors** (drain `todo/ → archive/`): the **drive executor** (`/drive` — solo main-agent + developer approval per ticket) and the **trip executor** (`/trip` — three-agent team, with Constructor implements → Architect reviews → Planner E2E standing in for the developer gate; `drive/archive.sh` archives each ticket).

`/trip` is **context-aware** (like `/report` and `/ship`): `/trip <instruction>` over an empty queue is source+executor (design → decompose → drive, as **one continuous run** — the team flows from the fixed design straight into the build with no developer green-light pause; review happens afterward via `/report`); `/trip` over a populated queue is executor-only (trip-drive the existing `/ticket` queue, no design — the `ticket → trip` direction); `/trip` over nothing tells you to `/ticket` first. Because both executors read the same `todo/`, you can switch between them mid-queue (`trip → interrupt → /drive`). So `trips/` holds the *why*, `tickets/` the *what*, and `/report`/`/ship` treat a trip exactly like a drive.

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

The plugin's `commands/`, `agents/`, `hooks/`, and `rules/` are Claude-Code-only: the `skills` CLI and Codex read only the `skills/` dir, so those directories are never scanned — invisible on other agents, not broken.

To preview what the CLI would install, run `npx skills add . --list` (add `INSTALL_INTERNAL_SKILLS=1` to include internal skills).

#### Cross-agent distribution (workflow skills, built)

The workflow skills (ticket/drive/report/ship) depend on shared scripts elsewhere in the plugin (via `${CLAUDE_PLUGIN_ROOT}`) and so are **not** self-contained in source. They ship to non-Claude agents as a **generated, self-contained, committed plugin** at `outputs/workflows/`, produced by `scripts/build-plugins` from the DRY `plugins/workaholic` source (`trip` is excluded — Agent Teams, Claude-only). **One neutral generated dir serves every non-Claude agent** through two manifests that point at it:

- **Codex** reads `.agents/plugins/marketplace.json` (repo root); its `workflows` plugin `source.path` is `./outputs/workflows`, and Codex consumes the co-located `outputs/workflows/.codex-plugin/plugin.json`.
- **OpenCode, Cursor, Pi, 40+** get it via the `skills` CLI, which reads the `workflows` plugin entry in `.claude-plugin/marketplace.json` (`source: ./outputs/workflows`) and its `skills/` (the `design`/`implementation`/`operation` policy skills are exposed the same way). The `skills` CLI ignores the co-located `.codex-plugin/` dir, so the same folder serves both systems. `write-release-note` and `review-sections` ship inside this plugin too.

Source-vs-artifact rule: the `plugins/workaholic` workflow skills keep `metadata.internal: true` and `${CLAUDE_PLUGIN_ROOT}` (so the `skills` CLI never offers the broken source); the **committed `outputs/workflows/` artifacts** are the public versions — self-contained, `${CLAUDE_PLUGIN_ROOT}` rewritten to relative paths, and `metadata.internal` / `user-invocable` / the `skills:` preload block stripped with namespace prefixes flattened by `publicizeSkillMd`. **Regenerate with the argument-less `node scripts/build-plugins/build.mjs` whenever a `workaholic` workflow skill or its script closure changes** (a *targeted* build only writes a throwaway scratch dir and does not touch `outputs/`). `outputs/` is **committed, not gitignored** — Codex and the `skills` CLI install by reading repo paths, so the artifacts must be present. The `Outputs Freshness` CI workflow (`.github/workflows/outputs-freshness.yml`) rebuilds and fails on any `outputs/` diff, keeping artifact and source in lockstep.

Claude Code reads `plugins/` directly and consumes nothing from `outputs/`. The `workflows` entry in `.claude-plugin/marketplace.json` is read by Claude Code too, so it is **opt-in** — its description points Claude users to the `workaholic` plugin to avoid installing duplicate workflow skills.

#### OKF knowledge bundle (generated)

`outputs/okf/` is an [Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf) (OKF v0.1) bundle of the four pillars' policy hard copies, generated by `scripts/build-plugins/okf.mjs` (wired into the same argument-less `build.mjs` full build): one concept document per `plugins/workaholic/skills/<pillar>/policies/*.md` with OKF frontmatter (`type`/`title`/`description`/`resource`/`tags`; no `timestamp` — commit-date-derived values would break the rebuild-and-diff freshness guard), bundle-absolute intra-bundle links, and a bundle-root `index.md` declaring `okf_version`. Any OKF consumer reads it straight from the repo path — no marketplace manifest involved, so neither Claude Code nor the `skills` CLI/Codex ever installs it as a plugin. `verify.mjs` asserts freshness plus OKF conformance (parseable frontmatter, non-empty `type`, reserved filenames, in-bundle link resolution); the `Outputs Freshness` CI diff over `outputs/` covers it like every other generated artifact. The adoption record (reason/assessment/monitoring/exit) is `docs/dependencies/okf.md`; OKF vocabulary stays inside `okf.mjs` — the translation boundary — and never shapes the source conventions.

#### `.workaholic/` as an OKF bundle (runtime)

Separately from the generated policy bundle, the `.workaholic/` tree of any project using the plugin is itself kept OKF-compatible **as the workflows generate documents**: every written artifact carries frontmatter with a non-empty `type` (tickets `enhancement|bugfix|refactoring|housekeeping`, stories `Story`, release notes `Release Note`, deferred concerns `Concern`, trip artifacts `Direction|Model|Design|Review|Rollback|Trip Plan|Event Log`), and the internal `okf` skill's `refresh-index.sh` deterministically regenerates the bundle hierarchy — `.workaholic/index.md` (bundle root, declares `okf_version`) plus per-area `index.md` files — before each knowledge commit (called by `drive`'s `archive.sh`, `ship`'s `commit-release-note.sh`/`extract-deferred-concerns.sh`, and the `report` story flow). `stories/index.md` stays report-maintained; `tickets/` internals are never index-managed (the queue scripts and structure guards own that tree). `README.md` and `index.md` are the two files allowed at the `.workaholic/` root.

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
| `/ticket <description>`          | Write implementation spec for a feature          |
| `/drive`                         | Implement queued specs one by one                |
| `/commit`                        | Commit working changes with a policy-conformant message (small non-ticketed changes; prefer `/drive` for ticketed work) |
| `/report`                        | Context-aware: generate story or journey report and create PR |
| `/ship`                          | Context-aware: merge PR, deploy, and verify      |
| `/catch [window]`                | Read-only by-developer catch-up report over a recent window (commits, tickets, stories), then follow-up Q&A |
| `/carry`                         | Hand off in-progress work to a fresh session (capture-only): write a resumption ticket / trip checkpoint a later `/drive` continues, instead of relying on compaction |
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

  Bypass a single commit with `git commit --no-verify`; undo with `git config --unset core.hooksPath`. Both layers share one rule source (`hooks/lib/check-subject.sh`) so they cannot drift. These hooks are Claude-Code-only / git-native and have **no `outputs/` footprint** (not bundled, no rebuild). `commit-msg` is exempt from `posix-lint` only because git requires that exact extensionless name; it is POSIX `#!/bin/sh -eu` by construction.

### AskUserQuestion project-label enforcement

The `[<project label>]` prompt-prefix convention (each `AskUserQuestion` question body opens with the owning repo's label, from `skills/gather/scripts/project-label.sh`, so a developer with many parallel sessions sees which repo is asking) is enforced as a gate, not just prose. `hooks/guard-askuserquestion-label.sh` is a blocking `PreToolUse(AskUserQuestion)` hook (shipped active in `hooks.json`): it reads `tool_input.questions[].question` and exits 2 (re-issue) when any body lacks a leading `[…]` label. It fires on every `AskUserQuestion` by design — labeling any prompt with its repo is a net good, so the over-fire onto ad-hoc questions is intentional. Claude-Code-only, POSIX `#!/bin/sh -eu`, **no `outputs/` footprint**. The rule itself stays where it was — the per-skill "User interaction" prose — this hook only makes it machine-checked.

A companion `hooks/guard-working-directory.sh` (`PreToolUse(Bash)`, shipped active) is **non-blocking**: it reminds and steers a top-level cwd-moving `cd` toward an absolute path or a `( cd … )` subshell so the working directory stays at the repo root, but never blocks a deliberate `cd`. It is the machine-surfaced half of the `workaholify` working-directory ground rules (`skills/workaholify/`); like the other guards it is Claude-Code-only, POSIX `#!/bin/sh -eu`, with no `outputs/` footprint.

### Always-on policy lens

`hooks/policy-lens.sh` is a non-blocking `UserPromptSubmit` hook that injects the engineering-policy lens for the workflow commands that carry the `workaholic:policy-lens` sentinel marker (`/ticket`, `/report`, `/ship`, `/trip`, `/drive`). The sentinel rides in the expanded command body, so the lens fires once per workflow invocation and stays in accumulated context. Two layers, by design:

- **Refer for bodies**: the hook points at the four pillar policy skills (`workaholic:planning`/`design`/`implementation`/`operation`); the full Goal/Responsibility/Practices live in `skills/<pillar>/policies/<slug>.md` and are read **on demand** when a change touches that policy.
- **Embed the index only**: the hook appends `hooks/policy-index.md` — a **generated** table of contents (per-policy heading + one-line summary across all four pillars), produced by `scripts/build-plugins/policy-index.mjs` from the four `SKILL.md` `## Policies` sections. This is the single bounded exception to "refer, never embed": headings are an index, not policy rules. The `## Policies` sections stay the single source of the heading list (kept fresh from qmu.co.jp by the `workaholic-standards-sync` controller). **Regenerate with `build.mjs` after editing any pillar's `## Policies` list.** Freshness is enforced in CI the same way `outputs/` is: the `Outputs Freshness` workflow rebuilds and fails on any diff to the committed `hooks/policy-index.md` (not by `verify.mjs`, which only flags a stale *working-tree* index when run before a build — after a build it is vacuously fresh).

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
