---
date: 2026-01-25
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.1h
commit_hash: 4b7b10e
category: Added
---

# Add "Approve and stop" option to drive command

## Overview

The `/drive` command currently offers two approval options: "Approve" (continue to next ticket) and "Needs changes" (revise implementation). Users need a third option: "Approve and stop" to approve the current ticket but stop driving without processing remaining tickets. This is useful when the user wants to review changes before continuing, take a break, or handle remaining tickets in a separate session.

## Key Files

- `plugins/core/commands/drive.md` - Update step 2.3 to add the third option

## Implementation Steps

1. **Update step 2.3 "Ask User to Review Implementation"** in `drive.md`:

   Change the approval options from:
   ```
   - "Approve" - implementation is correct, proceed to commit
   - "Needs changes" - user will provide feedback to fix
   ```

   To:
   ```
   - "Approve" - implementation is correct, proceed to commit and continue to next ticket
   - "Approve and stop" - implementation is correct, commit this ticket but stop driving
   - "Needs changes" - user will provide feedback to fix
   ```

2. **Update the approval prompt format** to show three options:

   Change:
   ```
   [Approve / Needs changes]
   ```

   To:
   ```
   [Approve / Approve and stop / Needs changes]
   ```

3. **Add handling instructions** for "Approve and stop":

   After step 2.5 (Commit and Archive), add logic:
   - If user selected "Approve and stop": complete the current ticket's commit/archive, then stop and report remaining tickets count
   - If user selected "Approve": continue to next ticket as before

4. **Update the example workflow** to show the new option in the prompt

## Considerations

- The "Approve and stop" wording is clear about its dual action: approving the current work AND stopping the drive loop
- The option order (Approve / Approve and stop / Needs changes) groups the two approval variants together
- When stopping, inform the user how many tickets remain so they can resume later with `/drive`

## Final Report

Development completed as planned.
