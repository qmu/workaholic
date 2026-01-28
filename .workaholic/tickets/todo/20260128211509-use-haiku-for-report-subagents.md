---
title: Use Haiku model for /report subagents
category: enhancement
created_at: 2026-01-28T21:15:09+09:00
---

# Use Haiku model for /report subagents

## Context

The `/report` command invokes 6 subagents via the Task tool:

**Phase 1 (parallel)**:
- `core:changelog-writer`
- `core:spec-writer`
- `core:terms-writer`
- `core:release-readiness`

**Phase 2**:
- `core:story-writer`

**Phase 3**:
- `core:pr-creator`

Currently, no `model` parameter is specified, so subagents inherit the parent model (likely Sonnet or Opus). Using Haiku for these subagents would reduce cost and latency while maintaining adequate quality for documentation generation tasks.

## Related History

None found.

## Task

Add `model: "haiku"` parameter to each Task tool invocation in `plugins/core/commands/report.md`.

## Implementation

1. **Edit `plugins/core/commands/report.md`**:
   - In Phase 1 instructions, specify that each of the 4 parallel Task tool calls should include `model: "haiku"`
   - In Phase 2 instructions, specify that story-writer Task tool call should include `model: "haiku"`
   - In Phase 3 instructions (step 7), specify that pr-creator Task tool call should include `model: "haiku"`

2. **Update the documentation** to make it clear that Haiku is the intended model for cost-efficiency

## Example Change

Before:
```
Invoke 4 agents in parallel via Task tool (single message with 4 tool calls):
- **changelog-writer** (`subagent_type: "core:changelog-writer"`)
```

After:
```
Invoke 4 agents in parallel via Task tool (single message with 4 tool calls, each with `model: "haiku"`):
- **changelog-writer** (`subagent_type: "core:changelog-writer"`, `model: "haiku"`)
```

## Verification

- Run `/report` and confirm subagents are invoked with Haiku model
- Documentation generation should complete successfully with comparable quality
