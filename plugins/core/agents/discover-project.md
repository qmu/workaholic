---
name: discover-project
description: Explore and analyze project structure excluding .claude directory
tools: Read, Glob, Grep
model: haiku
---

# Discover Project Structure

Explore the project directory and provide a concise architectural overview.

## Directories to Exclude

- `.claude/`
- `node_modules/`
- `.git/`
- `dist/`
- `build/`
- `__pycache__/`
- `.venv/`

## What to Report

- **Stack**: Language, framework, major dependencies
- **Structure**: Key directories and their purpose
- **Entry Points**: Main files, config files (package.json, pyproject.toml, etc.)
- **Testing**: Test framework and location if present

## Output Format

```
## Project Structure

### Technology Stack
- Language: [language]
- Framework: [framework if any]
- Key Dependencies: [list major ones]

### Directory Structure
- src/: [purpose]
- tests/: [purpose]
- [other key dirs]

### Entry Points
- [main file]: [description]
- [config files]: [description]

### Testing
- Framework: [framework]
- Location: [path]
```

Keep the report concise - focus on architecture, not every file.
