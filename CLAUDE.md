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
    commands/            # ticket, drive, story
    rules/               # general, typescript
    skills/              # archive-ticket
```

## Architecture Policy

### Component Nesting Rules

| Caller   | Can invoke         | Cannot invoke       |
| -------- | ------------------ | ------------------- |
| Command  | Skill, Subagent    | —                   |
| Subagent | Skill              | Subagent, Command   |
| Skill    | —                  | Subagent, Command   |

**Allowed**:
- Command → Skill (preload via `skills:` frontmatter)
- Command → Subagent (via Task tool)
- Subagent → Skill (preload via `skills:` frontmatter)

**Prohibited**:
- Skill → Subagent (skills are passive knowledge, not orchestrators)
- Skill → Command (skills cannot invoke user-facing commands)
- Subagent → Subagent (prevents deep nesting and context explosion)
- Subagent → Command (subagents are invoked by commands, not the reverse)

### Design Principle

**Thin commands and subagents, comprehensive skills.**

- **Commands**: Orchestration only (~50-100 lines). Define workflow steps, invoke subagents, handle user interaction.
- **Subagents**: Orchestration only (~20-40 lines). Define input/output, preload skills, minimal procedural logic.
- **Skills**: Comprehensive knowledge (~50-150 lines). Contain templates, guidelines, rules, and bash scripts.

Skills are the knowledge layer. Commands and subagents are the orchestration layer.

## Commands

| Command                          | Description                                      |
| -------------------------------- | ------------------------------------------------ |
| `/ticket <description>`          | Write implementation spec for a feature          |
| `/drive`                         | Implement queued specs one by one                |
| `/story`                         | Generate documentation and create/update PR      |
| `/release [major\|minor\|patch]` | Release new marketplace version                  |

## Development Workflow

1. **Create specs**: Use `/ticket` to write implementation specs
2. **Implement specs**: Use `/drive` to implement and commit each spec
3. **Create PR**: Use `/story` to generate documentation and create PR
4. **Release**: Use `/release` to bump version and publish

## Type Checking

No build step required - this is a configuration/documentation project.

## Version Management

- Marketplace version: `.claude-plugin/marketplace.json`
- Plugin versions: `plugins/<name>/.claude-plugin/plugin.json`
- Keep versions in sync when releasing
