---
created_at: 2026-03-10T22:07:56+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Establish Consistent Commit Message Rules for Trip Command

## Overview

Define and enforce a deterministic, descriptive commit message format for the trip workflow in the Trippin plugin. Currently, the `trip-commit.sh` script produces messages in the format `trip(<agent>): <step>` with the phase in the body. However, the agent name uses lowercase without a standardized prefix convention, and the `<step>` and `<description>` arguments are free-form text with no guidance on what constitutes a good message. This leads to inconsistent commit messages during trip sessions -- some agents may use file names, symbols, or terse labels instead of intuitive descriptions. The commit messages need a clear, enforced format that: identifies the authoring agent with a square-bracket prefix like `[Planner]`, requires a descriptive summary of the committed content, and follows the repository's English language policy.

## Key Files

- `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` - Shell script that constructs the commit message; must be updated to produce the new format
- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill documenting the commit-per-step rule and message format; must reflect the new convention
- `plugins/trippin/commands/trip.md` - Command orchestration referencing the commit rule; must show the updated format in the Agent Teams instructions
- `plugins/trippin/agents/planner.md` - Planner agent definition with commit rule section; must reference updated format
- `plugins/trippin/agents/architect.md` - Architect agent definition with commit rule section; must reference updated format
- `plugins/trippin/agents/constructor.md` - Constructor agent definition with commit rule section; must reference updated format

## Related History

The trip command and its commit infrastructure were implemented recently. The commit message format was defined as `trip(<agent>): <step>` during initial implementation, but the format was intentionally minimal to get the workflow operational. The drivin plugin has undergone multiple iterations of commit message format evolution (structured sections, expanded sections for lead agents), demonstrating that commit message conventions benefit from deliberate design.

Past tickets that touched similar areas:

- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the trip command, agents, protocol, and trip-commit.sh with the initial `trip(<agent>): <step>` format (direct predecessor)
- [20260131145539-structured-commit-messages.md](.workaholic/tickets/archive/feat-20260131-125844/20260131145539-structured-commit-messages.md) - Introduced structured commit message format in drivin (analogous effort for drive workflow)
- [20260210154917-expand-commit-message-sections.md](.workaholic/tickets/archive/drive-20260210-121635/20260210154917-expand-commit-message-sections.md) - Expanded drivin commit message to five sections (shows evolution pattern)
- [20260310220221-deterministic-artifact-review-convention.md](.workaholic/tickets/todo/20260310220221-deterministic-artifact-review-convention.md) - Sibling ticket addressing review artifact conventions in the same trip workflow (related but distinct concern)

## Implementation Steps

1. **Define the new commit message format** in `plugins/trippin/skills/trip-protocol/SKILL.md`: Replace the current `trip(<agent>): <step>` format with `[Agent] Descriptive summary of what was done`. The agent prefix uses capitalized names in square brackets: `[Planner]`, `[Architect]`, `[Constructor]`. The summary must be a human-readable English sentence describing the content of the commit (not a file name or symbol). The body retains the phase information and the optional description for additional context.

2. **Update `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`** to produce the new format:
   - Change the commit message subject line from `trip(${agent}): ${step}` to `[${Agent}] ${description}` where `Agent` is capitalized (first letter uppercase)
   - The `<step>` parameter becomes metadata in the body (e.g., `Step: <step>`)
   - The `<description>` parameter becomes the mandatory subject line content
   - Make `<description>` a required parameter (not optional) and validate it is non-empty
   - Capitalize the agent name for the bracket prefix (planner -> Planner)

3. **Add commit message guidelines to `plugins/trippin/skills/trip-protocol/SKILL.md`**: Add a subsection under "Commit-per-Step Rule" with examples of good and bad commit messages. Good: `[Planner] Define user authentication flow and stakeholder priorities`. Bad: `[Planner] direction-v1.md`. Good: `[Architect] Review direction for semantic consistency and identify type safety gaps`. Bad: `[Architect] review`.

4. **Update the commit rule in each agent definition** (`plugins/trippin/agents/planner.md`, `plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`): Update the example invocation to show the new parameter order and format. Add guidance that the description must be an intuitive English sentence summarizing what was accomplished.

5. **Update the Agent Teams instructions in `plugins/trippin/commands/trip.md`**: Change the commit rule block to show the new format and emphasize that the description argument is mandatory and must be descriptive.

6. **Add language policy reminder**: In the commit message guidelines section of the protocol skill, state explicitly that all commit messages must be written in English per the repository language policy.

## Patches

### `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`

```diff
--- a/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh
+++ b/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh
@@ -1,8 +1,9 @@
 #!/bin/bash
 # Commit a trip workflow step with standardized message format.
-# Usage: bash trip-commit.sh <agent> <phase> <step> [description]
-# Example: bash trip-commit.sh planner specification "write direction v1" "Initial creative direction"
-# Commit message format: trip(<agent>): <step>
-# Body: Phase: <phase>\n<description>
+# Usage: bash trip-commit.sh <agent> <phase> <step> <description>
+# Example: bash trip-commit.sh planner specification "write-direction-v1" "Define initial creative direction based on user requirements"
+# Commit message format: [Agent] <description>
+# Body: Phase: <phase>\nStep: <step>

 set -euo pipefail
@@ -11,7 +12,7 @@
 step="${3:-}"
 description="${4:-}"

-if [ -z "$agent" ] || [ -z "$phase" ] || [ -z "$step" ]; then
-  echo '{"error": "usage: trip-commit.sh <agent> <phase> <step> [description]"}' >&2
+if [ -z "$agent" ] || [ -z "$phase" ] || [ -z "$step" ] || [ -z "$description" ]; then
+  echo '{"error": "usage: trip-commit.sh <agent> <phase> <step> <description>"}' >&2
   exit 1
 fi
@@ -20,14 +21,14 @@
 if ! git diff --quiet HEAD 2>/dev/null || ! git diff --cached --quiet HEAD 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard)" ]; then
   git add -A

-  body="Phase: ${phase}"
-  if [ -n "$description" ]; then
-    body="${body}
-${description}"
-  fi
+  # Capitalize agent name for bracket prefix
+  agent_cap="$(echo "${agent:0:1}" | tr '[:lower:]' '[:upper:]')${agent:1}"
+
+  body="Phase: ${phase}
+Step: ${step}"

   git commit -m "$(cat <<EOF
-trip(${agent}): ${step}
+[${agent_cap}] ${description}

 ${body}
 EOF
```

> **Note**: This patch is speculative - verify exact line numbers before applying.

### `plugins/trippin/skills/trip-protocol/SKILL.md`

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -40,11 +40,33 @@
 ## Commit-per-Step Rule

 **Every discrete workflow step produces a git commit.** The trip branch's commit history is the complete trace of the collaborative process.

 ```bash
-bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh <agent> <phase> <step> [description]
+bash ~/.claude/plugins/marketplaces/workaholic/plugins/trippin/skills/trip-protocol/sh/trip-commit.sh <agent> <phase> <step> <description>
 ```

+### Commit Message Format
+
+```
+[Agent] Descriptive summary of what was done
+
+Phase: <phase>
+Step: <step>
+```
+
+- **Agent prefix**: Capitalized name in square brackets: `[Planner]`, `[Architect]`, `[Constructor]`
+- **Description**: A clear, intuitive English sentence summarizing the content of the commit. Must describe *what was accomplished*, not just name a file or use a symbol.
+- **Language**: All commit messages must be written in English.
+
+### Good and Bad Examples
+
+| Good | Bad |
+| ---- | --- |
+| `[Planner] Define user authentication flow and stakeholder priorities` | `[Planner] direction-v1.md` |
+| `[Architect] Review direction for semantic consistency and identify type safety gaps` | `[Architect] review` |
+| `[Constructor] Design database schema with migration strategy for user accounts` | `[Constructor] design` |
+| `[Planner] Create integration test plan covering authentication edge cases` | `[Planner] test plan` |
+| `[Constructor] Implement login endpoint with JWT token generation` | `[Constructor] impl` |
+
 Commit points in Phase 1 (Specification):
 - Planner writes direction → commit
 - Architect reviews direction → commit
@@ -63,8 +85,6 @@
 - Each iteration fix → commit

-Message format: `trip(<agent>): <step>` with phase in the body.
-
 ## Artifact Storage
```

> **Note**: This patch is speculative - verify exact line numbers before applying.

## Considerations

- The `trip-commit.sh` script currently makes `description` optional (4th positional argument). Making it required is a breaking change for any existing invocations, but since the trip command is new and has only been used in one session, the migration risk is minimal. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` lines 13-17)
- The capitalization logic in bash (`${agent:0:1}` with `tr`) assumes the agent name is a simple ASCII word. This is safe given the three known agent names but should be noted for future extensibility. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
- The existing `trip(<agent>): <step>` format embeds the step identifier in the subject line. The new format moves the step to the body and puts the description in the subject. This changes how `git log --oneline` output reads -- it will show `[Planner] Define user authentication flow...` instead of `trip(planner): write direction v1`. This is intentionally more readable. (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 66)
- The sibling ticket for deterministic artifact review convention may also need updates to commit message examples if it assumes the old format. Coordinate both tickets during implementation. (`.workaholic/tickets/todo/20260310220221-deterministic-artifact-review-convention.md`)
- Agent Teams agents operate in separate context windows and may not consistently follow commit message guidelines despite documentation. The enforcement via the shell script (requiring non-empty description, formatting the bracket prefix automatically) provides a mechanical guarantee that the format is correct even if the agent passes poor content. (`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)
