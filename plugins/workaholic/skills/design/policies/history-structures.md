---
title: Proactive Introduction of History Structures
slug: history-structures
category: design
source: https://qmu.co.jp/design/history-structures
---

# Proactive Introduction of History Structures

_Design data structures to preserve history from the start; the ability to answer "what was the state at time T" and "who changed what, when" is much cheaper to build in than to add later._

Many products reach a point where they need to answer questions about the past: what changed in this record, who approved this transaction, what did the state look like before this bug was introduced? If the data structure only holds current state, answering these questions requires either a reconstruction from logs — if logs were comprehensive — or the answer is simply unavailable. History structures — temporal tables, append-only event logs, audit tables, or event sourcing — are the design patterns that make these questions answerable. Our policy is to decide early, for each significant data model, what history is needed and to build it in before data accumulates.

## Goal (目標)

The situation this policy aims to achieve is one in which the history the product needs to answer its operational, audit, and debugging questions is present in the database, having been accumulated from the first write.

- Each significant entity has a defined history policy: snapshot-on-change, event log, or current-state-only with external log.
- The who-changed-what audit trail is queryable for entities that require it.
- Point-in-time queries — "what did the state look like at this timestamp" — are possible for entities whose temporal state matters.

## Responsibility (責務)

The situation this policy aims to prevent is one in which a history question arises in production and cannot be answered because the data structure never accumulated the needed information.

States we do not tolerate:

- Current-state-only tables for entities whose change history is operationally or compliance-relevant, with no audit trail anywhere.
- History decided as a retrofit after the first data has accumulated in current-state-only form. The retrofitted audit trail contains no history from before the retrofit.
- Audit logs that record only the user and timestamp of a change, without the before and after state of the changed fields. An audit log that says "user X changed record Y at time T" but not what changed is insufficient for most audit use cases.

## Practices (実践)

### Decide the history policy when designing each significant entity

When a new entity is designed, decide: does this need an audit trail (who changed what, when)? Does it need temporal query support (what was the state at time T)? Neither? Record the decision in the migration notes or ADR. The default is current-state-only, but the decision is explicit.

### Use append-only tables for entities that require audit trails

For entities that require an audit trail, design an accompanying history or changelog table: for each change, insert a row with the entity ID, timestamp, changed-by user ID, and the before and after values of changed fields. The history table is append-only (no updates or deletes). This complements the relational database stance in the persistence policy — see [Schema-First Database Design](../../implementation/policies/persistence.md).

### Consider event sourcing for entities that need temporal queries

For entities that need point-in-time queries (financial ledgers, version-controlled documents, state machine records), consider an event-sourcing model: store events (what happened), derive current state from the event log. See the event sourcing section of [Schema-First Database Design](../../implementation/policies/persistence.md) for when to adopt this.

### Related: Schema-First Database Design, Respecting User Data Sovereignty, Capacity and Recovery Planning

History structures are an extension of [Schema-First Database Design](../../implementation/policies/persistence.md). The right to access and export history is part of [Respecting User Data Sovereignty](data-sovereignty.md). Backup and recovery of historical data must be planned in [Capacity and Recovery Planning](../../implementation/policies/operational-planning.md).
