---
name: handle-abandon
description: Handle abandoned implementation with failure analysis.
user-invocable: false
---

# Handle Abandon

When user selects "Abandon", do NOT commit implementation changes. Follow this procedure:

## 1. Discard Implementation Changes

```bash
git restore .
```

Reverts all uncommitted changes to the working directory.

## 2. Append Failure Analysis Section

Add to the ticket file:

```markdown
## Failure Analysis

### What Was Attempted
- <Brief description of the implementation approach>

### Why It Failed
- <Reason the implementation didn't work or was abandoned>

### Insights for Future Attempts
- <Learnings that could help if this is reattempted>
```

## 3. Move Ticket to Abandoned Directory

```bash
mkdir -p .workaholic/tickets/abandoned
mv <ticket-path> .workaholic/tickets/abandoned/
```

## 4. Commit the Abandonment

```bash
git add .workaholic/tickets/
git commit -m "Abandon: <ticket-title>"
```

This preserves the failure analysis in git history.

## 5. Continue to Next Ticket

Automatically proceed to the next ticket without asking for confirmation.

This allows users to abandon a failed implementation attempt while preserving insights for future reference.
