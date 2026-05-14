---
created_at: 2026-05-14T14:13:39+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Unify `gather-git-context` and `gather-ticket-metadata` into a Single `gather` Skill

## Overview

Two skills under `plugins/core/skills/` -- `gather-git-context` and `gather-ticket-metadata` -- exist solely as tiny JSON-emitting shell probes. Each consists of one SKILL.md whose body is essentially "run this script and parse its JSON" and one `scripts/gather.sh`. They share no substantive instructional content, but they share a purpose (gather context for the work flow), they're often consumed together (story-writer + ticket-organizer chains preload them in tandem), and they bloat both the `plugins/core/skills/` directory listing and the CLAUDE.md "Common Operations" table with parallel rows that say the same thing.

Collapse them into one skill `plugins/core/skills/gather/` containing both scripts. Both scripts keep their behavior verbatim; only their location and frontmatter labels change. After this refactor, an agent that previously preloaded `core:gather-git-context` and/or `core:gather-ticket-metadata` instead preloads `core:gather`, and call sites switch from `…/skills/gather-{git-context,ticket-metadata}/scripts/gather.sh` to `…/skills/gather/scripts/{git-context,ticket-metadata}.sh`.

The two `gather-*/scripts/gather.sh` filenames collide once moved into a single directory, so the script files are also renamed to drop the now-redundant `gather-` prefix and the redundant `gather.sh` basename: `git-context.sh` and `ticket-metadata.sh`.

This is purely mechanical -- behavior is preserved exactly. The win is one fewer skill directory, one consolidated CLAUDE.md row, and one preload entry instead of two wherever both are currently listed (none today, but the door is open for new callers).

## Key Files

The change set is exhaustive. Every entry below is a live (non-archive) reference that must be updated.

### Files being moved/renamed/deleted

- `plugins/core/skills/gather-git-context/SKILL.md` -- 39 lines; absorbed into the new `plugins/core/skills/gather/SKILL.md` and then the original is deleted.
- `plugins/core/skills/gather-git-context/scripts/gather.sh` -- 38 lines; moved to `plugins/core/skills/gather/scripts/git-context.sh` verbatim (no script-body changes; no internal references to the old path exist).
- `plugins/core/skills/gather-ticket-metadata/SKILL.md` -- 34 lines; absorbed into the new `plugins/core/skills/gather/SKILL.md` and then the original is deleted.
- `plugins/core/skills/gather-ticket-metadata/scripts/gather.sh` -- 18 lines; moved to `plugins/core/skills/gather/scripts/ticket-metadata.sh` verbatim.
- `plugins/core/skills/gather-git-context/` and `plugins/core/skills/gather-ticket-metadata/` -- both directories deleted entirely after their content is migrated.

### Files being created

- `plugins/core/skills/gather/SKILL.md` -- new combined skill page documenting both scripts and their JSON outputs.
- `plugins/core/skills/gather/scripts/git-context.sh` -- renamed move target (content unchanged).
- `plugins/core/skills/gather/scripts/ticket-metadata.sh` -- renamed move target (content unchanged).

### Caller files (script path references)

- `plugins/core/skills/create-ticket/SKILL.md` line 18 -- `${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh` becomes `${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh`.
- `CLAUDE.md` line 70 -- the "Ticket metadata" row's Usage column carries the same path and is updated identically.
- `CLAUDE.md` line 69 -- the "Git context" row carries `${CLAUDE_PLUGIN_ROOT}/skills/gather-git-context/scripts/gather.sh` and becomes `${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh`.
- `CLAUDE.md` line 106 -- example of a wrong relative path. Update from `bash .claude/skills/gather-ticket-metadata/scripts/gather.sh` to `bash .claude/skills/gather/scripts/ticket-metadata.sh` to keep the contrast example in sync (the line is illustrative of a bad pattern, not a live call site, but the basename should still match the post-refactor reality).
- `CLAUDE.md` line 111 -- the matching "correct" example, update from `${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh` to `${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh`.

### Caller files (frontmatter `skills:` references)

- `plugins/core/skills/create-ticket/SKILL.md` line 5 -- `- gather-ticket-metadata` becomes `- gather` (same-plugin reference; no prefix).
- `plugins/work/agents/ticket-organizer.md` line 9 -- `- core:gather-ticket-metadata` becomes `- core:gather`.
- `plugins/work/agents/performance-analyst.md` line 5 -- `- core:gather-git-context` becomes `- core:gather`.
- `plugins/work/agents/story-writer.md` line 6 -- `- core:gather-git-context` becomes `- core:gather`.

No agent currently preloads both, so no dedup is needed. (A future agent that wants both would now just preload `core:gather` once.)

### Caller files (prose references)

- `plugins/work/agents/performance-analyst.md` line 15 -- `"Gather context using the preloaded gather-git-context skill"` becomes `"Gather context using the preloaded gather skill"`.
- `plugins/work/agents/story-writer.md` line 18 -- `"Gather all context using the preloaded gather-git-context skill. Returns: branch, base_branch, repo_url, archived_tickets, git_log."` becomes `"Gather all context using the preloaded gather skill (git-context.sh). Returns: …"` so it's still clear which script to invoke.
- `plugins/work/commands/drive.md` line 91 -- `"and <repo-url> comes from the gather-git-context output."` becomes `"and <repo-url> comes from the gather skill's git-context.sh output."`.

### Documentation block updates

- `CLAUDE.md` line 20 (Project Structure, core skills listing) -- currently lists both `gather-git-context, gather-ticket-metadata`; replace those two entries with a single `gather`. Keep alphabetical ordering: `… discover, drive, gather, report, …`.
- `CLAUDE.md` lines 67-71 (Common Operations table) -- collapse the two rows into one. Preferred form: a single row covering both scripts (see Patches).

### Files intentionally not touched

- `.workaholic/policies/*.md`, `.workaholic/specs/*.md`, `.workaholic/stories/*.md`, `.workaholic/release-notes/*.md`, `CHANGELOG.md`, and everything under `.workaholic/tickets/archive/` -- these are historical record. The next `/report` run regenerates `.workaholic/stories/` and `.workaholic/release-notes/`. The `.workaholic/specs/` and `.workaholic/policies/` paths are regenerated by their own writer flows. Archived tickets are immutable history. No edits to any of these are part of this ticket.

## Related History

Two recent precedents establish the exhaustive-inventory-with-patches style for mechanical migrations of this kind, and one establishes the consolidation precedent within `plugins/core/skills/`.

- [20260514130950-move-non-leading-skills-to-core.md](.workaholic/tickets/archive/work-20260417-092936/20260514130950-move-non-leading-skills-to-core.md) - Same shape: enumerate every caller, update frontmatter and script paths in lockstep, list every documentation block that mentions the old names. Use as the structural template.
- [20260514130949-move-standards-agents-to-work.md](.workaholic/tickets/archive/work-20260417-092936/20260514130949-move-standards-agents-to-work.md) - Same author within the same branch; cited by the user as the reference template for "exhaustive Key Files inventory + Patches."
- [20260330210138-consolidate-drivin-skills.md](.workaholic/tickets/archive/drive-20260329-173608/20260330210138-consolidate-drivin-skills.md) - Within-plugin skill consolidation precedent in `plugins/drivin/skills/` (since renamed). Confirms that merging related skills inside one plugin is a sanctioned move.
- [20260330201937-consolidate-generic-skills-to-core.md](.workaholic/tickets/archive/drive-20260329-173608/20260330201937-consolidate-generic-skills-to-core.md) - The migration that originally placed both `gather-git-context` and `gather-ticket-metadata` in `plugins/core/skills/` (where this ticket finds them).
- [20260202182054-gather-ticket-metadata-skill.md](.workaholic/tickets/archive/drive-20260202-134332/20260202182054-gather-ticket-metadata-skill.md) - The original creation of the `gather-ticket-metadata` skill (touches the same files).

## Implementation Steps

1. **Create the new directory structure.**
   - `mkdir -p plugins/core/skills/gather/scripts`.
2. **Move the scripts (preserving git history with `git mv`).**
   - `git mv plugins/core/skills/gather-git-context/scripts/gather.sh plugins/core/skills/gather/scripts/git-context.sh`
   - `git mv plugins/core/skills/gather-ticket-metadata/scripts/gather.sh plugins/core/skills/gather/scripts/ticket-metadata.sh`
   - Do not edit the script bodies. They have no self-references to their old paths (verified during ticket authoring) and behave identically from the new location.
3. **Write the combined `plugins/core/skills/gather/SKILL.md`.** Frontmatter `name: gather`, `description: Gather git context and ticket metadata in single calls`, `allowed-tools: Bash`, `user-invocable: false`. Body documents both scripts, each with a Usage code block and a Fields table, under separate `## Git Context` and `## Ticket Metadata` headings. Pattern after the existing two SKILL.md files; do not invent new content. See Patches for the exact body.
4. **Delete the old SKILL.md files and their now-empty parent directories.**
   - `git rm plugins/core/skills/gather-git-context/SKILL.md`
   - `git rm plugins/core/skills/gather-ticket-metadata/SKILL.md`
   - `rmdir plugins/core/skills/gather-git-context/scripts plugins/core/skills/gather-git-context plugins/core/skills/gather-ticket-metadata/scripts plugins/core/skills/gather-ticket-metadata`
5. **Update frontmatter `skills:` preloads** in each of:
   - `plugins/core/skills/create-ticket/SKILL.md` -- `- gather-ticket-metadata` -> `- gather`
   - `plugins/work/agents/ticket-organizer.md` -- `- core:gather-ticket-metadata` -> `- core:gather`
   - `plugins/work/agents/performance-analyst.md` -- `- core:gather-git-context` -> `- core:gather`
   - `plugins/work/agents/story-writer.md` -- `- core:gather-git-context` -> `- core:gather`
6. **Update script-path references** in each of:
   - `plugins/core/skills/create-ticket/SKILL.md` -- `${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh` -> `${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh`
   - `CLAUDE.md` four locations enumerated in Key Files above.
7. **Update prose mentions** in `performance-analyst.md`, `story-writer.md`, and `drive.md` (see Key Files for the exact phrasings).
8. **Update CLAUDE.md Project Structure block** (line 20) -- replace `gather-git-context, gather-ticket-metadata` with a single `gather`. Keep alphabetical ordering.
9. **Update CLAUDE.md Common Operations table** (lines 67-71) -- collapse the two rows into one row pointing at the new skill, but listing both script paths so the table still answers "where do I find each operation?" (See Patches for the exact form.)
10. **Verification.** Run, from repo root:
    - `grep -rn "gather-git-context\|gather-ticket-metadata" plugins/ CLAUDE.md` -- expect zero matches in `plugins/` and `CLAUDE.md`. Matches under `.workaholic/` and `CHANGELOG.md` are historical and expected (and not in scope).
    - `grep -rn "skills/gather/scripts/" plugins/ CLAUDE.md` -- expect at least: 1 in `plugins/core/skills/create-ticket/SKILL.md`, 1 in `plugins/core/skills/gather/SKILL.md` (the Usage example), and 2-4 in `CLAUDE.md` (table row + example block).
    - `grep -rn "core:gather" plugins/work/agents/` -- expect `ticket-organizer.md`, `performance-analyst.md`, `story-writer.md`, each with a single `core:gather` entry.
    - `bash plugins/core/skills/gather/scripts/git-context.sh` and `bash plugins/core/skills/gather/scripts/ticket-metadata.sh` -- both should emit the same JSON they did before the move.

## Patches

> **Note**: All patches below are concrete and apply against the current `work-20260417-092936` branch. Line numbers are valid at ticket-authoring time and may drift if other changes land first.

### `plugins/core/skills/gather/SKILL.md` (new file)

```diff
--- /dev/null
+++ b/plugins/core/skills/gather/SKILL.md
@@ -0,0 +1,52 @@
+---
+name: gather
+description: Gather git context and ticket metadata in single calls.
+allowed-tools: Bash
+user-invocable: false
+---
+
+# Gather
+
+Bundled probes that emit JSON for the work flow. Each script is independent; preload this skill once and call whichever script you need.
+
+## Git Context
+
+Gathers all context needed for documentation subagents in a single shell script call.
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh
+```
+
+Output:
+
+```json
+{
+  "branch": "feature-branch-name",
+  "base_branch": "main",
+  "repo_url": "https://github.com/owner/repo",
+  "archived_tickets": [".workaholic/tickets/archive/branch/ticket1.md", "..."],
+  "git_log": "abc1234 First commit\\ndef5678 Second commit"
+}
+```
+
+Fields: `branch` (current branch), `base_branch` (default branch of the remote), `repo_url` (HTTPS form; SSH URLs are converted), `archived_tickets` (array of ticket paths for current branch), `git_log` (oneline log from base to HEAD).
+
+## Ticket Metadata
+
+Gathers all dynamic metadata values needed for ticket frontmatter in a single shell script call.
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh
+```
+
+Output:
+
+```json
+{
+  "created_at": "2026-01-31T19:25:46+09:00",
+  "author": "developer@company.com",
+  "filename_timestamp": "20260131192546"
+}
+```
+
+Fields: `created_at` (ISO 8601 with timezone for frontmatter), `author` (git user email), `filename_timestamp` (YYYYMMDDHHmmss for the ticket filename).
```

### `plugins/core/skills/create-ticket/SKILL.md`

```diff
--- a/plugins/core/skills/create-ticket/SKILL.md
+++ b/plugins/core/skills/create-ticket/SKILL.md
@@ -2,7 +2,7 @@
 name: create-ticket
 description: Create implementation tickets with proper format and conventions.
 skills:
-  - gather-ticket-metadata
+  - gather
 user-invocable: false
 ---

@@ -12,10 +12,10 @@ Guidelines for creating implementation tickets in `.workaholic/tickets/`.

 ## Step 1: Capture Dynamic Values

-**Run the gather-ticket-metadata script:**
+**Run the ticket-metadata script:**

 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh
+bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh
 ```
```

### `plugins/work/agents/ticket-organizer.md`

```diff
--- a/plugins/work/agents/ticket-organizer.md
+++ b/plugins/work/agents/ticket-organizer.md
@@ -6,7 +6,7 @@ model: opus
 skills:
   - core:branching
   - core:create-ticket
-  - core:gather-ticket-metadata
+  - core:gather
   - standards:leading-validity
   - standards:leading-accessibility
   - standards:leading-security
```

### `plugins/work/agents/performance-analyst.md`

```diff
--- a/plugins/work/agents/performance-analyst.md
+++ b/plugins/work/agents/performance-analyst.md
@@ -2,7 +2,7 @@
 name: performance-analyst
 description: Evaluate decision-making quality across five viewpoints
 skills:
-  - core:gather-git-context
+  - core:gather
   - core:analyze-performance
 ---

@@ -12,7 +12,7 @@ Analyze a development branch's decision-making quality.

 ## Instructions

-1. **Gather context** using the preloaded gather-git-context skill
+1. **Gather context** using the preloaded gather skill (run `git-context.sh`)
 2. **Calculate metrics** using the preloaded analyze-performance skill:
```

### `plugins/work/agents/story-writer.md`

```diff
--- a/plugins/work/agents/story-writer.md
+++ b/plugins/work/agents/story-writer.md
@@ -3,7 +3,7 @@ name: story-writer
 description: Generate branch story for PR description and create/update the pull request.
 tools: Read, Write, Edit, Bash, Glob, Grep, Task
 skills:
-  - core:gather-git-context
+  - core:gather
   - core:report
 ---

@@ -15,7 +15,7 @@ Generate a branch story in `.workaholic/stories/<branch-name>.md` and create/upd

 ### Phase 0: Gather Context

-**Gather all context** using the preloaded gather-git-context skill. Returns: branch, base_branch, repo_url, archived_tickets, git_log.
+**Gather all context** using the preloaded gather skill -- run `git-context.sh`. Returns: branch, base_branch, repo_url, archived_tickets, git_log.
```

### `plugins/work/commands/drive.md`

```diff
--- a/plugins/work/commands/drive.md
+++ b/plugins/work/commands/drive.md
@@ -88,7 +88,7 @@ Phase 2 instructions:
      <ticket-path> "<title>" <repo-url> "<description>" "<changes>" "<test-plan>" "<release-prep>"
    ```
    Where `<ticket-path>` is the current ticket file path in `todo/`, `<title>` is the commit title,
-   and `<repo-url>` comes from the gather-git-context output.
+   and `<repo-url>` comes from the gather skill's `git-context.sh` output.
    **NEVER manually move tickets** with `mv` + `git add` -- always use the archive script.
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -17,7 +17,7 @@ Edit `plugins/` not `.claude/`. This repo develops plugins - changes go to `plug
 plugins/                 # Plugin source directories
   core/                  # Core shared plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
-    skills/              # analyze-performance, analyze-policy, analyze-viewpoint, branching, check-deps, commit, create-ticket, discover, drive, gather-git-context, gather-ticket-metadata, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-changelog, write-overview, write-release-note, write-spec, write-terms
+    skills/              # analyze-performance, analyze-policy, analyze-viewpoint, branching, check-deps, commit, create-ticket, discover, drive, gather, report, review-sections, ship, system-safety, trip-protocol, validate-writer-output, write-changelog, write-overview, write-release-note, write-spec, write-terms
   standards/             # Standards policy plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
     skills/              # leading-*
@@ -66,8 +66,7 @@ Subagents must use skills for common operations instead of inline shell commands

 | Operation | Skill | Usage |
 | --------- | ----- | ----- |
-| Git context (branch, base, URL) | gather-git-context | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-git-context/scripts/gather.sh` |
-| Ticket metadata (date, author) | gather-ticket-metadata | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh` |
+| Git context (branch, base, URL) | gather | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/git-context.sh` |
+| Ticket metadata (date, author) | gather | `bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh` |

 Never write inline git commands like `git branch --show-current` or `git remote show origin` in subagent markdown files. Subagents preload the skill and gather context themselves.
@@ -103,11 +102,11 @@ Claude Code expands `${CLAUDE_PLUGIN_ROOT}` inline in all plugin content (skills

 **Wrong** (relative path):
 ```bash
-bash .claude/skills/gather-ticket-metadata/scripts/gather.sh
+bash .claude/skills/gather/scripts/ticket-metadata.sh
 ```

 **Correct** (same-plugin reference):
 ```bash
-bash ${CLAUDE_PLUGIN_ROOT}/skills/gather-ticket-metadata/scripts/gather.sh
+bash ${CLAUDE_PLUGIN_ROOT}/skills/gather/scripts/ticket-metadata.sh
 ```
```

## Considerations

- **No behavior change in the scripts themselves.** Both scripts are moved verbatim. The verification step runs each from its new location and compares JSON output to the pre-move output. (`plugins/core/skills/gather/scripts/git-context.sh`, `plugins/core/skills/gather/scripts/ticket-metadata.sh`)
- **Ubiquitous Language**: per `standards:leading-validity`, a single concept gets a single term. Today the work flow says both "gather-git-context" and "gather-ticket-metadata" for what is structurally the same operation -- bundled JSON probes. Collapsing them to one term `gather` (disambiguated by script name where needed) is exactly the consolidation that policy prescribes. The Considerations section of any future cross-reference can simply say "the gather skill" without disambiguation in 90% of cases. (`plugins/standards/skills/leading-validity/SKILL.md`)
- **No `depends_on` linkage** is required. This ticket stands alone; no other queued ticket touches these paths.
- **Generated documentation under `.workaholic/`** still references the old basenames after this change lands. That is expected and left to the next `/report` and `/scan` cycle to regenerate. Archived tickets under `.workaholic/tickets/archive/` are immutable history and never get updated. (`.workaholic/specs/`, `.workaholic/policies/`, `.workaholic/stories/`)
- **Plugin Dependencies policy** is unaffected -- the moved skill stays in `core`, every caller in `work` keeps using the `core:` prefix exactly as before, and `standards` has no references to either skill. (`CLAUDE.md` Plugin Dependencies section)
- **Skill Script Path Rule** continues to hold: every updated script-path reference still uses `${CLAUDE_PLUGIN_ROOT}` and either `skills/gather/scripts/…` (same-plugin from inside core) or `${CLAUDE_PLUGIN_ROOT}/../core/skills/gather/scripts/…` (cross-plugin from work, though no work file currently calls the scripts directly -- they all preload the skill and call inside their own bodies through the preload). (`CLAUDE.md` Skill Script Path Rule section)
- **Design Principle**: the new `gather/SKILL.md` is ~50 lines, comfortably inside the "comprehensive skills" envelope. The two predecessors were under-spec at ~35 lines each. Consolidation moves them closer to the documented norm, not further. (`CLAUDE.md` Design Principle section)
- **Out of scope**: the `write-*` and `analyze-*` families are explicitly excluded -- they share a name prefix but no shared content, and each is preloaded by exactly one consumer, so consolidating them would inflate preload sites with unrelated guidance. The user scoped this ticket to "just the gather pair."
