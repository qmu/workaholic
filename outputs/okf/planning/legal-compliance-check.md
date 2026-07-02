---
type: Engineering Policy
title: "Legal Compliance Verification"
description: "Enumerating applicable laws and regulatory requirements before design begins, so legal constraints are a shared premise rather than a late discovery."
resource: https://qmu.co.jp/planning/legal-compliance-check
tags:
  - planning
  - legal-compliance-check
---

# Legal Compliance Verification

_Before entering design, enumerate the laws and regulatory requirements that apply to the product, and make them a shared premise of all design decisions._

Before entering product design, we enumerate in advance the legal and regulatory requirements that apply, place them as a premise of design decisions, and comply with them. Our policy is to make it the starting point of planning and design to grasp, at the stage of deciding what to build, which laws apply to the functions and business form — lining up before design such questions as preparation of terms of service and privacy policy, notation based on the Act on Specified Commercial Transactions, notification as a telecommunications carrier for chat functions, cookie consent, GDPR applicability determination, and log retention periods.

## Goal (目標)

We aim for a state in which, by the time design begins, the enumeration of legal and regulatory requirements applicable to the product is complete, and each requirement is shared as a premise of design decisions among all involved. The state where we can see before deciding screens and tables which laws apply to which functions, what needs to be stated, what needs to be notified, what needs to be consented to, and how long data may be retained.

## Responsibility (責務)

Our responsibility is to prevent a state in which we advance design without checking applicable laws and reach publication, only for violations or non-conformance to surface later.

When legal verification is deferred and concrete artifacts are assembled, rework to bring already-running design into conformance with legal requirements tends to pile up. In a firm where generative AI is our default author, the failure of AI producing features at speed while applicability determination passes through no human hands and flows into publication is a real risk. We want to prevent a state in which functions alone are completed first without terms of service, commercial transaction law notation, notification, or consent, and non-conformance is found afterward.

## Practices (実践)

### List applicable laws before design

Before entering design, we list the legal and regulatory requirements that may apply from the business form and functions of the product. Terms of service and privacy policy preparation; notation based on the Act on Specified Commercial Transactions for products or paid services; notification as a telecommunications carrier for chat functions that mediate messages between users; consent acquisition for use of cookies or similar technologies; GDPR applicability determination for products that may reach European users; and how long logs may be retained — these are the questions we put on the table before deciding function specifics. The requirements laid out here become the premises of subsequent design decisions.

### Add to the risk register

The legal requirements enumerated are recorded together with the state of verification and remaining uncertainty, and placed in the risk register managed under ISMS risk management to make them trackable. We want to leave in a traceable form both the fact of having made them a design premise and the questions not yet fully verified.

### Focus on verification; defer specific legal texts to the safety policy

Specific responses to consent acquisition and disclosure requests, and individual legal texts and published statements themselves, are deferred to the safety policy side. Published statements on acquisition, use, and disclosure requests regarding personal information are handled by the Privacy Policy. Note that specific applicability determination requires expert verification; this policy is not a substitute for legal advice.

### Related: Privacy Policy, Respecting User Data Sovereignty, Risk Management

Related: Privacy Policy, [Respecting User Data Sovereignty](/design/data-sovereignty.md), and ISMS Risk Management.
