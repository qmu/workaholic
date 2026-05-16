---
name: discover
description: Guidelines for discovering historical context, source code, and repository standards.
allowed-tools: Bash
user-invocable: false
---

# Discover

Context discovery guidelines for ticket creation. Three discovery phases run in parallel by separate subagents.

## Discover History

Search all tickets (archive, todo, icebox) to find related past work and check for duplicates or overlaps.

### Instructions

Run the bundled script with keywords extracted from the ticket request:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/discover/scripts/search.sh <keyword1> [keyword2] ...
```

### Keyword Extraction

Extract 3-5 keywords from:
- Key file paths (e.g., `ticket.md`, `drive.md`)
- Domain terms (e.g., `branch`, `commit`, `archive`)
- Layer names (e.g., `Config`, `UX`)

### Output Format

The script searches archive, todo, and icebox directories. Results are sorted by relevance (match count):

```
5 .workaholic/tickets/archive/feat-xxx/ticket-a.md
3 .workaholic/tickets/todo/ticket-b.md
2 .workaholic/tickets/icebox/ticket-c.md
```

### Interpreting Results

- Higher count = more keyword matches = more relevant
- Read top 5 tickets to understand context
- Extract: title, overview, key files, layer

### Overlap Analysis

For tickets found in todo/ and icebox/, perform overlap analysis against the proposed ticket:

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

#### Merge Candidates (40-80%)

Tickets are merge candidates when:
- Significant key file overlap (2+ shared files)
- Related but distinct goals that benefit from unified approach
- Sequential dependencies that should be one atomic change

#### Split Candidates

An existing ticket needs splitting when:
- Covers multiple distinct features/concerns
- Key files span unrelated areas
- Implementation steps lack cohesion
- Estimated effort exceeds 4h

#### Related Tickets (<40%)

Tickets are related (not blocking) when:
- Minor file overlap (1 shared file)
- Same domain area but different goals
- Useful context but independent implementation

### History Output Schema

Return structured JSON combining historical context and ticket moderation:

```json
{
  "summary": "2-3 sentence synthesis of related historical work",
  "tickets": [
    {
      "path": ".workaholic/tickets/archive/branch/ticket.md",
      "title": "Ticket title",
      "match_reason": "Why this ticket is relevant"
    }
  ],
  "moderation": {
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
}
```

#### Moderation Status Values

| Status | Meaning | Next Action |
|--------|---------|-------------|
| `clear` | No blocking issues | Proceed with ticket creation |
| `duplicate` | Existing ticket covers request | Do not create new ticket |
| `needs_decision` | Merge/split opportunity found | User must decide strategy |

If no todo/icebox tickets match, set `moderation.status` to `"clear"` with empty `matches` array.

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

In source mode, the discoverer has access to Glob, Grep, Read, and Bash tools but should primarily use Glob, Grep, Read:

- Cannot execute code or follow dynamic imports
- Cannot analyze runtime behavior
- Static analysis of source files only
- Large files may need partial reads (use Read with offset/limit)

## Discover Policy

Guidelines for identifying repository standards, coding conventions, design decisions, and architecture patterns.

### Search Locations

Examine these locations for standards evidence:

- `CLAUDE.md` - Project-level instructions and architecture policy
- `.claude/rules/` - Repository-scoped rules
- Plugin rules directories (e.g., `plugins/*/rules/`)
- `README.md` files at root and plugin level
- Configuration files (`tsconfig.json`, `.eslintrc`, `.prettierrc`, `package.json`, etc.)
- Standards plugin content (`plugins/standards/`) — leading skills (`leading-*/SKILL.md`) are the canonical policy source

### Discovery Categories

#### Coding Conventions

Identify patterns for:
- Naming conventions (files, variables, functions)
- Formatting rules (indentation, line length, quotes)
- Import/export patterns
- Error handling patterns
- Comment and documentation style

#### Architecture Decisions

Identify structural patterns for:
- Component nesting rules (what can invoke what)
- Plugin/module dependency rules
- Design principles (e.g., "thin commands, comprehensive skills")
- Layering conventions (UX, Domain, Infrastructure, DB, Config)
- File organization patterns
- Apply the four leading skills (`standards:leading-{validity,availability,security,accessibility}`) as the project's authoritative policy lenses. Cite specific policies and practices when a discovered constraint maps to one (e.g., "leading-validity: Ours/Theirs Layer Segregation").

#### Shell Script Policies

Identify rules for:
- Script extraction requirements (no inline conditionals)
- Path resolution rules (`${CLAUDE_PLUGIN_ROOT}`)
- Script location conventions

#### Documentation Standards

Identify conventions for:
- File structure templates (frontmatter, sections)
- Naming conventions for documentation files
- Required sections and field formats

### Evaluation Process

1. **Read `CLAUDE.md`** at repository root - primary source of explicit standards
2. **Glob for rule files** in `.claude/rules/` and plugin rule directories
3. **Read README files** at root and plugin directories for conventions
4. **Scan configuration files** for tool-enforced standards
5. **Examine standards plugin** (if present) for formalized policies
6. **Synthesize findings** into categorized evidence

### Policy Output Schema

Return structured JSON with discovered standards:

```json
{
  "summary": "2-3 sentence synthesis of repository standards approach",
  "policies": [
    {
      "category": "coding|architecture|shell|documentation",
      "source_file": "path/to/source",
      "description": "What the policy requires",
      "evidence": "Quoted or paraphrased text from source"
    }
  ],
  "architecture": {
    "structure": "Brief description of repository structure",
    "principles": ["List of stated design principles"],
    "dependency_rules": "How components relate and what can invoke what"
  }
}
```

#### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `summary` | Yes | High-level synthesis of standards approach |
| `policies` | Yes | List of discovered policies with evidence |
| `architecture` | Yes | Structural patterns and principles |
