---
created_at: 2026-02-07T02:48:08+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Add Policy-Writer Subagent for Concurrent Policy Generation

## Overview

Add a `policy-writer` subagent that generates policy documents under `.workaholic/policies/`, following the same pattern as `spec-writer` generates specs under `.workaholic/specs/`. The `policy-writer` orchestrates 7 concurrent `policy-analyst` subagents, each analyzing the repository from a different policy domain: test, security, quality, accessibility, observability, delivery, and recovery. The scanner subagent is extended to invoke `policy-writer` alongside `changelog-writer`, `spec-writer`, and `terms-writer`. Each policy-analyst uses an `analyze-policy` skill to gather context, analyze the repo, and write `.workaholic/policies/<slug>.md` + `_ja.md`, producing 14 output files per scan (7 policies x 2 languages).

## Key Files

- `plugins/core/skills/analyze-policy/SKILL.md` - New comprehensive skill defining all 7 policy domains, analysis prompts, output templates, and writing guidelines
- `plugins/core/skills/analyze-policy/sh/gather.sh` - New context gathering script accepting policy slug + base branch
- `plugins/core/agents/policy-analyst.md` - New thin subagent (~20-40 lines) receiving policy slug, gathering context via analyze-policy skill, analyzing repo, writing `.workaholic/policies/<slug>.md` + `_ja.md`
- `plugins/core/agents/policy-writer.md` - New orchestrator subagent invoking 7 parallel policy-analyst subagents via Task tool
- `plugins/core/agents/scanner.md` - Update to invoke 4 agents in parallel (add policy-writer alongside existing 3)
- `plugins/core/commands/scan.md` - Update git add to include `.workaholic/policies/`

## Related History

The scanner/writer orchestration pattern is well established through multiple iterations. The spec-writer currently follows a sequential analysis approach (soon to be replaced by viewpoint-based parallel analysts), and the scanner invokes 3 writers in parallel. The proposed policy-writer mirrors this exact pattern, adding a fourth concurrent writer to the scanner.

Past tickets that touched similar areas:

- [20260207023921-viewpoint-based-spec-architecture.md](.workaholic/tickets/todo/20260207023921-viewpoint-based-spec-architecture.md) - Transforms spec-writer to orchestrate 8 parallel architecture-analyst subagents (same pattern: writer -> N parallel analysts)
- [20260203122448-add-story-moderator-and-scanner.md](.workaholic/tickets/archive/drive-20260203-122444/20260203122448-add-story-moderator-and-scanner.md) - Introduced scanner two-tier orchestration pattern (same component: scanner)
- [20260203182617-extract-scan-command.md](.workaholic/tickets/archive/drive-20260203-122444/20260203182617-extract-scan-command.md) - Extracted /scan as standalone command from /report (same component: scanner)
- [20260205203449-add-filesystem-validation-to-spec-writer.md](.workaholic/tickets/archive/drive-20260205-195920/20260205203449-add-filesystem-validation-to-spec-writer.md) - Added structure validation to spec-writer (same layer: Config)
- [20260123235437-performance-analyst-subagent.md](.workaholic/tickets/archive/feat-20260123-191707/20260123235437-performance-analyst-subagent.md) - Added performance-analyst subagent with analyze skill pattern (same architecture: analyst + analyze-* skill)

## Implementation Steps

1. **Create `plugins/core/skills/analyze-policy/SKILL.md`** - Comprehensive skill defining all 7 policy domains:

   For each policy domain, define:
   - Slug (kebab-case identifier used as filename)
   - Description (what this policy covers)
   - Analysis prompts (specific questions to answer about the repository)
   - Output template (section structure for the generated policy document)

   The 7 policy domains:
   - **test**: The verification and validation strategy -- testing levels, coverage targets, and processes that ensure correctness
   - **security**: The assets worth protecting, threat model, authentication/authorization boundaries, and safeguards in place
   - **quality**: Code quality standards, linting rules, review processes, and metrics (e.g., complexity, duplication) used to maintain maintainability
   - **accessibility**: Compliance targets (WCAG levels, i18n support), assistive technology considerations, and inclusive design practices
   - **observability**: The observability strategy -- metrics collected, logging practices, tracing implementation, and alerting thresholds
   - **delivery**: The CI/CD pipeline stages, deployment strategies (blue-green, canary, etc.), and artifact promotion flow from source to production
   - **recovery**: Data backup schedules, retention policies, disaster recovery procedures, and RTO/RPO targets

   Include:
   - Inference baseline guidelines (document what exists, clearly mark inferred vs explicit knowledge)
   - Comprehensiveness policy (document everything discoverable, mark gaps as "not observed")
   - Frontmatter template matching write-spec conventions (`title`, `description`, `category: developer`, `modified_at`, `commit_hash`)
   - File naming convention: `<slug>.md` and `<slug>_ja.md` under `.workaholic/policies/`

2. **Create `plugins/core/skills/analyze-policy/sh/gather.sh`** - Context gathering script:
   - Accept policy slug as `$1` and base branch as `$2` (default: `main`)
   - Output structured sections: BRANCH, POLICIES (existing policy files), DIFF (stat against base), COMMIT (short hash)
   - Include policy-domain-specific file scanning (e.g., for "test" slug, list test files; for "security" slug, list auth-related files; for "delivery" slug, list CI config files)
   - Follow the pattern established by `write-spec/sh/gather.sh` and `write-terms/sh/gather.sh`

3. **Create `plugins/core/agents/policy-analyst.md`** - Thin subagent:
   - Frontmatter: name, description, tools (Read, Write, Edit, Bash, Glob, Grep), skills (analyze-policy, translate)
   - Input: policy slug, base branch
   - Instructions:
     1. Run `gather.sh <slug> <base-branch>` to collect context
     2. Read analyze-policy skill for the specific policy domain definition
     3. Analyze the codebase from that policy perspective
     4. Write `.workaholic/policies/<slug>.md` following analyze-policy formatting rules
     5. Write `.workaholic/policies/<slug>_ja.md` following translate skill
   - Output: JSON with status and files written

4. **Create `plugins/core/agents/policy-writer.md`** - Thin orchestrator subagent:
   - Frontmatter: name, description, tools (Read, Write, Edit, Bash, Glob, Grep, Task), skills (gather-git-context)
   - Input: base branch (usually `main`)
   - Instructions:
     1. Gather context using gather-git-context skill
     2. Invoke 7 policy-analyst subagents in parallel via Task tool, each with a different policy slug (test, security, quality, accessibility, observability, delivery, recovery)
     3. After all complete, update `.workaholic/policies/README.md` and `README_ja.md` index files
     4. Collect results and report per-domain status
   - Output: JSON with per-policy status

5. **Update `plugins/core/agents/scanner.md`** - Add policy-writer as fourth parallel agent:
   - Update description to mention policy-writer
   - Add policy-writer invocation alongside existing 3 agents (changelog-writer, spec-writer, terms-writer)
   - Update output JSON to include `policy_writer` status field

6. **Update `plugins/core/commands/scan.md`** - Include policies in git staging:
   - Update git add command to include `.workaholic/policies/`
   - Update description to mention policies

7. **Create `.workaholic/policies/README.md`** and **`.workaholic/policies/README_ja.md`** - Index files:
   - List all 7 policy documents with brief descriptions
   - Link to both English and Japanese versions
   - Follow the same index pattern as `.workaholic/specs/README.md`

## Patches

### `plugins/core/agents/scanner.md`

```diff
--- a/plugins/core/agents/scanner.md
+++ b/plugins/core/agents/scanner.md
@@ -1,6 +1,6 @@
 ---
 name: scanner
-description: Invoke documentation scanners (changelog-writer, spec-writer, terms-writer) in parallel.
+description: Invoke documentation scanners (changelog-writer, spec-writer, terms-writer, policy-writer) in parallel.
 tools: Read, Write, Edit, Bash, Glob, Grep, Task
 skills:
   - gather-git-context
@@ -8,13 +8,14 @@

 # Scanner

-Invoke documentation scanning agents in parallel and return their combined status.
+Invoke documentation scanning agents in parallel and return their combined status.

 ## Instructions

 1. **Gather context** using the preloaded gather-git-context skill (uses branch, base_branch, repo_url)

-2. **Invoke 3 agents in parallel** via Task tool (single message with 3 tool calls):
+2. **Invoke 4 agents in parallel** via Task tool (single message with 4 tool calls):

 - **changelog-writer** (`subagent_type: "core:changelog-writer"`, `model: "opus"`): Updates `CHANGELOG.md` with entries from archived tickets. Pass repository URL.
 - **spec-writer** (`subagent_type: "core:spec-writer"`, `model: "opus"`): Updates `.workaholic/specs/` to reflect codebase changes. Pass branch name.
 - **terms-writer** (`subagent_type: "core:terms-writer"`, `model: "opus"`): Updates `.workaholic/terms/` with new terms. Pass branch name.
+- **policy-writer** (`subagent_type: "core:policy-writer"`, `model: "opus"`): Updates `.workaholic/policies/` with policy documents. Pass branch name.

-Wait for all 3 agents to complete. Track which succeeded and which failed.
+Wait for all 4 agents to complete. Track which succeeded and which failed.

 ## Output

@@ -25,5 +26,6 @@ Return JSON with status of each writer:
 {
   "changelog_writer": { "status": "success" | "failed", "error": "..." },
   "spec_writer": { "status": "success" | "failed", "error": "..." },
-  "terms_writer": { "status": "success" | "failed", "error": "..." }
+  "terms_writer": { "status": "success" | "failed", "error": "..." },
+  "policy_writer": { "status": "success" | "failed", "error": "..." }
 }
```

### `plugins/core/commands/scan.md`

```diff
--- a/plugins/core/commands/scan.md
+++ b/plugins/core/commands/scan.md
@@ -1,6 +1,6 @@
 ---
 name: scan
-description: Update .workaholic/ documentation (changelog, specs, terms).
+description: Update .workaholic/ documentation (changelog, specs, terms, policies).
 ---

 # Scan
@@ -8,7 +8,7 @@

 **Notice:** When user input contains `/scan` - whether "run /scan", "do /scan", "update /scan", or similar - they likely want this command.

-Update `.workaholic/` documentation by invoking the scanner subagent.
+Update `.workaholic/` documentation by invoking the scanner subagent.

 ## Instructions

 1. **Invoke scanner** (`subagent_type: "core:scanner"`, `model: "opus"`)
-2. **Stage and commit**: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ && git commit -m "Update documentation"`
+2. **Stage and commit**: `git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ && git commit -m "Update documentation"`
 3. **Report results** from scanner output
```

## Considerations

- **3-level nesting**: The call chain `scanner -> policy-writer -> 7x policy-analyst` creates depth 3 nesting, identical to the proposed `scanner -> spec-writer -> 8x architecture-analyst` from the viewpoint ticket. This is acceptable because all 7 analyst invocations are parallel, not sequential (`plugins/core/agents/scanner.md`)
- **Coordination with viewpoint ticket**: The viewpoint-based spec architecture ticket (`20260207023921-viewpoint-based-spec-architecture.md`) transforms the spec-writer into the same pattern this ticket introduces for policies. Implementation order does not matter since they modify different files, but both modify `scanner.md` -- the second ticket implemented should merge cleanly since changes are additive (`.workaholic/tickets/todo/20260207023921-viewpoint-based-spec-architecture.md`)
- **Output volume**: 14 files per scan (7 policies x 2 languages) adds to the scanner's total output. Combined with the viewpoint ticket's 16 spec files and existing terms/changelog, a full scan could produce 40+ file writes. Ensure policy-analyst subagents produce substantive content rather than thin stubs (`.workaholic/policies/`)
- **Repository-agnostic policies**: Many policy domains (security, delivery, recovery, observability) may have no explicit evidence in a given repository. The analyze-policy skill must handle this gracefully by documenting what is observed and marking gaps as "not observed" rather than inventing policies (`plugins/core/skills/analyze-policy/SKILL.md`)
- **Shell script policy**: The `gather.sh` script must follow the shell script principle from CLAUDE.md -- all conditional logic for domain-specific file scanning belongs in the script, not inline in agent markdown (`plugins/core/skills/analyze-policy/sh/gather.sh`)
- **Index file management**: The policy-writer must create and maintain `README.md` and `README_ja.md` under `.workaholic/policies/`. These must also be linked from the parent `.workaholic/README.md` and `README_ja.md` (`plugins/core/agents/policy-writer.md`)
- **Skill scope boundary**: The `analyze-policy` skill defines policy domain knowledge. It should not duplicate write-spec formatting rules. Policy documents follow the same frontmatter and content style as specs, so policy-analyst should reference write-spec conventions where applicable (`plugins/core/skills/analyze-policy/SKILL.md`)
- **Scanner description update**: The scanner's description string in its frontmatter must be updated to include policy-writer, and the scan command's description must also reflect the new output directory (`plugins/core/agents/scanner.md`, `plugins/core/commands/scan.md`)
