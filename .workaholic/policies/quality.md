---
title: Quality Policy
description: Code quality standards, linting rules, review processes, and metrics used to maintain maintainability
category: developer
modified_at: 2026-02-12T10:15:46+00:00
commit_hash: f385117
---

[English](quality.md) | [Japanese](quality_ja.md)

# Quality Policy

This policy documents the code quality standards, linting rules, review processes, and metrics used to maintain maintainability in the Workaholic project. Quality enforcement is achieved through CI validation, post-tool hooks, configuration rules, and performance evaluation frameworks.

## Linting and Formatting

### Shell Script Standards

All shell scripts must follow POSIX sh compatibility standards enforced through the `shell.md` rule file (`.claude-plugin/plugin.json` loads rules from `plugins/core/rules/`).

**Shebang requirement**: Scripts must use `#!/bin/sh -eu` to enable strict mode (`-e` exits on error, `-u` errors on undefined variables). (Enforced by `plugins/core/rules/shell.md`.)

**Forbidden bash features**: Arrays, `[[ ]]`, `declare`, and other bash-specific constructs are prohibited. This ensures scripts run on Alpine Linux containers which lack bash. (Enforced by `plugins/core/rules/shell.md`.)

**Inline complexity prohibition**: Commands and agents cannot contain complex inline shell commands. Prohibited constructs include conditionals (`if`, `case`, `test`, `[ ]`, `[[ ]]`), pipes and chains (`|`, `&&`, `||`), text processing (`sed`, `awk`, `grep`, `cut`), loops (`for`, `while`), and variable expansion with logic (`${var:-default}`, `${var:+alt}`). All multi-step or conditional operations must be extracted to bundled scripts in skills (`skills/<name>/sh/<script>.sh`). (Enforced by `CLAUDE.md` Shell Script Principle and verified through code review.)

**Validation**: 21 shell scripts in the codebase follow these standards. Most use `#!/bin/sh -eu`, while one hook uses `#!/bin/bash` and two helper scripts lack the `-eu` flags. (Verified via `find . -name "*.sh" -type f | wc -l`.)

### TypeScript Conventions

The `typescript.md` rule defines coding standards enforced through code review:

**Type safety**: Prefer `unknown` over `any`, avoid `as` type assertions in favor of type guards. (Enforced by `plugins/core/rules/typescript.md`.)

**Style preferences**: Use `type` over `interface`, prefer `undefined` over `null`, inline single-use types in function signatures. (Enforced by `plugins/core/rules/typescript.md`.)

**Dead code policy**: Delete unused exports, components, and functions immediately. Always grep for usage before editing code. (Enforced by `plugins/core/rules/typescript.md`.)

**Import organization**: Use path aliases (e.g., `@lib/*`, `@utils/*`) instead of relative imports (`../`). Only use `./` for same-directory imports. (Enforced by `plugins/core/rules/typescript.md`.)

**Note**: The project contains no TypeScript files currently, making these standards preparatory for future development.

### Documentation Standards

**Mermaid requirement**: All diagrams must use Mermaid syntax in fenced code blocks, not ASCII art. Box-drawing characters (`+--+`, `|`, `└──`), ASCII arrows (`-->`, `==>`, `->`), and manual alignment with spaces are prohibited. Node labels containing special characters (`/`, `{`, `}`, `[`, `]`) must be quoted to prevent GitHub rendering errors. (Enforced by `plugins/core/rules/diagrams.md`.)

**Heading numbering**: Numbered headings are required for h2 and h3 levels in specs, terms, stories, and skills (e.g., `## 1. Section`, `### 1-1. Subsection`). READMEs and configuration docs are exempt. (Enforced by `plugins/core/rules/general.md`.)

**Markdown links**: When referencing `.md` files in documentation, use markdown links (`[filename.md](path/to/file.md)`) not backticks. This applies especially to stable docs (specs, terms, stories). (Enforced by `plugins/core/rules/general.md`.)

### Multi-Language Documentation

**i18n enforcement**: All files in `.workaholic/` must have corresponding Japanese translations (`_ja.md` suffix). Each language's README must link to documents in the same language, creating parallel link structures. The project respects the CLAUDE.md language setting - if the primary language is Japanese, `_ja.md` translations are not produced (they would duplicate the primary content). (Enforced by `plugins/core/rules/i18n.md` and verified through the `translate` skill.)

**Language separation**: Code and code comments, commit messages, pull requests, and documentation outside `.workaholic/` use English only. The `.workaholic/` directory supports both English and Japanese. (Enforced by `CLAUDE.md` Written Language section.)

## Code Review

### Manual Review Process

**Approval workflow**: The `/drive` command implements a mandatory approval flow. After implementing each ticket, the system presents changes to the developer using `AskUserQuestion` with selectable options (Approve, Approve and stop, Abandon, Other). Free-form feedback is supported through the "Other" option. (Enforced by `plugins/core/commands/drive.md` and `plugins/core/skills/drive-approval/SKILL.md`.)

**Revision tracking**: When developers provide feedback, the ticket file is updated BEFORE code changes. A Discussion section is appended with timestamp, verbatim feedback, ticket updates, and direction change interpretation. Subsequent revisions are numbered (Revision 1, Revision 2, etc.). (Enforced by `plugins/core/skills/drive-approval/SKILL.md` Section 3.)

**Abandonment documentation**: When implementations are abandoned, a Failure Analysis section is appended to the ticket documenting what was attempted, why it failed, and insights for future attempts. Changes are discarded via `git restore`, and the ticket is archived to `.workaholic/tickets/abandoned/`. (Enforced by `plugins/core/skills/drive-approval/SKILL.md` Section 4.)

### Automated Review

**Ticket validation hook**: A PostToolUse hook (`plugins/core/hooks/validate-ticket.sh`) validates ticket frontmatter on every Write or Edit operation with a 10-second timeout. It checks filename format (YYYYMMDDHHmmss-*.md), directory location (todo/, icebox/, or archive/<branch>/), frontmatter presence, and required fields (created_at in ISO 8601, author as email excluding @anthropic.com, type from enumerated values, layer as YAML array, effort from valid formats, commit_hash as git hash, category from enumerated values). (Enforced by `plugins/core/hooks/validate-ticket.sh` and registered in `plugins/core/.claude-plugin/plugin.json`.)

**CI validation**: The `validate-plugins.yml` workflow runs on push and pull requests to main. It validates JSON syntax in `marketplace.json` and `plugin.json` files, checks required fields (name, version), verifies skill file paths exist, and ensures marketplace plugins match directory structure. (Enforced by `.github/workflows/validate-plugins.yml`.)

**Output validation**: Before updating README indexes, the `validate-writer-output` skill verifies that analyst subagent output files exist and are non-empty. It returns per-file status (ok, missing, empty) and an overall pass/fail flag. README updates are blocked if validation fails. (Enforced by `plugins/core/skills/validate-writer-output/SKILL.md`.)

## Quality Metrics

### Complexity Constraints

**Component size policy**: Commands are orchestration-only (~50-100 lines), subagents are orchestration-only (~20-40 lines), skills are comprehensive knowledge (~50-150 lines). This "thin commands and subagents, comprehensive skills" principle enforces separation of concerns. (Enforced by `CLAUDE.md` Design Principle.)

**Nesting boundaries**: The architecture enforces strict invocation boundaries. Commands can invoke skills and subagents. Subagents can invoke skills and other subagents but not commands. Skills can invoke other skills but not subagents or commands. (Enforced by `CLAUDE.md` Component Nesting Rules.)

### Decision Quality Evaluation

The `analyze-performance` skill evaluates development branch decision-making across five dimensions:

**Consistency**: Did decisions follow established patterns? Were similar problems solved similarly? Did pivots converge toward better solutions rather than oscillate indecisively?

**Intuitivity**: Were solutions obvious and easy to understand? Did decisions align with common expectations? Would another developer find the choices natural?

**Describability**: Did final names land well? Were naming improvements made when better options were discovered? Did terminology avoid semantic conflicts and support future extension?

**Agility**: How well did the developer respond to unexpected issues? Did they iterate effectively, incorporating lessons learned into subsequent work? Were course corrections made quickly when needed?

**Density**: Does the code express meaning economically? Is the ratio of conceptual value to textual surface area high? Does the solution achieve its purpose without verbose scaffolding, redundant abstractions, or diluted semantics?

Each dimension receives a rating (Strong, Adequate, Needs Improvement) with 1-2 sentences of evidence-based analysis. The evaluation distinguishes productive iteration (convergence toward better solutions) from indecisive oscillation. (Enforced by `plugins/core/skills/analyze-performance/SKILL.md` and invoked by the story-writer agent.)

### Performance Metrics

The `calculate.sh` script in the `analyze-performance` skill computes quantitative branch metrics:

- Commit count
- Duration (hours and business days)
- Start and end timestamps
- Velocity (commits per time unit)

These metrics are calculated from git history and included in branch stories for transparency. (Enforced by `plugins/core/skills/analyze-performance/sh/calculate.sh` and invoked by the story-writer agent.)

## Type Safety

**No build step**: This is a configuration/documentation project with no build step required. Type checking is not applicable to the current codebase. (Documented in `CLAUDE.md` Type Checking section.)

**Future TypeScript support**: The `typescript.md` rule defines type safety standards (prefer `unknown` over `any`, avoid `as` assertions) that will apply when TypeScript files are added to the project. (Enforced by `plugins/core/rules/typescript.md`.)

## Observations

The project enforces quality through multiple complementary mechanisms:

1. **Rule files** define standards for shell scripts, TypeScript, diagrams, i18n, and general conventions
2. **PostToolUse hook** validates ticket format and frontmatter on every write operation
3. **CI workflow** validates JSON configuration and plugin structure
4. **Manual approval flow** requires developer review before committing each ticket implementation
5. **Performance evaluation** assesses decision quality across five dimensions
6. **Component size constraints** enforce separation of concerns through line count recommendations
7. **Architectural boundaries** prevent inappropriate cross-layer dependencies

Shell script compliance is high (19 scripts follow POSIX sh standards) but not perfect (1 bash script, 2 missing strict mode flags). Documentation standards (Mermaid, heading numbering, markdown links) rely on code review rather than automated enforcement. TypeScript standards are defined but unused as the codebase contains no TypeScript files.

The decision quality evaluation framework is comprehensive and evidence-based, distinguishing healthy iteration from problematic oscillation. Performance metrics provide quantitative transparency into development velocity.

## Gaps

**Automated linting**: No ESLint, Prettier, or shellcheck configurations exist. Linting is enforced through documentation (rule files) and code review rather than automated tooling.

**Complexity metrics**: No automated complexity thresholds (cyclomatic complexity, cognitive complexity, maximum function length) are configured. Complexity constraints rely on documentation-based line count recommendations (~50-100 lines for commands) rather than tooling.

**Duplication detection**: No automated duplication detection is configured. Duplication prevention relies on the architecture policy (skills as reusable knowledge layer) and code review.

**Coverage requirements**: No test coverage thresholds or reporting mechanisms exist. The project is primarily configuration/documentation with no application code requiring test coverage.

**Pre-commit hooks**: No pre-commit hooks (e.g., husky, lint-staged) exist for formatting or linting enforcement. Quality gates occur through the PostToolUse hook (ticket validation) and CI workflow (plugin validation) rather than git hooks.

**Documentation linting**: Mermaid syntax validation and markdown link checking are not automated. These rely on code review and manual verification.
