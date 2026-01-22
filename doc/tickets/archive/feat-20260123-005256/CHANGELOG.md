# Branch Changelog

## Added
- Add description field to CHANGELOG entries ([c7a9251](https://github.com/qmu/workaholic/commit/c7a9251)) - [ticket](20260123005822-comprehensive-changelog-entries.md)
  Enables richer PR summaries by capturing the motivation behind each change in the branch CHANGELOG.
## Changed
- Move doc-writer agent from core to TDD plugin ([84b4292](https://github.com/qmu/workaholic/commit/84b4292)) - [ticket](20260123012356-move-doc-writer-to-tdd.md)
  The doc-writer is TDD-specific tooling used by /drive, so it belongs with the rest of the TDD workflow components.
  The doc-writer agent was skipping documentation. Now it must document everything without exception or judgment calls.
## Removed
