# Branch Changelog

## Added

## Changed
- Rewrite sync-doc-specs as actionable command ([a59efda](https://github.com/qmu/workaholic/commit/a59efda)) - [ticket](20260123135431-rewrite-sync-doc-specs-command.md)
  Converts the thin 5-line wrapper into a comprehensive step-by-step command that Claude can execute directly without referencing external rules.
  Eliminates verbose 'let me read the file again' announcements by removing per-edit formatting hooks and adding formatting as a pre-PR step instead.
## Removed
