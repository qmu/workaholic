# Workaholic

Private marketplace for Claude Code plugins.

## Important

Edit `plugins/` not `.claude/`. This repo develops plugins - changes go to `plugins/`, never `.claude/` unless explicitly requested.

## Written Language

- **`.workaholic/` directory**: English or Japanese (i18n)
- **All other content**: English only
  - Code and code comments
  - Commit messages
  - Pull requests
  - Documentation outside `.workaholic/`

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
    commands/            # report, ship, worktree
    skills/              # branching, ship, system-safety
  standards/             # Standards policy plugin (no dependencies)
    .claude-plugin/      # Plugin configuration
    agents/              # leads, managers, writers, analysts
    skills/              # lead-*, manage-*, analyze-*, write-*
  drivin/                # Drivin ticket-driving plugin (depends on: core)
    .claude-plugin/      # Plugin configuration
    agents/              # ticket-organizer, drive-navigator, story-writer
    commands/            # ticket, drive, scan
    rules/               # general, typescript
    skills/              # archive-ticket, drive-workflow
  trippin/               # Trippin exploration plugin (depends on: core, drivin)
    .claude-plugin/      # Plugin configuration
    commands/            # trip
    agents/              # planner, architect, constructor
    skills/              # trip-protocol, write-trip-report
    rules/               # i18n
```

## Architecture Policy

### Component Nesting Rules

| Caller   | Can invoke         | Cannot invoke       |
| -------- | ------------------ | ------------------- |
| Command  | Skill, Subagent    | —                   |
| Subagent | Skill, Subagent    | Command             |
| Skill    | Skill              | Subagent, Command   |

### Plugin Dependencies

```
core (base)       standards (base)
  ^       ^
  |       |
drivin  trippin
  ^       |
  |_______|
```

Each plugin declares `dependencies` in its `plugin.json`. Cross-plugin `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must only target declared dependencies. Core commands have soft references to drivin and trippin for context-aware routing (report, ship).

### Design Principle

**Thin commands and subagents, comprehensive skills.**

- **Commands**: Orchestration only (~50-100 lines). Define workflow steps, invoke subagents, handle user interaction.
- **Subagents**: Orchestration only (~20-40 lines). Define input/output, preload skills, minimal procedural logic.
- **Skills**: Comprehensive knowledge (~50-150 lines). Contain templates, guidelines, rules, and bash scripts.

Skills are the knowledge layer. Commands and subagents are the orchestration layer.

### Common Operations

Subagents must use skills for common operations instead of inline shell commands:

| Operation | Skill | Usage |
| --------- | ----- | ----- |
| Git context (branch, base, URL) | gather-git-context | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-git-context/sh/gather.sh` |
| Ticket metadata (date, author) | gather-ticket-metadata | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/sh/gather.sh` |

Never write inline git commands like `git branch --show-current` or `git remote show origin` in subagent markdown files. Subagents preload the skill and gather context themselves.

### Shell Script Principle

> **CRITICAL: Never use complex inline shell commands in subagent or command markdown files.**

This includes:
- **Conditionals**: `if`, `case`, `test`, `[ ]`, `[[ ]]`
- **Pipes and chains**: `|`, `&&`, `||`
- **Text processing**: `sed`, `awk`, `grep`, `cut`
- **Loops**: `for`, `while`
- **Variable expansion with logic**: `${var:-default}`, `${var:+alt}`

Extract ALL multi-step or conditional shell operations to bundled scripts in skills (`skills/<name>/sh/<script>.sh`). This ensures consistency, testability, and permission-free execution.

**Wrong** (inline conditional):
```bash
current=$(git branch --show-current)
if [ "$current" = "main" ]; then echo "on_main"; fi
```

**Correct** (skill script):
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/sh/check.sh
```

### Skill Script Path Rule

> **CRITICAL: All skill shell script references must use `${CLAUDE_PLUGIN_ROOT}`.**

Claude Code expands `${CLAUDE_PLUGIN_ROOT}` inline in all plugin content (skills, agents, commands) at load time. This resolves to the plugin's installed directory. Relative paths like `.claude/skills/` do NOT resolve at runtime and cause exit code 127 failures.

**Wrong** (relative path):
```bash
bash .claude/skills/gather-ticket-metadata/sh/gather.sh
```

**Correct** (same-plugin reference):
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/sh/gather.sh
```

**Correct** (cross-plugin reference — declared dependency):
```bash
bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/sh/check-worktrees.sh
```

## Commands

| Command                          | Description                                      |
| -------------------------------- | ------------------------------------------------ |
| `/ticket <description>`          | Write implementation spec for a feature          |
| `/drive`                         | Implement queued specs one by one                |
| `/scan`                          | Full documentation scan (all 14 agents)          |
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
- `plugins/drivin/.claude-plugin/plugin.json` - plugin `version` field
- `plugins/trippin/.claude-plugin/plugin.json` - plugin `version` field

Keep all versions in sync. When bumping version:
1. Read current version from `.claude-plugin/marketplace.json`
2. Increment PATCH by default (e.g., 1.0.0 → 1.0.1)
3. Update all version files with the new version
4. Stage and commit: `Bump version to v{new_version}`
