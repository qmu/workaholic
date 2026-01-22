# Features

## Plugin System

| Feature             | Description                              |
| ------------------- | ---------------------------------------- |
| Plugin installation | Install plugins from marketplace via CLI |
| Plugin versioning   | Semantic versioning for plugins          |
| Plugin discovery    | Browse available plugins in marketplace  |

## Core Plugin

Core development commands and project discovery.

### Commands

| Feature         | Description                             |
| --------------- | --------------------------------------- |
| `/branch`       | Create topic branch with timestamp      |
| `/commit`       | Structured commits with formatting      |
| `/pull-request` | PR creation with auto-generated summary |

### Skills

| Skill               | Description                         |
| ------------------- | ----------------------------------- |
| `refer-cc-document` | Reference Claude Code documentation |

### Agents

| Agent                 | Description                               |
| --------------------- | ----------------------------------------- |
| `discover-project`    | Analyze project structure and conventions |
| `discover-claude-dir` | Analyze existing .claude/ configuration   |

### Rules

| Rule            | Description                   |
| --------------- | ----------------------------- |
| `general.md`    | Commit confirmation required  |
| `typescript.md` | TypeScript coding conventions |

## TDD Plugin

Ticket-driven development workflow.

### Commands

| Feature   | Description                           |
| --------- | ------------------------------------- |
| `/ticket` | Implementation ticket generation      |
| `/drive`  | Ticket-driven implementation workflow |

### Skills

| Skill            | Description                                  |
| ---------------- | -------------------------------------------- |
| `archive-ticket` | Format, archive, changelog, commit in one op |

## Auto-Documentation

| Feature                   | Description                                                                                  |
| ------------------------- | -------------------------------------------------------------------------------------------- |
| User docs generation      | GETTING_STARTED, USER_GUIDE, FAQ                                                             |
| Developer docs generation | FEATURES, ARCHITECTURE, NFR, API, DATA_MODEL, CONFIGURATION, SECURITY, TESTING, DEPENDENCIES |
| Incremental updates       | Only modified sections are updated                                                           |
| README index              | Auto-maintained links to all docs                                                            |
