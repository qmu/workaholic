---
okf_version: "0.1"
---

# Workaholic Knowledge Base

The development knowledge this project's workaholic workflows generate and maintain,
organized as an Open Knowledge Format bundle. Enter any area through its index.

* [tickets/](tickets/) - implementation tickets (two states: todo / archive; the outcome is the status: field)
* moderations/ - the /moderate tick log, one file per UTC day (an operational log, not knowledge: no type:, no index, and git-ignored - it stays in the checkout and is committed nowhere)
* [stories](stories/index.md) - branch development narratives (PR descriptions and historical record)
* [missions](missions/index.md) - optional epic-equivalent batches of tickets, with acceptance progress and an append-only changelog
* [feedbacks](feedbacks/index.md) - the inbound feedback stream: immutable records of insights, instructions, concerns, and customer material
* [strategies](strategies/index.md) - outbound, resolved direction: one aim per file, with the date it is bound by and who carries it
* [deployments](deployments/index.md) - deployment targets and confirmation methods
* [release-notes](release-notes/index.md) - per-branch release notes, one per shipped unit
* [terms](terms/index.md) - domain terminology
* [trips](trips/index.md) - legacy, read-only: design rationale from the retired trip workflow
