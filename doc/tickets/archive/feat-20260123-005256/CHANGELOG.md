# Branch Changelog

## Added
- Add final report step to drive command workflow ([2788d9d](https://github.com/qmu/workaholic/commit/2788d9d)) - [ticket](20260123024044-drive-final-report.md)
  Creates historical record of implementation decisions by appending a Final Report section to tickets before archiving.
  Clarifies the conceptual difference: specs are snapshots of current state while tickets are change requests (past/future work log).
  Ensures every subdirectory has an index for discoverability and enforces the no-orphan-documents constraint.
  Enables doc-writer to delete outdated documentation files and empty directories, fulfilling the cleanup requirement in drive.md step 2.3.
  Enables richer PR summaries by capturing the motivation behind each change in the branch CHANGELOG.
## Changed
- Consolidate documentation rule and skill into path-specific rule ([e511e15](https://github.com/qmu/workaholic/commit/e511e15)) - [ticket](20260123023519-merge-doc-rule-and-skill.md)
  Simplifies architecture by merging doc-writer skill and documentation.md rule into a single path-specific doc-specs rule that auto-loads for doc/specs/**.
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
