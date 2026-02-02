---
name: discover-source
description: Guidelines for exploring source code to understand context.
user-invocable: false
---

# Discover Source

Guidelines for finding and analyzing source code related to a ticket. Provides comprehensive exploration strategies for collecting rich codebase context.

## Exploration Phases

### Phase 1: Direct Matches

Start with files directly matching the request keywords.

- Glob for files matching keywords from request
- Grep for function/class names mentioned
- Read directly relevant files (5-10 files)

### Phase 2: Import Chain Exploration

Follow dependencies to understand context.

- For each Phase 1 file, extract import statements
- Follow imports to find upstream dependencies (depth 2 max)
- Trace exports to find downstream consumers
- Read dependency files that provide context (additional 5-10 files)

### Phase 3: Usage Discovery

Find how code is used across the codebase.

- Grep for function/class usage across codebase
- Find example invocations in other modules
- Locate integration points (additional 3-5 files)

### Phase 4: Related Test Files

Understand expected behavior from tests.

- For each source file `foo.ts`, check for `foo.test.ts`, `foo.spec.ts`
- Search `__tests__/`, `tests/`, `spec/` directories
- Read test files to understand expected behavior (additional 3-5 files)

### Phase 5: Configuration and Schema Files

Find related configuration and type definitions.

- Find related config files (package.json, tsconfig, webpack)
- Locate schema definitions, type declarations (`*.d.ts`)
- Check for related documentation files (additional 2-3 files)

## Depth Controls

- **Max files per phase**: Limit each phase to recommended file counts above
- **Relevance scoring**: Prioritize files with higher keyword density
- **Stop conditions**: Stop following chains when files become tangential
- **Total budget**: Target 20-30 files total across all phases
- **Time budget**: Complete exploration within 30 seconds

## Exploration Heuristics

### Language-Specific Patterns

- **TypeScript/JavaScript**: Follow `import`/`require` statements, check `*.d.ts` files
- **Python**: Follow `import`/`from` statements, check `__init__.py` files
- **Markdown plugins**: Follow `skills:` frontmatter references, check SKILL.md patterns
- **Configuration**: Check `package.json` dependencies, tool config files

### Skip Patterns

Avoid files that add noise without value:

- Generated files (`*.min.js`, `*.bundle.js`, `dist/`, `build/`)
- Lock files (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`)
- Large binary files
- Third-party dependencies (`node_modules/`, `vendor/`, `.venv/`)
- Cache directories (`.cache/`, `__pycache__/`)

## Output Format

Return structured JSON with categorized discoveries:

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

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `summary` | Yes | High-level synthesis of findings |
| `files` | Yes | List of relevant files with metadata |
| `import_graph` | Optional | Dependency relationships discovered |
| `code_flow` | Yes | Component interaction description |
| `patterns` | Optional | Patterns to follow in implementation |
| `test_coverage` | Optional | Existing test coverage summary |

## Tool Constraints

The source-discoverer has access to Glob, Grep, Read tools only:

- Cannot execute code or follow dynamic imports
- Cannot analyze runtime behavior
- Static analysis of source files only
- Large files may need partial reads (use Read with offset/limit)
