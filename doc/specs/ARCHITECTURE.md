# Architecture

## System Overview

```
cc-market-place-internal/
├── .claude-plugin/           # Marketplace configuration
│   └── marketplace.json      # Plugin registry
├── plugins/                  # Plugin source directories
│   └── workaholic/          # Workaholic plugin
│       ├── .claude-plugin/  # Plugin metadata
│       ├── commands/        # Slash commands
│       ├── skills/          # Reference skills
│       └── agents/          # Agent definitions
└── doc/
    ├── specs/               # Auto-generated documentation
    └── tickets/             # Implementation tickets queue
```

## Components

### Marketplace

- **marketplace.json**: Registry of available plugins with metadata
- **Version management**: Semantic versioning for marketplace and plugins

### Plugin Structure

Each plugin contains:

- **plugin.json**: Name, version, description, author
- **commands/**: Slash command definitions (markdown)
- **skills/**: Reference skills with topics and templates
- **agents/**: Agent prompt definitions

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
