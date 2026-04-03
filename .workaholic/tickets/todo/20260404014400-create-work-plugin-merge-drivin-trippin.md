---
created_at: 2026-04-04T01:44:00+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Create work plugin by merging drivin and trippin

## Context

The drivin and trippin plugins are currently separate plugins with overlapping concerns. Drivin provides ticket-driven development (`/ticket`, `/drive`, `/scan`) and trippin provides AI-collaborative exploration (`/trip`). Both depend on core and share reporting/shipping infrastructure through core's cross-plugin references.

Trippin already declares a dependency on drivin (`"dependencies": ["core", "drivin"]`), and both use the same report/ship pipeline. Merging them into a single `work` plugin simplifies the dependency graph, eliminates cross-plugin references between the two, and creates a unified development workflow plugin.

## Plan

### Step 1: Create `plugins/work/` directory structure

```
plugins/work/
  .claude-plugin/plugin.json
  README.md
  agents/          # merged from both plugins
  commands/        # merged from both plugins
  hooks/           # from drivin
  rules/           # from drivin
  skills/          # merged from both plugins
```

### Step 2: Create `plugins/work/.claude-plugin/plugin.json`

```json
{
  "name": "work",
  "description": "Unified development workflow: ticket-driven development and AI-collaborative exploration",
  "version": "1.0.43",
  "dependencies": ["core"],
  "author": {
    "name": "tamurayoshiya",
    "email": "a@qmu.jp"
  }
}
```

### Step 3: Move drivin content into work

Files to move (preserving directory structure):

**Agents** (8 files):
- `drivin/agents/drive-navigator.md` -> `work/agents/drive-navigator.md`
- `drivin/agents/history-discoverer.md` -> `work/agents/history-discoverer.md`
- `drivin/agents/pr-creator.md` -> `work/agents/pr-creator.md`
- `drivin/agents/release-readiness.md` -> `work/agents/release-readiness.md`
- `drivin/agents/source-discoverer.md` -> `work/agents/source-discoverer.md`
- `drivin/agents/story-writer.md` -> `work/agents/story-writer.md`
- `drivin/agents/ticket-discoverer.md` -> `work/agents/ticket-discoverer.md`
- `drivin/agents/ticket-organizer.md` -> `work/agents/ticket-organizer.md`

**Commands** (3 files):
- `drivin/commands/drive.md` -> `work/commands/drive.md`
- `drivin/commands/scan.md` -> `work/commands/scan.md`
- `drivin/commands/ticket.md` -> `work/commands/ticket.md`

**Hooks** (2 files):
- `drivin/hooks/hooks.json` -> `work/hooks/hooks.json`
- `drivin/hooks/validate-ticket.sh` -> `work/hooks/validate-ticket.sh`

**Rules** (2 files):
- `drivin/rules/general.md` -> `work/rules/general.md`
- `drivin/rules/workaholic.md` -> `work/rules/workaholic.md`

**Skills** (4 skills with all scripts):
- `drivin/skills/create-ticket/` -> `work/skills/create-ticket/`
- `drivin/skills/discover/` -> `work/skills/discover/`
- `drivin/skills/drive/` -> `work/skills/drive/`
- `drivin/skills/report/` -> `work/skills/report/`

### Step 4: Move trippin content into work

**Agents** (3 files):
- `trippin/agents/architect.md` -> `work/agents/architect.md`
- `trippin/agents/constructor.md` -> `work/agents/constructor.md`
- `trippin/agents/planner.md` -> `work/agents/planner.md`

**Commands** (1 file):
- `trippin/commands/trip.md` -> `work/commands/trip.md`

**Skills** (2 skills with all scripts):
- `trippin/skills/trip-protocol/` -> `work/skills/trip-protocol/`
- `trippin/skills/write-trip-report/` -> `work/skills/write-trip-report/`

### Step 5: Update internal references within work plugin

All cross-plugin references that previously pointed between drivin and trippin now become same-plugin references:

- In trip.md: `${CLAUDE_PLUGIN_ROOT}/../core/skills/branching/scripts/...` stays (still cross-plugin to core)
- Any references from trippin files to drivin files become same-plugin: `${CLAUDE_PLUGIN_ROOT}/skills/...`

Update `subagent_type` references within work's own commands:
- `drivin:drive-navigator` -> `work:drive-navigator` (in drive.md)
- `drivin:ticket-organizer` -> `work:ticket-organizer` (in ticket.md)
- `drivin:story-writer` -> stays as-is in core/report.md (handled by ticket #3)
- `trippin:planner`, `trippin:architect`, `trippin:constructor` -> `work:planner`, `work:architect`, `work:constructor` (in trip.md)

Update skill preload references in command frontmatter:
- `drive.md` skills: `drive` and `core:system-safety` stay same
- `scan.md` skills: `core:gather-git-context`, `standards:select-scan-agents`, etc. stay same
- `trip.md` skills: `trip-protocol` stays same (now in same plugin)
- `report.md` (core): `trip-protocol` -> `work:trip-protocol`, `write-trip-report` -> `work:write-trip-report` (handled by ticket #3)

### Step 6: Create work/README.md

Merge the content from drivin/README.md and trippin/README.md into a unified README covering both workflows.

## Verification

- All files from plugins/drivin/ have corresponding files in plugins/work/
- All files from plugins/trippin/ have corresponding files in plugins/work/
- No broken `${CLAUDE_PLUGIN_ROOT}` references within work plugin
- plugin.json declares `"dependencies": ["core"]`
