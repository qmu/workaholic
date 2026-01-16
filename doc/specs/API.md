# API

## Command Interface

Commands are invoked via Claude Code CLI:

```
/<command> [arguments]
```

### /commit

No arguments. Commits all pending changes.

### /pull-request

No arguments. Creates or updates PR for current branch.

### /ticket

```
/ticket <description>
```

- `description`: Feature or task to implement

### /drive

No arguments. Implements next queued ticket.

### /release

```
/release [major|minor|patch]
```

- `major`: Breaking changes (x.0.0)
- `minor`: New features (0.x.0)
- `patch`: Bug fixes (0.0.x)

## Plugin JSON Schema

### marketplace.json

```json
{
  "name": "string",
  "version": "semver",
  "description": "string",
  "owner": { "name": "string", "email": "string" },
  "plugins": [{ "name": "string", "source": "path", ... }]
}
```

### plugin.json

```json
{
  "name": "string",
  "version": "semver",
  "description": "string",
  "author": {
    "name": "string",
    "email": "string"
  }
}
```

## File Conventions

| Path                      | Format   | Purpose             |
| ------------------------- | -------- | ------------------- |
| `commands/*.md`           | Markdown | Command definitions |
| `skills/*/SKILL.md`       | Markdown | Skill metadata      |
| `skills/*/topics/*.md`    | Markdown | Topic guides        |
| `skills/*/templates/*.md` | Markdown | Content templates   |
| `agents/*.md`             | Markdown | Agent prompts       |
