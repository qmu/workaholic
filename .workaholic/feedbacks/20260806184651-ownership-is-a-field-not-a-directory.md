---
type: Feedback
title: Ownership is a field, not a directory
kind: instruction
source: discussion
created_at: 2026-08-06T18:46:51+09:00
author: a@qmu.jp
supersedes: 
---

# Ownership is a field, not a directory

The developer's ruling, 2026-08-06, on being shown a routine prompt that carried a `git config user.email` line: do not keep patching -- if "who" is properly propagated as information through the structure, this class of patch should not recur. Design it properly instead.

THE FLAW. A ticket's owner is encoded in its PATH (`.workaholic/tickets/todo/<user-slug>/`), so plan-units.sh resolves the runner's git identity to a slug and opens only that directory. With no identity there is no directory to open, so an unreadable queue and an empty queue are the same observation -- nothing in the data distinguishes them. Two further costs follow: reassignment is a file move, and following renames is exactly what the claim reader's rename map and filename fallback exist for (both added after real double-pick incidents); and two ownership models coexist, since a mission carries plural assignees resolved through one reader with empty meaning team-owned, while a ticket has exactly one owner expressed as a directory and no unowned state at all. The better model already exists and is proven; the queue uses the worse one.

THE DESIGN. Ownership becomes a FIELD on the ticket -- the mission's own schema and reader -- and the queue goes flat. A runner with no identity then reads the whole queue and reports owner_unresolved with its size; reassignment is a frontmatter edit; an unowned ticket is claimable by anyone, which is what /propose needs for work that is nobody's yet. The git identity keeps exactly one job: claim authorship and resumption, where it asks "is this my own run" and fails loudly.

AND "WHO" RIDES THE ARTIFACTS. The Propose routine already fires on an issue assigned to a person, so the identity is known at the trigger and should travel from there -- issue assignee to proposal assignees to ticket assignees to the implementing run -- rather than being re-derived from whatever git config each container happens to carry.

ALSO SETTLED: retiring [Consent] is approved. A human-merged pull request is then announced by nobody, which is the accepted cost of one fewer standing process per project.
