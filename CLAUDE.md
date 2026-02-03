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
.claude-plugin/          # Marketplace configuration
  marketplace.json       # Marketplace metadata and plugin list
plugins/                 # Plugin source directories
  core/                  # Core development plugin
    .claude-plugin/      # Plugin configuration
    agents/              # performance-analyst
    commands/            # ticket, drive, report
    rules/               # general, typescript
    skills/              # archive-ticket
```

## Architecture Policy

### Component Nesting Rules

| Caller   | Can invoke         | Cannot invoke       |
| -------- | ------------------ | ------------------- |
| Command  | Skill, Subagent    | —                   |
| Subagent | Skill, Subagent    | Command             |
| Skill    | Skill              | Subagent, Command   |

**Allowed**:
- Command → Skill (preload via `skills:` frontmatter)
- Command → Subagent (via Task tool)
- Subagent → Skill (preload via `skills:` frontmatter)
- Subagent → Subagent (via Task tool, parallel only)
- Skill → Skill (preload via `skills:` frontmatter for composable knowledge)

**Prohibited**:
- Skill → Subagent (skills are passive knowledge, not orchestrators)
- Skill → Command (skills cannot invoke user-facing commands)
- Subagent → Subagent (sequential chains cause deep nesting and context explosion)
- Subagent → Command (subagents are invoked by commands, not the reverse)

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
| Git context (branch, base, URL) | gather-git-context | `bash .claude/skills/gather-git-context/sh/gather.sh` |
| Ticket metadata (date, author) | gather-ticket-metadata | `bash .claude/skills/gather-ticket-metadata/sh/gather.sh` |

Never write inline git commands like `git branch --show-current` or `git remote show origin` in subagent markdown files. Subagents preload the skill and gather context themselves.

## Commands

| Command                          | Description                                      |
| -------------------------------- | ------------------------------------------------ |
| `/ticket <description>`          | Write implementation spec for a feature          |
| `/drive`                         | Implement queued specs one by one                |
| `/scan`                          | Update .workaholic/ documentation                |
| `/report`                        | Generate documentation and create/update PR      |
| `/release [major\|minor\|patch]` | Release new marketplace version                  |

## Development Workflow

1. **Create specs**: Use `/ticket` to write implementation specs
2. **Implement specs**: Use `/drive` to implement and commit each spec
3. **Create PR**: Use `/report` to generate documentation and create PR
4. **Release**: Use `/release` to bump version and publish

## Type Checking

No build step required - this is a configuration/documentation project.

## Version Management

Version files:
- `.claude-plugin/marketplace.json` - root `version` field
- `plugins/core/.claude-plugin/plugin.json` - plugin `version` field

Keep all versions in sync. When bumping version:
1. Read current version from `.claude-plugin/marketplace.json`
2. Increment PATCH by default (e.g., 1.0.0 → 1.0.1)
3. Update both version files with the new version
4. Stage and commit: `Bump version to v{new_version}`
