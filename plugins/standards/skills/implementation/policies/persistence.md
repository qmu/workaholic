---
title: Schema-First Database Design
slug: persistence
category: implementation
source: https://qmu.co.jp/implementation/persistence
---

# Schema-First Database Design

At our company, we take it as a foundational stance in design to consider the database schema before the domain model. For persisting the data that software handles, we adopt a properly normalized relational database as our first choice, and we build the domain model on top of that storage structure as its base.

We have been influenced in many ways by DDD (Domain-Driven Design). We have also engaged, in various forms, with the design approach of modeling around phenomena in the domain first and only afterward reconciling that model with technical constraints.

However, we could not bring ourselves to dismiss the concern of persistence as a mere technical detail or constraint. Aggregates, transaction boundaries, and the like are matters that ought rather to be considered together with the database schema, and we came to understand the model as a projection carved out of the space of persistable states according to the purpose for which it is used.

Of course, it is not desirable for the model's semantics or expressive power to be compromised by being dragged excessively into the details. But if we understand the relationship between the model and the persistence structure in this way, then considering the database schema first is, in our view, a natural ordering for design.

## Goal (目標)

The situation this policy aims to achieve is one in which the database schema contributes as a guardrail for the domain model, yielding a model of higher quality. We aim for a state in which the database schema brings into relief the contours of the space of states in which the model can hold, and serves as the base on which a coherent model is grown.

## Responsibility (責務)

The situation this policy aims to prevent is one in which, by letting things drift, one uses an AI coding agent and the choice of saving JSON objects as-is is taken. We make persistence premised on schemas and migrations on a relational database our principle. At the same time, we are also wary of leaning in the direction where implementation is carried out using only the data records returned by an ORM and the like, leaving the domain model neglected.

## Practices (実践)

### Design the database schema first (DB スキーマを先に設計する)

When beginning work on a new feature or area, we first design the database schema. We put in place a structure that can record the events the application handles at the necessary granularity and with the necessary relationships, and on top of that, the developer stands up a domain model suited to the feature or purpose.

### Place the relational database at the foundation (関係 DB を基盤に置く)

The foundation of persistence is the relational database. Document stores, key-value stores, and graph databases are adopted as means of solving problems that are hard to handle with the relational model, when the need for them arises. Reasons for placing the relational database at the foundation:

- Consistency and referential integrity at storage boundaries can be enforced as a database feature.

- The schema remains as documentation of the rationale, and can be read with the same meaning from multiple applications and tools.

- The maturity of the operational features needed for persistence — backups, PITR, replication, and so on — is high.

- By riding on SQL, a standard query language, room for migration between vendors is preserved (passive vendor dependence).

### Make use of established schema and migration methods (確立されたスキーマ・マイグレーション手法を活用する)

In order to make the fundamental structure of the data explicit, and to update it through the course of its evolution without losing consistency, we adopt as-is the long-established frameworks for schema definition and migration. We judge that an existing framework is more readable and easier to evolve for developers than replacing it with our own bespoke operation.

- Table names, column names, and constraints are named in the terms of the domain, and NOT NULL, foreign keys, and check constraints are used as enforceable declarations in place of comments. We place on the schema side as well the same stance we take in the recommendation of thick typing, of gathering things into types.

- Schema changes are left in the history as migrations, in a form that can reproduce past schema states. Migration files are written on the premise that they will be read as a pair with the PR description, as a record of "when, why, and what."

### Align aggregates with transaction boundaries (集約とトランザクション境界を一致させる)

We make transaction boundaries coincide with the boundaries of the aggregate that protects the business invariants. A design that updates multiple aggregates in a single SQL query tends, over the long term, to become a breeding ground for lock contention and consistency incidents.

### Prepare event sourcing as an option (イベントソーシングは選択肢として準備する)

Event sourcing is a persistence method that records the state transitions themselves, rather than the latest snapshot of state. We do not adopt it immediately, but we keep ourselves prepared — with persistence kept separated — so that we can adopt it when the following conditions appear.

- For audit and compliance purposes, "when, who, and what was changed" is needed as primary-source material.

- The same facts need to be expressed in multiple ways as different projections (read models).

- There is a need to reconstruct the state at a past point in time (time-series reasoning, replay).

We do not build a distributed event store in advance. The decision to adopt it is made at the point when the conditions become manifest.
