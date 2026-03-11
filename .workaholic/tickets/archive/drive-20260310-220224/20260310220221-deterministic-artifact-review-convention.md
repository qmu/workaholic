---
created_at: 2026-03-10T22:02:21+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: bfbb625
category: Added
---

# Deterministic Artifact Review Convention for Concurrent Agents

## Overview

Establish a deterministic rule for how reviewer agents interact with artifacts during the trip specification process. Currently, the trip-protocol skill instructs agents to "review" artifacts and "add review notes" but does not prescribe the mechanism. In practice, the Architect created a separate markdown file in the `directions/` directory as feedback, while the Constructor edited the direction file directly. When agents operate concurrently, this inconsistency causes git conflicts and non-deterministic behavior. A single, explicit convention is needed so that all reviewing agents follow the same pattern and avoid concurrent write conflicts on the same file.

## Key Files

- `plugins/trippin/skills/trip-protocol/SKILL.md` - Protocol skill that defines artifact format and review workflow; lacks explicit review feedback convention
- `plugins/trippin/agents/architect.md` - Architect agent definition; references reviewing but does not specify review output format
- `plugins/trippin/agents/constructor.md` - Constructor agent definition; same gap as architect
- `plugins/trippin/agents/planner.md` - Planner agent definition; same gap as architect
- `plugins/trippin/commands/trip.md` - Trip command orchestration; Phase 1 steps 2-3 say "add review notes" without specifying how

## Related History

The trip workflow was implemented in the most recent drive session, establishing the three-agent protocol, worktree isolation, and commit-per-step convention. The review mechanism was left underspecified, and this ticket addresses the gap exposed during actual usage.

Past tickets that touched similar areas:

- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Implemented the entire trip command, agents, and protocol (direct predecessor)

## Implementation Steps

1. **Choose a review convention**: The recommended approach is that reviewers write their feedback as separate files in a `reviews/` subdirectory scoped to the artifact type. For example, when reviewing `directions/direction-v1.md`, the Architect writes `directions/reviews/direction-v1-architect.md` and the Constructor writes `directions/reviews/direction-v1-constructor.md`. This eliminates concurrent write conflicts entirely because each agent writes to a unique file path.

2. **Update the Artifact Format section in trip-protocol** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Add a "Review Artifacts" subsection after the existing Artifact Format section. Define the naming convention (`<artifact-basename>-<agent>.md`), the directory convention (`reviews/` subdirectory), and the content format (assessment, concerns, approval/rejection).

3. **Update the Artifact Storage section in trip-protocol** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Add `reviews/` subdirectories to the storage tree diagram so agents know the full directory structure.

4. **Update the Phase 1 Step 1 section in trip-protocol** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Replace the vague "reviews for X" language with explicit instructions: "Architect writes `directions/reviews/direction-v1-architect.md`" and "Constructor writes `directions/reviews/direction-v1-constructor.md`".

5. **Update the Phase 1 Step 2 section in trip-protocol** (`plugins/trippin/skills/trip-protocol/SKILL.md`): Apply the same pattern for Model and Design cross-reviews.

6. **Add a Review Convention rule to each agent definition** (`plugins/trippin/agents/architect.md`, `plugins/trippin/agents/constructor.md`, `plugins/trippin/agents/planner.md`): Add a "Review Output" section specifying that review feedback is always written to `<artifact-dir>/reviews/<artifact-basename>-<agent>.md`, never by modifying the original artifact or creating files outside the `reviews/` subdirectory.

7. **Clarify artifact ownership**: State explicitly that only the artifact's author agent may modify the original artifact file. Other agents express feedback exclusively through review files. The author then incorporates feedback into the next version (e.g., `direction-v2.md`).

8. **Update the trip command orchestration** (`plugins/trippin/commands/trip.md`): In the Phase 1 instructions within the Agent Teams launch block, replace "add review notes" with the explicit review file convention.

9. **Update init-trip.sh** (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`): Create `reviews/` subdirectories inside `directions/`, `models/`, and `designs/` during trip initialization.

## Patches

### `plugins/trippin/skills/trip-protocol/SKILL.md`

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -69,10 +69,16 @@
 ```
 .workaholic/.trips/<trip-name>/
-  directions/    # Planner's artifacts
-  models/        # Architect's artifacts
-  designs/       # Constructor's artifacts
+  directions/           # Planner's artifacts
+    reviews/            # Review feedback on directions
+  models/               # Architect's artifacts
+    reviews/            # Review feedback on models
+  designs/              # Constructor's artifacts
+    reviews/            # Review feedback on designs
 ```

 Versioning: `direction-v1.md`, `direction-v2.md`, etc. Each revision is a new file, preserving history for review.
```

### `plugins/trippin/skills/trip-protocol/SKILL.md`

> **Note**: This patch is speculative - verify line numbers before applying.

```diff
--- a/plugins/trippin/skills/trip-protocol/SKILL.md
+++ b/plugins/trippin/skills/trip-protocol/SKILL.md
@@ -157,6 +157,28 @@
 <feedback from reviewing agents, added during review>
 ```
+
+## Review Convention
+
+**Rule**: Only the artifact's author may modify the original artifact file. All other agents express feedback through separate review files.
+
+### Review File Convention
+
+When reviewing an artifact, write feedback to a dedicated file in the `reviews/` subdirectory:
+
+```
+<artifact-dir>/reviews/<artifact-basename>-<reviewer-agent>.md
+```
+
+Examples:
+- Architect reviewing direction-v1: `directions/reviews/direction-v1-architect.md`
+- Constructor reviewing direction-v1: `directions/reviews/direction-v1-constructor.md`
+- Planner reviewing model-v1: `models/reviews/model-v1-planner.md`
+
+This ensures:
+- No concurrent write conflicts (each agent writes to a unique path)
+- Clear attribution of feedback
+- Original artifacts remain clean for the author to revise
+
+After reviews are committed, the artifact author reads all review files and incorporates feedback into the next version (e.g., `direction-v2.md`).
```

## Considerations

- The `reviews/` subdirectory convention adds depth to the artifact tree, but keeps the review process deterministic and conflict-free (`plugins/trippin/skills/trip-protocol/SKILL.md`)
- The moderation protocol may also need clarification: when the third agent moderates, should the resolution go into a review file or a new artifact version? The moderator is acting as author of the resolution, so a new version of the contested artifact (authored by the moderator) may be more appropriate (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 142-156)
- The existing "Review Notes" section in the Artifact Format template becomes redundant if reviews are separate files; consider removing it or repurposing it as a summary of incorporated feedback (`plugins/trippin/skills/trip-protocol/SKILL.md` lines 159-176)
- The `init-trip.sh` script currently creates only three directories; it needs to also create `reviews/` subdirectories to prevent agents from needing to `mkdir -p` during reviews (`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`)
- Agent Teams agents may execute concurrently within the same phase step; the convention must account for truly parallel writes, not just sequential reviews with different approaches (`plugins/trippin/commands/trip.md` lines 65-74)

## Final Report

### Changes Made

- **`plugins/trippin/skills/trip-protocol/SKILL.md`**: Updated Artifact Storage tree with `reviews/` subdirectories. Updated Phase 1 Step 1 and Step 2c with explicit review file paths. Added Review Convention section with naming convention, examples, and ownership rule.
- **`plugins/trippin/commands/trip.md`**: Replaced "add review notes" with explicit review file paths in Phase 1 instructions.
- **`plugins/trippin/agents/architect.md`**: Added Review Output section.
- **`plugins/trippin/agents/constructor.md`**: Added Review Output section.
- **`plugins/trippin/agents/planner.md`**: Added Review Output section.
- **`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`**: Updated to create `reviews/` subdirectories during initialization.

### Approach

Separate review files per agent eliminate concurrent write conflicts. Each agent writes to a unique path, and only the artifact author may modify the original file.
