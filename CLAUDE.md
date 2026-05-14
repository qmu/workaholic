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
    skills/              # analyze-performance, analyze-policy, analyze-viewpoint, branching, check-deps, commit, create-ticket, discover, drive, gather-git-context, gather-ticket-metadata, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-changelog, write-overview, write-release-note, write-spec, write-terms
  standards/             # Standards policy plugin (no dependencies)
    .claude-plugin/      # Plugin configuration
    skills/              # leading-*
  work/                  # Work plugin: drive + trip workflows (depends on: core)
    .claude-plugin/      # Plugin configuration
    agents/              # drive-navigator, story-writer, planner, architect, constructor, etc.
    commands/            # ticket, drive, trip, report, ship
    hooks/               # ticket validation
    rules/               # general, workaholic
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
  ^               ⤴ soft
  |            ⤴
work ─ ─ ─ ─ ─
```

Each plugin declares `dependencies` in its `plugin.json`. Cross-plugin `${CLAUDE_PLUGIN_ROOT}/../<name>/` references must only target declared dependencies. Soft references (skill preloads, subagent invocations) do not require a declared dependency — they are used when the referenced plugin is installed but do not prevent the caller from functioning without it. Work has soft references to standards (leading skill preloads, writer subagent invocations).

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
| Git context (branch, base, URL) | gather-git-context | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-git-context/scripts/gather.sh` |
| Ticket metadata (date, author) | gather-ticket-metadata | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh` |

Never write inline git commands like `git branch --show-current` or `git remote show origin` in subagent markdown files. Subagents preload the skill and gather context themselves.

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
bash .claude/skills/gather-ticket-metadata/scripts/gather.sh
```

**Correct** (same-plugin reference):
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh
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
