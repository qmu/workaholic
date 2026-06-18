---
title: Cautious Consideration of Distributed Systems
slug: modular-monolith-first
category: design
source: https://qmu.co.jp/design/modular-monolith-first
---

# Cautious Consideration of Distributed Systems

_Start with a well-structured monolith; consider moving to a distributed architecture only when the evidence for it becomes clear and the cost is justified._

Building a distributed system — microservices, event-driven architecture, or any form of service mesh — brings real operational complexity: service discovery, distributed tracing, network-failure handling, cross-service transaction boundaries, and independent deployment pipelines per service. These are costs that may be worth bearing, but only after the natural boundaries between services have become evident through actual use, not before. We treat a modular monolith, with clear internal module boundaries, as the starting point from which distribution can be extracted when the need is concrete.

## Goal (目標)

The situation this policy aims to achieve is one in which the system's architecture matches its actual complexity — neither too simple to support the requirements, nor burdened with distributed systems overhead before the need for that overhead has been demonstrated.

- Module boundaries are established inside the monolith before services are extracted from it.
- Each module's public interface is defined explicitly, so that extraction to a separate service is mechanical rather than exploratory.
- The decision to distribute is made on concrete evidence: throughput requirements that a single process cannot meet, independent deployment cadences that genuinely conflict, or data sovereignty constraints.

## Responsibility (責務)

The situation this policy aims to prevent is one in which distributed system overhead is introduced speculatively, before the boundaries between parts of the system are understood.

States we do not tolerate:

- Splitting into microservices before a working monolith exists. A system whose service boundaries are chosen before the domain is understood tends to need costly restructuring when the real boundaries become clear.
- Crossing service boundaries for operations that a single module boundary would resolve. Every network hop is a latency, a failure point, and a consistency challenge; internal function calls are free.
- Treating distributed architecture as a mark of quality in itself. The goal is operational reliability and development velocity, not architectural sophistication.

## Practices (実践)

### Establish module boundaries inside the monolith first

Before considering service extraction, create explicit module boundaries within the monolith: separate directories or packages, restricted cross-module imports, and clearly defined public interfaces for each module. A boundary that holds inside the monolith will hold across the network; a boundary that leaks inside will leak further when services are separated.

### Extract to a service only when the evidence is concrete

The evidence that justifies extraction is specific: a module's throughput requirements that a single process cannot meet, a deployment cadence that conflicts with the rest of the codebase, or a compliance boundary that requires separate infrastructure. Architectural preference and anticipated future scale are not evidence.

### Treat the distributed path as additive, not foundational

The distributed version of a system adds operational infrastructure on top of the monolith's module structure — it does not replace it. Keep the module structure clean so that, if distribution is warranted, the extraction path is predictable. Do not design the monolith in a way that assumes distribution.

### Related: Conservative Vendor Dependence, Containerization

When services are introduced, each service adds a vendor or runtime dependency of its own. See [Conservative Vendor Dependence](vendor-neutrality.md) for how to manage those choices. Container boundaries and their deployment are covered in the implementation pillar's Containerization policy.
