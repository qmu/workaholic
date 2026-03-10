---
created_at: 2026-03-11T01:18:13+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain, Infrastructure]
effort:
commit_hash:
category:
---

# Dev Environment Readiness Validation in Trip Worktree Preparation

## Overview

Enhance the trip command's worktree preparation phase to include full development environment validation and setup before any planning begins. Currently the trip command flow is: create worktree, init trip artifacts, launch Agent Teams (which immediately starts the Planner writing direction). The worktree is created as a bare git checkout with no validation that the development environment inside it is actually functional -- no dependency installation, no environment variable checks, no port conflict detection for concurrent worktrees.

The new flow inserts a validation/preparation step between trip initialization and planning: create worktree, init trip, **validate and prepare dev environment**, then start planning. A new shell script (`validate-dev-env.sh`) checks environment readiness and reports what is missing or misconfigured as structured JSON feedback. The trip command's leader agent uses this feedback to take corrective actions (copy `.env` files from the main worktree, run `npm install`, configure unique ports) before the Planner begins writing direction artifacts. This ensures the Constructor can implement code in Phase 2 without hitting environment failures.

Concurrent worktree isolation is a key concern: multiple trip sessions may run simultaneously in separate worktrees, and the validation must detect and prevent resource conflicts (network ports, lock files, shared state directories).

## Key Files

- `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` - Creates the worktree; currently does not validate the dev environment inside it
- `plugins/trippin/skills/trip-protocol/sh/init-trip.sh` - Initializes trip artifact directories; runs after worktree creation
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill defining worktree isolation and workflow phases; needs a Dev Environment Readiness section
- `plugins/trippin/commands/trip.md` - Trip command orchestration; needs a new Step 3 (validate/prepare dev env) inserted between init trip and Agent Teams launch

## Related History

The trip command was recently implemented and has been iterated on with phase gate synchronization, model-before-design dependency enforcement, commit message rules, and deterministic review conventions. All existing tickets focused on the specification and agent coordination workflow. No ticket has addressed development environment preparation or concurrent worktree isolation at the infrastructure level.

Past tickets that touched similar areas:

- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the trip command including ensure-worktree.sh and init-trip.sh (direct predecessor; the scripts this ticket extends)
- [20260310221131-enforce-phase-gate-synchronization-in-trip.md](.workaholic/tickets/archive/drive-20260310-220224/20260310221131-enforce-phase-gate-synchronization-in-trip.md) - Added phase gate synchronization to the trip workflow (same workflow area; this ticket adds a pre-planning gate)
- [20260310234932-add-e2e-assurance-policy-to-planner.md](.workaholic/tickets/todo/20260310234932-add-e2e-assurance-policy-to-planner.md) - Extends Planner's Phase 2 testing with E2E support; E2E tests require a working dev environment, making this ticket a prerequisite

## Implementation Steps

1. **Create `validate-dev-env.sh` script** (`plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh`): A shell script that validates development environment readiness inside a worktree. Accept the worktree path as an argument. Check for:
   - Existence of `.env` or `.env.local` files (report missing if not found)
   - Existence of `node_modules/` directory (report missing if `package.json` exists but `node_modules/` does not)
   - Existence of other dependency directories as appropriate (e.g., `vendor/` for PHP, `venv/` for Python)
   - Network port conflicts: if the project has configuration files specifying ports (e.g., in `.env`, `package.json` scripts, or config files), check if those ports are already in use by other processes
   - Lock file conflicts: check for stale lock files that could block concurrent execution
   - Output structured JSON with validation results:
     ```json
     {
       "ready": false,
       "checks": [
         {"name": "env_files", "status": "missing", "details": ".env not found", "action": "copy .env from main worktree"},
         {"name": "dependencies", "status": "missing", "details": "node_modules not found", "action": "run npm install"},
         {"name": "ports", "status": "ok", "details": "no port conflicts detected"}
       ]
     }
     ```
   - When all checks pass, return `{"ready": true, "checks": [...]}` with all statuses "ok"

2. **Add a Dev Environment Readiness section to the trip-protocol skill** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Place this after the Worktree Isolation section. Define:
   - **Purpose**: The worktree must have a functional development environment before any specification work begins, so that Phase 2 implementation can proceed without environment-related failures
   - **Concurrent isolation principle**: Each worktree must be fully independent -- no shared network ports, no shared lock files, no shared state directories between concurrent trip sessions
   - **Validation-feedback-action loop**: The validation script reports what is missing, the leader agent takes corrective action, then re-validates until the environment is ready
   - **Script reference**: `bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh <worktree_path>`

3. **Insert Step 3 (Validate/Prepare Dev Environment) into the trip command** (`plugins/trippin/commands/trip.md`): Between the current Step 2 (Initialize Trip Artifacts) and Step 3 (Launch Agent Teams), add a new step:
   - Run `validate-dev-env.sh` with the worktree path
   - Parse the JSON output
   - If `ready` is false, iterate through the `checks` array and take corrective action for each failing check:
     - `env_files` missing: copy `.env` files from the repository root to the worktree
     - `dependencies` missing: run `npm install` (or equivalent) inside the worktree
     - `ports` conflict: modify port configuration in the worktree's `.env` to use non-conflicting ports
   - Re-run validation after corrections
   - Only proceed to Agent Teams launch when `ready` is true
   - Renumber the current Step 3 (Launch Agent Teams) to Step 4 and Step 4 (Present Results) to Step 5

4. **Update the Worktree Isolation section in trip-protocol** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Extend the existing section to mention that worktree creation is only the first part of preparation -- the dev environment inside the worktree must also be validated and configured. Reference the new Dev Environment Readiness section.

## Patches

### `plugins/trippin/commands/trip.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/commands/trip.md
+++ b/plugins/trippin/commands/trip.md
@@ -37,7 +37,25 @@

 Parse the JSON output for `trip_path`. If an error is returned, inform the user and stop.

-### Step 3: Launch Agent Teams
+### Step 3: Validate and Prepare Dev Environment
+
+Validate the development environment inside the worktree:
+
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh "<worktree_path>"
+```
+
+Parse the JSON output. If `ready` is false, take corrective action for each failing check:
+- `env_files` missing: Copy `.env` files from the repository root (`<repo_root>`) to the worktree (`<worktree_path>`)
+- `dependencies` missing: Run the appropriate install command inside the worktree (e.g., `cd <worktree_path> && npm install`)
+- `ports` conflict: Modify port values in the worktree's environment files to avoid conflicts with other running worktrees
+
+After corrections, re-run validation. Repeat until `ready` is true.
+
+If validation cannot be resolved (e.g., no `.env` file exists anywhere to copy), warn the user and proceed with the caveat that Phase 2 implementation may encounter environment issues.
+
+### Step 4: Launch Agent Teams

 Create a three-member Agent Team with the following instruction:
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify exact line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -63,6 +63,30 @@

 All agent work happens inside the worktree directory. After completion, the user can merge the trip branch or inspect changes independently.

+## Dev Environment Readiness
+
+After creating the worktree and initializing trip artifacts, the development environment inside the worktree must be validated and prepared **before** the Planner begins writing any direction artifacts.
+
+```bash
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh <worktree_path>
+```
+
+### Concurrent Isolation
+
+Multiple trip sessions may run simultaneously in separate worktrees. Each worktree must be fully independent:
+- **No shared network ports**: If the project uses specific ports (dev server, database), each worktree must use unique ports
+- **No shared lock files**: Build tools, package managers, and databases may use lock files that conflict across worktrees
+- **No shared state directories**: Caches, temp files, and runtime state must be worktree-local
+
+### Validation-Feedback-Action Loop
+
+The validation script outputs structured JSON indicating what is missing or misconfigured. The leader agent reads this feedback and takes corrective action:
+1. Run validation script
+2. Parse results: if `ready` is true, proceed to planning
+3. If `ready` is false, address each failing check (copy env files, install dependencies, configure ports)
+4. Re-run validation
+5. Repeat until ready or report unresolvable issues to the user
+
 ## Commit-per-Step Rule
```

## Considerations

- The validation script must follow the Shell Script Principle from CLAUDE.md: all conditional logic resides in the shell script, not inline in the command markdown. The trip command only calls the script and parses JSON output. (`plugins/trippin/commands/trip.md`)
- Port conflict detection is environment-dependent. On Linux, the script can check ports using `ss -tlnp` or `lsof -i`. On macOS, `lsof -i -P -n` works. The script should handle both platforms or gracefully skip port checks if the detection tool is unavailable. (`plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh`)
- Copying `.env` files from the repository root to the worktree assumes the repository root has valid `.env` files. If the project uses `.env.example` patterns, the script should detect `.env.example` and report that manual configuration may be needed. (`plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh`)
- The `npm install` corrective action can be slow and produce significant output. The leader agent should run it with appropriate timeout handling. For monorepos with workspaces, a simple `npm install` at the root may not be sufficient. (`plugins/trippin/commands/trip.md`)
- The E2E Assurance Policy ticket (`20260310234932-add-e2e-assurance-policy-to-planner.md`) depends on having a working dev environment. If that ticket is implemented before this one, E2E tests in Phase 2 may fail due to missing dependencies or environment configuration in the worktree. This ticket should ideally be implemented first. (`.workaholic/tickets/todo/20260310234932-add-e2e-assurance-policy-to-planner.md`)
- The script must use the absolute path convention per CLAUDE.md: `bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh`. Never use relative paths. (`plugins/trippin/commands/trip.md`, `plugins/trippin/skills/trip-protocol/SKILL.md`)
- Git worktrees share the same `.git` directory. Operations like `git stash`, `git bisect`, or concurrent `git` commands from multiple worktrees can interfere with each other. The validation script should not attempt git operations beyond reading status. (`plugins/trippin/skills/trip-protocol/sh/validate-dev-env.sh`)
