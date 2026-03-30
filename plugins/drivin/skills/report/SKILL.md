---
name: report
description: Story writing, PR creation, and release readiness assessment for branch reporting.
allowed-tools: Bash
user-invocable: false
---

# Report

Guidelines for generating branch stories, creating pull requests, and assessing release readiness.

## Write Story

Generate a branch story that serves as the single source of truth for PR content.

### Agent Output Mapping

Story sections are populated from parallel agent outputs:

| Agent | Sections | Fields |
| ----- | -------- | ------ |
| overview-writer | 1, 2, 3 (journey preamble) | `overview`, `highlights[]`, `motivation`, `journey.mermaid`, `journey.summary` |
| section-reviewer | 4, 5, 6, 7 | `outcome`, `historical_analysis`, `concerns`, `ideas` |
| release-readiness | 8 | `verdict`, `concerns[]`, `instructions.pre_release[]`, `instructions.post_release[]` |
| release-note-writer | (separate file) | Writes to `.workaholic/release-notes/<branch>.md` |

Section 3 (Changes) comes from archived tickets, prefaced by journey content from overview-writer. Section 9 (Notes) is optional context.

### Story Content Structure

The story content (this IS the PR description):

```markdown
## 1. Overview

[Content from overview-writer `overview` field: 2-3 sentence summary capturing the branch essence.]

**Highlights:**

1. [From overview-writer `highlights[0]}]
2. [From overview-writer `highlights[1]`]
3. [From overview-writer `highlights[2]`]

## 2. Motivation

[Content from overview-writer `motivation` field: paragraph synthesizing the "why" from commit context.]

## 3. Changes

[Content from overview-writer `journey.mermaid` for the flowchart and `journey.summary` for the prose below it.]

```mermaid
[Content from overview-writer `journey.mermaid`]
```

[Content from overview-writer `journey.summary`]

**Flowchart Guidelines:**
- Use `flowchart LR` for horizontal timeline (subgraphs arranged left-to-right)
- Use `direction TB` inside each subgraph for vertical item flow
- Group by theme: each subgraph represents one concern or decision area
- Connect subgraphs in timeline order to show work progression
- Use descriptive node labels: `id[Description]` syntax
- Maximum 3-5 subgraphs per diagram

One subsection per ticket, in chronological order:

### 3-1. <Ticket title> ([hash](<repo-url>/commit/<hash>))

<1-3 sentence summary of what this ticket changed and why. Focus on the intent and scope of the change rather than enumerating individual files.>

### 3-2. <Next ticket title> ([hash](<repo-url>/commit/<hash>))

<1-3 sentence summary of what this ticket changed and why.>

### ...

**Changes Guidelines:**
- One subsection per ticket (not grouped by theme)
- **CRITICAL**: Commit hash MUST be a clickable GitHub link, not plain text
  - Wrong: `(abc1234)` or `(<hash>)`
  - Correct: `([abc1234](<repo-url>/commit/abc1234))`
- Format: `### 3-N. <Title> ([hash](<repo-url>/commit/<hash>))`
- **Summarize the change** in 1-3 sentences per ticket -- describe what was done and why, not individual files
- Focus on intent, scope, and impact rather than enumerating every modified file
- Chronological order matches ticket creation time

## 4. Outcome

[Summarize what was accomplished. Reference key tickets for details.]

## 5. Historical Analysis

[Context from related past work. What similar problems were solved before? What patterns emerge from the Related History sections of tickets? If no related tickets exist, write "No related historical context."]

## 6. Concerns

[Risks, trade-offs, or issues discovered during implementation. Each concern should include identifiable references.]

**Format**: `- <description> (see [hash](<repo-url>/commit/<hash>) in path/to/file.ext)`

**Example**:
- The pathspec exclusion syntax requires modern git versions (see [7eab801](<repo-url>/commit/7eab801) in `plugins/drivin/skills/drive/SKILL.md`)
- Auto-approval configuration may be broader than intended (`~/.claude/settings.local.json`)

**Guidelines**:
- Reference the commit hash from section 3 where the concern was introduced
- Include the file path where readers should investigate
- Write "None" if nothing to report

## 7. Ideas

[Enhancement suggestions for future work. Improvements that were out of scope. "Nice to have" features identified during implementation. Write "None" if nothing to report.]

## 8. Release Preparation

**Verdict**: [Ready for release / Needs attention before release]

### 8-1. Concerns

- [List any concerns from release-readiness analysis]
- Or "None - changes are safe for release"

### 8-2. Pre-release Instructions

- [Steps to take before running /release]
- Or "None - standard release process applies"

### 8-3. Post-release Instructions

- [Steps to take after release]
- Or "None - no special post-release actions needed"
```

**Release-readiness input:**

The release-readiness JSON is provided by story-writer which invokes release-readiness as a parallel agent. The JSON contains:

```json
{
  "releasable": true/false,
  "verdict": "Ready for release" / "Needs attention before release",
  "concerns": [],
  "instructions": {
    "pre_release": [],
    "post_release": []
  }
}
```

Format this JSON into section 8.

```markdown
## 9. Notes

Additional context for reviewers or future reference.
```

### Story Frontmatter

Create `.workaholic/stories/<branch-name>.md` with YAML frontmatter:

```yaml
---
branch: <branch-name>
tickets_completed: <count of tickets>
---
```

### Writing Guidelines

- Write in third person ("The developer discovered..." not "I discovered...")
- Connect tickets into a narrative arc, not a list
- Highlight decision points and trade-offs
- Keep Motivation/Journey/Outcome concise (Journey: 50-100 words)
- Changes section: one entry per ticket, brief descriptions
- Historical Analysis/Concerns/Ideas can be "None" if empty

### Updating Stories Index

Update `.workaholic/stories/README.md` to include the new story:

- Add entry: `- [<branch-name>.md](<branch-name>.md) - Brief description of the branch work`

## Create PR

Create or update a GitHub pull request using the story file as PR content.

### Derive PR Title

Extract the first item from the Summary section of the story file:

```markdown
## 1. Summary

1. First meaningful change
```

Use that first item as the title. If multiple items exist, append "etc" (e.g., "Add dark mode toggle etc").

### Create or Update PR

Run the bundled script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/report/sh/create-or-update.sh <branch-name> "<title>"
```

#### What the Script Does

1. Strips YAML frontmatter via `strip-frontmatter.sh` from `.workaholic/stories/<branch-name>.md`
2. Writes clean content to `/tmp/pr-body.md`
3. Checks if PR exists for the branch
4. Creates new PR or updates existing one
5. Outputs the result in required format

### Strip Frontmatter Script

A reusable script for removing YAML frontmatter from any markdown file:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/report/sh/strip-frontmatter.sh <file>
```

Outputs clean markdown body to stdout. Handles files with frontmatter, without frontmatter (pass-through), and empty files. Only strips frontmatter starting on line 1 -- content `---` separators elsewhere are preserved.

### PR Output Format

Exactly one line:

```
PR created: <URL>
```

or

```
PR updated: <URL>
```

This output format is required by the story command.

## Assess Release Readiness

Analyze a branch to determine if it's ready for release.

### Analysis Tasks

1. **Review code changes**: Check `git diff main..HEAD` for:
   - Incomplete work (TODO, FIXME, XXX comments in new code)
   - Security concerns (hardcoded secrets, credentials)
   - Runtime errors or obvious bugs

2. **Check for blocking issues**:
   - Tests failing (if tests exist)
   - Type errors (if type checking exists)
   - Missing files referenced in code

3. **Identify actionable items** (not theoretical concerns):
   - Documentation that needs updating
   - Version numbers to bump
   - Files to stage/commit before release

### What NOT to Flag

- "Breaking changes" for command renames - users adapt
- API changes in a plugin - plugins are configuration, not APIs
- Internal refactoring - doesn't affect users
- Theoretical upgrade concerns - users pull fresh versions

### Release Readiness Output Format

Return JSON:

```json
{
  "releasable": true,
  "verdict": "Ready for release",
  "concerns": [],
  "instructions": {
    "pre_release": [],
    "post_release": []
  }
}
```

Or if issues found:

```json
{
  "releasable": false,
  "verdict": "Needs attention before release",
  "concerns": [
    "Found TODO comment in src/foo.ts",
    "Tests failing in commands/drive.md"
  ],
  "instructions": {
    "pre_release": ["Fix failing tests", "Remove TODO comments"],
    "post_release": []
  }
}
```

### Release Readiness Guidelines

- Focus on issues that actually block releases
- Provide actionable instructions, not theoretical warnings
- "Breaking change" is rarely a real concern for plugins
- Empty concerns array is the happy path, not a failure
- If it doesn't require action, don't flag it
