# Workaholic

Private marketplace for Claude Code plugins.

## Important

Edit `plugins/` not `.claude/`. This repo develops plugins - changes go to `plugins/`, never `.claude/` unless explicitly requested.

## Written Language

- **`.work/` directory**: English or Japanese (i18n)
- **All other content**: English only
  - Code and code comments
  - Commit messages
  - Pull requests
  - Documentation outside `.work/`

## Project Structure

```
.claude-plugin/          # Marketplace configuration
  marketplace.json       # Marketplace metadata and plugin list
plugins/                 # Plugin source directories
  core/                  # Core development plugin
    .claude-plugin/      # Plugin configuration
    agents/              # performance-analyst
    commands/            # branch, commit, pull-request, ticket, drive, sync-src-doc
    rules/               # general, typescript
    skills/              # archive-ticket
```

## Commands

| Command                          | Description                                              |
| -------------------------------- | -------------------------------------------------------- |
| `/commit`                        | Commit changes in logical units with meaningful messages |
| `/pull-request`                  | Create or update PR with CHANGELOG-based summary         |
| `/release [major\|minor\|patch]` | Release new marketplace version                          |
| `/ticket <description>`          | Write implementation spec for a feature                  |
| `/drive`                         | Implement queued specs one by one                        |

## Development Workflow

1. **Create specs**: Use `/ticket` to write implementation specs
2. **Implement specs**: Use `/drive` to implement and commit each spec
3. **Create PR**: Use `/pull-request` to create PR with auto-generated summary
4. **Release**: Use `/release` to bump version and publish

## Type Checking

No build step required - this is a configuration/documentation project.

## Version Management

- Marketplace version: `.claude-plugin/marketplace.json`
- Plugin versions: `plugins/<name>/.claude-plugin/plugin.json`
- Keep versions in sync when releasing
