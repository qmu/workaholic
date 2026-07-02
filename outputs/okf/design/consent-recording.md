---
type: Engineering Policy
title: "Recording of Policy Changes and Consent"
description: "Recording the version of terms and policies each user consented to, and re-obtaining consent when material changes occur, as an auditable trail."
resource: https://qmu.co.jp/design/consent-recording
tags:
  - design
  - consent-recording
---

# Recording of Policy Changes and Consent

_Record the version of terms and policies each user consented to, and re-obtain consent when material changes occur; make the consent record auditable._

Terms of service and privacy policies change. When they do, it matters — for compliance, for trust, and in the event of a dispute — whether a specific user had consented to the version in effect at a given time. We design consent recording as an auditable trail: which version of which policy was shown, when it was shown, and whether it was accepted. When a material change occurs, users are notified and their consent is obtained for the new version, rather than assuming continued use implies acceptance.

## Goal (目標)

The situation this policy aims to achieve is one in which the consent state of any user can be answered definitively: which version of the terms they accepted, when they accepted it, and whether the current version requires re-consent.

- Terms and privacy policies are versioned, and the version identifier is part of the consent record.
- The consent record includes a timestamp, the user identifier, the policy identifier, and the version accepted.
- When a material change requires re-consent, the product presents the change and blocks access or limits functionality until consent is obtained.

## Responsibility (責務)

The situation this policy aims to prevent is one in which, in a compliance audit or legal dispute, the product cannot demonstrate that a specific user consented to the terms in effect at a relevant time.

States we do not tolerate:

- "Continued use of the product constitutes acceptance" as the sole mechanism for recording consent to policy changes. This is insufficient for material changes.
- Consent records that record only whether a user accepted, not which version was accepted.
- Policy versions stored only in an external CMS without a version identifier that can be cross-referenced from the consent record.
- Consent obtained via a dark pattern — pre-checked boxes, buried disclosure, or misleading language — see [Elimination of Dark Patterns](/design/no-dark-patterns.md).

## Practices (実践)

### Version all policies with a persistent identifier

Each published version of the terms of service and privacy policy is assigned a version identifier (a timestamp, a semantic version number, or a hash) that is stored in the repository alongside the policy text. The identifier is what is recorded in the consent log.

### Record consent as an event

Consent is recorded as an immutable event: the user ID, the policy type (terms of service, privacy policy, marketing consent), the version accepted, the timestamp, and the IP address if needed by jurisdiction. Do not update a boolean column; insert a new row. This preserves the historical record even when consent is subsequently withdrawn.

### Classify changes as material or non-material before publishing

Before publishing a new version of a policy, classify the change: is it a material change (one that meaningfully alters user rights, data use, or the terms of service) or a non-material change (typo corrections, clarifications that do not change meaning)? Material changes require re-consent. Non-material changes may be published with notice but without blocking re-consent.

### Related: Respecting User Data Sovereignty, Elimination of Dark Patterns, Legal Compliance Verification

Consent records are part of the broader data sovereignty commitment — [Respecting User Data Sovereignty](/design/data-sovereignty.md). Consent flows must not use dark patterns — [Elimination of Dark Patterns](/design/no-dark-patterns.md). The legal requirements that drive consent obligations are enumerated in [Legal Compliance Verification](/planning/legal-compliance-check.md).
