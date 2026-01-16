# CLAUDE.md Structure

Best practices for project CLAUDE.md files.

## When to Propose

- Project has no CLAUDE.md
- Existing CLAUDE.md is incomplete or outdated

## Analysis Steps

1. Check for existing CLAUDE.md
2. Read package.json, Cargo.toml, go.mod for tech stack
3. Read README.md for project description
4. Check existing documentation patterns

## Required Sections

### 1. Written Language

Specify language for all written content:
- Documentation and comments
- Commit messages
- Issues and pull requests

### 2. Project Summary

Brief description of what the project does.

### 3. Tech Stack

- Runtime/language version
- Major frameworks
- Build tools
- Testing tools

### 4. Setup

Commands to get the project running:
- Install dependencies
- Build commands
- Run development server
- Run tests

## Customization Questions

| Question | Options | Default |
|----------|---------|---------|
| Written language | English, Japanese, other | ask user |
| Project summary | from README, custom | from README |
| Additional sections | Commands table, Architecture | none |

## Template

See `../templates/claude-md.md`
