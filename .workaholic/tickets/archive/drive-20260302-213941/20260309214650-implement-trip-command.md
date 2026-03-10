---
created_at: 2026-03-09T21:46:50+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort: 0.5h
commit_hash: 35340d7
category: Added
---

# Implement `/trip` Command for Trippin Plugin

## Overview

Implement the `/trip` command in the trippin plugin that launches a Claude Code Agent Teams session with three collaborative agents (Planner, Architect, Constructor). The command orchestrates a two-phase workflow: specification (inner loop) where agents produce and mutually review Direction, Model, and Design artifacts, followed by implementation (outer loop) where they test, build, and review. All artifacts are persisted under `.workaholic/.trips/<trip-name>/`.

The entire trip session runs inside a **git worktree** for isolation. The trip command must first check worktree readiness (ensure the repo is not in a state that prevents worktree creation) and create a dedicated worktree branch before launching the Agent Teams session. An `ensure-worktree.sh` script handles readiness checks and worktree creation.

Every discrete workflow step produces a **git commit** in the worktree branch. This includes artifact creation, reviews, moderation resolutions, test planning, code implementation, code review, and testing. The commit history on the trip branch becomes a complete trace of the collaborative process. A `trip-commit.sh` script standardizes commit messages with agent name and step context.

## Key Files

- `plugins/trippin/commands/trip.md` - Command orchestration (new)
- `plugins/trippin/agents/planner.md` - Planner agent definition (new)
- `plugins/trippin/agents/architect.md` - Architect agent definition (new)
- `plugins/trippin/agents/constructor.md` - Constructor agent definition (new)
- `plugins/trippin/skills/trip-protocol/trip-protocol.md` - Protocol knowledge skill (new)
- `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` - Trip directory initialization script (new)
- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Worktree readiness check and creation script (new)
- `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` - Standardized commit script for trip workflow steps (new)
- `plugins/trippin/.claude-plugin/plugin.json` - Register command (update)
- `plugins/trippin/README.md` - Update documentation (update)
- `plugins/trippin/commands/.gitkeep` - Remove (cleanup)
- `plugins/trippin/agents/.gitkeep` - Remove (cleanup)
- `plugins/trippin/skills/.gitkeep` - Remove (cleanup)

## Related History

The trippin plugin was created as a skeleton in the previous drive session, establishing the directory structure and marketplace registration. The branching skill already supports `trip-*` branch prefixes, indicating the convention was planned from the start.

Past tickets that touched similar areas:

- [20260302215036-create-trippin-plugin-skeleton.md](.workaholic/tickets/archive/drive-20260302-213941/20260302215036-create-trippin-plugin-skeleton.md) - Created the trippin plugin skeleton with empty directories (direct predecessor)
- [20260302215035-rename-core-to-drivin.md](.workaholic/tickets/archive/drive-20260302-213941/20260302215035-rename-core-to-drivin.md) - Renamed core plugin to drivin, establishing the two-plugin marketplace structure

## Implementation Steps

1. **Create the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/trip-protocol.md`):
   - Define the two-phase workflow (Specification inner loop, Implementation outer loop)
   - Document artifact types: Direction (Planner), Model (Architect), Design (Constructor)
   - Document artifact storage structure: `.workaholic/.trips/<trip-name>/directions/`, `models/`, `designs/`
   - Document versioning convention: `direction-v1.md`, `direction-v2.md`, etc.
   - Document the moderation protocol (each agent can mediate between the other two)
   - Document consensus requirements for phase transitions
   - Keep to ~100-150 lines as the comprehensive knowledge layer

2. **Create the ensure-worktree shell script** (`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`):
   - Accept trip name as argument (used as branch name suffix)
   - Check that git is available and the repo is a git repository
   - Check for uncommitted changes that would block worktree creation
   - Create a new branch `trip/<trip-name>` from current HEAD
   - Create a worktree at `.worktrees/trip-<trip-name>/`
   - Output JSON: `{"worktree_path": "...", "branch": "trip/<trip-name>"}`
   - If worktree already exists, return error

3. **Create the init-trip shell script** (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`):
   - Accept trip name as argument
   - Create `.workaholic/.trips/<trip-name>/` with `directions/`, `models/`, `designs/` subdirectories
   - Output JSON with the created path: `{"trip_path": ".workaholic/.trips/<trip-name>"}`
   - Validate trip name (alphanumeric and hyphens only)
   - Check for existing trip directory to prevent overwrites

4. **Create the Planner agent** (`plugins/trippin/agents/planner.md`):
   - Progressive stance ("Extrinsic Idealism")
   - Responsibilities: Creative Direction, Stakeholder Profiling, Explanatory Accountability
   - Phase 1: Produce Direction artifact, review Model and Design from others
   - Phase 2: Create test plan, validate through testing
   - Preload trip-protocol skill
   - Keep to ~20-40 lines (orchestration only)

5. **Create the Architect agent** (`plugins/trippin/agents/architect.md`):
   - Neutral stance ("Structural Idealism")
   - Responsibilities: Semantical Consistency, Static Verification, Accessibility & Accommodability
   - Phase 1: Review Direction, produce Model artifact, review Design
   - Phase 2: Review structural integrity of implementation
   - Preload trip-protocol skill
   - Keep to ~20-40 lines (orchestration only)

6. **Create the Constructor agent** (`plugins/trippin/agents/constructor.md`):
   - Conservative stance ("Intrinsic Idealism")
   - Responsibilities: Sustainable Implementation, Infrastructure Reliability, Delivery Coordination
   - Phase 1: Review Direction, review Model, produce Design artifact
   - Phase 2: Implement the program based on approved artifacts
   - Preload trip-protocol skill
   - Keep to ~20-40 lines (orchestration only)

7. **Create the trip command** (`plugins/trippin/commands/trip.md`):
   - Accept `$ARGUMENT` as the trip instruction/description
   - Generate trip name from timestamp (e.g., `trip-20260309-214650`)
   - Run ensure-worktree.sh to check readiness and create isolated worktree
   - Run init-trip.sh inside the worktree to create artifact directories
   - Launch Agent Teams session with three agents (Planner, Architect, Constructor)
   - Coordinate Phase 1 (specification) then Phase 2 (implementation)
   - Keep to ~50-100 lines (orchestration only)
   - Include frontmatter with `name: trip` and `description`

8. **Update plugin.json** (`plugins/trippin/.claude-plugin/plugin.json`):
   - No schema change needed; commands are auto-discovered from `commands/` directory

9. **Update README.md** (`plugins/trippin/README.md`):
   - Add `/trip` command to the Commands section
   - Add trip-protocol to the Skills section

10. **Remove .gitkeep files** from `commands/`, `agents/`, `skills/` directories since they now contain real files

## Patches

### `plugins/trippin/README.md`

```diff
--- a/plugins/trippin/README.md
+++ b/plugins/trippin/README.md
@@ -4,13 +4,17 @@ AI-oriented exploration and creative development workflow for Claude Code project

 ## Commands

-*No commands yet.*
+| Command | Description |
+| ------- | ----------- |
+| `/trip <instruction>` | Launch Agent Teams session with Planner, Architect, and Constructor |

 ## Skills

-*No skills yet.*
+| Skill | Description |
+| ----- | ----------- |
+| trip-protocol | Two-phase collaborative workflow protocol and artifact conventions |

 ## Rules

-*No rules yet.*
+*No rules yet.*

 ## Installation
```

## Considerations

- The Agent Teams feature is experimental and requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to be enabled in the environment. The command should check for this or document the requirement clearly. (`plugins/trippin/commands/trip.md`)
- The design PDF describes agents communicating through filesystem artifacts rather than the Agent Teams mailbox system. Determine whether to use the native Agent Teams communication primitives (shared task list, mailbox messaging) or the filesystem-based approach described in the design, or a hybrid. (`plugins/trippin/skills/trip-protocol/trip-protocol.md`)
- Agent Teams teammates work independently in their own context windows and cannot directly read each other's context. The filesystem-based artifact exchange aligns well with this constraint since agents can read each other's outputs from `.workaholic/.trips/`. (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`)
- The trip-protocol skill will be preloaded by all three agents, meaning it must be self-contained and not reference drivin-specific skills. Any shared skills (like gather-git-context) would need to use the trippin plugin path. (`plugins/trippin/skills/trip-protocol/trip-protocol.md`)
- Per CLAUDE.md shell script principle, the init-trip.sh script must handle all conditional logic (directory existence checks, name validation) rather than inlining these in the command markdown. (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`)
- The `.workaholic/.trips/` directory does not yet exist and is not tracked in git. The init-trip.sh script should create it, and consider whether trip artifacts should be git-tracked or gitignored. (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`)
- The moderation protocol (third-party arbitration) adds complexity to the command orchestration. The trip command needs clear logic for detecting disagreement between two agents and delegating to the third. This may require additional iteration tracking in the protocol skill. (`plugins/trippin/commands/trip.md` lines related to Phase 1)

## Final Report

### Changes

- Created `plugins/trippin/skills/trip-protocol/SKILL.md` — comprehensive protocol skill (~165 lines) defining the Implosive Structure workflow, worktree isolation, commit-per-step rule, artifact format, moderation protocol, and consensus gates
- Created `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` — initializes `.workaholic/.trips/<trip-name>/` with `directions/`, `models/`, `designs/` subdirectories
- Created `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` — validates git state and creates isolated worktree with `trip/<trip-name>` branch
- Created `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` — standardized commit script with `trip(<agent>): <step>` message format
- Created `plugins/trippin/agents/planner.md` — Progressive/Extrinsic Idealism agent (creative direction, test planning)
- Created `plugins/trippin/agents/architect.md` — Neutral/Structural Idealism agent (semantical consistency, structural review)
- Created `plugins/trippin/agents/constructor.md` — Conservative/Intrinsic Idealism agent (sustainable implementation, delivery)
- Created `plugins/trippin/commands/trip.md` — command orchestration (worktree creation → artifact init → Agent Teams launch with commit-per-step)
- Updated `plugins/trippin/README.md` — added command and skill tables
- Removed `.gitkeep` from `commands/`, `agents/`, `skills/` directories

### Test Plan

- Verified `init-trip.sh` creates correct directory structure and outputs valid JSON
- Verified `ensure-worktree.sh` creates worktree and branch, outputs valid JSON
- Verified worktree cleanup works (remove + branch delete)
- Shell scripts are executable (chmod +x)
