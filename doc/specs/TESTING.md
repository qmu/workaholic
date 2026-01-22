# Testing

## Test Strategy

This is a configuration/documentation project with no executable code. Testing is manual.

## Manual Testing

### Plugin Installation

1. Run `/plugin install core@qmu/workaholic`
2. Run `/plugin install tdd@qmu/workaholic`
3. Verify `.claude/` directory is configured
4. Verify commands are available

### Command Testing

| Command         | Test Steps                                            |
| --------------- | ----------------------------------------------------- |
| `/commit`       | Make changes, run command, verify commit              |
| `/pull-request` | Create branch, commit, run command, verify PR         |
| `/ticket`       | Run with description, verify ticket in `doc/tickets/` |
| `/drive`        | Add ticket, run command, verify implementation        |
| `/release`      | Run with version type, verify version bump            |

### Documentation Testing

1. Create a ticket with `/ticket`
2. Run `/drive` to implement
3. Verify `doc/specs/` files updated
4. Verify changes are relevant to implementation

## Validation Checklist

- [ ] marketplace.json is valid JSON
- [ ] plugin.json is valid JSON
- [ ] All markdown files render correctly
- [ ] Command templates produce valid output
- [ ] Version numbers are in sync

## Regression Testing

After changes:

1. Install plugin in fresh project
2. Run each command once
3. Verify expected output
