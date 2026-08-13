---
type: Feedback
title: workaholify still stops at setup sheets instead of applying routine configuration
kind: instruction
source: discussion
created_at: 2026-08-13T20:51:16+09:00
author: a@qmu.jp
supersedes: 
---

# workaholify still stops at setup sheets instead of applying routine configuration

The 2026-08-10 instruction (20260810214929-make-setup-routines-and-workaholify-configure-routines-automatically-via-remotetrigger.md) named both commands, but only /setup-routines was converged to the direct-apply doctrine; /workaholify's command definition (commands/workaholify.md, section 5) still runs render-setup-sheet.sh --all and reports, telling the developer to create the routines by hand. The developer's expectation from the start is that /workaholify runs the same direct-apply path as /setup-routines — find the RemoteTrigger-family transport, list the account's routines, diff each against its template, and apply create/update — within its own end-to-end flow, keeping the sheet only as the no_transport recovery path. A confirmation dialog before applying is acceptable; stopping at a rendered sheet is not.
