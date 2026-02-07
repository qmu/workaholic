---
created_at: 2026-02-07T03:50:26+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 1h
commit_hash: b4a5d8d
category: Changed
---

# Flatten Scan Command Writer Nesting to Eliminate 3-Level Task Chain

## Overview

The `/scan` command's 3-level Task nesting chain (`scanner -> spec-writer/policy-writer -> architecture-analyst/policy-analyst`) fails because the writer-level subagents do not reliably invoke their child analyst subagents. This was diagnosed in ticket `20260207033431` and a prompt-engineering fix was applied (Phase-based headings, explicit bullet lists), but the fundamental problem persists: 3-level Task nesting is inherently unreliable in Claude Code's execution model.

The solution is to eliminate the writer middle layer entirely. The scanner subagent should directly invoke all 8 `architecture-analyst` and 7 `policy-analyst` subagents in parallel (alongside `changelog-writer` and `terms-writer`), reducing the nesting to 2 levels. The scanner then handles validation and README index updates that spec-writer and policy-writer currently own. The `spec-writer.md` and `policy-writer.md` agent files are deleted. Their viewpoint/policy domain definitions move into the scanner (which already contains the orchestration context), and their validation/index-update logic becomes inline scanner phases.

## Key Files

- `plugins/core/agents/scanner.md` - Currently invokes 4 writers in parallel; will be rewritten to directly invoke 8+7 analysts plus changelog-writer and terms-writer (17 parallel subagents total)
- `plugins/core/agents/spec-writer.md` - Contains 8 viewpoint definitions, validation, and README index update logic; will be deleted
- `plugins/core/agents/policy-writer.md` - Contains 7 policy domain definitions, validation, and README index update logic; will be deleted
- `plugins/core/agents/architecture-analyst.md` - Remains unchanged; invoked directly by scanner instead of by spec-writer
- `plugins/core/agents/policy-analyst.md` - Remains unchanged; invoked directly by scanner instead of by policy-writer
- `plugins/core/agents/changelog-writer.md` - Remains unchanged; still invoked by scanner
- `plugins/core/agents/terms-writer.md` - Remains unchanged; still invoked by scanner
- `plugins/core/skills/validate-writer-output/sh/validate.sh` - Remains unchanged; called by scanner after analysts complete
- `plugins/core/skills/write-spec/SKILL.md` - Index file rules referenced by scanner for README updates
- `plugins/core/skills/analyze-viewpoint/SKILL.md` - Viewpoint analysis framework used by architecture-analyst
- `plugins/core/skills/analyze-policy/SKILL.md` - Policy analysis framework used by policy-analyst

## Related History

The scan command has gone through multiple architectural iterations. The 3-level nesting was introduced when spec-writer and policy-writer were created as orchestrator subagents. A previous fix attempted prompt restructuring (Phase-based headings) to make writer-level invocations reliable, but this approach was never verified and the fundamental 3-level nesting fragility remains.

Past tickets that touched similar areas:

- [20260207033431-fix-writer-analyst-invocation.md](.workaholic/tickets/archive/drive-20260205-195920/20260207033431-fix-writer-analyst-invocation.md) - Attempted to fix writer-analyst invocation via prompt restructuring; diagnosed the 3-level nesting problem but did not flatten the architecture (same files: spec-writer.md, policy-writer.md, scanner.md)
- [20260207031812-validate-analyst-output-before-readme-update.md](.workaholic/tickets/archive/drive-20260205-195920/20260207031812-validate-analyst-output-before-readme-update.md) - Added validation gates to spec-writer and policy-writer; this validation logic moves to scanner (same files: spec-writer.md, policy-writer.md)
- [20260207024808-add-policy-writer-subagent.md](.workaholic/tickets/archive/drive-20260205-195920/20260207024808-add-policy-writer-subagent.md) - Created policy-writer with 7 policy domain definitions; these definitions move to scanner (same file: policy-writer.md, scanner.md)
- [20260207023921-viewpoint-based-spec-architecture.md](.workaholic/tickets/archive/drive-20260205-195920/20260207023921-viewpoint-based-spec-architecture.md) - Created spec-writer with 8 viewpoint definitions; these definitions move to scanner (same file: spec-writer.md, scanner.md)
- [20260203182617-extract-scan-command.md](.workaholic/tickets/archive/drive-20260203-122444/20260203182617-extract-scan-command.md) - Extracted /scan as standalone command from /report (same component: scanner)
- [20260131192343-fix-write-story-performance-analyst-invocation.md](.workaholic/tickets/archive/feat-20260131-125844/20260131192343-fix-write-story-performance-analyst-invocation.md) - Fixed a previous skipped-invocation bug in story-writer; established the pattern that 2-level nesting works but 3-level does not (same pattern)

## Implementation Steps

1. **Create 8 per-viewpoint agent files** in `plugins/core/agents/`:
   - `stakeholder-analyst.md`, `model-analyst.md`, `usecase-analyst.md`, `infrastructure-analyst.md`, `application-analyst.md`, `component-analyst.md`, `data-analyst.md`, `feature-analyst.md`
   - Each bakes in its viewpoint definition (description, analysis prompts, Mermaid diagram type, output sections)
   - Each preloads skills: analyze-viewpoint, write-spec, translate
   - Each has hardcoded gather.sh invocation with its own slug
   - Tools: Read, Write, Edit, Bash, Glob, Grep (no Task needed)

2. **Create 7 per-policy agent files** in `plugins/core/agents/`:
   - `test-policy-analyst.md`, `security-policy-analyst.md`, `quality-policy-analyst.md`, `accessibility-policy-analyst.md`, `observability-policy-analyst.md`, `delivery-policy-analyst.md`, `recovery-policy-analyst.md`
   - Each bakes in its policy domain definition (description, analysis prompts, output sections)
   - Each preloads skills: analyze-policy, translate
   - Each has hardcoded gather.sh invocation with its own slug
   - Tools: Read, Write, Edit, Bash, Glob, Grep (no Task needed)

3. **Rewrite `plugins/core/agents/scanner.md`** as pure orchestration:
   - No viewpoint/policy definitions (those live in per-analyst agents)
   - Phase 1: Gather context (git context, commit hash)
   - Phase 2: Invoke 17 named agents in parallel (8 viewpoint + 7 policy + changelog-writer + terms-writer)
   - Phase 3-4: Validate spec/policy output
   - Phase 5: Update index files
   - Phase 6: Report status

4. **Delete `plugins/core/agents/spec-writer.md`**: Replaced by 8 per-viewpoint agents + scanner orchestration.

5. **Delete `plugins/core/agents/policy-writer.md`**: Replaced by 7 per-policy agents + scanner orchestration.

6. **Delete `plugins/core/agents/architecture-analyst.md`**: Replaced by 8 per-viewpoint agents.

7. **Delete `plugins/core/agents/policy-analyst.md`**: Replaced by 7 per-policy agents.

## Considerations

- **Scanner file size**: Absorbing 8 viewpoint definitions and 7 policy domain definitions makes scanner.md significantly larger (~150-200 lines). This pushes against the "thin subagents" principle in CLAUDE.md (20-40 lines). However, the viewpoint/policy definitions are reference data, not orchestration logic -- the actual orchestration remains thin. An alternative is to extract the definitions into a skill, but that adds indirection without solving the nesting problem. The pragmatic choice is to keep definitions inline in scanner.md. (`plugins/core/agents/scanner.md`)
- **17 parallel subagents**: Invoking 17 Task tool calls in a single message is the maximum parallelism this system has attempted. If the Claude Code runtime has limitations on concurrent Task calls, consider splitting into two waves: first 8+7 analysts, then 2 writers. However, story-writer already successfully invokes 4+2 agents in two phases, so 17 in one phase should work given that Task tool calls are designed for parallelism. (`plugins/core/agents/scanner.md`)
- **Validation gating**: Validation for specs and policies are independent. If spec validation fails but policy validation passes, the scanner should still update policy READMEs. The implementation should treat spec and policy validation results independently rather than requiring both to pass. (`plugins/core/skills/validate-writer-output/sh/validate.sh`)
- **Skill references in deleted files**: spec-writer.md preloads `analyze-viewpoint` and `write-spec`; policy-writer.md preloads `gather-git-context` and `analyze-policy`. The scanner must add these skills to its own frontmatter to ensure they are available for the validation and index-update phases. The analyst subagents already preload their own skills for the analysis work itself. (`plugins/core/agents/scanner.md`)
- **Architecture documentation**: The `.workaholic/specs/architecture.md` and `command-flows.md` (if they exist as viewpoint-generated files) will describe the scan command flow. After this refactoring, these documents will be regenerated by the next `/scan` run and should automatically reflect the new 2-level architecture. (`plugins/core/agents/architecture-analyst.md`)
- **Backward compatibility**: No external interface changes. The `/scan` command still invokes scanner, scanner still produces the same output files. Only the internal orchestration depth changes. (`plugins/core/commands/scan.md`)
- **Precedent**: The story-writer successfully invokes 4 subagents in Phase 1 and 2 subagents in Phase 4 (2-level nesting from `/report` command). This confirms 2-level nesting works reliably while 3-level does not. (`plugins/core/agents/story-writer.md`)

## Final Report

Implemented per-analyst agent architecture instead of the originally planned inline-definitions approach. Created 15 dedicated self-contained agent files (8 viewpoint analysts + 7 policy analysts), each baking in its own viewpoint/policy definition and preloading the appropriate skills. This keeps the scanner as pure orchestration (~110 lines) while each analyst is self-contained (~45 lines).

Files created: stakeholder-analyst.md, model-analyst.md, usecase-analyst.md, infrastructure-analyst.md, application-analyst.md, component-analyst.md, data-analyst.md, feature-analyst.md, test-policy-analyst.md, security-policy-analyst.md, quality-policy-analyst.md, accessibility-policy-analyst.md, observability-policy-analyst.md, delivery-policy-analyst.md, recovery-policy-analyst.md.

Files deleted: spec-writer.md, policy-writer.md, architecture-analyst.md, policy-analyst.md.

Files rewritten: scanner.md (from 4-agent orchestrator to 17-agent orchestrator with validation and index update phases).
