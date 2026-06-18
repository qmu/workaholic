---
title: No Customer Support in the Repository
slug: no-customer-support-in-repo
category: operation
source: https://qmu.co.jp/operation/no-customer-support-in-repo
---

# No Customer Support in the Repository

_Route customer support communication through a dedicated support channel, not through GitHub issues; the repository's issue tracker is for engineering work, not for end-user support requests._

A GitHub issue tracker is designed for engineering: bugs, features, and tasks that result in a commit. When customer support requests arrive as GitHub issues — "I can't log in," "how do I export my data," "my invoice looks wrong" — they mix two concerns in the same inbox: the engineering backlog and the support queue. The two have different triage flows, different resolution owners, and different response-time expectations. Mixing them degrades both: engineering issues compete with support requests for attention, and support requests receive the resolution experience of a code review rather than the resolution experience of a support interaction.

## Goal (目標)

The situation this policy aims to achieve is one in which customer support requests and engineering issues are handled in separate systems, and neither is degraded by the presence of the other.

- Every customer-facing product has a nominated support channel: an email address, a help desk tool (Linear, Intercom, Zendesk, or equivalent), or a support form.
- The path from a support request to resolution does not pass through the GitHub issue tracker.
- Engineering team members have a clear, quick action to take when a support request arrives in the repository: route it to the support channel and close the issue.

## Responsibility (責務)

The situation this policy aims to prevent is one in which customer support requests accumulate in the repository, are handled inconsistently, and cause the engineering backlog to become unreadable.

States we do not tolerate:

- Customer support requests answered in GitHub issues without being routed to the support channel.
- A repository issue tracker used as the primary contact point for end-user issues, in the absence of a dedicated support channel.
- Engineering team members spending significant time in GitHub issues triaging whether a report is a bug or a support request, without a clear protocol.

## Practices (実践)

### Nominate a support channel before the product goes live

Before the first user reaches the product, nominate a support channel: an email address at minimum, a help desk tool if the volume warrants it. The contact path is published in the product's help or about page. Users who encounter a problem have a directed path that does not go through GitHub.

### Define the response to support requests in issues

Define and document the response when a customer support request arrives as a GitHub issue. The standard response: thank the reporter, direct them to the support channel with the URL, and close the issue. The close is not dismissive — the issue is unresolved for the engineering team because it should be resolved through the support channel, not the engineering channel.

### Do not use issue labels to manage support requests inside the repository

Creating a `support` label and leaving support-labelled issues open in the repository is not a substitute for a support channel. It means the repository now hosts two issue trackers with one search box.

### Related: CI/CD Automation, AI-Assisted Production Investigation

The engineering issue tracker is maintained as a clean engineering backlog — see [CI/CD Automation](ci-cd.md) for the standards that keep the engineering pipeline healthy. For cases where a reported issue may indicate a production problem, see [AI-Assisted Production Investigation](ai-production-investigation.md).
