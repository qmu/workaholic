---
name: discover
description: Guidelines for discovering historical context, source code, and ticket overlaps.
allowed-tools: Bash
user-invocable: false
---

# Discover

Context discovery guidelines for ticket creation. Three discovery phases run in parallel by separate subagents.

## Discover History

Search archived tickets to find related past work.

### Instructions

Run the bundled script with keywords extracted from the ticket request:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/discover/sh/search.sh <keyword1> [keyword2] ...
```

### Keyword Extraction

Extract 3-5 keywords from:
- Key file paths (e.g., `ticket.md`, `drive.md`)
- Domain terms (e.g., `branch`, `commit`, `archive`)
- Layer names (e.g., `Config`, `UX`)

### Output Format

The script returns matches sorted by relevance (match count):

```
5 .workaholic/tickets/archive/feat-xxx/ticket-a.md
3 .workaholic/tickets/archive/feat-yyy/ticket-b.md
```

### Interpreting Results

- Higher count = more keyword matches = more relevant
- Read top 5 tickets to understand context
- Extract: title, overview, key files, layer

## Discover Source

Guidelines for finding and analyzing source code related to a ticket. Provides comprehensive exploration strategies for collecting rich codebase context.

### Exploration Phases

#### Phase 1: Direct Matches

Start with files directly matching the request keywords.

- Glob for files matching keywords from request
- Grep for function/class names mentioned
- Read directly relevant files (5-10 files)
- **Capture code snippets** from sections likely to be modified (store start/end lines and content)

#### Phase 2: Import Chain Exploration

Follow dependencies to understand context.

- For each Phase 1 file, extract import statements
- Follow imports to find upstream dependencies (depth 2 max)
- Trace exports to find downstream consumers
- Read dependency files that provide context (additional 5-10 files)

#### Phase 3: Usage Discovery

Find how code is used across the codebase.

- Grep for function/class usage across codebase
- Find example invocations in other modules
- Locate integration points (additional 3-5 files)

#### Phase 4: Related Test Files

Understand expected behavior from tests.

- For each source file `foo.ts`, check for `foo.test.ts`, `foo.spec.ts`
- Search `__tests__/`, `tests/`, `spec/` directories
- Read test files to understand expected behavior (additional 3-5 files)

#### Phase 5: Configuration and Schema Files

Find related configuration and type definitions.

- Find related config files (package.json, tsconfig, webpack)
- Locate schema definitions, type declarations (`*.d.ts`)
- Check for related documentation files (additional 2-3 files)

### Depth Controls

- **Hard limits per phase**: Phase 1 (8 files), Phase 2 (6), Phase 3 (3), Phase 4 (2), Phase 5 (1)
- **Relevance scoring**: Prioritize files with higher keyword density
- **Stop conditions**: Stop following chains when files become tangential
- **Total budget**: Hard limit of 20 files total - stop exploration immediately upon reaching limit
- **Time budget**: Complete exploration within 30 seconds

**Important**: These are hard limits, not guidelines. Stop adding files once limits are reached.

### Exploration Heuristics

#### Language-Specific Patterns

- **TypeScript/JavaScript**: Follow `import`/`require` statements, check `*.d.ts` files
- **Python**: Follow `import`/`from` statements, check `__init__.py` files
- **Markdown plugins**: Follow `skills:` frontmatter references, check SKILL.md patterns
- **Configuration**: Check `package.json` dependencies, tool config files

#### Skip Patterns

Avoid files that add noise without value:

- Generated files (`*.min.js`, `*.bundle.js`, `dist/`, `build/`)
- Lock files (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`)
- Large binary files
- Third-party dependencies (`node_modules/`, `vendor/`, `.venv/`)
- Cache directories (`.cache/`, `__pycache__/`)

### Source Output Format

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
  "snippets": [
    {
      "path": "path/to/file.ts",
      "start_line": 10,
      "end_line": 25,
      "content": "actual code content that may need modification"
    }
  ],
  "import_graph": "Brief description of dependency relationships",
  "code_flow": "How components interact end-to-end",
  "patterns": ["Existing patterns discovered that should be followed"],
  "test_coverage": "Summary of existing test coverage in affected areas"
}
```

#### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `summary` | Yes | High-level synthesis of findings |
| `files` | Yes | List of relevant files with metadata |
| `snippets` | Optional | Code snippets likely to need modification (for patch generation) |
| `import_graph` | Optional | Dependency relationships discovered |
| `code_flow` | Yes | Component interaction description |
| `patterns` | Optional | Patterns to follow in implementation |
| `test_coverage` | Optional | Existing test coverage summary |

### Tool Constraints

The source-discoverer has access to Glob, Grep, Read tools only:

- Cannot execute code or follow dynamic imports
- Cannot analyze runtime behavior
- Static analysis of source files only
- Large files may need partial reads (use Read with offset/limit)

## Discover Ticket

Guidelines for analyzing existing tickets to determine if a proposed ticket should proceed, merge with existing, or trigger a split.

### Search Locations

Search these directories for existing tickets:

- `.workaholic/tickets/todo/*.md` - Pending tickets
- `.workaholic/tickets/icebox/*.md` - Deferred tickets

### Overlap Analysis Criteria

#### Category Definitions

| Category | Overlap | Action |
|----------|---------|--------|
| **Duplicate** | 80%+ | Block creation - existing ticket covers request |
| **Merge candidate** | 40-80% | Suggest combining into single ticket |
| **Split candidate** | N/A | Existing ticket too broad - suggest decomposition |
| **Related** | <40% | Can coexist - note for cross-reference |

#### Calculating Overlap Percentage

Evaluate overlap based on:

1. **Key files overlap**: Do tickets modify the same files?
   - Same primary file = +40%
   - Overlapping key files = +20% per file
2. **Scope overlap**: Do tickets solve the same problem?
   - Identical goal = +40%
   - Subset/superset relationship = +20%
3. **Implementation overlap**: Would work be duplicated?
   - Same code changes = +20%

#### Duplicate Detection (80%+)

A ticket is a duplicate when:
- Same key files AND same implementation goal
- Existing ticket fully addresses the request
- Creating new ticket would duplicate completed work

Example: Request for "add validation to login form" when ticket exists for "implement form validation across auth pages"

#### Merge Candidates (40-80%)

Tickets are merge candidates when:
- Significant key file overlap (2+ shared files)
- Related but distinct goals that benefit from unified approach
- Sequential dependencies that should be one atomic change

Example: "Add error handling to API client" and "Improve API timeout behavior" - both touch the same module

#### Split Candidates

An existing ticket needs splitting when:
- Covers multiple distinct features/concerns
- Key files span unrelated areas
- Implementation steps lack cohesion
- Estimated effort exceeds 4h

Example: "Refactor user module and update dashboard" - these are unrelated concerns

#### Related Tickets (<40%)

Tickets are related (not blocking) when:
- Minor file overlap (1 shared file)
- Same domain area but different goals
- Useful context but independent implementation

### Evaluation Process

1. **Extract keywords** from proposed ticket description
2. **Glob search** for tickets in todo/ and icebox/
3. **Read matching tickets** and compare:
   - Key Files sections
   - Implementation Steps
   - Overview goals
4. **Calculate overlap** per criteria above
5. **Categorize each match** and determine status

### Ticket Output Schema

Return structured JSON recommendation:

```json
{
  "status": "clear|duplicate|needs_decision",
  "matches": [
    {
      "path": ".workaholic/tickets/todo/filename.md",
      "title": "Ticket title from H1",
      "category": "duplicate|merge|split|related",
      "overlap_percentage": 85,
      "reason": "Specific explanation of overlap"
    }
  ],
  "recommendation": "Action to take"
}
```

#### Status Values

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `clear` | No blocking issues | Proceed with ticket creation |
| `duplicate` | Existing ticket covers request | Do not create new ticket |
| `needs_decision` | Merge/split opportunity found | User must decide strategy |

#### Recommendation Examples

- `"Proceed"` - No conflicts found
- `"Block - duplicate of 20260101-feature.md"` - Exact duplicate exists
- `"Merge with 20260101-feature.md - both modify API client"` - Merge candidate
- `"Split 20260101-large-ticket.md before creating"` - Split candidate
- `"Proceed - related to 20260101-feature.md (cross-reference)"` - Related only
