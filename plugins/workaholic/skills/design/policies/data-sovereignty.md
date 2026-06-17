---
title: Respecting User Data Sovereignty
slug: data-sovereignty
category: design
source: https://qmu.co.jp/design/data-sovereignty
---

# Respecting User Data Sovereignty

_Design the product so that users retain meaningful control over their own data — the ability to export it, delete it, and understand what is held._

Users' data belongs to users. The product acts as a steward, not an owner. Concretely, this means building the mechanisms that let users exercise control — export, deletion, a comprehensible inventory of what data is held — as first-class features, not afterthoughts or compliance checkbox items. Products that make user data captive tend to erode trust and, in markets subject to GDPR or similar regulation, create legal exposure. We design data sovereignty features into the product from the start.

## Goal (目標)

The situation this policy aims to achieve is one in which a user who wants to leave, audit, or manage their data can do so without asking support or writing to an administrator.

- Users can export all data associated with their account in a portable, machine-readable format.
- Users can request deletion of their account and data, and the product can fulfill that request completely.
- The product's data retention practices — what is kept, for how long, and why — are documented and disclosed.
- The product collects only the data it has a specific use for (data minimization).

## Responsibility (責務)

The situation this policy aims to prevent is one in which users are unable to access or remove their own data, or in which data is collected without a clear purpose.

States we do not tolerate:

- No self-service export path. A user who wants their data should not have to submit a support ticket and wait.
- Soft deletes that retain data indefinitely without disclosure. If a "delete account" action soft-deletes rather than purges, the retention period and purpose must be documented and disclosed.
- Collecting data fields whose use case is "might be useful later." Data collected without a current purpose creates retention liability.
- Disclosure language that does not match the implementation. The privacy policy's description of what is collected and retained should be derived from the actual schema.

## Practices (実践)

### Design export from the first feature that stores user data

When the first user-owned data model is designed, decide at that time what the export representation will be. Export is much cheaper to add at design time than to retrofit later, when data models have accumulated across tables and services.

### Define deletion semantics in the schema

When designing a table that holds user data, decide at schema time what deletion means: hard delete, soft delete with a retention window, or anonymization. Record that decision in a comment or migration note. Cascade behavior for related tables (ON DELETE CASCADE vs. ON DELETE RESTRICT) should follow from the deletion semantics, not be set to a default.

### Apply data minimization at schema time

Before adding a column, have a use case for it. "We might want this later" is not a use case. Data that is never collected cannot be leaked or misused. Review schema PRs for columns whose purpose is unclear.

### Audit retention against the privacy policy

Periodically compare the data retention implementation — what is actually stored, for how long, and where — against the privacy policy disclosure. Discrepancy between the two is a compliance risk.

### Related: Recording of Policy Changes and Consent, Legal Compliance Verification, Schema-First Database Design

Data sovereignty connects to consent management — [Recording of Policy Changes and Consent](consent-recording.md) — and to legal compliance — [Legal Compliance Verification](../../planning/policies/legal-compliance-check.md). The schema design practices that support deletion semantics are covered in [Schema-First Database Design](../../implementation/policies/persistence.md).
