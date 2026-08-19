---
type: Feedback
title: Routine registration should be three per-repository routines plus one per-user updater
kind: instruction
source: discussion
subject: person:tamura_yoshiya
created_at: 2026-08-19T05:25:47+00:00
author: a@qmu.jp
supersedes: 
---

# Routine registration should be three per-repository routines plus one per-user updater

# Routine registration should be three per-repository routines plus one per-user updater

`/workaholify` and `/setup-dev-routines` should be updated so that routine registration
produces exactly four routines: three scoped per repository and one scoped per user,
shared across all of that user's repositories rather than duplicated per repository.

The per-user routine is a new one, **[Workaholic]**: it runs hourly, checks the
workaholic repository itself for updates to the routine definitions, and when it finds
one, updates that user's other workaholic routines across all their repositories to the
new versions. The three per-repository routines are **[Specificate]** (renamed from the
current [Propose] — behavior and logic stay as-is, only the name changes),
**[Implement]** (unchanged in name and behavior) and **[Propose]** (renamed from the
current [Housekeep] — again a name change only).

The reporter flags the rename mapping explicitly as a swap rather than two independent
renames: Propose becomes Specificate, and Housekeep becomes Propose, so the new
"Propose" is sourced from the old "Housekeep" and not from the old "Propose".
Implementers are asked to double check every reference to "Propose" to determine which
of the two it means.

Requested by tamura_yoshiya.

Source: https://github.com/qmu/workaholic/issues/526
