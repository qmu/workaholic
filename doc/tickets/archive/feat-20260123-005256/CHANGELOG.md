# Branch Changelog

## Added
- Add Bash tool to doc-writer for documentation cleanup ([e2b4023](https://github.com/qmu/workaholic/commit/e2b4023)) - [ticket](20260123012527-doc-writer-bash-tool.md)
  Enables doc-writer to delete outdated documentation files and empty directories, fulfilling the cleanup requirement in drive.md step 2.3.
  Enables richer PR summaries by capturing the motivation behind each change in the branch CHANGELOG.
## Changed
- Move doc-writer agent from core to TDD plugin ([84b4292](https://github.com/qmu/workaholic/commit/84b4292)) - [ticket](20260123012356-move-doc-writer-to-tdd.md)
  The doc-writer is TDD-specific tooling used by /drive, so it belongs with the rest of the TDD workflow components.
  The doc-writer agent was skipping documentation. Now it must document everything without exception or judgment calls.
## Removed
