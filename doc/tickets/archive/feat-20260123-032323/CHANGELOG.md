# Branch Changelog

## Added
- Add cross-cutting documentation guidance to sync-doc-specs ([c73ed30](https://github.com/qmu/workaholic/commit/c73ed30)) - [ticket](20260123154228-sync-doc-specs-cross-cutting-docs.md)
  Enhances documentation to capture the big picture across files, directories, and layers rather than just file-by-file details.
  Enables AI to understand documentation state at a specific git commit and discover changes by comparing hashes.
## Changed
- Rewrite sync-doc-specs as actionable command ([a59efda](https://github.com/qmu/workaholic/commit/a59efda)) - [ticket](20260123135431-rewrite-sync-doc-specs-command.md)
  Converts the thin 5-line wrapper into a comprehensive step-by-step command that Claude can execute directly without referencing external rules.
  Eliminates verbose 'let me read the file again' announcements by removing per-edit formatting hooks and adding formatting as a pre-PR step instead.
## Removed
