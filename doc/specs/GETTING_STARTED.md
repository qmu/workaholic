# Getting Started

## Prerequisites

- Claude Code CLI installed
- Git repository

## Installation

First, add the internal marketplace:

```
/plugin marketplace add qmu/cc-market-place-internal
```

Then install the workaholic plugin:

```
/plugin install workaholic@qmu/cc-market-place-internal
```

## First Steps

1. **Run `/workaholic`** to configure your project's `.claude/` directory
2. **Use `/commit`** for structured commits
3. **Use `/ticket`** to create implementation tickets
4. **Use `/drive`** to implement tickets one by one

## Quick Commands

| Command          | Purpose                                 |
| ---------------- | --------------------------------------- |
| `/commit`        | Commit changes with meaningful messages |
| `/pull-request`  | Create PR with auto-generated summary   |
| `/ticket <desc>` | Write implementation ticket             |
| `/drive`         | Implement queued tickets                |
