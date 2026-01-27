---
title: Getting Started
description: Installation and first steps with Workaholic
category: user
modified_at: 2026-01-28T01:00:15+09:00
commit_hash: 88b4b18
---

[English](getting-started.md) | [日本語](getting-started_ja.md)

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
/branch         # Create timestamped topic branches
/ticket         # Write implementation specs
/drive          # Implement tickets one by one
/report         # Generate docs and create PRs
```

## Next Steps

Read the [Command Reference](commands.md) for detailed documentation on each command, or the [Workflow Guide](workflow.md) to understand the ticket-driven development approach.
