---
created_at: 2026-02-07T11:37:21+09:00
author: a@qmu.jp
type: enhancement
layer: [Config, Domain]
effort:
commit_hash:
category:
---

# Implement Full-Scan and Partial-Scan Modes in Scanner

## Overview

Add two scan modes to the scanner subagent: **full-scan** (invokes all 17 agents to regenerate all `.workaholic/` documentation from scratch) and **partial-scan** (invokes only agents relevant to branch changes for quicker documentation updates). The `/scan` command triggers full-scan. A new `/story` command triggers partial-scan before generating the branch story and creating a PR. This replaces the current `/report` command with `/story` that includes a lightweight documentation refresh step, making it faster and more focused.

Currently, `/scan` always invokes all 17 agents (8 viewpoint analysts, 7 policy analysts, changelog-writer, terms-writer) regardless of what changed. A partial-scan uses `git diff --stat` against the base branch to determine which documentation areas are affected, then invokes only the relevant subset of agents. This makes the `/story` workflow significantly faster since it only updates documentation that the branch actually touched.

## Key Files

- `plugins/core/agents/scanner.md` - Currently hardcodes 17-agent parallel invocation; needs to accept a `mode` parameter (`full` or `partial`) and conditionally select agents
- `plugins/core/commands/scan.md` - Currently invokes scanner without mode; needs to pass `mode: full`
- `plugins/core/commands/report.md` - Will be renamed/replaced by story command
- `plugins/core/commands/story.md` - New command to create; invokes scanner with `mode: partial`, then invokes story-writer
- `plugins/core/agents/story-writer.md` - No changes needed; invoked by `/story` after partial-scan completes
- `plugins/core/skills/gather-git-context/sh/gather.sh` - Already provides diff stat; may need enhancement to return structured change categories
- `plugins/core/skills/select-scan-agents/sh/select.sh` - New skill script to create; analyzes diff stat and returns list of agents to invoke
- `plugins/core/skills/select-scan-agents/SKILL.md` - New skill documentation
- `CLAUDE.md` - Update Commands table (rename `/report` to `/story`, update description)
- `plugins/core/skills/validate-writer-output/sh/validate.sh` - Needs to handle partial file lists (validate only the agents that were invoked)

## Related History

The scanner has evolved through multiple architectural iterations, from a 3-level nesting chain to the current flat 2-level design with 17 parallel agents. The `/scan` command was extracted from `/report` to decouple documentation scanning from PR creation. The original `/story` command was renamed to `/report` earlier in the project history.

Past tickets that touched similar areas:

- [20260207035026-flatten-scan-writer-nesting.md](.workaholic/tickets/archive/drive-20260205-195920/20260207035026-flatten-scan-writer-nesting.md) - Flattened scanner to 2-level with 17 parallel agents; established the current scanner architecture (same file: scanner.md)
- [20260203182617-extract-scan-command.md](.workaholic/tickets/archive/drive-20260203-122444/20260203182617-extract-scan-command.md) - Extracted /scan as standalone command from /report; decoupled scanning from PR creation (same component: scanner, scan command)
- [20260203180235-rename-story-to-report.md](.workaholic/tickets/archive/drive-20260203-122444/20260203180235-rename-story-to-report.md) - Renamed /story to /report; this ticket introduces a new /story with different semantics (same command name)
- [20260203122448-add-story-moderator-and-scanner.md](.workaholic/tickets/archive/drive-20260203-122444/20260203122448-add-story-moderator-and-scanner.md) - Original introduction of scanner subagent as part of story-moderator pattern (same component: scanner)
- [20260207023921-viewpoint-based-spec-architecture.md](.workaholic/tickets/archive/drive-20260205-195920/20260207023921-viewpoint-based-spec-architecture.md) - Introduced 8 viewpoint analysts invoked by scanner (same component: scanner)
- [20260207024808-add-policy-writer-subagent.md](.workaholic/tickets/archive/drive-20260205-195920/20260207024808-add-policy-writer-subagent.md) - Introduced 7 policy analysts invoked by scanner (same component: scanner)

## Implementation Steps

1. **Create `select-scan-agents` skill** at `plugins/core/skills/select-scan-agents/`:
   - Create `SKILL.md` documenting the agent selection logic
   - Create `sh/select.sh` that takes a base branch argument, runs `git diff --stat` against the base, and outputs a JSON list of agent slugs to invoke
   - Mapping rules for partial scan (analyze diff stat paths to determine relevant agents):
     - Changes in `plugins/core/commands/` or `plugins/core/agents/` -> `application-analyst`, `usecase-analyst`, `component-analyst`
     - Changes in `plugins/core/skills/` -> `component-analyst`, `feature-analyst`
     - Changes in `plugins/core/rules/` -> `quality-policy-analyst`, `component-analyst`
     - Changes in `.workaholic/tickets/` -> `data-analyst`, `model-analyst`
     - Changes in `.workaholic/terms/` -> `terms-writer`
     - Changes in `.workaholic/specs/` -> (skip, these are outputs)
     - Changes in `.workaholic/policies/` -> (skip, these are outputs)
     - Changes in `.claude-plugin/` or `plugins/*/` config files -> `infrastructure-analyst`, `delivery-policy-analyst`
     - Changes in `README.md` or `CLAUDE.md` -> `stakeholder-analyst`, `feature-analyst`
     - Changes in `.github/` -> `delivery-policy-analyst`, `security-policy-analyst`
     - Always include: `changelog-writer` (always reflects branch changes)
     - For full mode: return all 17 agent slugs
   - Output JSON format: `{"mode": "full|partial", "agents": ["stakeholder-analyst", "changelog-writer", ...]}`

2. **Update `plugins/core/agents/scanner.md`**:
   - Add `select-scan-agents` to skills in frontmatter
   - Phase 1: Gather context (existing) plus determine scan mode from input
   - Phase 1.5 (new): If mode is `partial`, run `bash .claude/skills/select-scan-agents/sh/select.sh <base_branch>` to get agent list; if mode is `full`, use all 17 agents
   - Phase 2: Invoke only the selected agents in parallel (not always all 17)
   - Phase 3-4: Validate output only for agents that were actually invoked (pass only the relevant filenames to validate.sh)
   - Phase 5: Update index files only if the relevant agents were invoked and passed validation
   - Phase 6: Report status including which mode was used and which agents were invoked

3. **Update `plugins/core/commands/scan.md`**:
   - Pass `mode: full` in the scanner invocation prompt
   - Update description to mention full-scan explicitly

4. **Create `plugins/core/commands/story.md`**:
   - Frontmatter: name: story, description: "Partial-scan documentation, generate story, and create/update PR"
   - Notice section matching pattern of other commands
   - Instructions:
     1. Invoke scanner with `mode: partial` (partial-scan)
     2. Stage and commit partial documentation changes
     3. Invoke story-writer (same as current `/report`)
     4. Display PR URL
   - This replaces `/report` as the standard workflow command

5. **Update or remove `plugins/core/commands/report.md`**:
   - Option A: Delete report.md and replace entirely with story.md
   - Option B: Keep report.md as an alias that invokes story-writer WITHOUT scanning (for cases where user already ran `/scan` manually)
   - Recommended: Option B - keep `/report` as scan-less story+PR, add `/story` as partial-scan+story+PR

6. **Update `CLAUDE.md`**:
   - Add `/story` to Commands table with description "Partial-scan, generate story, and create/update PR"
   - Update `/scan` description to mention "full documentation scan"
   - Update Development Workflow section to show `/story` as the standard step after `/drive`

7. **Update `plugins/core/README.md`** and `README.md`**:
   - Add `/story` command to command tables

## Considerations

- **Agent selection accuracy**: The mapping from diff paths to relevant agents is heuristic. Some changes may affect multiple viewpoints in ways the mapping does not capture. The partial scan accepts this tradeoff for speed; the full `/scan` command remains available for comprehensive regeneration. (`plugins/core/skills/select-scan-agents/sh/select.sh`)
- **Name collision with historical `/story`**: The original `/story` command was renamed to `/report` in ticket 20260203180235. Reintroducing `/story` with different semantics (partial-scan + story + PR instead of just story + PR) may cause confusion for users familiar with the history. The new `/story` is a superset of the old functionality. (`plugins/core/commands/story.md`)
- **Validation with partial agent lists**: The `validate-writer-output/sh/validate.sh` script validates a list of expected files. For partial scan, only the invoked agents' output files should be passed. Files from non-invoked agents should not be checked (they may be stale from a previous full scan, which is acceptable). (`plugins/core/skills/validate-writer-output/sh/validate.sh`)
- **Index file updates during partial scan**: If only a subset of viewpoint analysts run, the README index should not be regenerated (it would only list the subset). Index updates should be skipped in partial mode, or only update entries for agents that actually ran. (`plugins/core/agents/scanner.md` Phase 5)
- **Shell script principle**: The agent selection logic involves conditionals and text processing (analyzing diff stat output, matching paths to agent categories). Per CLAUDE.md policy, this must be a skill script, not inline shell in scanner.md. (`plugins/core/skills/select-scan-agents/sh/select.sh`)
- **Changelog writer always needed**: Regardless of scan mode, `changelog-writer` should always run in partial scan because it reflects the actual commits on the branch, which always change. Terms-writer may also need to always run since new terminology can appear in any change. (`plugins/core/agents/scanner.md`)
- **Workflow change**: The standard development workflow shifts from `/ticket` -> `/drive` -> `/scan` -> `/report` to `/ticket` -> `/drive` -> `/story` (with optional `/scan` for comprehensive updates). This is a user-facing workflow change that should be communicated clearly. (`CLAUDE.md` Development Workflow section)
