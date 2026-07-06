---
type: Engineering Policy
title: "Command Scripts for Development Tasks"
description: "Consolidating common development operations into runnable scripts so that any team member or AI agent can perform them consistently, and CI invokes the same commands as developers."
resource: https://qmu.co.jp/implementation/command-scripts
tags:
  - implementation
  - command-scripts
---

# Command Scripts for Development Tasks

_Consolidate common development operations into runnable scripts so that any team member — or an AI agent — can perform them consistently without tribal knowledge._

A codebase whose common operations are discoverable only through prior knowledge, chat history, or convention creates a gap between those who know and those who do not. Npm scripts, Makefiles, and Task files close that gap by making the operations explicit, named, and runnable. The secondary benefit is that CI can invoke the same scripts as a developer, rather than maintaining separate procedure in CI YAML, ensuring that local and CI execution paths stay identical.

## Goal (目標)

The situation this policy aims to achieve is one in which the operations a developer regularly needs — build, test, lint, format, start, seed, migrate, deploy — are discoverable from a single place and executable with a short, memorable command.

- `make help` or `npm run` (or equivalent) lists all available operations.
- A developer new to the project can complete the local setup by following the README and running the documented commands, without asking a colleague.
- CI invokes the same commands as a developer, not a separate set of commands maintained in CI YAML.

## Responsibility (責務)

The situation this policy aims to prevent is one in which common operations live only in a contributor's memory or in a chat log, so that performing them requires asking the right person.

States we do not tolerate:

- CI YAML that contains multi-step shell logic not encapsulated in a script. A CI step that is not reproducible locally is a debugging bottleneck.
- Operations that require environment-specific invocations not documented in the scripts. "On macOS you do X, on Linux you do Y" belongs in the script logic, not in a Slack thread.
- A script file that exists but is never run in CI, creating a divergence between documented and actual procedure.

## Practices (実践)

### Define the canonical development operations in a script file

Choose one tool — npm scripts in `package.json`, a `Makefile`, or a `Taskfile.yml` — and use it as the single place to define common operations. For a polyglot repository, a Makefile is often the lowest-common-denominator entry point. Include at minimum: `install`, `build`, `test`, `lint`, `format`, `start`, `migrate`.

### Have CI call the script, not reinvent it

CI configuration (`.github/workflows/*.yml`, etc.) invokes the project's script commands rather than re-implementing their logic inline. A step like `run: make test` is preferable to inlining the test invocation, because it keeps local and CI paths identical.

### Document the scripts in the README

The project README lists the available commands and what they do. The documentation does not need to be exhaustive, but it should cover the operations a developer needs on their first day.

### Related: CI/CD Automation, Coding Standards and Conventions

The CI/CD policy depends on the scripts being reproducible locally — see [CI/CD Automation](/operation/ci-cd.md). Script naming and formatting conventions follow the same standards as code — [Coding Standards and Conventions](/implementation/coding-standards.md).
