---
name: update-ticket-frontmatter
description: Update ticket YAML frontmatter fields (effort, commit_hash, category).
allowed-tools: Bash
user-invocable: false
---

# Update Ticket Frontmatter

Update ticket YAML frontmatter fields after implementation.

## Usage

```bash
bash .claude/skills/update-ticket-frontmatter/sh/update.sh <ticket-path> <field> <value>
```

## Fields

### effort

Time spent in numeric hours.

Valid values: `0.1h`, `0.25h`, `0.5h`, `1h`, `2h`, `4h`

Invalid: `XS`, `S`, `M`, `10m` (t-shirt sizes and minutes are not allowed)

Update when: After implementation, before archiving.

### commit_hash

Short git commit hash (7 characters).

Update when: After creating the commit, set automatically by archive script.

### category

Change category based on commit message verb.

Values:
- **Added**: Add, Create, Implement, Introduce
- **Changed**: Update, Fix, Refactor (default)
- **Removed**: Remove, Delete

Update when: After creating the commit, set automatically by archive script.

## Field Insertion Order

When a field doesn't exist, it's inserted in this order:
1. After `layer:` → `effort:`
2. After `effort:` → `commit_hash:`
3. After `commit_hash:` → `category:`
