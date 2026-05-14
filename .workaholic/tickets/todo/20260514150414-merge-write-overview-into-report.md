---
created_at: 2026-05-14T15:04:14+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
depends_on:
---

# Merge write-overview skill into report skill

## Overview

`plugins/core/skills/write-overview/SKILL.md` (~116 lines) is preloaded only by `plugins/work/agents/overview-writer.md`, whose JSON output (`overview`, `highlights`, `motivation`, `journey`) is embedded into the story file produced by `core:report`. Because the `overview-writer` is invoked exactly once — by `story-writer` during `/report` — and `story-writer` already preloads `core:report`, keeping `write-overview` as a separate skill duplicates the load surface area for a single consumer.

This ticket absorbs `write-overview/SKILL.md` into `report/SKILL.md` as an "Overview Generation" section (placed near the agent-output mapping table where the overview fields are already referenced), relocates the `collect-commits.sh` script to `plugins/core/skills/report/scripts/`, repoints `overview-writer.md` from `core:write-overview` to `core:report`, and removes the now-empty `write-overview/` directory. CLAUDE.md's `core skills` line drops the `write-overview` entry.

The script is non-trivial (~48 lines of shell with `git log`, `sed` pipelines, and a `cat <<EOF` heredoc) so option (a) — move the script verbatim into `report/scripts/` — applies. The script has no internal `${CLAUDE_PLUGIN_ROOT}` references, so the move is path-neutral.

## Key Files

- `plugins/core/skills/write-overview/SKILL.md` - Source of the content to merge. Will be deleted after the merge.
- `plugins/core/skills/write-overview/scripts/collect-commits.sh` - Shell script that collects commit info. Moves to `plugins/core/skills/report/scripts/collect-commits.sh` (path-neutral; no internal `${CLAUDE_PLUGIN_ROOT}` references).
- `plugins/core/skills/report/SKILL.md` - Receives the new "Overview Generation" section. The Agent Output Mapping table already references the four overview-writer fields; the new section is the natural counterpart describing how to generate them.
- `plugins/core/skills/report/scripts/` - New home for `collect-commits.sh`, alongside `create-or-update.sh` and `strip-frontmatter.sh`.
- `plugins/work/agents/overview-writer.md` - Sole consumer. Frontmatter `skills:` entry switches from `core:write-overview` to `core:report`. Inline bash path updates. Body prose mentioning "the write-overview skill" rewords to refer to the report skill.
- `CLAUDE.md` - Project Structure section's `core/skills/` line lists every skill by name; drop `write-overview` from that comma-separated list.

## Related History

The repository has repeatedly consolidated skills whose content lived too far from their only consumer. The `merge-approval-flow-skills` and `reorganize-story-agent-hierarchy` tickets folded narrowly-used skills into broader orchestration skills, and the `audit-replace-relative-skill-script-paths` ticket established the `${CLAUDE_PLUGIN_ROOT}` reference rule that the moved script must continue to satisfy.

Past tickets that touched similar areas:

- [20260202184602-merge-approval-flow-skills.md](.workaholic/tickets/archive/drive-20260202-134332/20260202184602-merge-approval-flow-skills.md) - Merged single-consumer skills into a broader skill (same refactoring pattern)
- [20260202200553-reorganize-story-agent-hierarchy.md](.workaholic/tickets/archive/drive-20260202-134332/20260202200553-reorganize-story-agent-hierarchy.md) - Touched the story-writer/overview-writer hierarchy this ticket modifies
- [20260202181348-add-overview-writer-subagent.md](.workaholic/tickets/archive/drive-20260202-134332/20260202181348-add-overview-writer-subagent.md) - Introduced overview-writer and write-overview originally (the pair being unmerged here)
- [20260213131505-audit-replace-relative-skill-script-paths.md](.workaholic/tickets/archive/drive-20260213-131416/20260213131505-audit-replace-relative-skill-script-paths.md) - Established `${CLAUDE_PLUGIN_ROOT}` path rule; the script move must remain compliant
- [20260204201108-add-release-note-writer-to-report.md](.workaholic/tickets/archive/drive-20260204-160722/20260204201108-add-release-note-writer-to-report.md) - Most recent extension of the `report` skill — precedent for adding sibling generation sections inside it

## Implementation Steps

1. **Insert "Overview Generation" section into `plugins/core/skills/report/SKILL.md`**: Place the new section immediately after `## Write Story` → `### Agent Output Mapping` and before `### Story Content Structure`, so the field-list-then-generation-guidance reads top-down. The section should contain, verbatim from `write-overview/SKILL.md`:
   - The "Collect Commits" subsection (referencing the new script path)
   - The script output JSON shape
   - The four content components (Overview, Highlights, Motivation, Journey)
   - The Flowchart Guidelines (Mermaid block)
   - The final Output Format JSON schema with all four fields
   Update the inline script path inside this section from `${CLAUDE_PLUGIN_ROOT}/skills/write-overview/scripts/collect-commits.sh` to `${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/collect-commits.sh`.

2. **Move the script**: `git mv plugins/core/skills/write-overview/scripts/collect-commits.sh plugins/core/skills/report/scripts/collect-commits.sh`. The script body needs no edits — it has no `${CLAUDE_PLUGIN_ROOT}` references and uses only `git`, `sed`, and shell builtins.

3. **Reconcile existing report/SKILL.md mentions**: The existing Story Content Structure block notes Flowchart Guidelines for the Changes section (lines 58-65). The new Overview Generation section also includes Flowchart Guidelines. Decide whether to (a) leave both — they apply at different points in the workflow — or (b) replace the inner one with an intra-doc cross-reference. Recommend (a): the existing guidelines are embedded in story-structure documentation for readers of the rendered story; the new section's guidelines are for the agent generating the field. Keeping both is intentional.

4. **Update `plugins/work/agents/overview-writer.md`**:
   - Frontmatter `skills:` entry: `- core:write-overview` → `- core:report`
   - Step 1 prose: "Run the write-overview skill script" → "Run the report skill's collect-commits script (see the Overview Generation section)"
   - Inline bash path: `${CLAUDE_PLUGIN_ROOT}/../core/skills/write-overview/scripts/collect-commits.sh` → `${CLAUDE_PLUGIN_ROOT}/../core/skills/report/scripts/collect-commits.sh`

5. **Delete the old skill directory**: `git rm -r plugins/core/skills/write-overview/`. After step 2 moves the script out, the directory contains only `SKILL.md`, whose content has been merged in step 1.

6. **Update CLAUDE.md**: In the `core/skills/` line of the Project Structure section, remove `write-overview` from the comma-separated skill list.

7. **Verify no stragglers**: Run `grep -rn 'write-overview' plugins/ CLAUDE.md` and confirm zero matches. Run `grep -rn 'collect-commits' plugins/` and confirm the only matches are in `plugins/core/skills/report/SKILL.md` and `plugins/work/agents/overview-writer.md`, both pointing at the new path.

8. **Functional smoke test**: From a branch with at least one commit beyond `main`, run `bash plugins/core/skills/report/scripts/collect-commits.sh main` and confirm the JSON shape matches what the pre-move script emitted: top-level keys `commits` (array of `{hash, subject, timestamp}` objects), `count` (integer), `base_branch` (string).

## Patches

### `plugins/work/agents/overview-writer.md`

```diff
--- a/plugins/work/agents/overview-writer.md
+++ b/plugins/work/agents/overview-writer.md
@@ -4,7 +4,7 @@ description: Generate overview content for story by analyzing commit history.
 tools: Read, Bash, Glob, Grep
 model: haiku
 skills:
-  - core:write-overview
+  - core:report
 ---

 # Overview Writer
@@ -20,9 +20,9 @@ You will receive:

 ## Instructions

-1. **Collect Commits**: Run the write-overview skill script:
+1. **Collect Commits**: Run the report skill's collect-commits script (see the Overview Generation section of `core:report`):
    ```bash
-   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/write-overview/scripts/collect-commits.sh <base-branch>
+   bash ${CLAUDE_PLUGIN_ROOT}/../core/skills/report/scripts/collect-commits.sh <base-branch>
    ```

 2. **Analyze Commit Patterns**: Group commits by theme, identify phases, extract key changes.
```

### `plugins/core/skills/report/SKILL.md`

> **Note**: The insertion below adds an "Overview Generation" section immediately after the Agent Output Mapping table. The body of the section is the substantive content of the deleted `write-overview/SKILL.md` (lines 10-116), with the inline script path updated from `skills/write-overview/scripts/` to `skills/report/scripts/`. This patch is speculative on exact whitespace — verify against the live file before applying.

```diff
--- a/plugins/core/skills/report/SKILL.md
+++ b/plugins/core/skills/report/SKILL.md
@@ -25,6 +25,108 @@ Story sections are populated from parallel agent outputs:

 Section 3 (Changes) comes from archived tickets, prefaced by journey content from overview-writer. Section 10 (Notes) is optional context.

+### Overview Generation
+
+Generate the four fields consumed by sections 1, 2, and 3 (`overview`, `highlights`, `motivation`, `journey`) by analyzing commit history for the branch. The `overview-writer` agent runs this generation in parallel with `release-readiness` and `section-reviewer`.
+
+#### Collect Commits
+
+Run the bundled script to collect commit information:
+
+```bash
+bash ${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/collect-commits.sh [base-branch]
+```
+
+Default base branch is `main`.
+
+##### Output Format (JSON)
+
+```json
+{
+  "commits": [
+    {
+      "hash": "abc1234",
+      "subject": "Add feature X",
+      "body": "Detailed description of the change...",
+      "timestamp": "2026-01-15T10:30:00+09:00"
+    }
+  ],
+  "count": 15,
+  "base_branch": "main"
+}
+```
+
+#### Content Structure
+
+Generate JSON with four components:
+
+##### 1. Overview
+
+A 2-3 sentence summary capturing the branch essence: main goal, approach taken, what was achieved. Past tense; synthesize from commit subjects.
+
+##### 2. Highlights
+
+Array of 3-5 meaningful changes: extracted from commit subjects, related commits grouped into single highlights, focused on user-visible or architecturally significant changes, ordered by importance not chronology.
+
+##### 3. Motivation
+
+A paragraph synthesizing the "why": what problem or opportunity started this work, why this approach was chosen, what constraints shaped it. Narrative prose, not a list.
+
+##### 4. Journey
+
+Two parts:
+- **mermaid**: A flowchart showing work progression
+- **summary**: 50-100 word summary of development journey
+
+##### Flowchart Guidelines
+
+```mermaid
+flowchart LR
+  subgraph Phase1[Initial Setup]
+    direction TB
+    a1[First step] --> a2[Second step]
+  end
+
+  subgraph Phase2[Core Work]
+    direction TB
+    b1[Third step] --> b2[Fourth step]
+  end
+
+  Phase1 --> Phase2
+```
+
+- Use `flowchart LR` for horizontal timeline
+- Use `direction TB` inside each subgraph for vertical flow
+- Group by theme: each subgraph is one concern area
+- Connect subgraphs in timeline order
+- Maximum 3-5 subgraphs per diagram
+
+#### Overview Output Format
+
+Return JSON:
+
+```json
+{
+  "overview": "2-3 sentence summary capturing the branch essence",
+  "highlights": [
+    "First meaningful change",
+    "Second meaningful change",
+    "Third meaningful change"
+  ],
+  "motivation": "Paragraph synthesizing the 'why' from commit context",
+  "journey": {
+    "mermaid": "flowchart LR\n  subgraph Phase1[Initial Work]\n    direction TB\n    a1[Step 1] --> a2[Step 2]\n  end\n  ...",
+    "summary": "50-100 word summary of the development journey"
+  }
+}
+```
+
 ### Story Content Structure

 The story content (this IS the PR description):
```

### `CLAUDE.md`

```diff
--- a/CLAUDE.md
+++ b/CLAUDE.md
@@ -17,7 +17,7 @@
 plugins/                 # Plugin source directories
   core/                  # Core shared plugin (no dependencies)
     .claude-plugin/      # Plugin configuration
     commands/            # report, ship
-    skills/              # branching, commit, gather-git-context, gather-ticket-metadata, ship, system-safety
+    skills/              # branching, commit, gather-git-context, gather-ticket-metadata, ship, system-safety
```

> **Note**: The current CLAUDE.md `core/skills/` line shown in the project memory does NOT list `write-overview` — but the live `grep` output confirms it appears in CLAUDE.md line 20. Before editing, re-read CLAUDE.md to find the exact comma-separated list of core skills and remove `write-overview` from it. The diff shown above is a placeholder; the real diff depends on the live ordering of the list.

### Script move (no content change)

```
git mv plugins/core/skills/write-overview/scripts/collect-commits.sh \
       plugins/core/skills/report/scripts/collect-commits.sh
```

### Directory removal

```
git rm plugins/core/skills/write-overview/SKILL.md
rmdir plugins/core/skills/write-overview/scripts 2>/dev/null || true
rmdir plugins/core/skills/write-overview 2>/dev/null || true
```

## Considerations

- **Component nesting rule compliance**: `overview-writer` is a subagent that preloads a skill — this is allowed (`plugins/work/agents/overview-writer.md` → `core:report`). The merge does not change the nesting class of the call (`plugins/core/skills/report/SKILL.md`).
- **Skill script path rule** (CLAUDE.md "Skill Script Path Rule"): the moved script must still be referenced via `${CLAUDE_PLUGIN_ROOT}`. Inside `report/SKILL.md` the reference is same-plugin (`${CLAUDE_PLUGIN_ROOT}/skills/report/scripts/...`); inside `overview-writer.md` it remains cross-plugin (`${CLAUDE_PLUGIN_ROOT}/../core/skills/report/scripts/...`). Both forms are correct per the rule.
- **No declared-dependency change needed**: `work` already declares `core` as a dependency, so `core:report` is reachable from `overview-writer` (`plugins/work/.claude-plugin/plugin.json`).
- **Ubiquitous Language** (`standards:leading-validity`): the term "Overview Generation" is introduced as the section heading. The existing report skill uses "Write Story" / "Create PR" / "Assess Release Readiness" as top-level section names, so "Overview Generation" follows the same noun-phrase pattern. No competing term exists in the codebase for this concept.
- **No `depends_on`**: this ticket is independent of any concurrent dead-code-deletion ticket. The merge is self-contained: file moves, content insertion, frontmatter swap, CLAUDE.md inventory edit. (`plugins/core/skills/write-overview/`, `plugins/work/agents/overview-writer.md`, `CLAUDE.md`)
- **Smoke test cost**: the verification in step 8 is cheap — `collect-commits.sh` is read-only, exits in milliseconds, and prints JSON to stdout. Worth running on this very branch to confirm the script produces output before declaring the move correct.
- **Section depth in the merge**: `write-overview/SKILL.md` uses `##` and `###` headings. When inserted under `report/SKILL.md`'s `## Write Story` as `### Overview Generation`, the inner headings should be demoted by one level (`##` → `###`, `###` → `####`, `####` → `#####`) to maintain a coherent outline. The patch above already reflects this demotion. (`plugins/core/skills/report/SKILL.md`)
- **Re-read CLAUDE.md before editing**: the patch on CLAUDE.md is speculative because the line shown in repo-memory context may differ from the live file. The implementer should read line 20 directly and remove only `write-overview, ` from the comma-separated list. (`CLAUDE.md` line 20)
