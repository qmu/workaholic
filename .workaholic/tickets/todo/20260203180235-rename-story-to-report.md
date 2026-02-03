---
created_at: 2026-02-03T18:02:35+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Rename /story to /report

## Overview

Rename the `/story` command to `/report`. This reverses the Jan 29 rename (`/report` -> `/story`). The command has been through three naming iterations: `/pull-request` -> `/report` -> `/story`. Reverting to `/report` suggests the documentation/reporting aspect is more intuitive than the narrative/story framing.

## Key Files

- `plugins/core/commands/story.md` - Rename to `report.md` and update frontmatter/headings
- `README.md` - Update command table and workflow examples
- `CLAUDE.md` - Update Commands table, Project Structure, and Development Workflow section
- `plugins/core/README.md` - Update command table and workflow references
- `.workaholic/guides/commands.md` - Update section header and content
- `.workaholic/guides/commands_ja.md` - Update Japanese version
- `plugins/core/agents/ticket-organizer.md` - Update reference to story-moderator context if any

## Related History

This command has evolved through three naming iterations, each reflecting different emphasis: PR creation, documentation generation, and narrative. This rename returns to the middle ground.

Past tickets that touched similar areas:

- [20260129003905-rename-report-to-story.md](.workaholic/tickets/archive/feat-20260128-220712/20260129003905-rename-report-to-story.md) - Previous rename of this command (/report -> /story)
- [20260127014257-rename-pull-request-to-report.md](.workaholic/tickets/archive/feat-20260126-214833/20260127014257-rename-pull-request-to-report.md) - First rename of this command (/pull-request -> /report)
- [20260203144736-correct-story-workflow-mappings.md](.workaholic/tickets/archive/drive-20260203-122444/20260203144736-correct-story-workflow-mappings.md) - Recent work on story command workflows

## Implementation Steps

1. Rename command file:
   - `mv plugins/core/commands/story.md plugins/core/commands/report.md`

2. Update `plugins/core/commands/report.md`:
   - Change frontmatter `name: story` to `name: report`
   - Update H1 heading from "# Story" to "# Report"
   - Update Notice section to reference `/report` instead of `/story`

3. Update `README.md`:
   - Change `/story` to `/report` in Quick Start command table
   - Update Typical Session example

4. Update `CLAUDE.md`:
   - Change `/story` to `/report` in Commands table
   - Update Project Structure comment (commands: ticket, drive, report)
   - Update Development Workflow step 3

5. Update `plugins/core/README.md`:
   - Change `/story` to `/report` in Commands table
   - Update Workflow section step 3

6. Update `.workaholic/guides/commands.md`:
   - Rename section header from `### /story` to `### /report`
   - Update command description and usage examples
   - Update Workflow Summary references

7. Update `.workaholic/guides/commands_ja.md`:
   - Rename section header from `### /story` to `### /report`
   - Update command description and usage examples
   - Update Workflow Summary references

## Patches

### `plugins/core/commands/story.md` (rename to report.md)

```diff
--- a/plugins/core/commands/story.md
+++ b/plugins/core/commands/report.md
@@ -1,11 +1,11 @@
 ---
-name: story
+name: report
 description: Generate documentation (changelog, story, specs, terms) and create/update a pull request.
 ---

-# Story
+# Report

-**Notice:** When user input contains `/story` - whether "run /story", "do /story", "update /story", or similar - they likely want this command.
+**Notice:** When user input contains `/report` - whether "run /report", "do /report", "update /report", or similar - they likely want this command.

 Generate comprehensive documentation and create or update a pull request for the current branch.
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -24,7 +24,7 @@ plugins/                 # Plugin source directories
   core/                  # Core development plugin
     .claude-plugin/      # Plugin configuration
     agents/              # performance-analyst
-    commands/            # ticket, drive, story
+    commands/            # ticket, drive, report
     rules/               # general, typescript
     skills/              # archive-ticket
 ```
@@ -68,7 +68,7 @@ Skills are the knowledge layer. Commands and subagents are the orchestration lay
 | -------------------------------- | ------------------------------------------------ |
 | `/ticket <description>`          | Write implementation spec for a feature          |
 | `/drive`                         | Implement queued specs one by one                |
-| `/story`                         | Generate documentation and create/update PR      |
+| `/report`                        | Generate documentation and create/update PR      |
 | `/release [major\|minor\|patch]` | Release new marketplace version                  |

 ## Development Workflow
@@ -76,7 +76,7 @@ Skills are the knowledge layer. Commands and subagents are the orchestration lay
 1. **Create specs**: Use `/ticket` to write implementation specs
 2. **Implement specs**: Use `/drive` to implement and commit each spec
-3. **Create PR**: Use `/story` to generate documentation and create PR
+3. **Create PR**: Use `/report` to generate documentation and create PR
 4. **Release**: Use `/release` to bump version and publish
```

### `README.md`

```diff
--- a/README.md
+++ b/README.md
@@ -31,7 +31,7 @@ Enable the plugin after installation. Auto update is recommended.
 | Command   | What it does                         |
 | --------- | ------------------------------------ |
 | `/ticket` | Plan a change with context and steps |
 | `/drive`  | Implement queued tickets one by one  |
-| `/story`  | Generate docs and create PR          |
+| `/report` | Generate docs and create PR          |

 ### Typical Session
@@ -41,9 +41,9 @@ Enable the plugin after installation. Auto update is recommended.
 /ticket support system preference detection
 /drive                            # implement both, confirm each
 /ticket fix flash of light theme on page load
 /drive                            # fix discovered issue
-/story                            # PR with feature + fix documented
+/report                           # PR with feature + fix documented
 ```
```

### `plugins/core/README.md`

```diff
--- a/plugins/core/README.md
+++ b/plugins/core/README.md
@@ -20,7 +20,7 @@ Each artifact reduces this load:
 | Command                 | Description                                                                      |
 | ----------------------- | -------------------------------------------------------------------------------- |
 | `/ticket <description>` | Explore codebase and write implementation ticket (auto-creates branch on main)   |
 | `/drive`                | Implement tickets from .workaholic/tickets/ one by one, commit each, and archive |
-| `/story`                | Generate documentation and create/update pull request                            |
+| `/report`               | Generate documentation and create/update pull request                            |

 ## Agents
@@ -47,7 +47,7 @@ Each artifact reduces this load:

 1. **Plan work**: Use `/ticket` to write implementation specs (auto-creates branch on main)
 2. **Implement tickets**: Use `/drive` to implement and commit each ticket
-3. **Create PR**: Use `/story` to generate documentation and create PR
+3. **Create PR**: Use `/report` to generate documentation and create PR
```

## Considerations

- **Breaking change**: Users familiar with `/story` will need to learn the new `/report` command name
- Subagent names (`story-writer`, `story-moderator`, etc.) remain unchanged - they are internal implementation details that don't need to match the command name
- Skill names (`write-story`) remain unchanged - they describe what they do, not the command that invokes them
- The `stories/` directory remains unchanged - it describes the content type (branch narratives), not the command
- Historical tickets and stories in archive should NOT be updated - they document past work accurately
