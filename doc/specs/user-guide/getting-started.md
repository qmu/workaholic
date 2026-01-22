---
title: Getting Started
description: Installation and first steps with Workaholic
category: user
last_updated: 2026-01-23
---

# Getting Started

Workaholic is a Claude Code plugin marketplace that provides development workflow commands. This guide covers installation and basic setup.

## Prerequisites

You need Claude Code installed and running. Workaholic is installed through Claude Code's plugin marketplace system.

## Installation

Start Claude Code in your terminal:

```bash
claude
```

Then install the marketplace:

```bash
/plugin marketplace add qmu/workaholic
```

When prompted, choose user scope for personal use. Enabling auto-updates is recommended to receive the latest features and fixes.

## Verification

After installation, the following commands become available:

```bash
/branch       # Create timestamped topic branches
/commit       # Commit with meaningful messages
/pull-request # Create PRs with auto-generated summaries
/ticket       # Write implementation specs
/drive        # Implement tickets one by one
```

## Next Steps

Read the [Command Reference](COMMANDS.md) for detailed documentation on each command, or the [Workflow Guide](WORKFLOW.md) to understand the ticket-driven development approach.
