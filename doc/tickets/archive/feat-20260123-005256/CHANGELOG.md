# Branch Changelog

## Added
- Add README.md requirement for doc/specs subdirectories ([df5f5ea](https://github.com/qmu/workaholic/commit/df5f5ea)) - [ticket](20260123014944-readme-in-specs-subdirs.md)
  Ensures every subdirectory has an index for discoverability and enforces the no-orphan-documents constraint.
  Enables doc-writer to delete outdated documentation files and empty directories, fulfilling the cleanup requirement in drive.md step 2.3.
  Enables richer PR summaries by capturing the motivation behind each change in the branch CHANGELOG.
## Changed
- Move documentation rule from core to TDD plugin ([c7aa44b](https://github.com/qmu/workaholic/commit/c7aa44b)) - [ticket](20260123020703-move-docs-rule-to-tdd.md)
  The documentation rule is TDD-specific, used only by doc-writer skill in the TDD workflow.
  Skills run in the main conversation context, providing better access to current state and eliminating subprocess overhead.
  Kebab-case is more readable and URL-friendly than UPPER_CASE for documentation files.
  The new names are more descriptive and follow common documentation conventions.
  PR-time documentation provides a holistic view of all changes rather than incremental per-ticket fragments.
  The doc-writer is TDD-specific tooling used by /drive, so it belongs with the rest of the TDD workflow components.
  The doc-writer agent was skipping documentation. Now it must document everything without exception or judgment calls.
## Removed
- Remove unused agents from core plugin ([a8c1e81](https://github.com/qmu/workaholic/commit/a8c1e81)) - [ticket](20260123021925-remove-core-agents.md)
  The discover-project and discover-claude-dir agents were not actively used, simplifying the core plugin to commands and rules only.
