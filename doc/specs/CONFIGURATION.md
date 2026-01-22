# Configuration

## Marketplace Configuration

**File**: `.claude-plugin/marketplace.json`

| Field       | Type   | Required | Description                |
| ----------- | ------ | -------- | -------------------------- |
| name        | string | Yes      | Marketplace identifier     |
| version     | semver | Yes      | Marketplace version        |
| description | string | Yes      | Human-readable description |
| owner       | object | Yes      | Owner name and email       |
| plugins     | array  | Yes      | List of available plugins  |

## Plugin Configuration

**File**: `plugins/<name>/.claude-plugin/plugin.json`

| Field       | Type   | Required | Description                |
| ----------- | ------ | -------- | -------------------------- |
| name        | string | Yes      | Plugin identifier          |
| version     | semver | Yes      | Plugin version             |
| description | string | Yes      | Human-readable description |
| author      | object | Yes      | Author name and email      |

## Command Configuration

Commands are configured via markdown files in `commands/` directory.

### Commit Command Options

| Option             | Values                       | Default     |
| ------------------ | ---------------------------- | ----------- |
| Formatter          | prettier, eslint --fix, none | prettier    |
| Commit prefixes    | conventional, plain verbs    | plain verbs |
| Ticket workflow    | yes, no                      | no          |
| Co-author          | yes, no                      | yes         |
| Auto-documentation | yes, no                      | yes         |

## Directory Structure

Projects using these plugins should have:

```
.claude/
├── commands/        # Custom slash commands
├── settings.json    # Claude Code settings
└── rules/           # Coding conventions
doc/
├── specs/           # Auto-generated documentation
└── tickets/         # Implementation spec queue
```
