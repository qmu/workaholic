# Branch Changelog

## Added
- Add branch story generation to pull-request workflow ([5a440d4](https://github.com/qmu/workaholic/commit/5a440d4)) - [ticket](20260123161059-branch-story-generation.md)
  Creates a narrative story document during PR creation that captures the developer's journey - motivation, challenges, and decisions - giving reviewers high-level context.
  Enhances documentation to capture the big picture across files, directories, and layers rather than just file-by-file details.
  Enables AI to understand documentation state at a specific git commit and discover changes by comparing hashes.
## Changed
- Document cognitive investment as core design principle ([b56b287](https://github.com/qmu/workaholic/commit/b56b287)) - [ticket](20260123162007-document-cognitive-investment-principle.md)
  Explains why Workaholic generates extensive documentation artifacts - investing in tickets, specs, stories, and changelogs reduces developer cognitive load.
  Uses more concrete and actionable terminology - these are deliberate choices to follow, not abstract principles to contemplate.
  Converts the thin 5-line wrapper into a comprehensive step-by-step command that Claude can execute directly without referencing external rules.
  Eliminates verbose 'let me read the file again' announcements by removing per-edit formatting hooks and adding formatting as a pre-PR step instead.
## Removed
