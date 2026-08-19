---
name: discover
description: Guidelines for discovering historical context, source code, and repository standards.
allowed-tools: Bash
user-invocable: false
metadata:
  internal: true
---

# Discover

Context discovery guidelines for ticket creation. Three modes run in parallel by separate subagents; each returns exactly its mode's JSON schema.

## Discover History

Search all tickets (archive, todo, icebox) for related past work, duplicates, and overlaps:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/discover/scripts/search.sh <keyword1> [keyword2] ...
```

Extract 3-5 keywords from key file paths, domain terms, and layer names. The script prints `match-count path` lines sorted by relevance; read the top 5 tickets and extract title, overview, and key files.

For matches in todo/ and icebox/, classify overlap with the proposed ticket. Score it: same primary file +40%, each overlapping key file +20%, identical goal +40%, subset/superset relationship +20%, duplicated code changes +20%.

| Category | Overlap | Action |
|----------|---------|--------|
| Duplicate | 80%+ — same key files AND same goal; existing ticket fully addresses the request | Block creation |
| Merge candidate | 40-80% — 2+ shared files, related-but-distinct goals, or an ordering that should be one atomic change | Suggest combining |
| Split candidate | existing ticket too broad — multiple distinct concerns, incohesive steps | Suggest decomposition |
| Related | <40% — minor overlap, same domain, independent implementation | Coexist; cross-reference |

### History Output Schema

```json
{
  "summary": "2-3 sentence synthesis of related historical work",
  "tickets": [{"path": "...", "title": "...", "match_reason": "..."}],
  "moderation": {
    "status": "clear|duplicate|needs_decision",
    "matches": [{"path": "...", "title": "...", "category": "duplicate|merge|split|related", "overlap_percentage": 85, "reason": "..."}],
    "recommendation": "Action to take"
  },
  "diagnosis_first": false
}
```

`clear` → proceed (set it, with empty `matches`, when no todo/icebox ticket matches); `duplicate` → do not create; `needs_decision` → the user chooses the merge/split strategy. `diagnosis_first` (see *Diagnosis-First Rule* below): `true` when the ask reports a failure of an existing mechanism, `false` (default) for a new-feature ask.

## Discover Source

Static exploration of the code the ticket touches, in five phases with hard per-phase file limits: direct keyword matches (8 files — glob/grep for keywords and named symbols, read the relevant files, capture snippets with start/end lines from sections likely to be modified), import-chain dependencies (6, depth 2, both upstream and consumers), usage sites across the codebase (3), related test files (2 — `foo.test.ts`, `__tests__/` etc.), config/schema/type definitions (1). Total budget: 20 files, ~30 seconds — hard limits, not guidelines; stop immediately at the cap and when chains turn tangential.

Follow the language's own linkage (`import`/`require` and `*.d.ts`, Python `import`/`from`, a markdown plugin's `skills:` frontmatter, tool config files). Skip noise: generated files (`dist/`, `*.min.js`), lockfiles, binaries, vendored deps (`node_modules/`, `vendor/`), caches.

### Source Output Schema

```json
{
  "summary": "2-3 sentence synthesis of codebase context",
  "files": [{"path": "...", "purpose": "...", "relevance": "...", "category": "direct|import|usage|test|config"}],
  "snippets": [{"path": "...", "start_line": 10, "end_line": 25, "content": "code likely to be modified"}],
  "import_graph": "dependency relationships",
  "code_flow": "how components interact end-to-end",
  "patterns": ["existing patterns to follow"],
  "test_coverage": "existing coverage in affected areas"
}
```

`summary`, `files`, and `code_flow` are required; `snippets` (feeds patch generation), `import_graph`, `patterns`, `test_coverage` optional. Glob/Grep/Read only — static analysis, no execution or runtime behavior; partial-read large files.

## Diagnosis-First Rule

Stated once here because both ticket-writing seams — `/ticket`'s Workflow §5 and
`/specificate`'s Emit-the-tickets step — already read this skill before authoring
Implementation Steps, and both would otherwise need to restate it.

An ask reporting a **failure of an existing mechanism** (a lookup misses, a check fails,
a routine silently no-ops) is not a new-feature ask: the live surface the failure lives
on must be measured before a fix is designed. Discover History already classifies a
ticket's overlap with prior work (*Duplicate / Merge / Split / Related*); extend the same
judgment with one more signal and carry it in the History output as
`"diagnosis_first": true|false` (default `false` — fail toward the ordinary, non-diagnosis
reading on ambiguity, since a false positive here only adds a reproduction step, while a
false negative on a genuine failure report ships a fix nobody measured).

When `diagnosis_first` is `true`, the ticket's Implementation Steps begin with
**reproducing and localizing the failure** — measuring the mechanism's actual live
behavior, not inferring it from the report — and design the fix only after that
measurement. Any mechanism the reporter proposes is recorded under `## Considerations` as
a hypothesis to weigh, never written into step 1 as the adopted design. Worked example:
commits `52681f0`/`3172a65` measured the notify thread-key lookup's actual miss (a
search-scope defect) before rewriting the ticket's steps, rather than adopting the
reporter's presumed persistence gap directly.

## Discover Policy

Identify repository standards, conventions, and architecture patterns. Read, in order: `CLAUDE.md` (primary source of explicit standards), rule files (`.claude/rules/`, plugin `rules/` dirs), README files at root and plugin level, tool config files (`tsconfig.json`, `.eslintrc`, `package.json`, …), and the four pillar policy skills — `workaholic:planning` / `workaholic:design` / `workaholic:implementation` / `workaholic:operation`, the canonical policy source; cite the specific policy when a discovered constraint maps to one (e.g. "workaholic:implementation — Domain Layer Separation").

Cover four categories: coding conventions (naming, formatting, imports, error handling, comment style), architecture decisions (component nesting and dependency rules, design principles such as "thin commands, comprehensive skills", layering, file organization), shell-script policies (script extraction over inline conditionals, `${CLAUDE_PLUGIN_ROOT}` path resolution, script locations), and documentation standards (file templates, frontmatter, required sections).

### Policy Output Schema

```json
{
  "summary": "2-3 sentence synthesis of repository standards approach",
  "policies": [{"category": "coding|architecture|shell|documentation", "source_file": "...", "description": "...", "evidence": "quoted or paraphrased text"}],
  "architecture": {"structure": "...", "principles": ["..."], "dependency_rules": "..."}
}
```

All three fields required.
