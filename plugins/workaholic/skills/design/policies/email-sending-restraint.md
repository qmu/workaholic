---
title: Careful Consideration of Email Sending
slug: email-sending-restraint
category: design
source: https://qmu.co.jp/design/email-sending-restraint
---

# Careful Consideration of Email Sending

_Evaluate each proposed email trigger carefully before adding it; unsolicited or unexpected email erodes deliverability and user trust, and the operational surface of email is wider than it appears._

Email is a high-trust channel that is easy to abuse and hard to restore once trust is damaged. A product that sends too much email, or email users did not expect, generates unsubscribes and spam reports. Spam reports damage deliverability for all emails from the domain — including transactional ones that users do want. The operational surface of email is wider than it first appears: bounce management, unsubscribe handling, SPF/DKIM/DMARC configuration, sending reputation, and compliance with CAN-SPAM and similar laws. We treat each email trigger as requiring deliberate justification rather than being easy to add.

## Goal (目標)

The situation this policy aims to achieve is one in which every email the product sends is wanted by the recipient.

- Email is sent only for events the user has a clear expectation of receiving an email about.
- Unsubscribe and preference management are complete before any marketing or notification email is sent.
- The sending infrastructure is configured correctly (SPF, DKIM, DMARC) before the first production email is sent.
- Each new email trigger is reviewed and justified before it is shipped.

## Responsibility (責務)

The situation this policy aims to prevent is one in which email is added incrementally without a review, until the product is sending more email than users want, damaging deliverability and trust.

States we do not tolerate:

- Adding a new email trigger without considering whether the recipient will have expected it.
- Sending marketing, re-engagement, or notification emails before unsubscribe management is in place.
- Sending from a domain without SPF, DKIM, and DMARC configured. Email sent from an improperly configured domain is likely to be filtered or blocked.
- Email that does not include an unsubscribe link, where one is legally required.

## Practices (実践)

### Classify each email as transactional or marketing before sending

Transactional emails (password reset, receipt, security alert) have a different legal and expectation basis than marketing emails (newsletters, product announcements, re-engagement). Each proposed email is classified before it is built. Transactional emails may be sent to users who have unsubscribed from marketing, but must not include marketing content.

### Use a managed transactional email service

Send email through a dedicated transactional email service (Resend, Postmark, SendGrid, AWS SES) rather than directly. These services handle bounce management, unsubscribe tracking, and provide visibility into deliverability. Do not self-host an SMTP server for production email unless there is a specific requirement.

### Configure authentication before the first production send

Before the first email is sent in production, configure SPF, DKIM, and DMARC for the sending domain. Confirm with the email service's domain verification flow. This is not something that can be retrofitted cleanly.

### Review new email triggers in PR

Each new email trigger is reviewed in the PR that introduces it. The review asks: will recipients have expected this email? Is unsubscribe management in place? Is the email classified correctly as transactional or marketing? Is there a rate limit on how frequently this trigger can fire per user?

### Related: Elimination of Dark Patterns, Recording of Policy Changes and Consent

Unsubscribe flows must not use dark patterns — [Elimination of Dark Patterns](no-dark-patterns.md). Consent for marketing email is part of the consent-recording model — [Recording of Policy Changes and Consent](consent-recording.md).
