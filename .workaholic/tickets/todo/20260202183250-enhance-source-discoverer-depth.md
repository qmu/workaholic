---
created_at: 2026-02-02T18:32:50+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
---

# Enhance source-discoverer for Deeper and Wider Codebase Exploration

## Overview

Enhance the source-discoverer subagent and its discover-source skill to collect wider, deeper, and more varied related files to bring beneficial information to parent context. The current implementation is minimal - it searches for files matching keywords and reads 5-10 files. The enhanced version should follow import chains, find usage examples, check related test files, explore configuration files, and collect richer code context that helps ticket-organizer write better implementation guidance.

## Key Files

- `plugins/core/agents/source-discoverer.md` - Subagent definition (expand instructions)
- `plugins/core/skills/discover-source/SKILL.md` - Skill with search guidelines (comprehensive enhancement)

## Related History

Historical tickets show the source-discoverer was created as a parallel companion to history-discoverer, initially with minimal search guidelines. Recent refactoring moved discovery from skills to subagents for richer analysis capability.

Past tickets that touched similar areas:

- [20260129-parallel-discovery-ticket-command.md](.workaholic/tickets/archive/feat-20260129-023941/20260129-parallel-discovery-ticket-command.md) - Original source-discoverer creation (minimal implementation to enhance)
- [20260202135507-parallel-subagent-discovery-in-ticket-organizer.md](.workaholic/tickets/archive/drive-20260202-134332/20260202135507-parallel-subagent-discovery-in-ticket-organizer.md) - Refactored to subagent invocation for "richer analysis"
- [20260127202525-add-related-history-summary.md](.workaholic/tickets/archive/feat-20260126-214833/20260127202525-add-related-history-summary.md) - Pattern: adding synthesis layer to discovery output

## Implementation Steps

### 1. Expand discover-source skill with comprehensive search strategies

Update `plugins/core/skills/discover-source/SKILL.md` to include detailed exploration phases:

```markdown
## Exploration Phases

### Phase 1: Direct Matches (current behavior)
- Glob for files matching keywords
- Grep for function/class names
- Read directly relevant files (5-10 files)

### Phase 2: Import Chain Exploration
- For each Phase 1 file, extract import statements
- Follow imports to find upstream dependencies
- Trace exports to find downstream consumers
- Read dependency files that provide context (additional 5-10 files)

### Phase 3: Usage Discovery
- Grep for function/class usage across codebase
- Find example invocations in other modules
- Locate integration points (additional 3-5 files)

### Phase 4: Related Test Files
- For each source file `foo.ts`, check for `foo.test.ts`, `foo.spec.ts`
- Search `__tests__/`, `tests/`, `spec/` directories
- Read test files to understand expected behavior (additional 3-5 files)

### Phase 5: Configuration and Schema Files
- Find related config files (package.json, tsconfig, webpack)
- Locate schema definitions, type declarations
- Check for related documentation files (additional 2-3 files)
```

### 2. Add depth controls to skill

Add guidelines for controlling exploration depth:

```markdown
## Depth Controls

- **Max files per phase**: Limit each phase to reasonable file count
- **Relevance scoring**: Prioritize files with higher keyword density
- **Stop conditions**: Stop following chains when files become tangential
- **Total budget**: Target 20-30 files total across all phases
```

### 3. Enhance output structure for richer context

Expand the output JSON to include categorized discoveries:

```markdown
## Output Format

```json
{
  "summary": "2-3 sentence synthesis of codebase context",
  "files": [
    {
      "path": "path/to/file.ts",
      "purpose": "What this file does",
      "relevance": "Why it matters for the ticket",
      "category": "direct|import|usage|test|config"
    }
  ],
  "import_graph": "Brief description of dependency relationships",
  "code_flow": "How components interact end-to-end",
  "patterns": ["Existing patterns discovered that should be followed"],
  "test_coverage": "Summary of existing test coverage in affected areas"
}
```

### 4. Update source-discoverer agent instructions

Expand `plugins/core/agents/source-discoverer.md` instructions to reference the exploration phases:

```markdown
## Instructions

1. Extract keywords and patterns from the request
2. Execute Phase 1: Find directly matching files
3. Execute Phase 2: Follow import chains (depth 2 max)
4. Execute Phase 3: Discover usage examples
5. Execute Phase 4: Find related test files
6. Execute Phase 5: Locate config and schema files
7. Synthesize findings into structured output

For each phase:
- Use appropriate tools (Glob, Grep, Read)
- Score relevance and skip tangential files
- Collect code snippets that illustrate patterns
```

### 5. Add exploration heuristics

Document heuristics for smart exploration:

```markdown
## Exploration Heuristics

- **TypeScript/JavaScript**: Follow `import`/`require` statements, check `*.d.ts` files
- **Python**: Follow `import`/`from` statements, check `__init__.py` files
- **Markdown plugins**: Follow `skills:` frontmatter references, check SKILL.md patterns
- **Configuration**: Check `package.json` dependencies, tool config files

## Skip Patterns

- Generated files (`*.min.js`, `*.bundle.js`, `dist/`)
- Lock files (`package-lock.json`, `yarn.lock`)
- Large binary files
- Third-party dependencies (`node_modules/`, `vendor/`)
```

## Considerations

- **Performance**: More thorough exploration takes longer. The skill should balance depth with response time. Consider adding timing guidance (complete within 30 seconds).
- **Context limits**: Collecting too many files may exceed context limits when ticket-organizer processes results. The 20-30 file budget is a reasonable upper bound.
- **Skill vs agent responsibility**: Per architecture policy, comprehensive guidelines belong in the skill (discover-source), while the agent (source-discoverer) provides orchestration only.
- **Backward compatibility**: The output JSON adds new optional fields (`import_graph`, `patterns`, `test_coverage`) but maintains existing fields for compatibility.
- **Tool limitations**: The subagent has access to Glob, Grep, Read - it cannot execute code or follow dynamic imports. The skill should acknowledge these constraints.
