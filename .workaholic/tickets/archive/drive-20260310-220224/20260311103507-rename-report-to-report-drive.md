---
created_at: 2026-03-11T10:35:07+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config]
effort: 0.25h
commit_hash: 4fb48fc
category: Changed
---

# Rename /report to /report-drive in Drivin Plugin

## Overview

Rename the existing `/report` command in the Drivin plugin to `/report-drive`. The command behavior remains identical: bump version, invoke story-writer, generate story, create/update PR. This rename makes room for a companion `/report-trip` command in the Trippin plugin, establishing a naming convention where report commands are namespaced by workflow type.

## Key Files

- `plugins/drivin/commands/report.md` - Rename to `report-drive.md`, update frontmatter `name` and Notice section
- `CLAUDE.md` - Update Commands table, Project Structure comment, Development Workflow step 3
- `README.md` - Update Drivin command table and typical session example
- `plugins/drivin/README.md` - Update Commands table and Workflow section step 3
- `plugins/drivin/rules/general.md` - Update `/report` reference in commit rule
- `plugins/drivin/skills/analyze-viewpoint/SKILL.md` - Update `/report` in slash-command example list
- `plugins/drivin/skills/write-story/SKILL.md` - Update `/report` reference in journey flowchart node label

## Related History

The report command has been through multiple naming iterations: `/pull-request` to `/report` to `/story` and back to `/report`. Each rename followed the same pattern of updating the command file plus cascading reference updates across documentation and rules, while leaving historical archives untouched.

Past tickets that touched similar areas:

- [20260203180235-rename-story-to-report.md](.workaholic/tickets/archive/drive-20260203-122444/20260203180235-rename-story-to-report.md) - Most recent rename of this command (/story to /report); identical pattern of file rename plus documentation sweep
- [20260129003905-rename-report-to-story.md](.workaholic/tickets/archive/feat-20260128-220712/20260129003905-rename-report-to-story.md) - Previous rename (/report to /story)
- [20260127014257-rename-pull-request-to-report.md](.workaholic/tickets/archive/feat-20260126-214833/20260127014257-rename-pull-request-to-report.md) - First rename (/pull-request to /report)
- [20260302215035-rename-core-to-drivin.md](.workaholic/tickets/archive/drive-20260302-213941/20260302215035-rename-core-to-drivin.md) - Plugin directory rename with same cascading reference update pattern

## Implementation Steps

1. Rename the command file:
   - `git mv plugins/drivin/commands/report.md plugins/drivin/commands/report-drive.md`

2. Update `plugins/drivin/commands/report-drive.md`:
   - Change frontmatter `name: report` to `name: report-drive`
   - Update H1 heading from `# Report` to `# Report Drive`
   - Update Notice section to reference `/report-drive` instead of `/report`

3. Update `CLAUDE.md`:
   - Change `/report` to `/report-drive` in the Commands table
   - Update Project Structure comment: `commands/` line from `ticket, drive, story, report` to `ticket, drive, report-drive`
   - Update Development Workflow step 3 to reference `/report-drive`

4. Update `README.md`:
   - Change `/report` to `/report-drive` in the Drivin command table
   - Update typical session example to use `/report-drive`
   - Update "How It Works" Drivin section to reference `/report-drive`

5. Update `plugins/drivin/README.md`:
   - Change `/report` to `/report-drive` in the Commands table
   - Update Workflow section step 3 to reference `/report-drive`

6. Update `plugins/drivin/rules/general.md`:
   - Change `/report` to `/report-drive` in the commit rule parenthetical

7. Update `plugins/drivin/skills/analyze-viewpoint/SKILL.md`:
   - Change `/report` to `/report-drive` in the slash-command example list

8. Update `plugins/drivin/skills/write-story/SKILL.md`:
   - Change `/report` to `/report-drive` in the flowchart node label (line 60: `c3[Rename to /report]`)

## Patches

### `plugins/drivin/commands/report.md` (rename to report-drive.md)

```diff
--- a/plugins/drivin/commands/report.md
+++ b/plugins/drivin/commands/report-drive.md
@@ -1,10 +1,10 @@
 ---
-name: report
+name: report-drive
 description: Generate story and create/update a pull request.
 ---

-# Report
+# Report Drive

-**Notice:** When user input contains `/report` - whether "run /report", "do /report", "update /report", or similar - they likely want this command.
+**Notice:** When user input contains `/report-drive` - whether "run /report-drive", "do /report-drive", "update /report-drive", or similar - they likely want this command.

 Generate story and create or update a pull request for the current branch.
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -27,7 +27,7 @@
   drivin/                # Drivin development plugin
     .claude-plugin/      # Plugin configuration
     agents/              # performance-analyst
-    commands/            # ticket, drive, story, report
+    commands/            # ticket, drive, report-drive
     rules/               # general, typescript
     skills/              # archive-ticket
@@ -115,7 +115,7 @@
 | `/ticket <description>`          | Write implementation spec for a feature          |
 | `/drive`                         | Implement queued specs one by one                |
 | `/scan`                          | Full documentation scan (all 14 agents)          |
-| `/report`                        | Generate story and create/update PR              |
+| `/report-drive`                  | Generate story and create/update PR              |
 | `/release [major\|minor\|patch]` | Release new marketplace version                  |

 ## Development Workflow
@@ -123,7 +123,7 @@
 1. **Create specs**: Use `/ticket` to write implementation specs
 2. **Implement specs**: Use `/drive` to implement and commit each spec
-3. **Create PR**: Use `/report` to generate story and create PR
+3. **Create PR**: Use `/report-drive` to generate story and create PR
 4. **Release**: Use `/release` to bump version and publish
```

### `plugins/drivin/rules/general.md`

```diff
--- a/plugins/drivin/rules/general.md
+++ b/plugins/drivin/rules/general.md
@@ -5,7 +5,7 @@

 # General Rules

-- **Never commit without explicit user request** - Only create git commits when executing a command that has commit steps (`/drive`, `/report`)
+- **Never commit without explicit user request** - Only create git commits when executing a command that has commit steps (`/drive`, `/report-drive`)
 - **Never use `git -C`** - Run git commands from the working directory, not with `-C` flag
```

### `README.md`

```diff
--- a/README.md
+++ b/README.md
@@ -25,7 +25,7 @@
 | `/ticket`  | Plan a change with context and steps          |
 | `/drive`   | Implement queued tickets one by one           |
 | `/scan`    | Full documentation scan                       |
-| `/report`  | Generate story and create PR                  |
+| `/report-drive` | Generate story and create PR             |

 **Typical session:**

@@ -35,7 +35,7 @@
 /drive                            # implement both, confirm each
 /ticket fix flash of light theme on page load
 /drive                            # fix discovered issue
-/report                           # generate story + create PR
+/report-drive                     # generate story + create PR
 ```
@@ -69,7 +69,7 @@
-When ready to deliver, `/report` generates changelogs and PR descriptions from the accumulated ticket history.
+When ready to deliver, `/report-drive` generates changelogs and PR descriptions from the accumulated ticket history.
```

### `plugins/drivin/README.md`

```diff
--- a/plugins/drivin/README.md
+++ b/plugins/drivin/README.md
@@ -22,7 +22,7 @@
 | `/ticket <description>` | Explore codebase and write implementation ticket (auto-creates branch on main)   |
 | `/drive`                | Implement tickets from .workaholic/tickets/ one by one, commit each, and archive |
 | `/scan`                 | Full documentation scan (all 17 agents)                                          |
-| `/report`               | Generate story and create/update pull request                                    |
+| `/report-drive`         | Generate story and create/update pull request                                    |

@@ -48,7 +48,7 @@
 1. **Plan work**: Use `/ticket` to write implementation specs (auto-creates branch on main)
 2. **Implement tickets**: Use `/drive` to implement and commit each ticket
-3. **Create PR**: Use `/report` to generate story and create PR
+3. **Create PR**: Use `/report-drive` to generate story and create PR
```

## Considerations

- This is the fourth name change for this command (`/pull-request` -> `/report` -> `/story` -> `/report` -> `/report-drive`). The naming convention should be considered stable going forward. (`plugins/drivin/commands/report-drive.md`)
- Subagent names (`story-writer`, `pr-creator`, etc.) and skill names (`write-story`, `create-pr`) remain unchanged since they are internal implementation details. (`plugins/drivin/agents/story-writer.md`, `plugins/drivin/skills/write-story/SKILL.md`)
- The `stories/` directory and story file format remain unchanged. (`plugins/drivin/skills/write-story/SKILL.md`)
- Historical references in archived tickets and stories should NOT be updated since they document past work accurately. (`.workaholic/tickets/archive/`, `.workaholic/stories/`)
- The companion ticket for `/report-trip` in the Trippin plugin should be implemented after this rename to avoid confusion about which command is `/report`. (`.workaholic/tickets/todo/20260311103508-add-report-trip-command.md`)

## Final Report

### Changes Made

- **`plugins/drivin/commands/report.md`** → **`report-drive.md`**: Renamed file, updated frontmatter name and Notice section.
- **`CLAUDE.md`**: Updated Commands table, Project Structure comment, and Development Workflow step 3.
- **`README.md`**: Updated Drivin command table, typical session example, and How It Works section.
- **`plugins/drivin/README.md`**: Updated Commands table and Workflow section.
- **`plugins/drivin/rules/general.md`**: Updated commit rule parenthetical.
- **`plugins/drivin/skills/write-story/SKILL.md`**: Updated flowchart node label.
- **`plugins/drivin/skills/analyze-viewpoint/SKILL.md`**: Updated slash-command example list.

### Approach

Straight file rename plus cascading reference sweep. Internal names (story-writer, write-story, etc.) left unchanged. Historical archives untouched.
