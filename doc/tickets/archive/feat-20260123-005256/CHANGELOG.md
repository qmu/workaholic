# Branch Changelog

## Added
- Add Bash tool to doc-writer for documentation cleanup ([e2b4023](https://github.com/qmu/workaholic/commit/e2b4023)) - [ticket](20260123012527-doc-writer-bash-tool.md)
  Enables doc-writer to delete outdated documentation files and empty directories, fulfilling the cleanup requirement in drive.md step 2.3.
  Enables richer PR summaries by capturing the motivation behind each change in the branch CHANGELOG.
## Changed
- Move documentation updates from /drive to /pull-request ([08c835f](https://github.com/qmu/workaholic/commit/08c835f)) - [ticket](20260123013443-docs-at-pr-not-drive.md)
  PR-time documentation provides a holistic view of all changes rather than incremental per-ticket fragments.
  The doc-writer is TDD-specific tooling used by /drive, so it belongs with the rest of the TDD workflow components.
  The doc-writer agent was skipping documentation. Now it must document everything without exception or judgment calls.
## Removed
