# Architecture

## System Overview

```
workaholic/
├── .claude-plugin/           # Marketplace configuration
│   └── marketplace.json      # Plugin registry
├── plugins/                  # Plugin source directories
│   ├── core/                # Core development plugin
│   │   ├── .claude-plugin/  # Plugin metadata
│   │   ├── commands/        # branch, commit, pull-request
│   │   ├── skills/          # refer-cc-document
│   │   ├── agents/          # discover-project, discover-claude-dir
│   │   └── rules/           # general, typescript
│   └── tdd/                 # Ticket-driven development plugin
│       ├── .claude-plugin/  # Plugin metadata
│       ├── commands/        # ticket, drive
│       └── skills/          # archive-ticket
└── doc/
    ├── specs/               # Auto-generated documentation
    └── tickets/             # Implementation tickets queue
```

## Components

### Marketplace

- **marketplace.json**: Registry of available plugins with metadata
- **Version management**: Semantic versioning for marketplace and plugins

### Plugin Structure

Each plugin is self-contained with:

- **plugin.json**: Name, version, description, author
- **commands/**: Slash command definitions (markdown)
- **skills/**: Skills with scripts and templates
- **agents/**: Agent prompt definitions (core only)
- **rules/**: Coding conventions (core only)

### Documentation Flow

```
Code Changes → /commit → Auto-update doc/specs/ → Commit
```

## Data Flow

1. User runs `/ticket <description>`
2. Agent analyzes codebase, writes ticket to `doc/tickets/`
3. User runs `/drive`
4. Agent implements ticket, commits with `/commit`
5. `/commit` updates `doc/specs/`, archives ticket
