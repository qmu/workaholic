---
title: Incident Response Procedure
slug: incident-response
category: safety
source: https://qmu.co.jp/safety/incident-response
---

# Incident Response Procedure

_The five response flows (record, prevent, remediate, disclose, and request external assistance) that the information security officer selects and executes based on incident type and severity._

This document defines the procedures at the time of incident discovery, reporting, and response. Before the policy defined here, preventive efforts are implemented in accordance with the [Security Standards](standard.md). At the same time, the goal is to prevent problems from expanding or becoming prolonged in the event of an issue by preparing to respond quickly and appropriately.

## Goal (目標)

We aim for a state in which, when an incident occurs, the information security officer can promptly determine the type and severity, select the appropriate response flow from the five flows below, and execute the response while keeping stakeholders informed. We aim for a state in which every response is recorded and retrospected, re-occurrence prevention measures are planned and verified, and the organization's incident response capability improves continuously.

## Responsibility (責務)

Our responsibility is to prevent a state in which an incident response is delayed because the information security officer does not have a clear process for making initial judgments, or in which the response is inadequate because the flow selected is not suited to the type and severity of the incident. We prevent a state in which completed incidents are not recorded and retrospected, causing the same type of incident to occur again.

## Practices (実践)

### Response flow

The following diagram shows the overall flow from incident recognition:

1. Recognition of the incident
2. Report to information security officer
3. Determine whether it constitutes an incident
   - If not applicable: Record background and reason for non-applicable determination in Notion and close
   - If applicable: Determine type and severity, decide response procedure, assign person in charge
4. Execute response procedure (alongside: determine whether mandatory reporting/notification obligations under the revised Personal Information Protection Act apply)
5. Complete response procedure

### Initial judgment and response decision

The information security officer who receives a report makes judgments in the following order:

1. Gather details through interview and determine whether the report content constitutes an incident.
   - If determined not to constitute an incident: record the reason in Notion's incident DB and close.
2. Determine the type and severity of the case, decide the response procedure, and assign persons in charge.
3. Determine whether the case falls under mandatory reporting/notification obligations under the revised Personal Information Protection Act.
   - If determined to apply: use the leakage report form referring to the Personal Information Protection Commission's resources on leakage response.

### The five response flows

Response to incidents is carried out by selecting the appropriate flow from the following five flows and following those procedures.

**Flow 1: Record response.** Used for relatively minor issues. Record the incident in the following order, clearly and accurately, concisely and comprehensively: (1) content and degree of disadvantage; (2) subject and period of disadvantage; (3) root cause and status of addressing that cause; (4) analysis and assessment. Pay attention to security and privacy when recording, even when the storage location and sharing destination is a private environment. Share the document with appropriate stakeholders.

**Flow 2: Preventive response.** Selected when a potential future similar or more serious problem should be prevented before it occurs — i.e., when a danger is perceived or a problem is recognized but there is no existing damage to address. Conduct root cause analysis, develop preventive measures, and implement and verify them (or plan them and set a verification date). Even when implementation and verification of preventive measures takes time, it is possible to declare the incident resolved once the preventive measures are sufficiently planned.

**Flow 3: Remediation response.** For cases where actual damage has occurred and needs to be addressed. First priority is resolving ongoing crisis or disadvantage, then investigating to confirm the period and scope of damage. Where restoration, recovery, and mitigation are possible, implement them, while taking sufficient care not to cause secondary damage. For irrecoverable damage, discuss recovery policy with the client. Where our Company is responsible and agrees, confirm whether our insurance coverage applies. Proceed with apology and explanation to affected parties in parallel with these responses. After remediation, proceed to record response and preventive response.

**Flow 4: Disclosure response.** Carries out external disclosure in parallel with remediation response. Determine the disclosure destination and content in consultation with the owner (client or our business division), and disclose. Candidates for disclosure include: the service's announcement function, the corporate site's announcement function, press release distribution services, and vulnerability reports to IPA. Disclosure content, in concise form: (1) content and degree of disadvantage; (2) subjects and period of disadvantage; (3) current situation and background; (4) future response. Notes: be careful about mentioning unconfirmed causes or scope of damage; avoid either making people think they are not affected (or only slightly) when the full picture is unclear, or unnecessarily alarming them and inducing unnecessary action. As a guide: "avoid speculation, actively mention possibilities" — e.g., "possibly X is occurring" is speculation; "up to X people may be affected by X" states a possibility.

**Flow 5: External assistance request.** Selected when internal resources and knowledge are insufficient for incident response — for highly specialized problems or problems requiring objectivity in the response process. Candidates for requesting assistance: cyber incident emergency response companies, forensic investigation firms, public institutions such as the police. After securing cooperation, proceed in accordance with the disclosure response flow unless the cooperating party gives specific instructions or proposals.

### After completing the response flow

After completing each response flow, declare incident resolution to stakeholders, after confirming that the following are complete or planned: conducting and recording a post-mortem; planning re-occurrence prevention measures and setting a validity confirmation date; preparing, submitting, and publishing a report document for stakeholders; handling recovery claims and insurance compensation applications; reviewing whether this standard and the basic web service development policy need revision.

### Incident type classification

Incidents are classified into five types: A-1 (accident or negligence within our Company); A-2 (accident or negligence in a service); B-1 (breach against our Company); B-2 (breach against a service); C-1 (other). The "other" category is selected for cases that are difficult to classify into the above. Note that "incident" is not limited to direct information security cases — any issue where impact on stakeholders is a concern is actively matched and used for problem resolution.

### Severity classification

Incidents are classified into five severity levels: Lv1 (pre-occurrence — no actual damage or judged highly unlikely); Lv2 (minor — actual damage but small impact on stakeholders); Lv3 (moderate — actual damage with direct financial disadvantage, legal violations, or partial attack success); Lv4 (severe I — cases significantly harming stakeholder interests or complete attack success with broad impact); Lv5 (severe II — cases causing serious damage to stakeholders and for which social accountability should be pursued).

The combination of type and severity determines the response flow selection, but this assignment is a guideline and the flow judged appropriate for the individual problem's nature may be selected.
