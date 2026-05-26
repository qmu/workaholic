# Workaholic

Private marketplace for Claude Code plugins.

## Important

Edit `plugins/` not `.claude/`. This repo develops plugins - changes go to `plugins/`, never `.claude/` unless explicitly requested.

## Project Structure

```
.claude/                 # Local Claude Code configuration
  rules/                 # Repository-scoped rules
    define-lead.md       # Lead agent schema enforcement
.claude-plugin/          # Marketplace configuration
  marketplace.json       # Marketplace metadata and plugin list
plugins/                 # Plugin source directories
  core/                  # Core shared plugin (no dependencies)
    .claude-plugin/      # Plugin configuration
    skills/              # branching, check-deps, commit, create-ticket, discover, drive, gather, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-release-note
  standards/             # Standards policy plugin (no dependencies; cross-agent exposed)
    .claude-plugin/      # Plugin configuration
    skills/              # leading-*
  work/                  # Work plugin: drive + trip workflows (depends on: core)
    .claude-plugin/      # Plugin configuration
    agents/              # Agent Teams members only: planner, architect, constructor (launched by /trip)
    commands/            # ticket, drive, trip, report, ship
    hooks/               # ticket validation
    rules/               # diagrams, general, shell, typescript, workaholic
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
- **Named Agent Teams members** (`planner`, `architect`, `constructor` in `plugins/work/agents/`) are launched **only by `/trip`** as Agent Teams members — not as `Task` subagents. They are exempt from the nesting table; `/trip` is intrinsically Agent-Teams-based and Claude-Code-only.

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

```
core (base)       standards (base)
  ^               ⤴ soft
  |            ⤴
work ─ ─ ─ ─ ─
```

Each plugin declares `dependencies` in its `plugin.json`. Cross-plugin `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must only target declared dependencies. Soft references (skill preloads) do not require a declared dependency — they are used when the referenced plugin is installed but do not prevent the caller from functioning without it. Work has soft references to standards (the `leading-*` skills are preloaded by `core:create-ticket`/`core:drive` and named in `general-purpose` subagent prompts when installed).

### Cross-Agent Skill Exposure

The `standards` skills are installable by non-Claude agents (Cursor, OpenCode, Codex, Pi, 50+) via `npx skills add qmu/workaholic`. The `skills` CLI (`vercel-labs/skills`) reads `.claude-plugin/marketplace.json`: the `skills` array on the `standards` plugin entry labels its discovery group. Two rules keep the exposed set honest:

- **Script-bearing `core` skills carry `metadata.internal: true`** in their SKILL.md frontmatter. Claude Code ignores this field (the skills still load normally); the `skills` CLI hides them from cross-agent discovery. This is required because the CLI always scans every marketplace plugin's `skills/` dir — `metadata.internal` is the only per-skill exclusion. Any new `core` skill that invokes a bundled script MUST include it.
- **`write-release-note` is intentionally exposed** (no `metadata.internal`). It is pure prose — no bundled script, no `${CLAUDE_PLUGIN_ROOT}`, no namespaced preload — so it resolves on every agent. It is currently the only exposed `core` skill.
- **Why script-bearing core skills stay internal** (verified 2026-05-26): every agent (Claude Code, OpenCode, Codex, Pi) runs a skill's shell in the *project* CWD and only injects the skill's base directory as text for the *model* to prepend — none `cd`s into the skill dir. Claude Code additionally expands `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_SKILL_DIR}` deterministically at load time. Rewriting a script call to the spec-relative `scripts/X.sh` form would drop that determinism and rely on non-deterministic model-prepend — unacceptable for skills workaholic runs in its own Claude-Code `/drive`/`/ship` critical path. So script-bearing skills keep the token and stay internal.
- **`work` needs nothing** — it has no `skills/` directory, so the CLI finds nothing to expose.

To preview what the CLI would install, run `npx skills add . --list` (add `INSTALL_INTERNAL_SKILLS=1` to include internal core skills).

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

## Version Management

Version files:
- `.claude-plugin/marketplace.json` - root `version` field
- `plugins/core/.claude-plugin/plugin.json` - plugin `version` field
- `plugins/standards/.claude-plugin/plugin.json` - plugin `version` field
- `plugins/work/.claude-plugin/plugin.json` - plugin `version` field

Keep all versions in sync. When bumping version:
1. Read current version from `.claude-plugin/marketplace.json`
2. Increment PATCH by default (e.g., 1.0.0 → 1.0.1)
3. Update all version files with the new version
4. Stage and commit: `Bump version to v{new_version}`
