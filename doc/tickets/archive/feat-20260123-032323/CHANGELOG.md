# Branch Changelog

## Added
- Add commit_hash to doc specs frontmatter ([3c3c01d](https://github.com/qmu/workaholic/commit/3c3c01d)) - [ticket](20260123135636-add-commit-hash-frontmatter.md)
  Enables AI to understand documentation state at a specific git commit and discover changes by comparing hashes.
## Changed
- Rewrite sync-doc-specs as actionable command ([a59efda](https://github.com/qmu/workaholic/commit/a59efda)) - [ticket](20260123135431-rewrite-sync-doc-specs-command.md)
  Converts the thin 5-line wrapper into a comprehensive step-by-step command that Claude can execute directly without referencing external rules.
  Eliminates verbose 'let me read the file again' announcements by removing per-edit formatting hooks and adding formatting as a pre-PR step instead.
## Removed
