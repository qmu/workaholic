# Workaholic

Private, cross-agent distribution of structured development workflows and engineering standards. It is richest on **Claude Code**, where it installs as a plugin marketplace (slash commands, hooks, `/trip` Agent Teams); the portable skills also ship to **Codex** (via `.agents/plugins/marketplace.json` → `outputs/workflows`) and to **OpenCode** plus 40+ other agents via the Agent Skills standard / `skills` CLI. Authored source lives under `plugins/`; cross-agent artifacts are generated into `outputs/`.

## Important

Edit `plugins/` not `.claude/`. This repo develops plugins - changes go to `plugins/`, never `.claude/` unless explicitly requested.

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
    skills/              # workflow skills (branching, check-deps, commit, create-ticket, discover, drive, gather, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-release-note) + policy skills (design, implementation, operation, each linking English hard copies under its policies/ dir)
    commands/            # ticket, drive, trip, report, ship (Claude-only; ignored by other agents)
    agents/              # Agent Teams members only: planner, architect, constructor (launched by /trip)
    hooks/               # ticket validation
    rules/               # diagrams, general, shell, typescript, workaholic
scripts/                 # Repo tooling
  claude.sh              # Launcher
  build-plugins/         # Generates outputs/ from plugins/workaholic/skills (run argument-less for a full build)
outputs/                    # GENERATED, committed cross-agent artifacts — do NOT hand-edit (CI-guarded)
  workflows/             # Portable workflows plugin: .codex-plugin/plugin.json + self-contained skills/
.agents/                 # Codex marketplace
  plugins/marketplace.json  # Codex plugin list (workflows -> ./outputs/workflows)
```

## Architecture Policy

### Component Nesting Rules

| Caller                         | Can invoke                                   | Cannot invoke              |
| ------------------------------ | -------------------------------------------- | -------------------------- |
| Command                        | Skill, `general-purpose` subagent            | —                          |
| Skill                          | Skill; (when loaded by a command/main agent) may direct it to spawn `general-purpose` subagents | Command                    |
| `general-purpose` subagent     | Skill (via preload)                          | Command, Task (no nesting) |

There are two distinct kinds of "subagent" in this repo, and the table above governs only the first:

- **`general-purpose` subagents** are the built-in Claude Code subagent type. They have **no `.md` agent file** — a command (or a skill running in the command's main-agent context) spawns them with a `Task` call whose prompt says "preload `core:<skill>`, run `<section>` with these inputs, return `<schema>`." This is how `/report`, `/drive`, and `/ticket` fan out. Skills cannot issue `Task` calls themselves; the prohibition on Skill→Subagent that previously appeared here is lifted **only** in the sense that a skill's prose may instruct its loading agent (a command/main agent) to spawn `general-purpose` leaves.
- **Named Agent Teams members** (`planner`, `architect`, `constructor` in `plugins/workaholic/agents/`) are launched **only by `/trip`** as Agent Teams members — not as `Task` subagents. They are exempt from the nesting table; `/trip` is intrinsically Agent-Teams-based and Claude-Code-only.

### No Per-Workflow Agent Files

Workflow orchestration does **not** get dedicated agent `.md` files. A command spawns `subagent_type: "general-purpose"` subagents whose prompts instruct them to preload the relevant `core` skill and run a named section. The knowledge lives in the skill; the subagent is a throwaway leaf. The only agent `.md` files in the repo are the Agent Teams members `/trip` requires (`planner`, `architect`, `constructor`).

When adding a new fan-out step, do not create an agent file — write the knowledge as a section in a `core` skill and have the command spawn a `general-purpose` subagent that preloads it.

### One-Level Fan-Out

A subagent **cannot** nest `Task` calls and **cannot** call `AskUserQuestion`. Therefore:

- All fan-out happens at the command/main-agent level. No subagent-that-spawns-subagents.
- All user interaction (`AskUserQuestion`) happens at the command/main-agent level.
- Leaf `general-purpose` subagents do non-interactive work only and return JSON for the command to act on.

When a workflow needs both parallel work and a user decision, the command spawns the leaves, collects their JSON, then issues the `AskUserQuestion` itself.

### Plugin Dependencies

There is **one** plugin (`workaholic`) with `dependencies: []` — everything that was previously split across `core`, `standards`, and `work` now lives in it. All skill references are same-plugin: `${CLAUDE_PLUGIN_ROOT}/skills/<name>/...` (no cross-plugin `../<name>/` paths) and `workaholic:<skill>` namespaces. The `workflows` plugin in the marketplace is the **generated** `outputs/workflows` bundle, not an authored plugin.

> **Note:** the prose below (Cross-Agent Skill Exposure and the distribution section) still describes the prior three-plugin topology (`core`/`standards`/`work`) in places; the mechanics (metadata.internal gating, the `${CLAUDE_PLUGIN_ROOT}` determinism rationale, the generated `outputs/workflows` bundle) are unchanged, but the plugin names and dependency framing are pending a narrative pass.

### Cross-Agent Skill Exposure

The `standards` skills are installable by non-Claude agents (Cursor, OpenCode, Codex, Pi, 50+) via `npx skills add qmu/workaholic`. The `skills` CLI (`vercel-labs/skills`) reads `.claude-plugin/marketplace.json`: the `skills` array on the `standards` plugin entry labels its discovery group. Two rules keep the exposed set honest:

- **Script-bearing `core` skills carry `metadata.internal: true`** in their SKILL.md frontmatter. Claude Code ignores this field (the skills still load normally); the `skills` CLI hides them from cross-agent discovery. This is required because the CLI always scans every marketplace plugin's `skills/` dir — `metadata.internal` is the only per-skill exclusion. Any new `core` skill that invokes a bundled script MUST include it.
- **`write-release-note` is intentionally exposed** (no `metadata.internal`). It is pure prose — no bundled script, no `${CLAUDE_PLUGIN_ROOT}`, no namespaced preload — so it resolves on every agent via the `skills` CLI.
- **Why script-bearing core skills stay internal** (verified 2026-05-26): every agent (Claude Code, OpenCode, Codex, Pi) runs a skill's shell in the *project* CWD and only injects the skill's base directory as text for the *model* to prepend — none `cd`s into the skill dir. Claude Code additionally expands `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_SKILL_DIR}` deterministically at load time. Rewriting a script call to the spec-relative `scripts/X.sh` form would drop that determinism and rely on non-deterministic model-prepend — unacceptable for skills workaholic runs in its own Claude-Code `/drive`/`/ship` critical path. So script-bearing skills keep the token and stay internal.
- **`work` needs nothing** — it has no `skills/` directory, so the CLI finds nothing to expose.

To preview what the CLI would install, run `npx skills add . --list` (add `INSTALL_INTERNAL_SKILLS=1` to include internal core skills).

#### Cross-agent distribution (workflow skills, built)

The workflow skills (ticket/drive/report/ship) depend on shared `core` scripts and so are **not** self-contained in source. They ship to non-Claude agents as a **generated, self-contained, committed plugin** at `outputs/workflows/`, produced by `scripts/build-plugins` from the DRY `plugins/workaholic` source (`trip` is excluded — Agent Teams, Claude-only). **One neutral generated dir serves every non-Claude agent** through two manifests that point at it:

- **Codex** reads `.agents/plugins/marketplace.json` (repo root); its `workflows` plugin `source.path` is `./outputs/workflows`, and Codex consumes the co-located `outputs/workflows/.codex-plugin/plugin.json`.
- **OpenCode, Cursor, Pi, 40+** get it via the `skills` CLI, which reads the `workflows` plugin entry in `.claude-plugin/marketplace.json` (`source: ./outputs/workflows`) and its `skills/` (the `standards` `design`/`implementation`/`operation` skills are exposed the same way). The `skills` CLI ignores the co-located `.codex-plugin/` dir, so the same folder serves both systems. `write-release-note` and `review-sections` ship inside this plugin too.

Source-vs-artifact rule: the `plugins/workaholic` workflow skills keep `metadata.internal: true` and `${CLAUDE_PLUGIN_ROOT}` (so the `skills` CLI never offers the broken source); the **committed `outputs/workflows/` artifacts** are the public versions — self-contained, `${CLAUDE_PLUGIN_ROOT}` rewritten to relative paths, and `metadata.internal` / `user-invocable` / the `skills:` preload block stripped with namespace prefixes flattened by `publicizeSkillMd`. **Regenerate with the argument-less `node scripts/build-plugins/build.mjs` whenever a `core` workflow skill or its script closure changes** (a *targeted* build only writes a throwaway scratch dir and does not touch `outputs/`). `outputs/` is **committed, not gitignored** — Codex and the `skills` CLI install by reading repo paths, so the artifacts must be present. The `Outputs Freshness` CI workflow (`.github/workflows/outputs-freshness.yml`) rebuilds and fails on any `outputs/` diff, keeping artifact and source in lockstep.

Claude Code reads `plugins/` directly and consumes nothing from `outputs/`. The `workflows` entry in `.claude-plugin/marketplace.json` is read by Claude Code too, so it is **opt-in** — its description points Claude users to `core`/`work` to avoid installing duplicate workflow skills.

### Design Principle

**Thin commands, comprehensive skills.**

- **Commands**: Orchestration only (~50-100 lines). Define workflow steps, spawn `general-purpose` subagents, handle all user interaction.
- **`general-purpose` subagent prompts**: Orchestration only. Name the `core` skill to preload, the section to run, the inputs, and the return schema — no per-workflow `.md` file.
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

A command's skills are already loaded via its `skills:` frontmatter and resolved through `${CLAUDE_PLUGIN_ROOT}` at load time. Invoke them by their loaded namespace (`core:`, `work:`, `standards:`) and run their bundled scripts via `${CLAUDE_PLUGIN_ROOT}`. Do **not**:

- read or run anything under `~/.claude/plugins/marketplaces/` or any other global/marketplace install — those may be stale copies from older versions and will silently run obsolete logic;
- guess a plugin or skill namespace. `drivin` and `trippin` are **obsolete** names that were merged into `work`; the only live plugins are `core`, `standards`, and `work`.

If a skill you expect is not in context, ask the user which plugins are loaded — do not search the filesystem for it. The five `work` command `**Notice:**` headers carry a short echo of this rule.

## Commands

| Command                          | Description                                      |
| -------------------------------- | ------------------------------------------------ |
| `/ticket <description>`          | Write implementation spec for a feature          |
| `/drive`                         | Implement queued specs one by one                |
| `/report`                        | Context-aware: generate story or journey report and create PR |
| `/ship`                          | Context-aware: merge PR, deploy, and verify      |
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
node scripts/build-plugins/build.mjs              # regenerate outputs/ if you touched a core skill or build.mjs
node scripts/build-plugins/verify.mjs             # assert generated skills are self-contained
node scripts/build-plugins/validate-metadata.mjs  # assert Codex manifests are well-formed and version-aligned
node scripts/test-workflow-scripts.mjs            # hermetic smoke tests for branching + drive scripts
```

The smoke tests create throwaway repositories under the OS temp dir, exercise the scripts there, assert on JSON output and filesystem state, and clean up. They never touch the working tree or call `gh`/network — safe to run anywhere.

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
