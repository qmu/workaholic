---
created_at: 2026-04-04T01:44:04+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort: 0.25h
commit_hash: 95b3cd6
category: Changed
---

# Update documentation, marketplace, and remove old plugins

## Context

After the work plugin is created and all references updated, the old drivin and trippin plugin directories must be removed. All project documentation and marketplace configuration must reflect the new structure.

## Plan

### Step 1: Update `marketplace.json`

Remove the `drivin` and `trippin` entries from the plugins array. Add a single `work` entry:

```json
{
  "name": "work",
  "description": "Unified development workflow: ticket-driven development and AI-collaborative exploration",
  "version": "1.0.43",
  "author": {
    "name": "tamurayoshiya",
    "email": "a@qmu.jp"
  },
  "source": "./plugins/work",
  "category": "development"
}
```

Also remove `plugins/drivin/.claude-plugin/plugin.json` and `plugins/trippin/.claude-plugin/plugin.json` from the version management list (they no longer exist).

### Step 2: Update `CLAUDE.md`

#### Project Structure

Replace the `drivin/` and `trippin/` entries with a single `work/` entry:

```
plugins/
  core/                  # Core shared plugin (no dependencies)
  standards/             # Standards policy plugin (no dependencies)
  work/                  # Work plugin: drive + trip workflows (depends on: core)
    .claude-plugin/      # Plugin configuration
    agents/              # drive-navigator, story-writer, planner, architect, constructor, etc.
    commands/            # ticket, drive, scan, trip
    hooks/               # ticket validation
    rules/               # general, workaholic
    skills/              # create-ticket, discover, drive, report, trip-protocol, write-trip-report, check-deps
```

#### Plugin Dependencies

Update the dependency graph:

```
core (base)       standards (base)
  ^
  |
work
```

Remove the drivin/trippin separate entries.

#### Version Management

Update version file list:
- Remove `plugins/drivin/.claude-plugin/plugin.json`
- Remove `plugins/trippin/.claude-plugin/plugin.json`
- Add `plugins/work/.claude-plugin/plugin.json`

#### Commands table

Merge into a single table showing all commands from work plugin.

#### Branch naming documentation

Update references from `drive-*`/`trip/*` to `work-YYYYMMDD-HHMMSS-feature` format.

### Step 3: Update `README.md`

#### Plugin sections

Replace Drivin and Trippin sections with a unified Work section:

- **Work**: Combined description covering both ticket-driven development and AI-collaborative exploration
- Command table includes `/ticket`, `/drive`, `/scan`, `/trip`
- Typical session examples show unified workflow
- Mention Agent Teams requirement for `/trip`

#### How It Works

Merge the "Drivin: Ticket-Driven Development" and "Trippin: AI-Collaborative Exploration" sections into a single "Work: Development Workflows" section, or keep them as subsections under Work.

### Step 4: Remove old plugin directories

```bash
git rm -r plugins/drivin/
git rm -r plugins/trippin/
```

### Step 5: Update any remaining references

Search entire codebase for any remaining `drivin` or `trippin` references:
- `.claude/rules/` files
- `.claude/settings.json` or `.claude/settings.local.json`
- `CHANGELOG.md` (historical references are OK, don't change those)
- Any other files

Update non-historical references. Leave CHANGELOG.md entries as-is (they document history).

### Step 6: Update memory files

Update `/home/ec2-user/.claude/projects/-home-ec2-user-projects-workaholic/memory/MEMORY.md` and related memory files if they reference the old plugin names.

## Verification

- `grep -r "drivin" plugins/` returns no results
- `grep -r "trippin" plugins/` returns no results
- `marketplace.json` lists core, standards, work (not drivin, trippin)
- `CLAUDE.md` project structure matches reality
- `README.md` describes the work plugin
- `plugins/drivin/` does not exist
- `plugins/trippin/` does not exist
- All version files (marketplace.json + 3 plugin.json files) are in sync
