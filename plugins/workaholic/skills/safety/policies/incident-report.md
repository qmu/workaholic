---
title: Incident Reporting Procedure
slug: incident-report
category: safety
source: https://qmu.co.jp/safety/incident-report
---

# Incident Reporting Procedure

_How developers report a suspected security incident to the information security officer using three structured points: summary, status and certainty, and scope of impact._

This page describes the reporting procedure when a developer recognizes an incident.

## Goal (目標)

We aim for a state in which every developer and collaborator who recognizes a potential incident reports it promptly to the information security officer through the designated channel, using the three-point structure below — so that the information security officer can make a timely determination and the response can begin without delay. We aim for a state in which active reporting is the norm, and the organization learns from each reported incident regardless of severity.

## Responsibility (責務)

Our responsibility is to prevent a state in which developers suppress or minimize reports out of concern for personal consequences, or in which incidents that should be reported are individually judged as non-applicable and go unreported. All responsibility toward stakeholders rests with management; employees and collaborators receive no personal penalty regardless of the content, frequency, or severity of their reports. The focus of each incident is on business processes and products and technology, not on individuals — this is declared in advance to encourage active reporting.

## Practices (実践)

### Report any event that may affect stakeholders, regardless of scale or certainty

Events that raise concern about impact on stakeholders are uniformly subject to reporting regardless of the scale of impact (large or small) or the probability of occurrence (high or low). Events where it is unclear whether they constitute an incident are also subject to reporting. Determination of whether something is an incident is made by the information security officer; individual staff making a determination of non-applicable and an issue later materializing is prevented.

### Report via Slack's "Incident Response" channel with three points

When an employee or collaborator confirms an incident, they report it to the information security officer by mentioning through Slack's "Incident Response" channel. At this time, the report references the following three points.

Example report:

【Incident Report】
1. **Summary of the problem**: Data loss due to configuration change error in the data analysis infrastructure of Company X
2. **Status and certainty**: Occurred January 1, 2024, unresolved, occurrence confirmed
3. **Scope of impact**: Within client, estimated 3 people affected

Reporting by phone or in person is not prohibited, but please also report via Slack even after the fact. This is to enable retrospective review by recording the response history.

The first report's content should be kept concise — this reduces the reporter's barrier and prevents delays in initial response due to slow reporting. Details are gathered through follow-up interviews as needed.

**1. Summary of the problem.** Describe the incident content so it is immediately understandable. It is recommended to keep this short so the report can be completed first, with details added to Slack after reporting. Example descriptions: information leakage from a web application exploit; unnecessary cost incurred from cloud infrastructure configuration error; unresolved error preventing management-privilege users from logging in; data loss from configuration change error in client's data analysis infrastructure; data destruction from a bug during improvement work on X service.

*Note: In actual reports, please also refer to the client, project name, and service name.*

**2. Status and certainty.** Clarify: (1) Is this a currently ongoing problem or one that existed in the past? (2) Is this a definitively occurring problem or one that may be occurring? Example: "Occurred January 1, 2024, unresolved, occurrence confirmed"; "From service start through the fix release on January 1, 2024 — inclusion of the bug is confirmed, actual information leakage unknown."

*Note: Please mention detailed time periods when known.*

**3. Scope of impact.** Describe the subjects that suffer disadvantage from this incident and their numbers. In many cases the subject is specific individuals, but is not limited to natural persons (disadvantage to legal entities is also possible). Examples: "Estimated 1,000 or more people including non-current users (e.g. resigned users)"; "All users of the X feature of the X service within the client, 12 people"; "Billing for client's X project AWS account."

### After reporting

Response is carried out in accordance with [Incident Response Procedure](incident-response.md).
