---
created_at: 2026-02-07T03:50:26+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
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

1. **Rewrite `plugins/core/agents/scanner.md`** to directly orchestrate all analysts:

   The scanner becomes the single orchestrator for all documentation generation. Its new structure:

   - **Frontmatter**: Add skills `analyze-viewpoint`, `analyze-policy`, `write-spec`, `validate-writer-output` to existing `gather-git-context`
   - **Viewpoints section**: Move the 8 viewpoint definitions (stakeholder, model, usecase, infrastructure, application, component, data, feature) from spec-writer.md into scanner.md. Each definition includes description, analysis prompts, Mermaid diagram type, and output sections.
   - **Policy Domains section**: Move the 7 policy domain definitions (test, security, quality, accessibility, observability, delivery, recovery) from policy-writer.md into scanner.md. Each definition includes description, analysis prompts, and output sections.
   - **Phase 1: Gather Context**: Use gather-git-context skill. Get commit hash via `git rev-parse --short HEAD`.
   - **Phase 2: Invoke All Agents in Parallel**: Single message with 17 Task tool calls:
     - 8x `architecture-analyst` (one per viewpoint, `model: "sonnet"`) -- pass viewpoint slug, full definition from Viewpoints section, base branch
     - 7x `policy-analyst` (one per policy domain, `model: "sonnet"`) -- pass policy slug, full definition from Policy Domains section, base branch
     - 1x `changelog-writer` (`model: "opus"`) -- pass repository URL
     - 1x `terms-writer` (`model: "opus"`) -- pass branch name
   - **Phase 3: Validate Spec Output**: Run `validate.sh .workaholic/specs stakeholder.md model.md usecase.md infrastructure.md application.md component.md data.md feature.md`
   - **Phase 4: Validate Policy Output**: Run `validate.sh .workaholic/policies test.md security.md quality.md accessibility.md observability.md delivery.md recovery.md`
   - **Phase 5: Update Index Files**: Only if both validations pass, update README.md and README_ja.md for both `.workaholic/specs/` and `.workaholic/policies/`. Follow write-spec skill for index file rules.
   - **Phase 6: Report Status**: Return JSON with per-agent status, validation results.

2. **Delete `plugins/core/agents/spec-writer.md`**: All its content (viewpoint definitions, validation, index updates) has been absorbed into scanner.md.

3. **Delete `plugins/core/agents/policy-writer.md`**: All its content (policy domain definitions, validation, index updates) has been absorbed into scanner.md.

4. **Update scanner.md output JSON schema** to reflect the new flat structure:

   ```json
   {
     "changelog_writer": { "status": "success" | "failed" },
     "terms_writer": { "status": "success" | "failed" },
     "spec_validation": { "pass": true },
     "policy_validation": { "pass": true },
     "viewpoints": {
       "stakeholder": { "status": "success" | "failed" },
       "model": { "status": "success" | "failed" },
       "usecase": { "status": "success" | "failed" },
       "infrastructure": { "status": "success" | "failed" },
       "application": { "status": "success" | "failed" },
       "component": { "status": "success" | "failed" },
       "data": { "status": "success" | "failed" },
       "feature": { "status": "success" | "failed" }
     },
     "policies": {
       "test": { "status": "success" | "failed" },
       "security": { "status": "success" | "failed" },
       "quality": { "status": "success" | "failed" },
       "accessibility": { "status": "success" | "failed" },
       "observability": { "status": "success" | "failed" },
       "delivery": { "status": "success" | "failed" },
       "recovery": { "status": "success" | "failed" }
     }
   }
   ```

5. **Update scanner.md description** in frontmatter to reflect the new role: "Invoke documentation generators (changelog-writer, terms-writer, 8 architecture-analysts, 7 policy-analysts) in parallel and update index files."

6. **Verify no other files reference spec-writer or policy-writer** by name. Check:
   - `plugins/core/commands/scan.md` -- references scanner only (no change needed)
   - `.workaholic/specs/` documentation -- may mention spec-writer in generated content
   - Any skill files that list spec-writer or policy-writer as consumers

## Considerations

- **Scanner file size**: Absorbing 8 viewpoint definitions and 7 policy domain definitions makes scanner.md significantly larger (~150-200 lines). This pushes against the "thin subagents" principle in CLAUDE.md (20-40 lines). However, the viewpoint/policy definitions are reference data, not orchestration logic -- the actual orchestration remains thin. An alternative is to extract the definitions into a skill, but that adds indirection without solving the nesting problem. The pragmatic choice is to keep definitions inline in scanner.md. (`plugins/core/agents/scanner.md`)
- **17 parallel subagents**: Invoking 17 Task tool calls in a single message is the maximum parallelism this system has attempted. If the Claude Code runtime has limitations on concurrent Task calls, consider splitting into two waves: first 8+7 analysts, then 2 writers. However, story-writer already successfully invokes 4+2 agents in two phases, so 17 in one phase should work given that Task tool calls are designed for parallelism. (`plugins/core/agents/scanner.md`)
- **Validation gating**: Validation for specs and policies are independent. If spec validation fails but policy validation passes, the scanner should still update policy READMEs. The implementation should treat spec and policy validation results independently rather than requiring both to pass. (`plugins/core/skills/validate-writer-output/sh/validate.sh`)
- **Skill references in deleted files**: spec-writer.md preloads `analyze-viewpoint` and `write-spec`; policy-writer.md preloads `gather-git-context` and `analyze-policy`. The scanner must add these skills to its own frontmatter to ensure they are available for the validation and index-update phases. The analyst subagents already preload their own skills for the analysis work itself. (`plugins/core/agents/scanner.md`)
- **Architecture documentation**: The `.workaholic/specs/architecture.md` and `command-flows.md` (if they exist as viewpoint-generated files) will describe the scan command flow. After this refactoring, these documents will be regenerated by the next `/scan` run and should automatically reflect the new 2-level architecture. (`plugins/core/agents/architecture-analyst.md`)
- **Backward compatibility**: No external interface changes. The `/scan` command still invokes scanner, scanner still produces the same output files. Only the internal orchestration depth changes. (`plugins/core/commands/scan.md`)
- **Precedent**: The story-writer successfully invokes 4 subagents in Phase 1 and 2 subagents in Phase 4 (2-level nesting from `/report` command). This confirms 2-level nesting works reliably while 3-level does not. (`plugins/core/agents/story-writer.md`)
