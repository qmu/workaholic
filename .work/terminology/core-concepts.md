---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-01-23
commit_hash: a0b2b29
---

# Core Concepts

Fundamental building blocks of the Workaholic plugin system.

## plugin

A modular collection of commands, skills, and rules that extends Claude Code functionality.

### Definition

A plugin packages related functionality into a single distributable unit. Each plugin has its own directory under `plugins/` containing a `.claude-plugin/` configuration folder with `plugin.json` metadata. Plugins can define commands (user-invocable), skills (helper routines), and rules (guidelines).

### Usage Patterns

- **Directory names**: `plugins/core/`, `plugins/tdd/`
- **File names**: `plugins/<name>/.claude-plugin/plugin.json`
- **Code references**: "Install the tdd plugin", "Core plugin commands"

### Related Terms

- command, skill, rule

## command

A user-invocable slash command that performs a specific task.

### Definition

Commands are the primary user interface for plugins. Users invoke them with a slash prefix (e.g., `/commit`, `/ticket`). Each command has a markdown file in the plugin's `commands/` directory that defines its behavior and instructions.

### Usage Patterns

- **Directory names**: `plugins/<name>/commands/`
- **File names**: `commit.md`, `pull-request.md`, `sync-doc-specs.md`
- **Code references**: "Run `/commit` to...", "The `/ticket` command..."

### Related Terms

- skill, plugin

## skill

A helper sub-routine that is not directly user-invocable.

### Definition

Skills are internal routines that support commands or other operations. Unlike commands, users cannot invoke skills directly with a slash prefix. They are typically called by commands or triggered automatically. Skills are defined in a plugin's `skills/` directory.

### Usage Patterns

- **Directory names**: `plugins/<name>/skills/`
- **File names**: `archive-ticket.md`
- **Code references**: "The archive-ticket skill handles..."

### Related Terms

- command, plugin

## rule

Guidelines and constraints that shape Claude's behavior within a plugin context.

### Definition

Rules provide persistent guidelines that Claude follows when working within a plugin's scope. They define coding standards, documentation requirements, or behavioral constraints. Rules are stored in a plugin's `rules/` directory.

### Usage Patterns

- **Directory names**: `plugins/<name>/rules/`
- **File names**: `general.md`, `typescript.md`
- **Code references**: "Following the general rule..."

### Related Terms

- plugin, command
