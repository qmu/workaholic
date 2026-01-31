---
type: enhancement
layer: Config
effort: 0.5h
created_at: 2026-01-31T18:29:05+09:00
author: a@qmu.jp
---

# Move performance-analyst to Phase 1 Parallel Execution

## Overview

Move `performance-analyst` from being invoked by `story-writer` in Phase 2 to running in parallel in Phase 1 alongside the other agents. This reduces total execution time by running performance analysis concurrently with changelog, spec, terms, and release-readiness updates. Phase 1 will have 5 parallel agents instead of 4.

New flow:
```
Phase 1: [changelog-writer, spec-writer, terms-writer, release-readiness, performance-analyst]
Phase 2: story-writer (receives release-readiness JSON + performance-analyst output)
Phase 3: pr-creator
```

## Related History

| Ticket | Relevance |
|--------|-----------|
| [invoke-release-readiness-in-parallel](../archive/feat-20260128-001720/20260127211737-invoke-release-readiness-in-parallel.md) | Same pattern: moved release-readiness from nested to parallel |
| [add-command-flow-spec](../archive/feat-20260128-220712/20260129020653-add-command-flow-spec.md) | Documents current Phase 1/2 architecture |
| [rename-report-to-story](../archive/feat-20260128-220712/20260129003905-rename-report-to-story.md) | Established current /story command structure |

## Key Files

| File | Purpose |
|------|---------|
| `plugins/core/commands/story.md` | Command orchestrating Phase 1 parallel agents |
| `plugins/core/agents/story-writer.md` | Currently invokes performance-analyst in step 5 |
| `plugins/core/agents/performance-analyst.md` | Agent to move to Phase 1 |
| `.workaholic/specs/command-flows.md` | Documentation of command execution flows |

## Implementation

### 1. Update story.md Command - Phase 1

Add performance-analyst as 5th parallel agent in Phase 1:

```markdown
**Phase 1**: Invoke 5 agents in parallel via Task tool (single message with 5 tool calls, each with `model: "haiku"`):

- **changelog-writer** ...
- **spec-writer** ...
- **terms-writer** ...
- **release-readiness** ...
- **performance-analyst** (`subagent_type: "core:performance-analyst"`, `model: "haiku"`): Evaluates decision quality

Pass to performance-analyst:
- List of archived tickets with overviews and final reports
- Git log (main..HEAD)
- Branch name for metrics context
```

### 2. Update story.md Command - Phase 2

Update Phase 2 to pass performance-analyst output to story-writer:

```markdown
**Phase 2**: Invoke **story-writer** (`subagent_type: "core:story-writer"`, `model: "haiku"`):
- Pass branch name and base branch
- Pass release-readiness JSON output (for section 10)
- Pass performance-analyst output (for section 9.2)
```

### 3. Update story-writer Agent

Remove step 5 (performance-analyst invocation) and update input/output:

**Input section:**
```markdown
You will receive:
- Branch name to generate story for
- Base branch (usually `main`)
- Release-readiness JSON output (from parallel agent invoked by `/story`)
- Performance-analyst output (from parallel agent invoked by `/story`)
```

**Instructions:**
- Remove step 5: "Get Performance Analysis: Invoke performance-analyst subagent..."
- Update step to just use the provided performance-analyst output

**Output section:**
- Change "Performance-analyst evaluation was included" to "Performance-analyst output was formatted into section 9.2"

### 4. Remove Task tool from story-writer

Update frontmatter to remove Task tool (no longer needed):

**Before:**
```yaml
tools: Read, Write, Edit, Bash, Glob, Grep, Task
```

**After:**
```yaml
tools: Read, Write, Edit, Bash, Glob, Grep
```

### 5. Update Documentation

Update `.workaholic/specs/command-flows.md`:
- Add performance-analyst to Phase 1 diagram
- Update component table
- Update notes about 5 parallel agents

Update `.workaholic/specs/architecture.md` dependency diagram:
- Show story command directly invoking performance-analyst
- Remove story-writer → performance-analyst connection

## Verification

1. Verify story.md invokes 5 agents in Phase 1
2. Verify story-writer no longer has Task tool or invokes performance-analyst
3. Verify performance-analyst output flows through Phase 2
4. Run `/story` to verify section 9.2 is populated correctly
