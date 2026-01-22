# Move Documentation Rule to TDD Plugin

## Overview

Move `plugins/core/rules/documentation.md` to `plugins/tdd/rules/documentation.md`. This rule is specifically for the TDD workflow's documentation management (used by doc-writer skill) and doesn't belong in the core plugin which contains general-purpose rules like `general.md` and `typescript.md`.

## Key Files

- `plugins/core/rules/documentation.md` - Current location (to be moved)
- `plugins/tdd/rules/documentation.md` - New location (to be created)
- `plugins/tdd/agents/doc-writer.md` - References the documentation rule (path needs update)

## Implementation Steps

1. **Create TDD rules directory**:

   - `mkdir -p plugins/tdd/rules`

2. **Move the file**:

   - `mv plugins/core/rules/documentation.md plugins/tdd/rules/documentation.md`

3. **Update doc-writer agent/skill** to reference new path:

   - Change `plugins/core/rules/documentation.md` to `plugins/tdd/rules/documentation.md`

4. **Update `plugins/tdd/README.md`**:

   - Add rules section listing documentation.md

5. **Update `plugins/core/README.md`** if it lists documentation rule:
   - Remove reference to documentation.md

## Considerations

- Core plugin rules (general.md, typescript.md) are broadly applicable
- Documentation rule is TDD-specific (only used by doc-writer in TDD workflow)
- This aligns with principle: TDD-specific config lives in TDD plugin
