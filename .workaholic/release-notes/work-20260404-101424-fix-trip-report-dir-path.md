# Trip Directory Fix, Agent Consolidation, and Command Migration

## Summary

Refined the plugin architecture post-trip session by fixing the trip directory path convention, simplifying branch naming, adding gitignored file sync before worktree erase, moving ship and scan commands to the core plugin, and consolidating 13 thin subagent files into 2 parameterized agents.

## Key Changes

- Consolidated 10 lead agents and 3 discoverer agents into 2 parameterized agents (-11 files)
- Moved `/ship` and `/scan` commands from work plugin to core plugin for proper dependency flow
- Added gitignored file sync prompt before worktree erase in ship workflow
- Fixed trip directory path from `.trips` to `trips`
- Simplified branch naming from `work-TIMESTAMP-FEATURE` to `work-TIMESTAMP` only

## Changes

### Added

- Gitignored file sync prompt before worktree erase in ship workflow
- Parameterized `lead.md` agent replacing 10 identical lead files
- Parameterized `discoverer.md` agent replacing 3 thin discoverer files

### Changed

- Moved `/ship` and `/scan` commands from work to core plugin
- Renamed `.trips` to `trips` across all plugin files
- Simplified branch naming to `work-TIMESTAMP` only
- Updated select-scan-agents output schema for domain-qualified lead objects

### Removed

- 10 individual lead agent files (a11y-lead, db-lead, delivery-lead, etc.)
- 3 individual discoverer agent files (history-discoverer, source-discoverer, ticket-discoverer)

## Metrics

- **Tickets Completed**: 6

## Links

- [Branch Story](.workaholic/stories/work-20260404-101424-fix-trip-report-dir-path.md)
