# Changelog

## feat-20260126-214833

### Added

- Add git guidelines to subagents to prevent confirmation prompts ([7933c67](https://github.com/qmu/workaholic/commit/7933c67958070b9132c948c6d17b8efa15629de8)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127010151-add-git-guidelines-to-subagents.md)
- Consolidate git guidelines into a rule for all subagents ([b94045a](https://github.com/qmu/workaholic/commit/b94045af226b52921e9e59dd49e02436bed8cb30)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127012323-strengthen-git-guidelines-in-subagents.md)

### Changed

- Convert sync-workaholic command to subagent ([d4e6a07](https://github.com/qmu/workaholic/commit/d4e6a07f95d7c129f16db5bc5d73ef34e9e649af)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127003251-sync-workaholic-subagent.md)
- Extract story-writer as subagent from pull-request command ([4c83014](https://github.com/qmu/workaholic/commit/4c83014d088d90ad784012bb5044ed3d79eff02a)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127004417-story-writer-subagent.md)
- Extract changelog-writer subagent and run 4 agents concurrently in pull-request ([b65d371](https://github.com/qmu/workaholic/commit/b65d371f39eaac6309eecba9612449a31d9e0c43)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127005414-changelog-writer-subagent-and-concurrent-pr-agents.md)
- Extract pr-creator subagent from pull-request command ([4ee763d](https://github.com/qmu/workaholic/commit/4ee763d9c0d9a07fdc4f202d0c058e36ecf4bf00)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127005601-pr-creator-subagent.md)
- Rename terminology to terms ([d213ea1](https://github.com/qmu/workaholic/commit/d213ea1d96b901c6194e44f730c31139f5cb6b19)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127010716-rename-terminology-to-terms.md)
- Fix Decision Review format in story-writer to match performance-analyst output ([d32bc52](https://github.com/qmu/workaholic/commit/d32bc52f912b2c07f28b070561e8978807995eb6)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127011734-fix-story-decision-review-format.md)
- Embed git guidelines directly in each subagent definition ([13101ad](https://github.com/qmu/workaholic/commit/13101ade1fbe400e79854bacc8324ccfb9377f67)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127013608-embed-git-guidelines-in-each-agent.md)
- Rename /pull-request to /report ([3005144](https://github.com/qmu/workaholic/commit/30051441da5c802398a053d9fdb760edd9cdb75d)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127014257-rename-pull-request-to-report.md)

### Removed

- Remove /sync-workaholic command ([d142373](https://github.com/qmu/workaholic/commit/d1423732616245c77e0438ea5047d089f03fcb11)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127010400-remove-sync-workaholic-command.md)
- Remove /commit command ([4e7658c](https://github.com/qmu/workaholic/commit/4e7658c7b5e0b865c829b4009a5e9988893e457b)) - [ticket](.workaholic/tickets/archive/feat-20260126-214833/20260127013941-remove-commit-command.md)

## [feat-20260126-131531](https://github.com/qmu/workaholic/tree/feat-20260126-131531)

### Added

- Add workaholic.md rule file for .workaholic/ directory conventions ([6ee6278](https://github.com/qmu/workaholic/commit/6ee6278))
  Enforces directory structure (only specs/, stories/, terminology/, tickets/ allowed), frontmatter requirements (author, modified_at), and timestamp field naming (_at suffix with datetime).

- Add commit_hash to stories README files ([cb96538](https://github.com/qmu/workaholic/commit/cb96538))
  Enables Claude to quickly identify git state and determine what changes need reflection.

### Changed

- Rename .work/ directory to .workaholic/ ([8778abe](https://github.com/qmu/workaholic/commit/8778abe))
  Aligns directory name with product name for consistency across the project.

- Standardize timestamp fields to _at convention with datetime ([5452b2d](https://github.com/qmu/workaholic/commit/5452b2d))
  All timestamp frontmatter fields now use _at suffix (e.g., modified_at instead of last_updated) with ISO 8601 datetime format.

- Rename /sync-work command to /sync-workaholic ([616d931](https://github.com/qmu/workaholic/commit/616d931))
  Aligns command name with directory name for consistency.

## [feat-20260124-200439](https://github.com/qmu/workaholic/tree/feat-20260124-200439)

### Added

- Add YAML frontmatter metadata to ticket files ([b7938ac](https://github.com/qmu/workaholic/commit/b7938ac)) - [ticket](.workaholic/tickets/archive/feat-20260124-200439/20260124210721-ticket-yaml-frontmatter.md)
  Enhances tickets with structured metadata (date, author, type, layer, effort) for better management and tracking.

- Add "Approve and stop" option to drive command ([4b7b10e](https://github.com/qmu/workaholic/commit/4b7b10e)) - [ticket](.workaholic/tickets/archive/feat-20260124-200439/20260125113309-drive-approve-and-stop-option.md)
  Enables developers to approve and commit the current ticket without processing remaining tickets.

- Auto-commit ticket file on creation ([455ed62](https://github.com/qmu/workaholic/commit/455ed62)) - [ticket](.workaholic/tickets/archive/feat-20260124-200439/20260125113858-auto-commit-ticket-on-creation.md)
  Tickets are immediately tracked in git history upon creation, separating planning from implementation commits.

- Invoke /sync-work on release ([55dcc77](https://github.com/qmu/workaholic/commit/55dcc77)) - [ticket](.workaholic/tickets/archive/feat-20260124-200439/20260125114146-invoke-sync-work-on-release.md)
  Documentation is synced automatically before publishing new releases.

### Changed

- Rename /sync-src-doc to /sync-work ([a87a013](https://github.com/qmu/workaholic/commit/a87a013)) - [ticket](.workaholic/tickets/archive/feat-20260124-200439/20260124225237-rename-sync-src-doc-to-sync-work.md)
  The new name better reflects the target directory `.workaholic/` rather than a generic "doc" folder.

- Rename ticket date field to created_at with datetime ([c82b53e](https://github.com/qmu/workaholic/commit/c82b53e)) - [ticket](.workaholic/tickets/archive/feat-20260124-200439/20260125113720-ticket-datetime-frontmatter.md)
  Uses ISO 8601 datetime format consistent with story timestamps.

- Require developer approval before moving tickets to icebox ([8935f8a](https://github.com/qmu/workaholic/commit/8935f8a)) - [ticket](.workaholic/tickets/archive/feat-20260124-200439/20260125114643-require-approval-for-icebox-moves.md)
  Prevents autonomous ticket moves; developers must approve all icebox operations.

### Removed

- Remove branch changelogs in favor of ticket frontmatter ([56855c7](https://github.com/qmu/workaholic/commit/56855c7)) - [ticket](.workaholic/tickets/archive/feat-20260124-200439/20260124223106-eliminate-branch-changelogs.md)
  Tickets are now the single source of truth for change metadata, eliminating the intermediate `.workaholic/changelogs/` directory.

## [feat-20260124-105903](https://github.com/qmu/workaholic/tree/feat-20260124-105903)

### Added

- Add Mermaid diagram requirement to general rules ([1f6cfb0](https://github.com/qmu/workaholic/commit/1f6cfb0)) - [ticket](.workaholic/tickets/archive/feat-20260124-105903/20260124120158-enforce-mermaid-for-diagrams.md)
  Prohibits ASCII art diagrams in favor of Mermaid syntax for better rendering and maintainability.
  Ensures language-specific READMEs maintain parallel link structure and replaces 'bilingual' terminology with 'i18n'.
  Provides translation policies as background knowledge for Claude, keeping technical terms in English for developer documentation.
  Enforces that spec documents must be placed in user-guide/ or developer-guide/ subdirectories matching their category.

### Changed

- Redefine Density to measure semantic expressiveness ([1fc163a](https://github.com/qmu/workaholic/commit/1fc163a)) - [ticket](.workaholic/tickets/archive/feat-20260124-105903/20260124192456-redefine-density-metric.md)
  The Density metric now evaluates how economically code expresses meaning, not commit efficiency. This separates code quality (semantic density) from workflow metrics (commit count).

- Use business days for multi-day performance metrics ([53f9765](https://github.com/qmu/workaholic/commit/53f9765)) - [ticket](.workaholic/tickets/archive/feat-20260124-105903/20260124144224-business-day-metrics.md)
  Raw elapsed hours are misleading for multi-day work because developers sleep and do other activities.
  Changed to use business days (count of distinct calendar days with commits) when duration exceeds 8 hours.
  Prevent /pull-request from pausing mid-execution by adding explicit no-confirmation instructions and mandatory PR URL output.
  Improve rule reliability by splitting 113-line general.md into focused files (diagrams.md, i18n.md) with path-specific frontmatter.
  Replaces complex heredoc approach with cleaner --body-file flag for updating existing PRs.

## [feat-20260123-191707](https://github.com/qmu/workaholic/tree/feat-20260123-191707)

### Added

- Add Japanese translations for .workaholic/ documentation ([b24e45c](https://github.com/qmu/workaholic/commit/b24e45c)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260124003751-bilingual-work-documentation.md)
  Creates Japanese translations for specs, stories, and terminology directories, implementing bilingual support for Japanese-speaking contributors.

- Add bilingual policy for .workaholic/ directory ([6ef2421](https://github.com/qmu/workaholic/commit/6ef2421)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260124002738-bilingual-work-directory-policy.md)
  Allows Japanese content in .workaholic/ directory while maintaining English-only policy for code, commits, and PRs.

- Add performance-analyst subagent for decision review ([bd64d64](https://github.com/qmu/workaholic/commit/bd64d64)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260123235437-performance-analyst-subagent.md)
  Extracts decision review logic into a dedicated subagent that evaluates decision-making quality across five viewpoints, providing more structured and consistent feedback in PR descriptions.

- Add multi-language documentation policy to general rules ([d378907](https://github.com/qmu/workaholic/commit/d378907)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260123234825-multi-language-documentation-policy.md)
  Provides guidance for structuring documentation when projects need multiple language support, covering naming conventions, folder structures, and language navigation.

- Move remaining tickets to icebox during PR creation ([c7acd5d](https://github.com/qmu/workaholic/commit/c7acd5d)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260123191605-pr-icebox-remaining-tickets.md)
  Prevents unfinished tickets from being silently ignored when creating a PR. Remaining tickets are now automatically moved to icebox with a warning.

### Changed

- Rebalance performance-analyst to value iteration over perfection ([3f6691e](https://github.com/qmu/workaholic/commit/3f6691e)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260124012341-performance-analyst-value-iteration.md)
  Shifts the evaluation framework to reward convergent iteration while only penalizing indecisive oscillation. Fast try-and-change cycles are healthy development practice, not poor planning.

- Refactor story to be the single source for PR description ([faa8b5a](https://github.com/qmu/workaholic/commit/faa8b5a)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260124005056-story-as-pr-description.md)
  Stories now contain the complete PR description content. The pull-request command generates a story and copies it directly to GitHub, eliminating duplication.

- Document automatic inclusion of uncommitted tickets in drive commits ([01ce7b6](https://github.com/qmu/workaholic/commit/01ce7b6)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260124002211-include-uncommitted-tickets-in-drive-commit.md)
  Clarifies that git add -A includes uncommitted ticket files, eliminating the need for separate ticket commits.

- Replace Reasonability with Describability in performance-analyst ([1418173](https://github.com/qmu/workaholic/commit/1418173)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260124001610-replace-reasonability-with-describability.md)
  Changes the evaluation focus from trade-off consideration to naming quality, semantic clarity, and extensible conventions.

- Merge tdd plugin into core for unified workflow ([8c6e57d](https://github.com/qmu/workaholic/commit/8c6e57d)) - [ticket](.workaholic/tickets/archive/feat-20260123-191707/20260124001231-merge-core-and-tdd-plugins.md)
  Simplifies the marketplace by consolidating ticket-driven development commands into the core plugin, providing a single comprehensive development workflow.

## [feat-20260123-032323](https://github.com/qmu/workaholic/tree/feat-20260123-032323)

### Added

- Add performance metrics and AI coaching to branch stories ([9aba6d9](https://github.com/qmu/workaholic/commit/9aba6d9)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123170120-add-performance-metrics-to-stories.md)
  Provides developer self-reflection through quantitative metrics and qualitative decision review, delivered as AI performance coaching in GitHub PR descriptions.

- Add branch story generation to pull-request workflow ([d1d7dc0](https://github.com/qmu/workaholic/commit/d1d7dc0)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123161059-branch-story-generation.md)
  Creates a narrative story document during PR creation that captures the developer's journey - motivation, challenges, and decisions - giving reviewers high-level context.

- Add commit_hash to doc specs frontmatter ([928baa2](https://github.com/qmu/workaholic/commit/928baa2)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123135636-add-commit-hash-frontmatter.md)
  Enables AI to understand documentation state at a specific git commit and discover changes by comparing hashes.

- Add cross-cutting documentation guidance to sync-doc-specs ([6ba46d5](https://github.com/qmu/workaholic/commit/6ba46d5)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123154228-sync-doc-specs-cross-cutting-docs.md)
  Enhances documentation to capture the big picture across files, directories, and layers rather than just file-by-file details.

### Changed

- Rename work/ to .workaholic/ for cleaner project root ([2c0f147](https://github.com/qmu/workaholic/commit/2c0f147)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123174516-rename-work-to-dotwork.md)
  The dot prefix makes development artifacts hidden, matching conventions of .git/, .claude/, .vscode/.

- Rename doc/ to work/ directory ([39b1729](https://github.com/qmu/workaholic/commit/39b1729)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123171203-rename-doc-to-work-directory.md)
  The name 'work' better reflects the purpose - containing working artifacts (tickets, changelogs, stories, specs) that support development, not just documentation.

- Rename story datetime fields to started_at/ended_at ([63da69a](https://github.com/qmu/workaholic/commit/63da69a)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123170651-rename-story-datetime-fields.md)
  Uses ISO 8601 datetime format for precise timing, following the \_at naming convention common for timestamp fields.

- Relocate changelogs to dedicated directory ([2d8d877](https://github.com/qmu/workaholic/commit/2d8d877)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123163827-relocate-changelogs-to-separate-directory.md)
  Separates change summaries from tickets into .workaholic/changelogs/ with flat structure, making changelogs easier to discover and browse.

- Improve doc/README.md as documentation hub ([6cb78fa](https://github.com/qmu/workaholic/commit/6cb78fa)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123164916-improve-doc-readme-as-index.md)
  Simplifies to link subdirectory READMEs and plugins, making it a single entry point for all documentation.

- Document cognitive investment as core design principle ([c5e6de0](https://github.com/qmu/workaholic/commit/c5e6de0)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123162007-document-cognitive-investment-principle.md)
  Explains why Workaholic generates extensive documentation artifacts - investing in tickets, specs, stories, and changelogs reduces developer cognitive load.

- Rename Philosophy to Design Policy throughout codebase ([4355638](https://github.com/qmu/workaholic/commit/4355638)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123161440-rename-philosophy-to-design-policy.md)
  Uses more concrete and actionable terminology - these are deliberate choices to follow, not abstract principles to contemplate.

- Rewrite sync-doc-specs as actionable command ([f5236d6](https://github.com/qmu/workaholic/commit/f5236d6)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123135431-rewrite-sync-doc-specs-command.md)
  Converts the thin 5-line wrapper into a comprehensive step-by-step command that Claude can execute directly without referencing external rules.

- Move code formatting from edit hook to PR workflow ([7eb9738](https://github.com/qmu/workaholic/commit/7eb9738)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123120608-silent-linter-reread.md)
  Eliminates verbose 'let me read the file again' announcements by removing per-edit formatting hooks and adding formatting as a pre-PR step instead.

### Removed

- Remove doc-specs rule in favor of explicit command ([740cfcf](https://github.com/qmu/workaholic/commit/740cfcf)) - [ticket](.workaholic/tickets/archive/feat-20260123-032323/20260123163947-remove-doc-specs-rule.md)
  Path-specific rules don't work reliably with plugins. The /sync-doc-specs command provides better control and clearer invocation.

## [feat-20260123-005256](https://github.com/qmu/workaholic/tree/feat-20260123-005256)

### Added

- Add final report step to drive command workflow ([2788d9d](https://github.com/qmu/workaholic/commit/2788d9d)) - [ticket](.workaholic/tickets/archive/feat-20260123-005256/20260123024044-drive-final-report.md)
  Creates historical record of implementation decisions by appending a Final Report section to tickets before archiving.
  Clarifies the conceptual difference: specs are snapshots of current state while tickets are change requests (past/future work log).
  Ensures every subdirectory has an index for discoverability and enforces the no-orphan-documents constraint.
  Enables doc-writer to delete outdated documentation files and empty directories, fulfilling the cleanup requirement in drive.md step 2.3.
  Enables richer PR summaries by capturing the motivation behind each change in the branch CHANGELOG.

### Changed

- Consolidate documentation rule and skill into path-specific rule ([e511e15](https://github.com/qmu/workaholic/commit/e511e15)) - [ticket](.workaholic/tickets/archive/feat-20260123-005256/20260123023519-merge-doc-rule-and-skill.md)
  Simplifies architecture by merging doc-writer skill and documentation.md rule into a single path-specific doc-specs rule that auto-loads for doc/specs/\*\*.
  The documentation rule is TDD-specific, used only by doc-writer skill in the TDD workflow.
  Skills run in the main conversation context, providing better access to current state and eliminating subprocess overhead.
  Kebab-case is more readable and URL-friendly than UPPER_CASE for documentation files.
  The new names are more descriptive and follow common documentation conventions.
  PR-time documentation provides a holistic view of all changes rather than incremental per-ticket fragments.
  The doc-writer is TDD-specific tooling used by /drive, so it belongs with the rest of the TDD workflow components.
  The doc-writer agent was skipping documentation. Now it must document everything without exception or judgment calls.

### Removed

- Remove unused agents from core plugin ([a8c1e81](https://github.com/qmu/workaholic/commit/a8c1e81)) - [ticket](.workaholic/tickets/archive/feat-20260123-005256/20260123021925-remove-core-agents.md)
  The discover-project and discover-claude-dir agents were not actively used, simplifying the core plugin to commands and rules only.

## [feat-20260122-210543](https://github.com/qmu/workaholic/tree/feat-20260122-210543)

### Added

- Add doc-writer subagent for flexible documentation ([3e55327](https://github.com/qmu/workaholic/commit/3e55327))
- Move prettier to PostToolUse hook for automatic formatting ([7443e8a](https://github.com/qmu/workaholic/commit/7443e8a))
- Show ticket title and summary in drive approval prompt ([023eaec](https://github.com/qmu/workaholic/commit/023eaec))
- Update PR title when updating existing PR ([4bf5a45](https://github.com/qmu/workaholic/commit/4bf5a45))

### Changed

- Auto-continue to next ticket after approval ([8afe46b](https://github.com/qmu/workaholic/commit/8afe46b))
- Remove 'internal' from marketplace descriptions
- Clear local plugin settings

### Removed

- Remove refer-cc-document skill from core plugin ([2e83c2e](https://github.com/qmu/workaholic/commit/2e83c2e))
- Remove incorrectly located doc/specs/icebox directory ([f09b2c6](https://github.com/qmu/workaholic/commit/f09b2c6))
